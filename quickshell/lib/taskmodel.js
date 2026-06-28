.pragma library
// deriveEntries(windows, pinned, screenName) → voci ordinate della taskbar.
// Ordine: launcher (app fissate SENZA finestre aperte), poi un app-group per appId
// (ordine di prima apparizione nell'array windows). screenName non filtra; serve
// solo ai chiamanti per la semantica di restore ("dove sono").
function deriveEntries(windows, pinned, screenName) {
    windows = windows || [];
    pinned  = pinned  || [];

    // Costruisce mappa appId → [window, ...] mantenendo l'ordine di prima comparsa.
    var appOrder = [];
    var appMap   = {};
    for (var i = 0; i < windows.length; i++) {
        var w = windows[i];
        if (!appMap[w.appId]) {
            appMap[w.appId] = [];
            appOrder.push(w.appId);
        }
        appMap[w.appId].push({
            address:   w.address,
            title:     w.title,
            focused:   !!w.activated,
            minimized: !!w.minimized
        });
    }

    var entries = [];

    // Launcher: app fissate senza finestre aperte.
    for (var p = 0; p < pinned.length; p++) {
        if (!appMap[pinned[p]])
            entries.push({ kind: "launcher", appId: pinned[p] });
    }

    // App group: una voce per appId, tutte le finestre (visibili + minimizzate).
    for (var a = 0; a < appOrder.length; a++) {
        var id   = appOrder[a];
        var wins = appMap[id];
        var anyFocused = false, allMin = true;
        for (var j = 0; j < wins.length; j++) {
            if (wins[j].focused)    anyFocused = true;
            if (!wins[j].minimized) allMin     = false;
        }
        entries.push({
            kind:         "app",
            appId:        id,
            windows:      wins,
            focused:      anyFocused,
            allMinimized: allMin,
            count:        wins.length
        });
    }

    return entries;
}
