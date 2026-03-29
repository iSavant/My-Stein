import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../"
import "../../services"

Scope {
    id: root

    property bool overviewVisible: false

    IpcHandler {
        target: "overviewToggle"
        function handleCall(data) {
            root.overviewVisible = !root.overviewVisible;
            if (root.overviewVisible) HyprlandData.refresh();
        }
    }

    PanelWindow {
        id: overviewPanel

        visible: root.overviewVisible

        screen: {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === "DP-1") return Quickshell.screens[i];
            }
            return Quickshell.screens[0];
        }

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MatugenColors { id: colors }

        property bool searchActive: false
        property string searchQuery: ""

        // Refresh data when visible
        Timer {
            interval: 500; running: root.overviewVisible; repeat: true
            onTriggered: HyprlandData.refresh()
        }

        // Keyboard handling
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (overviewPanel.searchActive) {
                    overviewPanel.searchActive = false;
                    overviewPanel.searchQuery = "";
                    searchBar.clear();
                } else {
                    root.overviewVisible = false;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (overviewPanel.searchActive && searchWidget.hasResults) {
                    searchWidget.launchSelected();
                    root.overviewVisible = false;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                if (overviewPanel.searchActive) searchWidget.selectNext();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                if (overviewPanel.searchActive) searchWidget.selectPrev();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                if (overviewPanel.searchActive) {
                    searchBar.backspace();
                }
                event.accepted = true;
            } else if (event.text.length > 0 && event.text.match(/^[a-zA-Z0-9 \-_.]$/)) {
                overviewPanel.searchActive = true;
                searchBar.appendChar(event.text);
                event.accepted = true;
            }
        }

        // Dim background
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(colors.crust.r, colors.crust.g, colors.crust.b, 0.7)

            MouseArea {
                anchors.fill: parent
                onClicked: root.overviewVisible = false
            }
        }

        // Search bar
        SearchBar {
            id: searchBar
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            z: 10

            onQueryChanged: query => {
                overviewPanel.searchQuery = query;
                overviewPanel.searchActive = query.length > 0;
            }
            onAccepted: {
                if (searchWidget.hasResults) {
                    searchWidget.launchSelected();
                    root.overviewVisible = false;
                }
            }
        }

        // Search results
        SearchWidget {
            id: searchWidget
            anchors.top: searchBar.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            z: 10
            visible: overviewPanel.searchActive && overviewPanel.searchQuery.length > 0
            query: overviewPanel.searchQuery
        }

        // Workspace overview grid
        OverviewWidget {
            id: overviewWidget
            anchors.fill: parent
            anchors.topMargin: 100
            anchors.margins: 60
            visible: !overviewPanel.searchActive
            onCloseOverview: root.overviewVisible = false
        }
    }
}
