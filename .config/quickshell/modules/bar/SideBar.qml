import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../"

Scope {
    id: root

    PanelWindow {
        id: sidebar

        screen: {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === "HDMI-A-1") return Quickshell.screens[i];
            }
            return null;
        }

        visible: sidebar.screen !== null

        anchors { top: true; right: true; bottom: true }
        implicitWidth: 44
        color: "transparent"
        exclusionMode: ExclusionMode.Normal

        WlrLayershell.namespace: "quickshell:sidebar"
        WlrLayershell.layer: WlrLayer.Top

        property var workspaceData: []
        property int activeWorkspaceId: 1
        property string _wsAccum: ""
        property string _activeWsAccum: ""
        property int volumePercent: 0
        property bool volumeMuted: false
        property string _volAccum: ""
        property string _muteAccum: ""
        property string timeStr: "00:00"
        property string dateStr: "Mon 1"

        MatugenColors { id: colors }

        // Workspace polling
        Process {
            id: wsProc
            command: ["hyprctl", "workspaces", "-j"]
            stdout: SplitParser { onRead: data => { sidebar._wsAccum += data; } }
            onExited: {
                try { sidebar.workspaceData = JSON.parse(sidebar._wsAccum); } catch(e) {}
                sidebar._wsAccum = "";
            }
        }
        Process {
            id: activeWsProc
            command: ["hyprctl", "activeworkspace", "-j"]
            stdout: SplitParser { onRead: data => { sidebar._activeWsAccum += data; } }
            onExited: {
                try { var d = JSON.parse(sidebar._activeWsAccum); sidebar.activeWorkspaceId = d.id || 1; } catch(e) {}
                sidebar._activeWsAccum = "";
            }
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                if (!wsProc.running) { sidebar._wsAccum = ""; wsProc.running = true; }
                if (!activeWsProc.running) { sidebar._activeWsAccum = ""; activeWsProc.running = true; }
            }
        }

        // Volume
        Process {
            id: volProc
            command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+%' | head -1 | tr -d '%'"]
            stdout: SplitParser { onRead: data => { sidebar._volAccum += data; } }
            onExited: { var v = parseInt(sidebar._volAccum.trim()); if (!isNaN(v)) sidebar.volumePercent = v; sidebar._volAccum = ""; }
        }
        Process {
            id: muteProc
            command: ["bash", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no'"]
            stdout: SplitParser { onRead: data => { sidebar._muteAccum += data; } }
            onExited: { sidebar.volumeMuted = (sidebar._muteAccum.trim() === "yes"); sidebar._muteAccum = ""; }
        }
        Timer {
            interval: 2000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                if (!volProc.running) { sidebar._volAccum = ""; volProc.running = true; }
                if (!muteProc.running) { sidebar._muteAccum = ""; muteProc.running = true; }
            }
        }

        // Clock
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                var d = new Date();
                var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
                sidebar.timeStr = d.toLocaleTimeString(Qt.locale(), "HH:mm");
                sidebar.dateStr = months[d.getMonth()] + " " + d.getDate();
            }
        }

        function hasWindows(wsId) {
            for (var i = 0; i < workspaceData.length; i++) {
                if (workspaceData[i].id === wsId && workspaceData[i].windows > 0) return true;
            }
            return false;
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            anchors.rightMargin: 4
            color: Qt.rgba(colors.mantle.r, colors.mantle.g, colors.mantle.b, 0.85)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 6

                // Workspace dots (vertical)
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            property int wsId: index + 1
                            property bool isActive: sidebar.activeWorkspaceId === wsId
                            property bool occupied: sidebar.hasWindows(wsId)

                            Layout.alignment: Qt.AlignHCenter
                            width: isActive ? 10 : (occupied ? 8 : 6)
                            height: width
                            radius: width / 2
                            color: isActive ? colors.blue : (occupied ? colors.overlay1 : "transparent")
                            border.width: (!isActive && !occupied) ? 1 : 0
                            border.color: colors.surface2

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)])
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Time (stacked vertically)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: sidebar.timeStr.charAt(0) + "\n" + sidebar.timeStr.charAt(1) + "\n:\n" + sidebar.timeStr.charAt(3) + "\n" + sidebar.timeStr.charAt(4)
                    horizontalAlignment: Text.AlignHCenter
                    color: colors.text
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    lineHeight: 0.85
                }

                Item { Layout.fillHeight: true }

                // Volume icon
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: sidebar.volumeMuted ? "󰝟" : (sidebar.volumePercent < 30 ? "󰖀" : "󰕾")
                    color: sidebar.volumeMuted ? colors.red : colors.text
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                }
            }
        }
    }
}
