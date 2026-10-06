# Thunderbird and Signal without a window

Both run in the background for their notifications
(`modules/background-apps.nix`), bound to niri.service.

## Thunderbird

The account is under Google's Advanced Protection: no app passwords, and only
a few clients are let at the mail at all, so a small IMAP watcher is not an
option, while Thunderbird is signed in already. Measured on 2026-10-04: about
330 MiB, and a notification with "Mark as Read" and "Delete".

Thunderbird runs one instance per profile. The `thunderbird` command
(`scripts/thunderbird.sh`, over the package's own) stops the headless unit
before the window comes up and starts it again once the window is closed; with
a window up already it is only a message to it. The unit's start is not waited
for: offline it takes up to 60 s.

Thunderbird has no setting for the folder to start in: the first tab comes
back from session.json with the folder it was closed on. The command points
that tab at the Inbox of the same account and selects it; the other tabs stay.

### The wait for the mail server

Logging in can come before the Wi-Fi is up (7 s ahead on 2026-10-06), and the
first mail check then fails with a notification; the next is 10 minutes later.
The same goes for the restart hypridle does after a suspend.

`thunderbird-wait-for-mail-server` waits for imap.gmail.com:993 to answer,
twice 2 s apart and not while `wg0` is coming up, for 60 s at most. Not
`nm-online`: it is done when NetworkManager has any connection, which is
before DNS works (2 s later on 2026-10-06) and before wg-auto has brought the
tunnel up on a foreign network.

It is the first of two `ExecCondition`s and always passes. The second looks
for a Thunderbird window, right before the start and not up to 60 s ahead of
it, and skips the start next to one.

## Signal

Unlike Thunderbird it needs no swapping for the window: started in the tray it
shows none, running it again brings up the window of the instance there is,
and closing that leaves it running. Checked on 8.28.0 with no tray in the bar,
2026-10-05; about 500 MiB.

The unit does not start next to a Signal started some other way: as its second
instance it would only bring that one's window up and end. The
`signal-desktop` command starts the unit first when no Signal runs, and waits
for its lock, so that the instance whose window comes up is the one that
stays.
