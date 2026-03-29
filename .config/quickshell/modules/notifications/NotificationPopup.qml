import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../"

Scope {
    id: root

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: notification => {
            // Auto-expire after 5 seconds if no timeout set
            if (notification.expireTimeout <= 0) {
                notification.expireTimeout = 5000;
            }
        }
    }

    PanelWindow {
        id: notifPanel

        screen: {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === "DP-1") return Quickshell.screens[i];
            }
            return Quickshell.screens[0];
        }

        visible: notifServer.trackedNotifications.values.length > 0

        anchors { top: true; right: true }
        implicitWidth: 320
        implicitHeight: Math.min(notifColumn.implicitHeight + 16, 500)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "quickshell:notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        MatugenColors { id: colors }

        Item {
            anchors.fill: parent
            anchors.topMargin: 52
            anchors.rightMargin: 8

            ColumnLayout {
                id: notifColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                Repeater {
                    model: {
                        var all = notifServer.trackedNotifications.values;
                        return all.length > 3 ? all.slice(all.length - 3) : all;
                    }

                    delegate: Rectangle {
                        id: notifItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: notifContent.implicitHeight + 20
                        radius: 10
                        color: colors.surface0
                        border.width: 1
                        border.color: colors.surface2

                        opacity: 1.0

                        RowLayout {
                            id: notifContent
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // App icon placeholder
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignTop
                                radius: 8
                                color: colors.surface1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰍡"
                                    color: colors.mauve
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.summary || "Notification"
                                        color: colors.text
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.appName || ""
                                        color: colors.overlay0
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    visible: text !== ""
                                    text: modelData.body || ""
                                    color: colors.subtext0
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            // Close button (visible on hover)
                            MouseArea {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignTop
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: modelData.dismiss()

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: parent.containsMouse ? colors.surface2 : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: colors.overlay1
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
