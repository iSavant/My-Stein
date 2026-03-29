import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root

    property string name: ""
    property string iconName: ""
    property string description: ""
    property string exec: ""
    property bool isSelected: false

    signal activated()

    height: 40
    radius: 8
    color: isSelected ? colors.surface2 : (itemMouse.containsMouse ? colors.surface1 : "transparent")

    MatugenColors { id: colors }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        // Icon placeholder
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 6
            color: colors.surface1

            Text {
                anchors.centerIn: parent
                text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : "?"
                color: colors.mauve
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.name
                color: colors.text
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.description !== ""
                text: root.description
                color: colors.subtext0
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
