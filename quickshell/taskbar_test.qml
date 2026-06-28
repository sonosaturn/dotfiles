import QtQuick
import "lib/taskmodel.js" as TM

QtObject {
    Component.onCompleted: {
        var wins = [
            { address: "0x1", appId: "kitty",   title: "t", monitorName: "DP-4", activated: true,  minimized: false },
            { address: "0x2", appId: "firefox", title: "f", monitorName: "DP-3", activated: false, minimized: false },
            { address: "0x3", appId: "Spotify", title: "s", monitorName: "DP-4", activated: false, minimized: true  }
        ];
        var pinned = ["kitty", "thunar"];   // kitty ha finestre → niente launcher; thunar → launcher

        var e = TM.deriveEntries(wins, pinned, "DP-4");
        if (e.length !== 3) { console.error("FAIL len DP-4=" + e.length); Qt.exit(1); }
        if (e[0].kind !== "launcher" || e[0].appId !== "thunar") { console.error("FAIL launcher"); Qt.exit(1); }
        if (e[1].kind !== "window" || e[1].appId !== "kitty" || !e[1].focused) { console.error("FAIL kitty"); Qt.exit(1); }
        if (e[2].appId !== "Spotify" || !e[2].minimized) { console.error("FAIL minimized"); Qt.exit(1); }

        var e3 = TM.deriveEntries(wins, pinned, "DP-3");
        if (!e3.some(function (x) { return x.appId === "firefox" && x.kind === "window"; })) { console.error("FAIL firefox DP-3"); Qt.exit(1); }
        if (!e3.some(function (x) { return x.appId === "Spotify" && x.minimized; })) { console.error("FAIL minimized DP-3"); Qt.exit(1); }
        // thunar (fissato, nessuna finestra) compare come launcher su entrambe
        if (!e3.some(function (x) { return x.kind === "launcher" && x.appId === "thunar"; })) { console.error("FAIL launcher DP-3"); Qt.exit(1); }

        console.log("PASS taskmodel");
        Qt.exit(0);
    }
}
