pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: state

    // Struttura: { "DP-4": { "file.txt": {x,y}, ... }, "DP-3": {...} }
    property var positions: posAdapter.positions

    FileView {
        id: posFile
        path: Quickshell.statePath("desktop-icons.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        JsonAdapter { id: posAdapter; property var positions: ({}) }
    }

    function pos(screenName, fileName) {
        var s = posAdapter.positions[screenName];
        if (s && s[fileName]) return s[fileName];
        return null;
    }

    function setPos(screenName, fileName, x, y) {
        var all = posAdapter.positions;
        if (!all[screenName]) all[screenName] = {};
        all[screenName][fileName] = { x: Math.round(x), y: Math.round(y) };
        posAdapter.positions = all;   // riassegnazione → onAdapterUpdated → writeAdapter()
    }

    function clearScreen(screenName) {
        var all = {};
        var p = posAdapter.positions;
        for (var key in p) {
            if (key !== screenName) {
                all[key] = p[key];
            }
        }
        posAdapter.positions = all;
    }
}
