pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "lib/fileops.js" as F

Singleton {
    id: model

    readonly property string home: Quickshell.env("HOME")
    readonly property string desktopDir: home + "/Desktop"
    property var files: []

    FolderListModel {
        id: fl
        folder: "file://" + model.desktopDir
        showDirs: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Type
        onStatusChanged: if (status === FolderListModel.Ready) model.rebuild()
        onCountChanged: model.rebuild()
    }

    function rebuild() {
        var arr = [];
        for (var i = 0; i < fl.count; i++)
            arr.push({ name: fl.get(i, "fileName"),
                       path: fl.get(i, "filePath"),
                       isDir: fl.get(i, "fileIsDir") });
        model.files = arr;
    }

    // esecutore comandi: Process usa-e-getta; notifica su errore; il modello si
    // ri-aggiorna da solo via FolderListModel (watcher), refresh() è un fallback.
    property Component procComp: Component { Process {} }
    function run(argv) {
        var p = procComp.createObject(model, { command: argv });
        p.exited.connect(function(code) {
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "Desktop",
                    "Operazione fallita: " + argv.join(" ")]);
            p.destroy();
        });
        p.running = true;
    }

    function refresh() { rebuild(); }

    // legge la clipboard di sistema in modo asincrono (Process usa-e-getta che cattura stdout)
    property Component readComp: Component {
        Process {
            property var cb
            stdout: StdioCollector { id: sc }
            onExited: function(code) { if (cb) cb(code === 0 ? sc.text : ""); destroy(); }
        }
    }
    function readClipboard(cb) {
        var p = readComp.createObject(model, { command: F.clipGet(), cb: cb });
        p.running = true;
    }

    // --- helpers ---
    function exists(name) {
        for (var i = 0; i < files.length; i++) if (files[i].name === name) return true;
        return false;
    }
    function uniqueName(base, ext) {
        var n = base + (ext || "");
        var k = 1;
        while (exists(n)) { n = base + " (" + (k++) + ")" + (ext || ""); }
        return n;
    }

    // --- azioni ---
    function openItem(item) {
        run(item.isDir ? F.openDir(item.path) : F.openFile(item.path));
    }
    function rename(path, newName) { if (newName && newName.length) run(F.rename(path, newName)); }

    // copia/taglia → clipboard di sistema (interop con Thunar e altri file manager)
    function setClipboard(paths, mode) { if (paths.length) run(F.clipSet(mode, paths)); }

    function _parentOf(p) { return p.substring(0, p.lastIndexOf("/")); }
    function _splitName(n) {
        var dot = n.lastIndexOf(".");
        return (dot > 0) ? { base: n.substring(0, dot), ext: n.substring(dot) } : { base: n, ext: "" };
    }
    function _pasteOne(op, src) {
        var name = src.split("/").pop();
        if (_parentOf(src) === desktopDir) {
            // sorgente già sul desktop: cut → niente (è già qui); copia → duplicato "(copia)"
            if (op === "cut") return;
            var sp = _splitName(name);
            var dn = uniqueName(sp.base + " (copia)", sp.ext);
            run(F.copyOne(src, desktopDir + "/" + dn));
        } else {
            run(op === "cut" ? F.move([src], desktopDir) : F.copy([src], desktopDir));
        }
    }
    // incolla dalla clipboard di sistema sul desktop (legge wl-paste, poi gio copy/move)
    function paste() {
        readClipboard(function(text) {
            var c = F.parseClip(text);
            if (!c) return;
            for (var i = 0; i < c.paths.length; i++) _pasteOne(c.op, c.paths[i]);
            if (c.op === "cut") run(F.clipClear());   // un taglio si consuma dopo l'incolla
        });
    }
    function showInThunar(path) { run(F.openDir(_parentOf(path))); }
    function trash(paths)  { if (paths.length) run(F.trash(paths)); }
    function remove(paths) { if (paths.length) run(F.remove(paths)); }
    // creano e ritornano il nome: il Desktop chiamante seleziona + avvia la rinomina
    function newFolder() {
        var name = uniqueName("Nuova cartella", "");
        run(F.mkdir(desktopDir + "/" + name));
        return name;
    }
    function newFile() {
        var name = uniqueName("Nuovo file", ".txt");
        run(F.touch(desktopDir + "/" + name));
        return name;
    }
    function compress(paths) {
        if (!paths.length) return;
        var names = paths.map(function(p) { return p.split("/").pop(); });
        var archive = desktopDir + "/" + uniqueName("archivio", ".tar.gz");
        run(F.compress(desktopDir, names, archive));
    }
    function properties(path)  { run(F.properties(path)); }
    function terminalHere(dir) { run(F.terminalHere(dir)); }
    function wallpaperNext()   { run(F.wallpaperNext(home)); }
}
