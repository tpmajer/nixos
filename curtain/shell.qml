import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A curtain over the session's first moments, in niri's backdrop colour,
// lifted in a fade once a wallpaper is there (modules/greeter.nix). The bar
// is not waited for: it pops in by itself. Background in notes/greeter.md.
ShellRoot {
    id: root

    property bool lifting: false

    // niri's backdrop: the crust of the palette the session left for the
    // login screen, Catppuccin's with none.
    FileView {
        id: paletteFile
        path: Quickshell.env("CURTAIN_PALETTE")
        blockLoading: true
        printErrors: false
    }
    readonly property color backdrop: paletteFile.text().match(/^crust=(#[0-9a-fA-F]{6})$/m)?.[1] ?? "#11111b"

    // Ends when niri has a wallpaper's layer, or in 2 s.
    Process {
        running: true
        command: [Quickshell.env("CURTAIN_WAIT"), "150", 'Namespace: "(wallpaper|awww-daemon)"']
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
                color: root.backdrop
                opacity: root.lifting ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running && root.lifting)
                            Qt.quit()
                    }
                }
            }
        }
    }
}
