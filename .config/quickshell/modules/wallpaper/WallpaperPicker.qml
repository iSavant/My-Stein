import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../"

Scope {
    id: root

    property bool pickerVisible: false

    PanelWindow {
        id: pickerPanel

        visible: root.pickerVisible

        screen: Quickshell.screens[0]

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true

        WlrLayershell.namespace: "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MatugenColors { id: colors }

        readonly property string scriptsDir: Qt.resolvedUrl(".").toString().replace("file://", "")
        readonly property string wallDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
        readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/wallpaper_picker"
        readonly property string searchThumbDir: cacheDir + "/search_thumbs"

        property var localFiles: []
        property var searchFiles: []
        property string searchQuery: ""
        property bool isSearching: false
        property string _localAccum: ""
        property string _searchAccum: ""
        property string selectedFile: ""
        property string mode: "local" // "local" or "search"

        // Scan local wallpapers
        Process {
            id: localProc
            command: ["bash", "-c", "find '" + pickerPanel.wallDir + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' \\) 2>/dev/null | sort"]
            stdout: SplitParser { onRead: data => { pickerPanel._localAccum += data + "\n"; } }
            onExited: {
                var lines = pickerPanel._localAccum.trim().split("\n").filter(l => l.length > 0);
                pickerPanel.localFiles = lines;
                pickerPanel._localAccum = "";
            }
        }

        // Scan search results directory
        Process {
            id: searchScanProc
            command: ["bash", "-c", "find '" + pickerPanel.searchThumbDir + "' -maxdepth 1 -type f 2>/dev/null | sort -t_ -k2 -n"]
            stdout: SplitParser { onRead: data => { pickerPanel._searchAccum += data + "\n"; } }
            onExited: {
                var lines = pickerPanel._searchAccum.trim().split("\n").filter(l => l.length > 0);
                pickerPanel.searchFiles = lines;
                pickerPanel._searchAccum = "";
            }
        }

        // Poll search results while searching
        Timer {
            interval: 2000; running: pickerPanel.isSearching; repeat: true
            onTriggered: {
                if (!searchScanProc.running) { pickerPanel._searchAccum = ""; searchScanProc.running = true; }
            }
        }

        // Refresh local files when visible
        Timer {
            interval: 100; running: root.pickerVisible; repeat: false
            onTriggered: {
                if (!localProc.running) { pickerPanel._localAccum = ""; localProc.running = true; }
            }
        }

        function startSearch(query) {
            if (query.trim().length === 0) return;
            // Stop any existing search
            Quickshell.execDetached(["bash", "-c", "echo stop > /tmp/ddg_search_control"]);
            // Clean old search results
            Quickshell.execDetached(["bash", "-c", "rm -rf '" + searchThumbDir + "' '" + cacheDir + "/search_map.txt'"]);
            Quickshell.execDetached(["bash", "-c", "mkdir -p '" + searchThumbDir + "'"]);
            // Start new search
            Quickshell.execDetached(["bash", "-c", "echo run > /tmp/ddg_search_control && bash '" + scriptsDir + "ddg_search.sh' '" + query.replace(/'/g, "'\\''") + "'"]);
            pickerPanel.isSearching = true;
            pickerPanel.searchFiles = [];
            pickerPanel.mode = "search";
        }

        function stopSearch() {
            Quickshell.execDetached(["bash", "-c", "echo stop > /tmp/ddg_search_control"]);
            pickerPanel.isSearching = false;
        }

        function applyWallpaper(filePath) {
            if (filePath.length === 0) return;
            var ext = filePath.split(".").pop().toLowerCase();
            if (ext === "mp4" || ext === "webm") {
                Quickshell.execDetached(["bash", "-c", "killall mpvpaper 2>/dev/null; mpvpaper -o 'no-audio loop' '*' '" + filePath + "'"]);
            } else {
                Quickshell.execDetached(["bash", "-c", "swww img '" + filePath + "' --transition-type fade --transition-duration 1"]);
            }
            // Run matugen + reload
            Quickshell.execDetached(["bash", "-c", "matugen image '" + filePath + "' && bash '" + scriptsDir + "matugen_reload.sh'"]);
            root.pickerVisible = false;
        }

        function downloadAndApply(thumbPath) {
            // Look up full URL from map file
            var filename = thumbPath.split("/").pop();
            Quickshell.execDetached(["bash", "-c",
                "FULL_URL=$(grep '^" + filename + "|' '" + cacheDir + "/search_map.txt' | cut -d'|' -f2); " +
                "if [ -n \"$FULL_URL\" ]; then " +
                "  DEST='" + pickerPanel.wallDir + "/ddg_$(date +%s).jpg'; " +
                "  curl -sL -A 'Mozilla/5.0' \"$FULL_URL\" -o \"$DEST\" && " +
                "  swww img \"$DEST\" --transition-type fade --transition-duration 1 && " +
                "  matugen image \"$DEST\" && bash '" + scriptsDir + "matugen_reload.sh'; " +
                "fi"
            ]);
            root.pickerVisible = false;
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                pickerPanel.stopSearch();
                root.pickerVisible = false;
                event.accepted = true;
            }
        }

        // Dim background
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(colors.crust.r, colors.crust.g, colors.crust.b, 0.8)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pickerPanel.stopSearch();
                    root.pickerVisible = false;
                }
            }
        }

        // Main container
        Rectangle {
            id: container
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.8, 900)
            height: Math.min(parent.height * 0.8, 700)
            radius: 16
            color: colors.base
            border.width: 1
            border.color: colors.surface2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header with search bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Mode tabs
                    Rectangle {
                        implicitWidth: 70; implicitHeight: 30; radius: 8
                        color: pickerPanel.mode === "local" ? colors.blue : colors.surface1
                        Text {
                            anchors.centerIn: parent; text: "Local"
                            color: pickerPanel.mode === "local" ? colors.base : colors.subtext0
                            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pickerPanel.mode = "local" }
                    }
                    Rectangle {
                        implicitWidth: 70; implicitHeight: 30; radius: 8
                        color: pickerPanel.mode === "search" ? colors.blue : colors.surface1
                        Text {
                            anchors.centerIn: parent; text: "Search"
                            color: pickerPanel.mode === "search" ? colors.base : colors.subtext0
                            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pickerPanel.mode = "search" }
                    }

                    Item { Layout.fillWidth: true }

                    // Search input
                    Rectangle {
                        Layout.preferredWidth: 300; Layout.preferredHeight: 30
                        radius: 8; color: colors.surface0; border.width: 1; border.color: colors.surface2

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6
                            Text { text: ""; color: colors.overlay0; font.family: "Iosevka Nerd Font"; font.pixelSize: 14 }
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: colors.text; font.family: "JetBrains Mono"; font.pixelSize: 12
                                clip: true
                                onAccepted: pickerPanel.startSearch(text)

                                Text {
                                    visible: searchInput.text.length === 0
                                    text: "Search DuckDuckGo..."
                                    color: colors.overlay0; font: searchInput.font
                                }
                            }
                        }
                    }

                    // Search button
                    Rectangle {
                        implicitWidth: 60; implicitHeight: 30; radius: 8
                        color: pickerPanel.isSearching ? colors.red : colors.mauve
                        Text {
                            anchors.centerIn: parent
                            text: pickerPanel.isSearching ? "Stop" : "Go"
                            color: colors.base; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pickerPanel.isSearching) pickerPanel.stopSearch();
                                else pickerPanel.startSearch(searchInput.text);
                            }
                        }
                    }
                }

                // Status line
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (pickerPanel.mode === "local") return pickerPanel.localFiles.length + " wallpapers in ~/Pictures/Wallpapers";
                        if (pickerPanel.isSearching) return "Searching... " + pickerPanel.searchFiles.length + " results";
                        return pickerPanel.searchFiles.length + " search results";
                    }
                    color: colors.overlay0; font.family: "JetBrains Mono"; font.pixelSize: 10
                }

                // Grid
                GridView {
                    id: gridView
                    Layout.fillWidth: true; Layout.fillHeight: true
                    cellWidth: 170; cellHeight: 110
                    clip: true

                    model: pickerPanel.mode === "local" ? pickerPanel.localFiles : pickerPanel.searchFiles

                    delegate: Rectangle {
                        width: gridView.cellWidth - 8; height: gridView.cellHeight - 8
                        radius: 8; color: colors.surface0
                        border.width: thumbMouse.containsMouse ? 2 : 1
                        border.color: thumbMouse.containsMouse ? colors.blue : colors.surface2

                        Image {
                            anchors.fill: parent; anchors.margins: 2
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 320; sourceSize.height: 200

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                radius: 6

                                // Filename overlay at bottom
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                    height: 20; color: Qt.rgba(0, 0, 0, 0.6)
                                    radius: 2
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.split("/").pop()
                                        color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 8
                                        elide: Text.ElideMiddle; width: parent.width - 8
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        // Loading placeholder when image hasn't loaded
                        Text {
                            anchors.centerIn: parent; visible: parent.children[0].status !== Image.Ready
                            text: "󰋩"; color: colors.overlay0; font.family: "Iosevka Nerd Font"; font.pixelSize: 24
                        }

                        MouseArea {
                            id: thumbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pickerPanel.mode === "local") pickerPanel.applyWallpaper(modelData);
                                else pickerPanel.downloadAndApply(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
