//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING = gray

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

// greetd's login screen, in a niri of its own (modules/greeter.nix): the
// clock, the date, the password field and the reader's icon of the lock in
// ~/.dotfiles, over the session's last wallpaper, blurred and dimmed. One user
// and one session, both from the environment.
ShellRoot {
    id: root

    readonly property string user: Quickshell.env("GREETER_USER")
    readonly property string session: Quickshell.env("GREETER_SESSION")
    // Where the session leaves what awww shows, a file per output.
    readonly property string wallpapers: Quickshell.env("GREETER_WALLPAPERS")

    // Catppuccin Mocha and the bar's font, as Theme.qml in ~/.dotfiles.
    readonly property color base: "#1e1e2e"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color green: "#a6e3a1"
    readonly property color red: "#f38ba8"
    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 17

    property string buffer: ""
    // Enter was pressed: no key but Esc is taken until PAM has answered.
    property bool entered: false
    // PAM waits for an answer, and how many it has had in this conversation.
    property bool asked: false
    property int answered: 0
    property bool accepted: false
    property bool rejected: false
    // What the empty field says, and whether what is typed may be seen: a
    // question after the password is PAM's to word.
    property string prompt: "password"
    property bool plain: false
    // The line below the field: what PAM or greetd had to say.
    property string status: Greetd.available ? "" : "greetd is not there"
    // The reader's icon: "" not asked, "waiting" for a finger, "bad" for a
    // moment after one it did not recognise, "ok" after one it did.
    property string finger: ""
    // Fingers not recognised in this conversation, and whether the reader
    // asked for one: it does not when there is none, or it is still held.
    property int misses: 0
    property bool readerAsked: false
    // When someone came back to dark screens, in ms.
    property real wokeAt: 0
    // A conversation is to be started, this long after the last one was
    // dropped, and whether PAM has said anything in the one there is.
    property bool wanted: false
    property int delay: 250
    property bool heard: false

    // A conversation is open whenever someone may be there: pam_fprintd
    // waits for a finger in it, then PAM asks for the password. Nothing typed
    // by then, and it is started over, for the reader to wait again.
    function begin() {
        rearm.stop();
        heard = false;
        asked = false;
        answered = 0;
        misses = 0;
        readerAsked = false;
        finger = "";
        Greetd.createSession(user);
    }

    // Not at once: Quickshell does not wait for greetd's answer to the
    // cancel, and would take it for the new conversation's success.
    function restart() {
        if (accepted)
            return;
        rearm.stop();
        wanted = true;
        // Nothing to answer until the next one asks.
        asked = false;
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        starter.restart();
    }

    // What was typed and asked is forgotten.
    function forget() {
        buffer = "";
        entered = false;
        asked = false;
        prompt = "password";
        plain = false;
    }

    function answer() {
        asked = false;
        answered++;
        Greetd.respond(buffer);
    }

    function enter() {
        if (entered || accepted)
            return;
        entered = true;
        status = "";
        // Else it is sent when PAM asks: the reader has its seconds first.
        if (asked)
            answer();
    }

    // What was typed is dropped. The conversation too, unless the reader
    // still waits in it: cancelled then, it would hold the reader.
    function cancel() {
        if (accepted)
            return;
        rejectionShown.stop();
        rejected = false;
        const waits = Greetd.state === GreetdState.Authenticating && !asked && answered === 0;
        forget();
        if (!waits)
            restart();
    }

    function key(event) {
        event.accepted = true;
        // The key that lights the screens is not typed.
        if (idle.isIdle || Date.now() - wokeAt < 300)
            return;
        if (event.key === Qt.Key_Escape) {
            cancel();
            return;
        }
        if (entered || accepted)
            return;
        // A key during the red line starts the next attempt.
        if (rejected) {
            rejectionShown.stop();
            rejected = false;
        }
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            enter();
            break;
        case Qt.Key_Backspace:
            buffer = event.modifiers & Qt.ControlModifier ? "" : buffer.slice(0, -1);
            // Nothing left to send: the reader again.
            if (buffer === "" && asked && answered === 0)
                restart();
            break;
        default:
            // Printable characters only.
            if (event.text.length > 0 && event.text >= " " && event.text !== "\x7f")
                buffer += event.text;
        }
    }

    Component.onCompleted: if (Greetd.available)
        begin()

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.heard = true;
            if (!responseRequired) {
                // pam_fprintd: its prompt for a finger, an error for each one
                // not recognised, and a word when it gives up.
                if (error && !/timed out/i.test(message)) {
                    root.misses++;
                    root.finger = "bad";
                    root.status = message.trim();
                    missShown.restart();
                } else if (!error) {
                    root.readerAsked = true;
                    if (root.finger !== "bad")
                        root.finger = "waiting";
                }
                return;
            }
            missShown.stop();
            root.finger = "";
            root.status = "";
            if (root.answered > 0) {
                // A second question: typed, then entered.
                root.buffer = "";
                root.entered = false;
                root.asked = true;
                root.prompt = message.trim().replace(/:$/, "").toLowerCase();
                root.plain = echoResponse;
                return;
            }
            // A conversation in order: the wait before the next one goes
            // back towards what it was.
            root.delay = Math.max(250, Math.round(root.delay * 3 / 4));
            root.asked = true;
            if (root.entered)
                root.answer();
            else if (root.buffer !== "" || idle.isIdle)
                return;
            else if (root.misses >= 3 || !root.readerAsked)
                // Not at once: the reader's limit holds, and a reader that is
                // not there, or held by a conversation dropped while it
                // waited, is tried again in a while.
                rearm.restart();
            else
                root.restart();
        }

        function onAuthFailure(message) {
            root.forget();
            root.rejected = true;
            rejectionShown.restart();
            // Quickshell cancels what is left of it.
            root.wanted = true;
            starter.restart();
        }

        function onReadyToLaunch() {
            // The answer to a cancel after all, come late: PAM lets nobody
            // in without a word. Once more, with a longer wait.
            if (!root.heard) {
                root.delay = Math.min(root.delay * 2, 4000);
                root.restart();
                return;
            }
            root.accepted = true;
            if (root.answered === 0)
                root.finger = "ok";
            // The session's type is logind's to know: greetd has a VT, which
            // makes it a tty otherwise.
            Greetd.launch([root.session], ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=niri"], true);
        }

        // greetd's own, a session it could not start among them. Started
        // over in a while, not at once: it would be, without end.
        function onError(error) {
            root.accepted = false;
            root.forget();
            root.finger = "";
            root.status = error;
            rearm.restart();
        }
    }

    Timer {
        id: starter
        interval: root.delay
        onTriggered: {
            if (!root.wanted || root.accepted)
                return;
            // Dropped again meanwhile, by Quickshell.
            if (Greetd.state !== GreetdState.Inactive) {
                root.restart();
                return;
            }
            root.wanted = false;
            root.begin();
        }
    }

    Timer {
        id: rejectionShown
        interval: 1500
        onTriggered: root.rejected = false
    }

    // How long the mark of a finger not recognised stays, and its line.
    Timer {
        id: missShown
        interval: 1500
        onTriggered: {
            root.finger = "waiting";
            root.status = "";
        }
    }

    // The reader again: half a minute after three fingers it did not know,
    // else in a few seconds.
    Timer {
        id: rearm
        interval: root.misses >= 3 ? 30000 : 5000
        onTriggered: if (Greetd.state === GreetdState.Inactive || (root.buffer === "" && !root.entered))
            root.restart()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The screens go dark after a minute; niri lights them at the next key.
    // Nobody there, and the conversation rests at the password; someone
    // back, and the reader waits again.
    IdleMonitor {
        id: idle
        timeout: 60
        onIsIdleChanged: {
            if (isIdle) {
                Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
                return;
            }
            root.wokeAt = Date.now();
            // Only one that rests: the reader waits in any other.
            if (root.asked && root.answered === 0 && root.buffer === "")
                root.restart();
        }
    }

    // Left at the login screen, the machine sleeps, as in the session
    // (~/.dotfiles, hypridle.conf).
    IdleMonitor {
        timeout: 600
        onIsIdleChanged: if (isIdle)
            Quickshell.execDetached(["systemctl", "suspend"])
    }

    component Label: Text {
        color: root.subtext0
        textFormat: Text.PlainText
        font.family: root.font
        font.pixelSize: root.fontSize
    }

    // A glyph that runs a command, in the screen's corner.
    component Button: Label {
        id: button

        required property list<string> command

        font.pixelSize: 24
        color: area.containsMouse ? root.subtext1 : root.subtext0
        opacity: area.containsMouse ? 1 : 0.6

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            onClicked: Quickshell.execDetached(button.command)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            color: root.base
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => root.key(event)
            }

            // None for this output, and the screen is plain.
            Image {
                id: image
                anchors.fill: parent
                visible: false
                source: root.wallpapers ? "file://" + root.wallpapers + "/" + modelData.name + ".jpg" : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Item {
                anchors.fill: parent
                opacity: image.status === Image.Ready ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: image
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    autoPaddingEnabled: false
                }

                // Dims the wallpaper, so the text reads on a bright one.
                Rectangle {
                    anchors.fill: parent
                    color: root.base
                    opacity: 0.7
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 24

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 96
                    font.bold: true
                    color: root.subtext1
                    opacity: 0.9
                    // Qt's default renderer leaves text this large with
                    // rough, colour-fringed edges.
                    renderType: Text.CurveRendering
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.user
                }

                // The password field: a mark per character typed.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    height: 48

                    Label {
                        anchors.centerIn: parent
                        visible: root.buffer === ""
                        text: root.rejected ? "not let in" : root.entered ? "checking…" : root.prompt
                        color: root.rejected ? root.red : root.subtext0
                    }

                    Label {
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width)
                        elide: Text.ElideLeft
                        visible: root.plain
                        text: root.buffer
                        color: root.subtext1
                    }

                    Row {
                        id: marks

                        anchors.centerIn: parent
                        visible: !root.plain
                        spacing: 8

                        // Pulses while the password is checked.
                        SequentialAnimation on opacity {
                            running: root.entered && !root.accepted
                            loops: Animation.Infinite
                            onStopped: marks.opacity = 1

                            NumberAnimation {
                                to: 0.35
                                duration: 450
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 1
                                duration: 450
                                easing.type: Easing.InOutSine
                            }
                        }

                        Repeater {
                            // As many as the field is wide.
                            model: Math.min(root.buffer.length, 18)

                            Label {
                                // The bar's mark of the active workspace.
                                text: String.fromCodePoint(0xf14fb)
                                color: root.accepted ? root.green : root.subtext1
                            }
                        }
                    }
                }

                // The reader's icon. It keeps its place when not shown, so
                // nothing moves.
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String.fromCodePoint(0xf0237)
                    font.pixelSize: 36
                    opacity: root.finger === "" ? 0 : 1
                    color: root.finger === "ok" ? root.green : root.finger === "bad" ? root.red : root.subtext0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Keeps its line when empty, so nothing moves.
                    text: root.status !== "" ? root.status : " "
                    color: root.red
                    font.pixelSize: root.fontSize - 2
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 32
                spacing: 32

                Button {
                    text: String.fromCodePoint(0xf0709)
                    command: ["systemctl", "reboot"]
                }

                Button {
                    text: String.fromCodePoint(0xf0425)
                    command: ["systemctl", "poweroff"]
                }
            }
        }
    }
}
