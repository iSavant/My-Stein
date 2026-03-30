import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../"

Scope {
    id: root

    property bool musicPopupVisible: false

    MonitorConfig { id: monConfig }

    PanelWindow {
        id: bar

        screen: {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === monConfig.primaryMonitor) return Quickshell.screens[i];
            }
            return Quickshell.screens[0];
        }

        anchors { top: true; left: true; right: true }
        implicitHeight: 44
        color: "transparent"
        exclusionMode: ExclusionMode.Normal

        WlrLayershell.namespace: "quickshell:topbar"
        WlrLayershell.layer: WlrLayer.Top

        // Data properties
        property var workspaceData: []
        property int activeWorkspaceId: 1
        property bool gamemodeActive: false
        property int volumePercent: 0
        property bool volumeMuted: false
        property string _wsAccum: ""
        property string _activeWsAccum: ""
        property string _volAccum: ""
        property string _muteAccum: ""

        MatugenColors { id: colors }

        // Workspace polling
        Process {
            id: wsProc
            command: ["hyprctl", "workspaces", "-j"]
            stdout: SplitParser {
                onRead: data => { bar._wsAccum += data; }
            }
            onExited: {
                try {
                    bar.workspaceData = JSON.parse(bar._wsAccum);
                } catch(e) {}
                bar._wsAccum = "";
            }
        }

        Process {
            id: activeWsProc
            command: ["hyprctl", "activeworkspace", "-j"]
            stdout: SplitParser {
                onRead: data => { bar._activeWsAccum += data; }
            }
            onExited: {
                try {
                    var d = JSON.parse(bar._activeWsAccum);
                    bar.activeWorkspaceId = d.id || 1;
                } catch(e) {}
                bar._activeWsAccum = "";
            }
        }

        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                if (!wsProc.running) { bar._wsAccum = ""; wsProc.running = true; }
                if (!activeWsProc.running) { bar._activeWsAccum = ""; activeWsProc.running = true; }
            }
        }

        // Gamemode polling
        Process {
            id: gamemodeProc
            command: ["gamemoded", "--status"]
            onExited: exitCode => { bar.gamemodeActive = (exitCode === 0); }
        }
        Timer {
            interval: 5000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: { if (!gamemodeProc.running) gamemodeProc.running = true; }
        }

        // Volume polling
        Process {
            id: volProc
            command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+%' | head -1 | tr -d '%'"]
            stdout: SplitParser {
                onRead: data => { bar._volAccum += data; }
            }
            onExited: {
                var v = parseInt(bar._volAccum.trim());
                if (!isNaN(v)) bar.volumePercent = v;
                bar._volAccum = "";
            }
        }
        Process {
            id: muteProc
            command: ["bash", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no'"]
            stdout: SplitParser {
                onRead: data => { bar._muteAccum += data; }
            }
            onExited: {
                bar.volumeMuted = (bar._muteAccum.trim() === "yes");
                bar._muteAccum = "";
            }
        }
        Timer {
            interval: 2000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                if (!volProc.running) { bar._volAccum = ""; volProc.running = true; }
                if (!muteProc.running) { bar._muteAccum = ""; muteProc.running = true; }
            }
        }

        // Clock
        property string timeStr: "00:00"
        property string dateStr: "Mon, Jan 1"
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                var d = new Date();
                var days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
                var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
                bar.timeStr = d.toLocaleTimeString(Qt.locale(), "HH:mm");
                bar.dateStr = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
            }
        }

        function hasWindows(wsId) {
            for (var i = 0; i < workspaceData.length; i++) {
                if (workspaceData[i].id === wsId && workspaceData[i].windows > 0) return true;
            }
            return false;
        }

        // Bar content
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            anchors.topMargin: 4
            color: Qt.rgba(colors.mantle.r, colors.mantle.g, colors.mantle.b, 0.85)
            radius: 20

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Left pill: workspaces + gamemode
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: leftPillRow.implicitWidth + 20
                    color: colors.surface0
                    radius: 14
                    border.width: 1
                    border.color: colors.surface2

                    RowLayout {
                        id: leftPillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Repeater {
                            model: 10
                            delegate: Rectangle {
                                property int wsId: index + 1
                                property bool isActive: bar.activeWorkspaceId === wsId
                                property bool occupied: bar.hasWindows(wsId)

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

                        // Gamemode indicator
                        Text {
                            visible: bar.gamemodeActive
                            text: "󰊗"
                            color: colors.yellow
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Middle pill: clock
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: clockRow.implicitWidth + 24
                    color: colors.surface0
                    radius: 14
                    border.width: 1
                    border.color: colors.surface2

                    RowLayout {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: bar.timeStr
                            color: colors.text
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: colors.overlay0
                        }
                        Text {
                            text: bar.dateStr
                            color: colors.subtext0
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right pill: volume + music toggle
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: rightPillRow.implicitWidth + 20
                    color: colors.surface0
                    radius: 14
                    border.width: 1
                    border.color: colors.surface2

                    RowLayout {
                        id: rightPillRow
                        anchors.centerIn: parent
                        spacing: 8

                        // Volume
                        Text {
                            text: bar.volumeMuted ? "󰝟" : (bar.volumePercent < 30 ? "󰖀" : "󰕾")
                            color: bar.volumeMuted ? colors.red : colors.text
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            text: bar.volumePercent + "%"
                            color: colors.subtext0
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }

                        Rectangle { width: 1; height: 16; color: colors.surface2 }

                        // Music toggle (triggers IPC so popup + icon stay in sync)
                        Text {
                            text: "󰎆"
                            color: root.musicPopupVisible ? colors.blue : colors.overlay1
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 16

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "musicToggle"])
                            }
                        }
                    }
                }
            }
        }
    }
}
