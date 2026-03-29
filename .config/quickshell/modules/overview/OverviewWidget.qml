import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../../services"

Item {
    id: root

    signal closeOverview()

    MatugenColors { id: colors }

    readonly property int rows: 2
    readonly property int cols: 5
    readonly property int cellSpacing: 12

    GridLayout {
        anchors.fill: parent
        rows: root.rows
        columns: root.cols
        rowSpacing: root.cellSpacing
        columnSpacing: root.cellSpacing

        Repeater {
            model: root.rows * root.cols

            delegate: Rectangle {
                id: wsCell
                property int wsId: index + 1
                property bool isActive: HyprlandData.activeWorkspace && HyprlandData.activeWorkspace.id === wsId
                property var windows: HyprlandData.windowsForWorkspace(wsId)

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: cellMouse.containsMouse ? colors.surface1 : colors.surface0
                border.width: isActive ? 2 : 1
                border.color: isActive ? colors.blue : colors.surface2

                // Workspace number label
                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 6
                    text: wsId
                    color: wsCell.isActive ? colors.blue : colors.overlay0
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: wsCell.isActive
                    z: 5
                }

                // Window previews
                Repeater {
                    model: wsCell.windows

                    delegate: OverviewWindow {
                        required property var modelData
                        windowData: modelData
                        cellWidth: wsCell.width
                        cellHeight: wsCell.height
                        monitorWidth: {
                            var mon = HyprlandData.focusedMonitor();
                            return mon ? mon.width : 1920;
                        }
                        monitorHeight: {
                            var mon = HyprlandData.focusedMonitor();
                            return mon ? mon.height : 1080;
                        }
                        onFocusWindow: address => {
                            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address]);
                            root.closeOverview();
                        }
                        onCloseWindow: address => {
                            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + address]);
                        }
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    z: -1
                    onClicked: {
                        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsCell.wsId)]);
                        root.closeOverview();
                    }
                }
            }
        }
    }
}
