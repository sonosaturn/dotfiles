import QtQuick
import "fileops.js" as F

QtObject {
    function eq(a, b, msg) {
        if (JSON.stringify(a) !== JSON.stringify(b))
            throw new Error("FAIL " + msg + " → " + JSON.stringify(a));
    }
    Component.onCompleted: {
        // argv puri: i path con spazi restano UN elemento (niente shell, niente escaping)
        eq(F.openFile("/home/x/Desktop/a b.txt"),
           ["xdg-open", "/home/x/Desktop/a b.txt"], "openFile");
        eq(F.openDir("/home/x/Desktop/Cartella di prova"),
           ["thunar", "/home/x/Desktop/Cartella di prova"], "openDir");
        eq(F.rename("/d/old name.txt", "new'name.txt"),
           ["gio","rename","/d/old name.txt","new'name.txt"], "rename");
        eq(F.copy(["/d/a.txt","/d/b c.txt"], "/dest"),
           ["cp","-a","/d/a.txt","/d/b c.txt","/dest"], "copy");
        eq(F.copyOne("/d/a b.txt", "/d/a b (copia).txt"),
           ["cp","-a","/d/a b.txt","/d/a b (copia).txt"], "copyOne");
        eq(F.move(["/d/a.txt"], "/dest"),
           ["gio","move","/d/a.txt","/dest"], "move");
        eq(F.trash(["/d/a.txt","/d/b.txt"]),
           ["gio","trash","/d/a.txt","/d/b.txt"], "trash");
        eq(F.remove(["/d/x"]), ["gio","remove","-f","/d/x"], "remove");
        eq(F.mkdir("/d/Nuova cartella"), ["gio","mkdir","/d/Nuova cartella"], "mkdir");
        eq(F.touch("/d/Nuovo file"), ["touch","/d/Nuovo file"], "touch");
        eq(F.compress("/d", ["a.txt","b c.txt"], "/d/archivio.tar.gz"),
           ["tar","-czf","/d/archivio.tar.gz","-C","/d","a.txt","b c.txt"], "compress");
        eq(F.terminalHere("/d/sub"), ["kitty","--working-directory","/d/sub"], "terminalHere");
        eq(F.properties("/d/a.txt"), ["thunar","/d/a.txt"], "properties");
        eq(F.wallpaperNext("/home/x"),
           ["/home/x/.config/hypr/scripts/wallpaper.sh","--next"], "wallpaperNext");

        // clipboard di sistema: payload "<op>\nfile://<uri>" con spazi URI-encoded
        eq(F.clipSet("copy", ["/d/a b.txt", "/d/c.txt"]),
           ["wl-copy","--type","x-special/gnome-copied-files",
            "copy\nfile:///d/a%20b.txt\nfile:///d/c.txt"], "clipSet");
        eq(F.clipGet(),
           ["wl-paste","--no-newline","--type","x-special/gnome-copied-files"], "clipGet");
        eq(F.clipClear(), ["wl-copy","--clear"], "clipClear");
        // parseClip decodifica gli URI e riconosce l'operazione
        eq(F.parseClip("cut\nfile:///d/a%20b.txt\nfile:///d/c.txt"),
           { op: "cut", paths: ["/d/a b.txt", "/d/c.txt"] }, "parseClip");
        eq(F.parseClip(""), null, "parseClip empty");
        eq(F.parseClip("copy"), null, "parseClip no-paths");
        // round-trip: payload di clipSet → parseClip
        var payload = F.clipSet("copy", ["/d/a b.txt"])[3];
        eq(F.parseClip(payload), { op: "copy", paths: ["/d/a b.txt"] }, "clip round-trip");

        console.log("fileops_test: ALL PASS");
    }
}
