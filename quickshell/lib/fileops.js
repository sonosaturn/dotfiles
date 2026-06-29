.pragma library

function openFile(path)            { return ["xdg-open", path]; }
function openDir(path)             { return ["thunar", path]; }
function rename(path, newName)     { return ["gio", "rename", path, newName]; }
// cp -a: copia ricorsiva (file E cartelle); gio copy non copia directory in questa versione
function copy(srcPaths, destDir)   { return ["cp", "-a"].concat(srcPaths).concat([destDir]); }
function copyOne(src, destPath)    { return ["cp", "-a", src, destPath]; }
function move(srcPaths, destDir)   { return ["gio", "move"].concat(srcPaths).concat([destDir]); }
function trash(paths)              { return ["gio", "trash"].concat(paths); }
function remove(paths)             { return ["gio", "remove", "-f"].concat(paths); }
function mkdir(path)               { return ["gio", "mkdir", path]; }
function touch(path)               { return ["touch", path]; }
function compress(parentDir, names, archivePath) {
    return ["tar", "-czf", archivePath, "-C", parentDir].concat(names);
}
function terminalHere(dir)         { return ["kitty", "--working-directory", dir]; }
function properties(path)          { return ["thunar", path]; }
function wallpaperNext(home)       { return [home + "/.config/hypr/scripts/wallpaper.sh", "--next"]; }

// --- clipboard di sistema (formato che i file manager GTK/Thunar capiscono) ---
// payload = "<op>\nfile:///uri1\nfile:///uri2"  (op = "copy" | "cut")
function _uri(path)   { return "file://" + encodeURI(path); }
function _unuri(uri)  { return decodeURIComponent(uri.replace(/^file:\/\//, "")); }

function clipSet(op, paths) {
    var lines = [op].concat(paths.map(_uri));
    return ["wl-copy", "--type", "x-special/gnome-copied-files", lines.join("\n")];
}
function clipGet()  { return ["wl-paste", "--no-newline", "--type", "x-special/gnome-copied-files"]; }
function clipClear(){ return ["wl-copy", "--clear"]; }

// parsa l'output di clipGet → { op, paths } (path decodificati); null se vuoto/non valido
function parseClip(text) {
    if (!text) return null;
    var lines = text.split("\n").filter(function(l) { return l.length > 0; });
    if (lines.length < 2) return null;
    return { op: lines[0], paths: lines.slice(1).map(_unuri) };
}
