pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: state

    // `mem` è la copia AUTOREVOLE in memoria (property JS normale): letture/scritture
    // sincrone e affidabili. L'adapter è usato SOLO come sink di persistenza — lo
    // scriviamo, non lo rileggiamo (rileggere un JsonAdapter appena assegnato, nella
    // stessa sequenza sincrona, restituisce un valore stale → posizioni perse).
    // Forma logica: { "DP-4": { "file": {x,y} }, ... }. Su disco: { "data": "<json>" }.
    property var mem: ({})

    FileView {
        id: posFile
        path: Quickshell.statePath("desktop-icons.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        JsonAdapter { id: posAdapter; property string data: "{}" }
    }

    // carica lo stato persistito una volta sola all'avvio
    Component.onCompleted: {
        try { mem = JSON.parse(posAdapter.data) || {}; } catch (e) { mem = {}; }
    }

    function pos(screenName, fileName) {
        var s = mem[screenName];
        if (s && s[fileName]) return s[fileName];
        return null;
    }

    function setPos(screenName, fileName, x, y) {
        if (!mem[screenName]) mem[screenName] = {};
        mem[screenName][fileName] = { x: Math.round(x), y: Math.round(y) };
        posAdapter.data = JSON.stringify(mem);   // sink → onAdapterUpdated → writeAdapter()
    }

    function clearScreen(screenName) {
        delete mem[screenName];
        posAdapter.data = JSON.stringify(mem);
    }
}
