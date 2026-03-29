pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Catppuccin-style color properties (Mocha defaults)
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color overlay0: "#6c7086"
    property color overlay1: "#7f849c"
    property color overlay2: "#9399b2"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color subtext1: "#bac2de"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color red: "#f38ba8"
    property color yellow: "#f9e2af"
    property color green: "#a6e3a1"
    property color teal: "#94e2d5"
    property color sky: "#89dceb"
    property color flamingo: "#f2cdcd"
    property color rosewater: "#f5e0dc"
    property color lavender: "#b4befe"

    // Material You style aliases
    property color primary: "#89b4fa"
    property color onPrimary: "#1e1e2e"
    property color primaryContainer: "#b4befe"
    property color onPrimaryContainer: "#1e1e2e"
    property color surfaceContainer: "#585b70"
    property color onSurface: "#cdd6f4"

    property string _accumulatedOutput: ""

    function applyColors(jsonStr) {
        try {
            var colors = JSON.parse(jsonStr);
            if (colors.base) root.base = colors.base;
            if (colors.mantle) root.mantle = colors.mantle;
            if (colors.crust) root.crust = colors.crust;
            if (colors.surface0) root.surface0 = colors.surface0;
            if (colors.surface1) root.surface1 = colors.surface1;
            if (colors.surface2) root.surface2 = colors.surface2;
            if (colors.overlay0) root.overlay0 = colors.overlay0;
            if (colors.overlay1) root.overlay1 = colors.overlay1;
            if (colors.overlay2) root.overlay2 = colors.overlay2;
            if (colors.text) root.text = colors.text;
            if (colors.subtext0) root.subtext0 = colors.subtext0;
            if (colors.subtext1) root.subtext1 = colors.subtext1;
            if (colors.blue) root.blue = colors.blue;
            if (colors.sapphire) root.sapphire = colors.sapphire;
            if (colors.mauve) root.mauve = colors.mauve;
            if (colors.pink) root.pink = colors.pink;
            if (colors.red) root.red = colors.red;
            if (colors.yellow) root.yellow = colors.yellow;
            if (colors.green) root.green = colors.green;
            if (colors.teal) root.teal = colors.teal;
            if (colors.sky) root.sky = colors.sky;
            if (colors.flamingo) root.flamingo = colors.flamingo;
            if (colors.rosewater) root.rosewater = colors.rosewater;
            if (colors.lavender) root.lavender = colors.lavender;
            if (colors.primary) root.primary = colors.primary;
            if (colors.onPrimary) root.onPrimary = colors.onPrimary;
            if (colors.primaryContainer) root.primaryContainer = colors.primaryContainer;
            if (colors.onPrimaryContainer) root.onPrimaryContainer = colors.onPrimaryContainer;
            if (colors.surfaceContainer) root.surfaceContainer = colors.surfaceContainer;
            if (colors.onSurface) root.onSurface = colors.onSurface;
        } catch (e) {
            console.warn("MatugenColors: Failed to parse colors JSON:", e);
        }
    }

    property var _readProc: Process {
        id: readProc
        command: ["cat", Quickshell.env("HOME") + "/.cache/matugen/quickshell-colors.json"]
        stdout: SplitParser {
            onRead: data => { root._accumulatedOutput += data; }
        }
        onExited: {
            if (root._accumulatedOutput.length > 0) {
                root.applyColors(root._accumulatedOutput);
            }
            root._accumulatedOutput = "";
        }
    }

    property var _pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!readProc.running) {
                root._accumulatedOutput = "";
                readProc.running = true;
            }
        }
    }
}
