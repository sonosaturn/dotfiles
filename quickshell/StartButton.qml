import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: sb
    implicitWidth: 44; implicitHeight: 44
    Process { id: launcher; command: ["rofi", "-show", "drun"] }
    Rectangle {
        anchors.fill: parent; anchors.margins: 2; radius: 10
        color: ma.containsMouse ? Theme.surface0 : "transparent"
        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xf303)   // nf-linux-archlinux
            color: Theme.blue; font.family: Theme.fontFamily; font.pixelSize: 22
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: launcher.running = true }
}
