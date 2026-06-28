.pragma library
// deriveEntries(windows, pinned, screenName) → voci ordinate della taskbar di uno schermo.
// Ordine: launcher (app fissate SENZA finestre), finestre visibili del monitor, minimizzate (ovunque).
function deriveEntries(windows, pinned, screenName) {
    windows = windows || [];
    pinned = pinned || [];
    var openAppIds = {};
    for (var i = 0; i < windows.length; i++) openAppIds[windows[i].appId] = true;

    var entries = [];
    for (var p = 0; p < pinned.length; p++)
        if (!openAppIds[pinned[p]]) entries.push({ kind: "launcher", appId: pinned[p] });

    for (var v = 0; v < windows.length; v++) {
        var w = windows[v];
        if (!w.minimized && w.monitorName === screenName)
            entries.push({ kind: "window", address: w.address, appId: w.appId,
                           title: w.title, focused: !!w.activated, minimized: false });
    }
    for (var m = 0; m < windows.length; m++) {
        var wm = windows[m];
        if (wm.minimized)
            entries.push({ kind: "window", address: wm.address, appId: wm.appId,
                           title: wm.title, focused: false, minimized: true });
    }
    return entries;
}
