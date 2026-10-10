import QtCore
import QtQuick
import QtQuick.Effects

// SDDM's login screen, drawn as the lock in ~/.dotfiles is
// (lock/LockView.qml), copied. One per screen. Background in notes/greeter.md.
Rectangle {
    id: root

    // Catppuccin Mocha and the bar's font, as Theme.qml in ~/.dotfiles.
    readonly property color base: "#1e1e2e"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color green: "#a6e3a1"
    readonly property color peach: "#fab387"
    readonly property color red: "#f38ba8"
    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 17

    // The sessions SDDM has: [{ name, file }], in its model's order.
    property var sessions: []
    // The one to start: niri, unless another is chosen; else SDDM's last.
    property int chosen: 0
    readonly property var session: sessions[chosen] ?? null

    function nextSession() {
        if (sessions.length > 1 && !checking && !accepted)
            chosen = (chosen + 1) % sessions.length;
    }

    property string buffer: ""
    // Entered, and PAM has not answered yet: no key is taken.
    property bool checking: false
    property bool accepted: false
    // The marks, kept green or red for a moment after the answer, and what
    // the red ones turn into.
    property bool rejected: false
    property int frozenMarks: -1
    property string rejection: ""
    readonly property int marks: frozenMarks >= 0 ? frozenMarks : buffer.length
    // The line below the field: what SDDM had to say.
    property string status: ""

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

    function enter() {
        if (checking || accepted)
            return;
        checking = true;
        status = "";
        sddm.login(config.user, buffer, chosen);
    }

    function key(event) {
        event.accepted = true;
        if (checking || accepted)
            return;
        if (event.key === Qt.Key_Tab) {
            nextSession();
            return;
        }
        // A key during the red marks starts the next attempt.
        endRejection();
        rejection = "";
        switch (event.key) {
        case Qt.Key_Escape:
            buffer = "";
            break;
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
        target: sddm

        function onLoginFailed() {
            root.frozenMarks = root.buffer.length;
            root.buffer = "";
            root.checking = false;
            root.rejected = true;
            root.rejection = "wrong password";
            rejectionShown.restart();
            rejectionGone.restart();
        }

        // The window is closed by SDDM right after.
        function onLoginSucceeded() {
            root.frozenMarks = root.buffer.length;
            root.buffer = "";
            root.accepted = true;
        }

        function onInformationMessage(message) {
            root.status = message;
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

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // The battery, as the greeter's compositor leaves it in a file
    // (modules/sddm.nix): a theme can read no sysfs, but it can read settings.
    Settings {
        id: batteryFile
        location: "file://" + config.battery
        category: "battery"
    }

    function readBattery() {
        batteryFile.sync();
        battery.capacity = Number(batteryFile.value("capacity", -1));
        battery.status = String(batteryFile.value("status", ""));
    }

    Component.onCompleted: readBattery()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.readBattery()
    }

    // The icon by the tenth, and the bar's warning colours while it runs low.
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

    // SDDM's sessions, out of its model: a role is read in a delegate alone.
    Repeater {
        model: sessionModel

        Item {
            required property string name
            required property string file
            required property int index

            Component.onCompleted: {
                const sessions = root.sessions.slice();
                sessions[index] = {name: name, file: file};
                root.sessions = sessions;
                if (/(^|\/)niri\.desktop$/.test(file))
                    root.chosen = index;
            }
        }
    }

    component Label: Text {
        color: root.subtext0
        textFormat: Text.PlainText
        font.family: root.font
        font.pixelSize: root.fontSize
    }

    // A glyph that does something, in the screen's corner.
    component Button: Label {
        id: button

        signal pressed

        font.pixelSize: 24
        color: area.containsMouse ? root.subtext1 : root.subtext0
        opacity: area.containsMouse ? 1 : 0.6

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            onClicked: button.pressed()
        }
    }

    color: base

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => root.key(event)
    }

    // The session's last wallpaper on this output (modules/sddm.nix); none,
    // and the screen is plain.
    Image {
        id: image
        anchors.fill: parent
        visible: false
        source: config.wallpapers ? "file://" + config.wallpapers + "/" + Screen.name + ".jpg" : ""
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
            text: Qt.formatDateTime(root.now, "HH:mm")
            font.pixelSize: 96
            font.bold: true
            color: root.subtext1
            opacity: 0.9
            // Qt's default renderer leaves text this large with rough,
            // colour-fringed edges.
            renderType: Text.CurveRendering
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
        }

        // The lock's row, of which only the battery is known here. It keeps
        // its line without one, so nothing moves.
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
                readonly property bool shown: root.marks === 0

                anchors.centerIn: parent

                text: root.rejection !== "" ? root.rejection : root.checking ? "checking…" : "password"
                color: root.rejection !== "" ? root.red : root.subtext0

                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }

                // Gone at the first key; back once the marks have faded.
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

            // One per character typed: a mark fades and grows in at the end
            // of the row, which stays centred by sliding.
            Row {
                id: marks

                x: (parent.width - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Pulses while the password is checked.
                SequentialAnimation {
                    running: root.checking && !root.accepted
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
                    // character: no mark is made anew at a key.
                    model: 18

                    // The bar's mark of the active workspace.
                    Label {
                        required property int index
                        readonly property bool typed: index < root.marks

                        text: String.fromCodePoint(0xf14fb)
                        color: root.accepted ? root.green : root.rejected ? root.red : root.subtext1

                        // Red comes in gradually. Green does not: what
                        // shows it is gone within a few frames.
                        Behavior on color {
                            enabled: !root.accepted
                            ColorAnimation {
                                duration: 250
                            }
                        }
                        opacity: typed ? 1 : 0
                        scale: typed ? 1 : 0.4
                        // Out of the row once faded: the row is as wide as
                        // what was typed.
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

        // Where the lock has the reader's icon: its place is kept.
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String.fromCodePoint(0xf0237)
            font.pixelSize: 36
            opacity: 0
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            // Caps Lock, else what SDDM had to say. Keeps its line when
            // empty, so nothing moves.
            text: keyboard.capsLock ? "caps lock is on" : root.status !== "" ? root.status : " "
            color: keyboard.capsLock ? root.peach : root.red
            font.pixelSize: root.fontSize - 2
        }
    }

    // The session to start; a click or Tab, and it is the next one. Not
    // there with one to choose from.
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
            onPressed: sddm.reboot()
        }

        Button {
            text: String.fromCodePoint(0xf0425)
            onPressed: sddm.powerOff()
        }
    }
}
