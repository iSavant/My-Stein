pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var windowList: []
    property var workspaceList: []
    property var activeWorkspace: ({id: 1})
    property var monitorList: []

    property string _clientsAccum: ""
    property string _wsAccum: ""
    property string _activeWsAccum: ""
    property string _monAccum: ""

    // Clients
    property var _clientsProc: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser { onRead: data => { root._clientsAccum += data; } }
        onExited: {
            try { root.windowList = JSON.parse(root._clientsAccum); } catch(e) {}
            root._clientsAccum = "";
        }
    }

    // Workspaces
    property var _wsProc: Process {
        command: ["hyprctl", "workspaces", "-j"]
        stdout: SplitParser { onRead: data => { root._wsAccum += data; } }
        onExited: {
            try { root.workspaceList = JSON.parse(root._wsAccum); } catch(e) {}
            root._wsAccum = "";
        }
    }

    // Active workspace
    property var _activeWsProc: Process {
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: SplitParser { onRead: data => { root._activeWsAccum += data; } }
        onExited: {
            try { root.activeWorkspace = JSON.parse(root._activeWsAccum); } catch(e) {}
            root._activeWsAccum = "";
        }
    }

    // Monitors
    property var _monProc: Process {
        command: ["hyprctl", "monitors", "-j"]
        stdout: SplitParser { onRead: data => { root._monAccum += data; } }
        onExited: {
            try { root.monitorList = JSON.parse(root._monAccum); } catch(e) {}
            root._monAccum = "";
        }
    }

    function refresh() {
        if (!_clientsProc.running) { _clientsAccum = ""; _clientsProc.running = true; }
        if (!_wsProc.running) { _wsAccum = ""; _wsProc.running = true; }
        if (!_activeWsProc.running) { _activeWsAccum = ""; _activeWsProc.running = true; }
        if (!_monProc.running) { _monAccum = ""; _monProc.running = true; }
    }

    function windowsForWorkspace(wsId) {
        var result = [];
        for (var i = 0; i < windowList.length; i++) {
            if (windowList[i].workspace && windowList[i].workspace.id === wsId) {
                result.push(windowList[i]);
            }
        }
        return result;
    }

    function focusedMonitor() {
        for (var i = 0; i < monitorList.length; i++) {
            if (monitorList[i].focused) return monitorList[i];
        }
        return monitorList.length > 0 ? monitorList[0] : null;
    }

    property var _pollTimer: Timer {
        interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
