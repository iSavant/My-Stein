import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: shell

    // TopBar for DP-1 (horizontal, main monitor)
    Loader {
        id: topBarLoader
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

    // Overview + App Launcher (Super+Tab) — owns its own IPC target
    Loader {
        active: true
        source: "modules/overview/Overview.qml"
    }

    // Wallpaper picker (toggled via IPC)
    Loader {
        id: wallpaperLoader
        active: true
        source: "modules/wallpaper/WallpaperPicker.qml"
    }

    // IPC: toggle music popup
    IpcHandler {
        target: "musicToggle"
        function handleCall(data) {
            if (musicLoader.item) {
                musicLoader.item.popupVisible = !musicLoader.item.popupVisible;
            }
            // Sync TopBar icon state
            if (topBarLoader.item) {
                topBarLoader.item.musicPopupVisible = musicLoader.item ? musicLoader.item.popupVisible : false;
            }
        }
    }

    // IPC: toggle wallpaper picker
    IpcHandler {
        target: "wallpaperToggle"
        function handleCall(data) {
            if (wallpaperLoader.item) {
                wallpaperLoader.item.pickerVisible = !wallpaperLoader.item.pickerVisible;
            }
        }
    }

    // NOTE: overviewToggle IPC target is defined in Overview.qml itself
    // Do NOT define it here to avoid duplicate target error
}
