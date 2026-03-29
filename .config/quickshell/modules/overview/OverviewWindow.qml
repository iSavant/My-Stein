import QtQuick
import Quickshell
import "../../"

Item {
    id: root

    property var windowData: ({})
    property real cellWidth: 300
    property real cellHeight: 200
    property real monitorWidth: 1920
    property real monitorHeight: 1080

    signal focusWindow(string address)
    signal closeWindow(string address)

    MatugenColors { id: colors }

    // Scale window position/size to cell
    readonly property real scaleX: cellWidth / monitorWidth
    readonly property real scaleY: cellHeight / monitorHeight

    x: (windowData.at ? windowData.at[0] : 0) * scaleX
    y: (windowData.at ? windowData.at[1] : 0) * scaleY
    width: Math.max(30, (windowData.size ? windowData.size[0] : 200) * scaleX)
    height: Math.max(20, (windowData.size ? windowData.size[1] : 150) * scaleY)
    z: 2

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: windowMouse.containsMouse ? colors.surface2 : colors.surface1
        border.width: 1
        border.color: colors.surface2
        clip: true

        // Window title
        Text {
            anchors.centerIn: parent
            width: parent.width - 8
            text: root.windowData.title || root.windowData.class || "?"
            color: colors.text
            font.family: "JetBrains Mono"
            font.pixelSize: Math.max(7, Math.min(11, parent.height * 0.3))
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.NoWrap
        }

        // Class label (top-left corner)
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 3
            text: root.windowData.class || ""
            color: colors.overlay0
            font.family: "JetBrains Mono"
            font.pixelSize: Math.max(6, Math.min(9, parent.height * 0.2))
            elide: Text.ElideRight
            width: parent.width - 6
            visible: parent.height > 30
        }
    }

    MouseArea {
        id: windowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        z: 3

        onClicked: mouse => {
            var addr = root.windowData.address || "";
            if (mouse.button === Qt.MiddleButton) {
                root.closeWindow(addr);
            } else {
                root.focusWindow(addr);
            }
        }
    }
}
