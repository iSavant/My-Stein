import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: shell

    // TopBar for DP-1 (horizontal, main monitor)
    Loader {
        active: true
        source: "modules/bar/TopBar.qml"
    }

    // SideBar for HDMI-A-1 (vertical, secondary monitor)
    Loader {
        active: true
        source: "modules/bar/SideBar.qml"
    }

    // Music popup (opens below TopBar right pill)
    Loader {
        id: musicLoader
        active: true
        source: "modules/music/MusicPopup.qml"
    }

    // Notification popup (top-right of DP-1)
    Loader {
        active: true
        source: "modules/notifications/NotificationPopup.qml"
    }

    // Overview + App Launcher (Super+Tab)
    Loader {
        active: true
        source: "modules/overview/Overview.qml"
    }

    // IPC handlers for toggling widgets
    IpcHandler {
        target: "musicToggle"
        function handleCall(data) {
            if (musicLoader.item) {
                musicLoader.item.visible = !musicLoader.item.visible;
            }
        }
    }

    IpcHandler {
        target: "wallpaperToggle"
        function handleCall(data) {
            if (wallpaperLoader.item) {
                wallpaperLoader.item.visible = !wallpaperLoader.item.visible;
            }
        }
    }

    IpcHandler {
        target: "overviewToggle"
        function handleCall(data) {
            // Overview handles its own toggle internally
        }
    }

    // Wallpaper picker (toggled via IPC)
    Loader {
        id: wallpaperLoader
        active: true
        source: "modules/wallpaper/WallpaperPicker.qml"
    }
}
