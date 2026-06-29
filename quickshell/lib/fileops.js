.pragma library

function openFile(path)            { return ["xdg-open", path]; }
function openDir(path)             { return ["thunar", path]; }
function rename(path, newName)     { return ["gio", "rename", path, newName]; }
function copy(srcPaths, destDir)   { return ["gio", "copy", "-p"].concat(srcPaths).concat([destDir]); }
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
