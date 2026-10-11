import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A curtain over the session's first moments, in niri's backdrop colour,
// lifted in a fade once the bar and a wallpaper are there
// (modules/sddm.nix). Background in notes/sddm.md.
ShellRoot {
    id: root

    property bool lifting: false

    // Ends when niri has the bar's layer and a wallpaper's, or in 2 s.
    Process {
        running: true
        command: [Quickshell.env("CURTAIN_WAIT"), "150", 'Namespace: "quickshell-bar"', 'Namespace: "(wallpaper|awww-daemon)"']
        onExited: settle.start()
    }

    // A moment for what is under it to be drawn.
    Timer {
        id: settle
        interval: 80
        onTriggered: root.lifting = true
    }

    // Lifted all the same, should the wait not end.
    Timer {
        interval: 3000
        running: true
        onTriggered: root.lifting = true
    }

    // Nothing reaches it: the pointer and the keys go to what is under it.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "session-curtain"
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: "#11111b"
                opacity: root.lifting ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running && root.lifting)
                            Qt.quit()
                    }
                }
            }
        }
    }
}
