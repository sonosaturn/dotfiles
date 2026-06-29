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
    property var clipboard: ({ paths: [], mode: "" })   // mode: "copy" | "cut"

    signal renameRequested(string name)

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
    function setClipboard(paths, mode) { model.clipboard = { paths: paths.slice(), mode: mode }; }
    function paste() {
        var c = model.clipboard;
        if (!c.paths.length) return;
        run(c.mode === "cut" ? F.move(c.paths, desktopDir) : F.copy(c.paths, desktopDir));
        if (c.mode === "cut") model.clipboard = { paths: [], mode: "" };
    }
    function trash(paths)  { if (paths.length) run(F.trash(paths)); }
    function remove(paths) { if (paths.length) run(F.remove(paths)); }
    function newFolder() {
        var name = uniqueName("Nuova cartella", "");
        run(F.mkdir(desktopDir + "/" + name));
        renameRequested(name);
    }
    function newFile() {
        var name = uniqueName("Nuovo file", ".txt");
        run(F.touch(desktopDir + "/" + name));
        renameRequested(name);
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
