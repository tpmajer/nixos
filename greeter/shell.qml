//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING = gray

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

// greetd's login screen, in a niri of its own (modules/greeter.nix): the
// clock, the date and the password field of the lock in ~/.dotfiles, on a
// plain background. One user and one session, both from the environment.
ShellRoot {
    id: root

    readonly property string user: Quickshell.env("GREETER_USER")
    readonly property string session: Quickshell.env("GREETER_SESSION")

    // Catppuccin Mocha and the bar's font, as Theme.qml in ~/.dotfiles.
    readonly property color base: "#1e1e2e"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color green: "#a6e3a1"
    readonly property color red: "#f38ba8"
    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 17

    property string buffer: ""
    // Entered, and not answered yet: no key but Esc is taken.
    property bool checking: false
    // Whether greetd's first question got the password.
    property bool sent: false
    // greetd waits for an answer that is still to be typed.
    property bool asked: false
    property bool accepted: false
    property bool rejected: false
    // What the empty field says, and whether what is typed may be seen: a
    // question after the password is PAM's to word.
    property string prompt: "password"
    property bool plain: false
    // The line below the field: what PAM or greetd had to say.
    property string status: Greetd.available ? "" : "greetd is not there"

    // As new, for the next attempt.
    function reset() {
        buffer = "";
        checking = false;
        sent = false;
        asked = false;
        prompt = "password";
        plain = false;
    }

    function enter() {
        if (checking || accepted)
            return;
        checking = true;
        status = "";
        if (asked) {
            asked = false;
            Greetd.respond(buffer);
        } else {
            Greetd.createSession(user);
        }
    }

    function cancel() {
        if (accepted)
            return;
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        reset();
    }

    function key(event) {
        event.accepted = true;
        if (event.key === Qt.Key_Escape) {
            cancel();
            return;
        }
        if (checking || accepted)
            return;
        // A key during the red marks starts the next attempt.
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
            break;
        default:
            // Printable characters only.
            if (event.text.length > 0 && event.text >= " " && event.text !== "\x7f")
                buffer += event.text;
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) {
                root.status = message.trim();
                return;
            }
            if (!root.sent) {
                root.sent = true;
                Greetd.respond(root.buffer);
                return;
            }
            // A second question: typed, then entered.
            root.buffer = "";
            root.checking = false;
            root.asked = true;
            root.prompt = message.trim().replace(/:$/, "").toLowerCase();
            root.plain = echoResponse;
        }

        function onAuthFailure(message) {
            root.reset();
            root.rejected = true;
            rejectionShown.restart();
        }

        function onReadyToLaunch() {
            root.accepted = true;
            // The session's type is logind's to know: greetd has a VT, which
            // makes it a tty otherwise.
            Greetd.launch([root.session], ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=niri"], true);
        }

        function onError(error) {
            root.reset();
            root.status = error;
        }
    }

    Timer {
        id: rejectionShown
        interval: 1500
        onTriggered: root.rejected = false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The screens go dark after a minute; niri lights them at the next key.
    IdleMonitor {
        timeout: 60
        onIsIdleChanged: if (isIdle)
            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"])
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
                        text: root.rejected ? "not let in" : root.checking ? "checking…" : root.prompt
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
                            running: root.checking
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
