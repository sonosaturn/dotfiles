pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var revealed: ({})   // screenName -> bool
    function setRevealed(name, on) { var r = revealed; r[name] = on; revealed = r; }
}
