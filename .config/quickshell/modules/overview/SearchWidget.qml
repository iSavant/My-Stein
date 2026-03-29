import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
    id: root

    property string query: ""
    property bool hasResults: resultModel.count > 0
    property int selectedIndex: 0

    function selectNext() { if (selectedIndex < resultModel.count - 1) selectedIndex++; }
    function selectPrev() { if (selectedIndex > 0) selectedIndex--; }
    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < resultModel.count) {
            var item = resultModel.get(selectedIndex);
            if (item && item.exec) {
                // Strip %u %U %f %F etc. from exec
                var cmd = item.exec.replace(/%[uUfFdDnNickvm]/g, "").trim();
                Quickshell.execDetached(["bash", "-c", cmd]);
            }
        }
    }

    width: 500
    height: Math.min(resultList.contentHeight + 16, 400)
    radius: 12
    color: colors.surface0
    border.width: 1
    border.color: colors.surface2
    visible: resultModel.count > 0

    MatugenColors { id: colors }

    ListModel { id: resultModel }

    property string _searchAccum: ""

    // Desktop file search process
    Process {
        id: searchProc
        command: ["bash", "-c",
            "for f in /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop; do " +
            "[ -f \"$f\" ] || continue; " +
            "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); " +
            "icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); " +
            "exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2); " +
            "comment=$(grep -m1 '^Comment=' \"$f\" | cut -d= -f2); " +
            "nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2); " +
            "[ \"$nodisplay\" = \"true\" ] && continue; " +
            "[ -z \"$name\" ] && continue; " +
            "echo \"$name|$icon|$exec|$comment\"; " +
            "done 2>/dev/null"
        ]
        stdout: SplitParser {
            onRead: data => { root._searchAccum += data + "\n"; }
        }
        onExited: {
            root.filterResults();
        }
    }

    // Load all desktop entries on first show
    property bool _loaded: false
    property string _allEntries: ""

    onVisibleChanged: {
        if (visible && !_loaded) {
            _loaded = true;
            root._searchAccum = "";
            searchProc.running = true;
        }
    }

    onQueryChanged: {
        selectedIndex = 0;
        if (_loaded && _allEntries.length > 0) {
            filterResults();
        }
    }

    function filterResults() {
        if (root._searchAccum.length > 0) {
            root._allEntries = root._searchAccum;
            root._searchAccum = "";
        }

        resultModel.clear();
        if (query.length === 0) return;

        var q = query.toLowerCase();
        var lines = _allEntries.split("\n");
        var count = 0;

        for (var i = 0; i < lines.length && count < 8; i++) {
            var parts = lines[i].split("|");
            if (parts.length < 3) continue;

            var name = parts[0];
            var icon = parts[1] || "";
            var exec = parts[2] || "";
            var comment = parts[3] || "";

            if (name.toLowerCase().indexOf(q) !== -1 ||
                exec.toLowerCase().indexOf(q) !== -1 ||
                comment.toLowerCase().indexOf(q) !== -1) {
                resultModel.append({name: name, icon: icon, exec: exec, comment: comment});
                count++;
            }
        }
    }

    ListView {
        id: resultList
        anchors.fill: parent
        anchors.margins: 8
        model: resultModel
        clip: true
        spacing: 2

        delegate: SearchItem {
            width: resultList.width
            name: model.name
            iconName: model.icon
            description: model.comment
            exec: model.exec
            isSelected: index === root.selectedIndex
            onActivated: {
                root.selectedIndex = index;
                root.launchSelected();
            }
        }
    }
}
