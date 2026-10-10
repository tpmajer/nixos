# org.kde.secretprompter, the prompter oo7 asks for a keyring's password when
# it takes the desktop for Plasma, with Quickshell drawing the prompt
# (~/.dotfiles, Keyring.qml). Started by D-Bus for a request, gone 10 s after
# the last one. Protocol in notes/oo7.md.

import asyncio
import json
import os
import socket
import traceback

from dbus_fast import Message, MessageType, NameFlag
from dbus_fast.aio import MessageBus

NAME = "org.kde.secretprompter"
PATH = "/SecretPrompter"
REQUEST = "org.kde.secretprompter.request"
ROLES = {
    "UnlockCollectionPrompt": "unlock",
    "CreateCollectionPrompt": "create",
}
SOCKET = os.environ["XDG_RUNTIME_DIR"] + "/quickshell-keyring.sock"
IDLE = 10


async def serve(bus, events, sender, path, role, collection):
    """One prompt, from its request to the Dismissed that ends it."""

    async def call(member, fd=None):
        reply = await bus.call(
            Message(
                destination=sender,
                path=path,
                interface=REQUEST,
                member=member,
                signature="h" if fd is not None else "",
                body=[0] if fd is not None else [],
                unix_fds=[fd] if fd is not None else [],
            )
        )
        # The action, 0 to dismiss or 1 to keep; None for an error.
        if reply.message_type is not MessageType.METHOD_RETURN:
            return None
        return reply.body[0] if reply.body else 0

    async def accepted(password):
        # oo7 reads the password from a socket, to its end.
        ours, theirs = socket.socketpair()
        try:
            ours.sendall(password.encode())
            ours.close()
            return await call("Accepted", theirs.fileno())
        finally:
            theirs.close()

    # Dismissed while it waited its turn: not shown at all.
    while not events.empty():
        if events.get_nowait()[0] == "Dismiss":
            await call("Dismissed")
            return

    try:
        reader, writer = await asyncio.open_unix_connection(SOCKET)
    except OSError:
        # No Quickshell to ask with.
        await call("Rejected")
        await call("Dismissed")
        return

    def say(**message):
        writer.write(json.dumps(message).encode() + b"\n")

    say(event="prompt", role=role, collection=collection)
    line = asyncio.ensure_future(reader.readline())
    event = asyncio.ensure_future(events.get())
    try:
        while True:
            await asyncio.wait(
                {line, event}, return_when=asyncio.FIRST_COMPLETED
            )
            if event.done():
                member, body = event.result()
                if member == "Dismiss":
                    break
                if member == "Retry":
                    say(event="retry", reason=body[0] if body else "")
                event = asyncio.ensure_future(events.get())
                continue
            # No password is a cancel, or Quickshell gone: no line of its.
            try:
                password = json.loads(line.result()).get("password")
            except (OSError, ValueError, AttributeError):
                password = None
            if not isinstance(password, str):
                await call("Rejected")
                break
            action = await accepted(password)
            if action != 1:
                say(event="done" if action == 0 else "failed")
                break
            # Kept for another try: Retry has said why by now.
            line = asyncio.ensure_future(reader.readline())
    except Exception:
        # Not left waiting, whatever went wrong here.
        await call("Rejected")
        raise
    finally:
        line.cancel()
        event.cancel()
        writer.close()
        await call("Dismissed")


async def main():
    bus = await MessageBus(negotiate_unix_fd=True).connect()
    requests = asyncio.Queue()
    # What oo7 signals to each prompt, by (sender, request path).
    signals = {}

    def handle(message):
        if (
            message.message_type is MessageType.METHOD_CALL
            and message.path == PATH
            and message.interface == NAME
            and message.member in ROLES
            and message.signature == "osss"
        ):
            request, _window, _token, collection = message.body
            key = (message.sender, request)
            signals[key] = asyncio.Queue()
            requests.put_nowait((key, ROLES[message.member], collection))
            return Message.new_method_return(message)
        if (
            message.message_type is MessageType.SIGNAL
            and message.interface == REQUEST
        ):
            events = signals.get((message.sender, message.path))
            if events is not None:
                events.put_nowait((message.member, message.body))
        return None

    bus.add_message_handler(handle)
    await bus.call(
        Message(
            destination="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            interface="org.freedesktop.DBus",
            member="AddMatch",
            signature="s",
            body=[f"type='signal',interface='{REQUEST}'"],
        )
    )
    await bus.request_name(NAME, NameFlag.DO_NOT_QUEUE)

    # One prompt at a time.
    while True:
        try:
            key, role, collection = await asyncio.wait_for(
                requests.get(), IDLE
            )
        except TimeoutError:
            # The name first: a request after this starts another of us.
            await bus.release_name(NAME)
            if requests.empty():
                break
            continue
        # A prompt that fails does not take those waiting with it.
        try:
            await serve(bus, signals[key], *key, role, collection)
        except Exception:
            traceback.print_exc()
        finally:
            del signals[key]


asyncio.run(main())
