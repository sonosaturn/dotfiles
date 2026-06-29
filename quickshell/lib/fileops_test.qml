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
           ["gio","copy","-p","/d/a.txt","/d/b c.txt","/dest"], "copy");
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
        console.log("fileops_test: ALL PASS");
    }
}
