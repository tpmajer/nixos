//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING = gray

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

// greetd's login screen, in a niri of its own (modules/greeter.nix): what the
// lock in ~/.dotfiles shows (lock/LockView.qml), copied, over the session's
// last wallpaper. One user, from the environment, and the sessions the system
// has.
ShellRoot {
    id: root

    readonly property string user: Quickshell.env("GREETER_USER")
    // The sessions to choose from, as a display manager finds them: the
    // desktop entries of a directory, [{ id: the file's name without its
    // ending, name, exec, desktops: its DesktopNames, ":" between them }].
    property var sessions: []
    // The one to start: niri, unless another is chosen; else the first.
    property int chosen: 0
    readonly property var session: sessions[chosen] ?? null

    function nextSession() {
        if (sessions.length > 1 && !accepted)
            chosen = (chosen + 1) % sessions.length;
    }

    Process {
        running: true
        command: ["sh", "-c", 'for f in "$1"/*.desktop; do echo "[$f]"; cat "$f"; done', "sh", Quickshell.env("GREETER_SESSIONS")]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const line of text.split("\n")) {
                    const file = line.match(/^\[\/.*\/([^\/]+)\.desktop\]$/);
                    const key = line.match(/^(Name|Exec|DesktopNames)=(.*)$/);
                    if (file)
                        found.push({id: file[1], name: file[1], exec: "", desktops: ""});
                    else if (key && found.length > 0)
                        found[found.length - 1][{Name: "name", Exec: "exec", DesktopNames: "desktops"}[key[1]]] = key[2].replace(/;+$/, "").replace(/;/g, ":");
                }
                const sessions = found.filter(s => s.exec !== "");
                root.chosen = Math.max(0, sessions.findIndex(s => s.id === "niri"));
                root.sessions = sessions;
            }
        }
    }

    // Where the session leaves what awww shows, a file per output.
    readonly property string wallpapers: Quickshell.env("GREETER_WALLPAPERS")

    // Catppuccin Mocha and the bar's font, as Theme.qml in ~/.dotfiles.
    readonly property color base: "#1e1e2e"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color green: "#a6e3a1"
    readonly property color peach: "#fab387"
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
    // The marks, kept green or red for a moment after the answer, and what
    // the red ones turn into.
    property bool rejected: false
    property int frozenMarks: -1
    property string rejection: ""
    readonly property int marks: frozenMarks >= 0 ? frozenMarks : buffer.length
    // What the empty field says, and whether what is typed may be seen: a
    // question after the password is PAM's to word.
    property string prompt: "password"
    property bool plain: false
    // The line below the field: what the reader, PAM or greetd had to say.
    property string status: Greetd.available ? "" : "greetd is not there"
    property bool capsLock: false
    // The reader's icon: "" not asked, "waiting" for a finger, "bad" for a
    // moment after one it did not recognise, "ok" after one it did.
    property string finger: ""
    // Fingers not recognised in this conversation, and whether the reader
    // asked for one: it does not when there is none, or it is still held.
    property int misses: 0
    property bool readerAsked: false
    // When someone came back to dark screens, in ms.
    property real wokeAt: 0
    // How long after one conversation was dropped the next is started, and
    // whether PAM has said anything in the one there is.
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

    // The red marks go, the field is empty again. They stay red while they
    // fade, unless a key has already started the next attempt.
    function endRejection(now = true) {
        if (!rejected)
            return;
        rejectionShown.stop();
        frozenMarks = -1;
        if (now) {
            rejectionFade.stop();
            rejected = false;
        } else {
            rejectionFade.restart();
        }
    }

    // What was typed is dropped, and the conversation with it, but for two
    // that greetd is busy in and would answer late, into the next one. Where
    // the reader still waits, the conversation stays: cancelled, it would
    // hold the reader too. Where an answer is being checked, nothing is
    // done: PAM's word on it comes first.
    function cancel() {
        if (accepted)
            return;
        if (Greetd.state === GreetdState.Authenticating && !asked && answered > 0)
            return;
        endRejection();
        rejection = "";
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
        if (event.key === Qt.Key_Tab) {
            nextSession();
            return;
        }
        // A moment later, for niri to have set the LED.
        if (event.key === Qt.Key_CapsLock) {
            capsDelay.restart();
            return;
        }
        if (event.key === Qt.Key_Escape) {
            cancel();
            return;
        }
        if (entered || accepted)
            return;
        // A key during the red marks starts the next attempt.
        endRejection();
        rejection = "";
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
                // pam_fprintd's, told by their words, which are English
                // under the system's locale: its prompt for a finger, an
                // error for one it does not know, which counts, or could not
                // read, which does not, and a word when it gives up.
                if (/timed out/i.test(message))
                    return;
                if (!/finger|swipe|sensor|reader/i.test(message)) {
                    // Another module's: said, and no more.
                    root.status = message.trim();
                } else if (error) {
                    if (/match/i.test(message))
                        root.misses++;
                    root.finger = "bad";
                    root.status = "fingerprint not recognised";
                    missShown.restart();
                } else {
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
            root.frozenMarks = root.buffer.length;
            root.forget();
            root.rejected = true;
            root.rejection = "wrong password";
            rejectionShown.restart();
            rejectionGone.restart();
            // Quickshell cancels what is left of it.
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
            const session = root.session;
            if (!session) {
                root.forget();
                root.status = "no session to start";
                root.restart();
                return;
            }
            // The marks turn green, and what was typed is not kept.
            root.frozenMarks = root.buffer.length;
            root.buffer = "";
            root.accepted = true;
            if (root.answered === 0)
                root.finger = "ok";
            // What a display manager says of the session. Its type is
            // logind's to know: greetd has a VT, which makes it a tty
            // otherwise.
            const environment = ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=" + session.id];
            if (session.desktops !== "")
                environment.push("XDG_CURRENT_DESKTOP=" + session.desktops);
            // greetd hands the command to a shell, after /etc/profile.
            Greetd.launch([session.exec], environment, true);
        }

        // greetd's own, a session it could not start among them. Started
        // over in a while, not at once: it would be, without end.
        function onError(error) {
            root.accepted = false;
            root.frozenMarks = -1;
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
            if (root.accepted)
                return;
            // Dropped again meanwhile, by Quickshell.
            if (Greetd.state !== GreetdState.Inactive) {
                root.restart();
                return;
            }
            root.begin();
        }
    }

    Timer {
        id: rejectionShown
        interval: 800
        onTriggered: root.endRejection(false)
    }

    // From the rejection: the red marks' time, then the three seconds.
    Timer {
        id: rejectionGone
        interval: rejectionShown.interval + 3000
        onTriggered: root.rejection = ""
    }

    Timer {
        id: rejectionFade
        interval: 120
        onTriggered: root.rejected = false
    }

    // Read at the start and after the Caps Lock key is pressed and released.
    Process {
        id: capsQuery
        running: true
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.capsLock = /[1-9]/.test(text)
        }
    }

    Timer {
        id: capsDelay
        interval: 60
        onTriggered: capsQuery.running = true
    }

    // BAT1 from sysfs, as the bar's module: the icon by the tenth, and the
    // bar's warning colours while it runs low.
    QtObject {
        id: battery

        property int capacity: -1
        property string status: ""
        readonly property bool known: capacity >= 0
        readonly property bool charging: status === "Charging"
        readonly property bool low: status === "Discharging" && capacity <= 25
        readonly property color color: !low ? root.subtext0 : capacity <= 15 ? root.red : root.peach
        readonly property var chargingIcons: [0xf089c, 0xf0086, 0xf0087, 0xf0088, 0xf089d, 0xf0089, 0xf089e, 0xf008a, 0xf008b, 0xf0085]
        readonly property var defaultIcons: [0xf007a, 0xf007b, 0xf007c, 0xf007d, 0xf007e, 0xf007f, 0xf0080, 0xf0081, 0xf0082, 0xf0079]
        readonly property string icon: String.fromCodePoint((charging ? chargingIcons : defaultIcons)[Math.min(9, Math.floor(Math.max(0, capacity) / 10))])
    }

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT1/capacity"
        onLoaded: battery.capacity = Number(text().trim())
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT1/status"
        onLoaded: battery.status = text().trim()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            capacityFile.reload();
            statusFile.reload();
        }
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
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_CapsLock)
                        capsDelay.restart();
                }
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

                // The lock's row, of which only the battery is known here.
                // It keeps its line without one, so nothing moves.
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: battery.known ? battery.icon + " " + battery.capacity + "%" : " "
                    color: battery.color
                }

                Item {
                    width: 1
                    height: 24
                }

                // The password field: a mark per character typed.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    height: 48

                    // The bar's shape and shadow, see-through as a whole.
                    Item {
                        anchors.fill: parent
                        opacity: 0.7

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#77000000"
                            shadowBlur: 1.0
                            blurMax: 24
                            shadowVerticalOffset: 3
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: root.base
                        }
                    }

                    Label {
                        id: placeholder
                        readonly property bool shown: root.marks === 0 && !(root.plain && root.buffer !== "")

                        anchors.centerIn: parent

                        text: root.rejection !== "" ? root.rejection : root.entered ? "checking…" : root.prompt
                        color: root.rejection !== "" ? root.red : root.subtext0

                        Behavior on color {
                            ColorAnimation {
                                duration: 250
                            }
                        }

                        // Gone at the first key; back once the marks have
                        // faded.
                        states: State {
                            name: "typing"
                            when: !placeholder.shown
                            PropertyChanges {
                                placeholder.opacity: 0
                            }
                        }
                        transitions: Transition {
                            from: "typing"
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: 100
                                }
                                NumberAnimation {
                                    property: "opacity"
                                    duration: 150
                                }
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 24)
                        elide: Text.ElideLeft
                        visible: root.plain
                        text: root.buffer
                        color: root.subtext1
                        opacity: marks.opacity
                    }

                    // One per character typed: a mark fades and grows in at
                    // the end of the row, which stays centred by sliding.
                    Row {
                        id: marks

                        x: (parent.width - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.plain
                        spacing: 8

                        // Pulses while the password is checked.
                        SequentialAnimation {
                            running: root.entered && !root.accepted
                            loops: Animation.Infinite
                            onStarted: pulseEnd.stop()
                            onStopped: pulseEnd.start()

                            NumberAnimation {
                                target: marks
                                property: "opacity"
                                to: 0.35
                                duration: 450
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: marks
                                property: "opacity"
                                to: 1
                                duration: 450
                                easing.type: Easing.InOutSine
                            }
                        }

                        // Back to full from wherever the pulse was.
                        NumberAnimation {
                            id: pulseEnd
                            target: marks
                            property: "opacity"
                            to: 1
                            duration: 150
                        }

                        Behavior on x {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            // As many as the field is wide, shown one per
                            // character: counting the characters would make
                            // all of them anew at every key.
                            model: 18

                            // The bar's mark of the active workspace.
                            Label {
                                required property int index
                                readonly property bool typed: index < root.marks

                                text: String.fromCodePoint(0xf14fb)
                                color: root.accepted ? root.green : root.rejected ? root.red : root.subtext1

                                // Red comes in gradually. Green does not:
                                // what shows it is gone within a few frames.
                                Behavior on color {
                                    enabled: !root.accepted
                                    ColorAnimation {
                                        duration: 250
                                    }
                                }
                                opacity: typed ? 1 : 0
                                scale: typed ? 1 : 0.4
                                // Out of the row once faded: the row is as
                                // wide as what was typed.
                                visible: opacity > 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: typed ? 150 : 100
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: typed ? 200 : 100
                                        easing.type: typed ? Easing.OutBack : Easing.InQuad
                                    }
                                }
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
                    // Caps Lock, which matters while typing, else what the
                    // reader or greetd had to say. Keeps its line when
                    // empty, so nothing moves.
                    text: root.capsLock ? "caps lock is on" : root.status !== "" ? root.status : " "
                    color: root.capsLock ? root.peach : root.red
                    font.pixelSize: root.fontSize - 2
                }
            }

            // The session to start; a click or Tab, and it is the next one.
            // Not there with one to choose from.
            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 32
                visible: root.sessions.length > 1
                text: root.session?.name ?? ""
                color: sessionArea.containsMouse ? root.subtext1 : root.subtext0
                opacity: sessionArea.containsMouse ? 1 : 0.6

                MouseArea {
                    id: sessionArea
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    onClicked: root.nextSession()
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
