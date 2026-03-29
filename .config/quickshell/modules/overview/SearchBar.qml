import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"

Rectangle {
    id: root

    signal queryChanged(string query)
    signal accepted()

    function clear() { searchInput.text = ""; }
    function appendChar(c) { searchInput.text += c; searchInput.forceActiveFocus(); }
    function backspace() {
        if (searchInput.text.length > 0) {
            searchInput.text = searchInput.text.substring(0, searchInput.text.length - 1);
        }
    }

    width: 500
    height: 44
    radius: 22
    color: colors.surface0
    border.width: 1
    border.color: colors.surface2

    MatugenColors { id: colors }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        Text {
            text: "󰍉"
            color: colors.overlay1
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 18
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: colors.text
            font.family: "JetBrains Mono"
            font.pixelSize: 15
            clip: true
            selectByMouse: true

            onTextChanged: root.queryChanged(text)
            onAccepted: root.accepted()

            // Placeholder
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text.length === 0
                text: "Search apps..."
                color: colors.overlay0
                font.family: "JetBrains Mono"
                font.pixelSize: 15
            }
        }
    }
}
