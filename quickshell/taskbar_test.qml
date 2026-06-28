import QtQuick
import "lib/taskmodel.js" as TM

// Test del modello a raggruppamento per app.
// Esegui: qs -p quickshell/taskbar_test.qml 2>&1 | grep -E 'PASS|FAIL'
QtObject {
    Component.onCompleted: {
        var wins = [
            // Due finestre di brave-browser su monitor diversi
            { address: "0x1", appId: "brave-browser", title: "Google - Brave",
              monitorName: "DP-4", activated: false, minimized: false },
            { address: "0x2", appId: "kitty",         title: "~",
              monitorName: "DP-4", activated: true,  minimized: false },
            { address: "0x3", appId: "brave-browser", title: "GitHub - Brave",
              monitorName: "DP-3", activated: false, minimized: false },
            { address: "0x4", appId: "Spotify",       title: "Spotify",
              monitorName: "DP-4", activated: false, minimized: true  }
        ];
        var pinned = ["kitty", "thunar"]; // kitty ha finestre → niente launcher; thunar → launcher

        var e = TM.deriveEntries(wins, pinned, "DP-4");

        // Atteso: [launcher:thunar, app:brave(2), app:kitty(1,focused), app:Spotify(allMinimized)]
        if (e.length !== 4) {
            console.error("FAIL len=" + e.length + " (atteso 4)"); Qt.exit(1);
        }

        // [0] launcher: thunar
        if (e[0].kind !== "launcher" || e[0].appId !== "thunar") {
            console.error("FAIL e[0] launcher thunar: " + JSON.stringify(e[0])); Qt.exit(1);
        }

        // [1] app: brave-browser, count 2, entrambe le finestre presenti
        if (e[1].kind !== "app" || e[1].appId !== "brave-browser" || e[1].count !== 2) {
            console.error("FAIL e[1] brave count 2: " + JSON.stringify(e[1])); Qt.exit(1);
        }
        if (e[1].windows.length !== 2
            || e[1].windows[0].address !== "0x1"
            || e[1].windows[1].address !== "0x3") {
            console.error("FAIL brave windows: " + JSON.stringify(e[1].windows)); Qt.exit(1);
        }
        if (e[1].focused || e[1].allMinimized) {
            console.error("FAIL brave focused/allMinimized: " + JSON.stringify(e[1])); Qt.exit(1);
        }

        // [2] app: kitty, count 1, focused
        if (e[2].kind !== "app" || e[2].appId !== "kitty"
            || e[2].count !== 1 || !e[2].focused || e[2].allMinimized) {
            console.error("FAIL e[2] kitty: " + JSON.stringify(e[2])); Qt.exit(1);
        }

        // [3] app: Spotify, allMinimized
        if (e[3].kind !== "app" || e[3].appId !== "Spotify"
            || !e[3].allMinimized || e[3].focused) {
            console.error("FAIL e[3] Spotify: " + JSON.stringify(e[3])); Qt.exit(1);
        }

        // Entrambe le barre devono produrre la stessa identica lista (niente filtro per monitor)
        var e3 = TM.deriveEntries(wins, pinned, "DP-3");
        if (JSON.stringify(e3) !== JSON.stringify(e)) {
            console.error("FAIL DP-3 != DP-4"); Qt.exit(1);
        }

        console.log("PASS taskmodel");
        Qt.exit(0);
    }
}
