import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../"

Scope {
    id: root

    property bool popupVisible: false

    MonitorConfig { id: monConfig }

    PanelWindow {
        id: panel

        visible: root.popupVisible

        screen: {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === monConfig.primaryMonitor) return Quickshell.screens[i];
            }
            return Quickshell.screens[0];
        }

        anchors { top: true; right: true }
        implicitWidth: 360
        implicitHeight: 560
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "quickshell:musicpopup"
        WlrLayershell.layer: WlrLayer.Overlay

        MatugenColors { id: colors }

        // --- DATA ---
        property var musicData: ({
            title: "Not Playing", artist: "", status: "Stopped", percent: 0,
            lengthStr: "00:00", positionStr: "00:00", timeStr: "--:-- / --:--",
            source: "Offline", playerName: "", deviceIcon: "󰓃", deviceName: "Speaker",
            length: "0", position: "0"
        })
        property var eqData: ({
            b1: 0, b2: 0, b3: 0, b4: 0, b5: 0,
            b6: 0, b7: 0, b8: 0, b9: 0, b10: 0,
            preset: "Flat", pending: false
        })

        property string _musicAccum: ""
        property string _eqAccum: ""
        property bool userIsSeeking: false
        property bool userToggledPlay: false
        property real lastEqUpdate: 0

        readonly property string scriptsDir: Qt.resolvedUrl(".").toString().replace("file://", "")

        function execCmd(cmdStr) {
            Quickshell.execDetached(["bash", "-c", cmdStr]);
        }

        function applyPresetOptimistically(presetName) {
            var presets = {
                "Flat": [0,0,0,0,0,0,0,0,0,0], "Bass": [5,7,5,2,1,0,0,0,1,2],
                "Treble": [-2,-1,0,1,2,3,4,5,6,6], "Vocal": [-2,-1,1,3,5,5,4,2,1,0],
                "Pop": [2,4,2,0,1,2,4,2,1,2], "Rock": [5,4,2,-1,-2,-1,2,4,5,6],
                "Jazz": [3,3,1,1,1,1,2,1,2,3], "Classic": [0,1,2,2,2,2,1,2,3,4]
            };
            if (presets[presetName]) {
                var temp = Object.assign({}, panel.eqData);
                for (var i = 0; i < 10; i++) temp["b" + (i + 1)] = presets[presetName][i];
                temp.preset = presetName;
                temp.pending = false;
                panel.eqData = temp;
                panel.lastEqUpdate = Date.now();
                execCmd(scriptsDir + "equalizer.sh preset " + presetName);
            }
        }

        // --- DEBOUNCE TIMERS ---
        Timer { id: seekDebounce; interval: 2500; onTriggered: panel.userIsSeeking = false }
        Timer { id: playDebounce; interval: 1500; onTriggered: panel.userToggledPlay = false }

        // --- POLLING (only when visible) ---
        Timer {
            interval: 500; running: root.popupVisible; repeat: true; triggeredOnStart: true
            onTriggered: {
                if (!musicProc.running) { panel._musicAccum = ""; musicProc.running = true; }
                if (!eqProc.running) { panel._eqAccum = ""; eqProc.running = true; }
            }
        }

        Process {
            id: musicProc
            command: ["bash", "-c", panel.scriptsDir + "music_info.sh"]
            stdout: SplitParser { onRead: data => { panel._musicAccum += data; } }
            onExited: {
                if (panel._musicAccum.length > 0) {
                    try {
                        var newData = JSON.parse(panel._musicAccum);
                        if (panel.userToggledPlay) newData.status = panel.musicData.status;
                        panel.musicData = newData;
                    } catch(e) {}
                }
                panel._musicAccum = "";
            }
        }

        Process {
            id: eqProc
            command: ["bash", "-c", panel.scriptsDir + "equalizer.sh get"]
            stdout: SplitParser { onRead: data => { panel._eqAccum += data; } }
            onExited: {
                if (Date.now() - panel.lastEqUpdate < 2000) { panel._eqAccum = ""; return; }
                if (panel._eqAccum.length > 0) {
                    try { panel.eqData = JSON.parse(panel._eqAccum); } catch(e) {}
                }
                panel._eqAccum = "";
            }
        }

        // --- UI ---
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            anchors.topMargin: 48
            color: colors.base
            radius: 12
            border.width: 1
            border.color: colors.surface2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Header: title, artist, device
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: panel.musicData.title || "Not Playing"
                        color: colors.text
                        font.family: "JetBrains Mono"; font.pixelSize: 16; font.bold: true
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        visible: panel.musicData.artist !== ""
                        text: "BY " + (panel.musicData.artist || "")
                        color: colors.subtext0
                        font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            color: colors.surface1; radius: 4
                            implicitHeight: 22; implicitWidth: devRow.implicitWidth + 14
                            RowLayout {
                                id: devRow; anchors.centerIn: parent; spacing: 4
                                Text { text: panel.musicData.deviceIcon || "󰓃"; color: colors.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: 12 }
                                Text { text: panel.musicData.deviceName || "Speaker"; color: colors.overlay2; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                            }
                        }
                        Text {
                            text: "VIA " + (panel.musicData.source || "Offline")
                            color: colors.overlay2; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; font.italic: true
                        }
                    }
                }

                // Progress bar
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4

                    Slider {
                        id: progBar
                        Layout.fillWidth: true; Layout.preferredHeight: 18
                        from: 0; to: 100

                        Connections {
                            target: panel
                            function onMusicDataChanged() {
                                if (!progBar.pressed && !panel.userIsSeeking) {
                                    var p = Number(panel.musicData.percent);
                                    if (!isNaN(p)) progBar.value = p;
                                }
                            }
                        }

                        onPressedChanged: {
                            if (pressed) { panel.userIsSeeking = true; seekDebounce.stop(); }
                            else {
                                var safePlayer = panel.musicData.playerName || "";
                                panel.execCmd(panel.scriptsDir + "player_control.sh seek " + value.toFixed(2) + " " + panel.musicData.length + ' "' + safePlayer + '"');
                                seekDebounce.restart();
                            }
                        }

                        background: Rectangle {
                            x: progBar.leftPadding
                            y: progBar.topPadding + (progBar.availableHeight - 8) / 2
                            width: progBar.availableWidth; height: 8; radius: 4
                            color: colors.surface0

                            Rectangle {
                                width: progBar.visualPosition * parent.width; height: parent.height
                                radius: 4; color: colors.blue
                            }
                        }

                        handle: Rectangle {
                            x: progBar.leftPadding + progBar.visualPosition * (progBar.availableWidth - width)
                            y: progBar.topPadding + (progBar.availableHeight - height) / 2
                            width: 14; height: 14; radius: 7; color: colors.text
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: panel.musicData.positionStr || "00:00"; color: colors.overlay2; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: panel.musicData.lengthStr || "00:00"; color: colors.overlay2; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 28
                    MouseArea {
                        width: 28; height: 28; cursorShape: Qt.PointingHandCursor
                        onClicked: panel.execCmd("playerctl previous")
                        Text { anchors.centerIn: parent; text: "󰒮"; color: colors.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: 22 }
                    }
                    MouseArea {
                        width: 40; height: 40; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panel.userToggledPlay = true; playDebounce.restart();
                            var temp = Object.assign({}, panel.musicData);
                            temp.status = (temp.status === "Playing" ? "Paused" : "Playing");
                            panel.musicData = temp;
                            panel.execCmd("playerctl play-pause");
                        }
                        Text {
                            anchors.centerIn: parent
                            text: panel.musicData.status === "Playing" ? "󰏤" : "󰐊"
                            color: colors.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: 36
                        }
                    }
                    MouseArea {
                        width: 28; height: 28; cursorShape: Qt.PointingHandCursor
                        onClicked: panel.execCmd("playerctl next")
                        Text { anchors.centerIn: parent; text: "󰒭"; color: colors.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: 22 }
                    }
                }

                // Separator
                Rectangle { Layout.fillWidth: true; height: 1; color: colors.surface2 }

                // EQ Header
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Equalizer"; color: colors.mauve; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }

                    Rectangle {
                        implicitHeight: 24; implicitWidth: applyTxt.implicitWidth + 20
                        radius: 8
                        color: panel.eqData.pending ? colors.mauve : colors.surface1
                        border.color: panel.eqData.pending ? colors.mauve : colors.surface2; border.width: 1

                        Text {
                            id: applyTxt; anchors.centerIn: parent
                            text: panel.eqData.pending ? "Apply" : "Saved"
                            color: panel.eqData.pending ? colors.base : colors.subtext0
                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: panel.eqData.pending ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (panel.eqData.pending) {
                                    var temp = Object.assign({}, panel.eqData); temp.pending = false; panel.eqData = temp;
                                    panel.lastEqUpdate = Date.now();
                                    panel.execCmd(panel.scriptsDir + "equalizer.sh apply");
                                }
                            }
                        }
                    }
                    Text { text: panel.eqData.preset || "Flat"; color: colors.subtext0; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; Layout.leftMargin: 8 }
                }

                // EQ Sliders
                Row {
                    Layout.fillWidth: true; Layout.preferredHeight: 140

                    Repeater {
                        model: [
                            {idx:1,lbl:"31"},{idx:2,lbl:"63"},{idx:3,lbl:"125"},{idx:4,lbl:"250"},{idx:5,lbl:"500"},
                            {idx:6,lbl:"1k"},{idx:7,lbl:"2k"},{idx:8,lbl:"4k"},{idx:9,lbl:"8k"},{idx:10,lbl:"16k"}
                        ]
                        delegate: Item {
                            width: parent.width / 10; height: parent.height

                            ColumnLayout {
                                anchors.fill: parent; spacing: 3

                                Slider {
                                    id: eqSlider
                                    Layout.fillHeight: true; Layout.alignment: Qt.AlignHCenter
                                    orientation: Qt.Vertical; from: -12; to: 12; stepSize: 1

                                    Connections {
                                        target: panel
                                        function onEqDataChanged() {
                                            if (!eqSlider.pressed) {
                                                var p = Number(panel.eqData["b" + modelData.idx]);
                                                if (!isNaN(p)) eqSlider.value = p;
                                            }
                                        }
                                    }

                                    onPressedChanged: {
                                        if (!pressed) {
                                            var temp = Object.assign({}, panel.eqData);
                                            temp["b" + modelData.idx] = Math.round(value);
                                            temp.preset = "Custom"; temp.pending = true;
                                            panel.eqData = temp;
                                            panel.lastEqUpdate = Date.now();
                                            panel.execCmd(panel.scriptsDir + "equalizer.sh set_band " + modelData.idx + " " + Math.round(value));
                                        }
                                    }

                                    background: Rectangle {
                                        x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
                                        y: eqSlider.topPadding
                                        width: 8; height: eqSlider.availableHeight; radius: 4
                                        color: colors.surface0

                                        Rectangle {
                                            width: parent.width; radius: 4; color: colors.blue
                                            height: (1 - eqSlider.visualPosition) * parent.height
                                            y: eqSlider.visualPosition * parent.height
                                        }
                                    }

                                    handle: Rectangle {
                                        x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
                                        y: eqSlider.topPadding + eqSlider.visualPosition * (eqSlider.availableHeight - height)
                                        width: 14; height: 14; radius: 7; color: colors.text
                                    }
                                }

                                Text {
                                    text: modelData.lbl; color: colors.overlay1
                                    font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }

                // Presets
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["Flat", "Bass", "Treble", "Vocal"]
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 8
                                property bool isActive: panel.eqData && panel.eqData.preset === modelData
                                color: isActive ? colors.mauve : (presetMa.containsMouse ? colors.surface2 : colors.surface1)
                                Text {
                                    anchors.centerIn: parent; text: modelData
                                    color: parent.isActive ? colors.base : colors.subtext0
                                    font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true
                                }
                                MouseArea {
                                    id: presetMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.applyPresetOptimistically(modelData)
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["Pop", "Rock", "Jazz", "Classic"]
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 8
                                property bool isActive: panel.eqData && panel.eqData.preset === modelData
                                color: isActive ? colors.mauve : (presetMa2.containsMouse ? colors.surface2 : colors.surface1)
                                Text {
                                    anchors.centerIn: parent; text: modelData
                                    color: parent.isActive ? colors.base : colors.subtext0
                                    font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true
                                }
                                MouseArea {
                                    id: presetMa2; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.applyPresetOptimistically(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
