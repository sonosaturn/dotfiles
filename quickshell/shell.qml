import Quickshell
import QtQuick

ShellRoot {
    id: root

    // Schermo DP-4, fallback al primo disponibile
    readonly property var targetScreen: {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === "DP-4")
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Component.onCompleted: console.log("quickshell: targetScreen =",
        root.targetScreen ? root.targetScreen.name : "none")

    ClockWidget { screen: root.targetScreen }
    SysMonitorWidget { screen: root.targetScreen }
    NowPlayingWidget { screen: root.targetScreen }
    ControlCenter { }
}
