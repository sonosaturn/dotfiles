import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: e
    required property var entry
    required property string screenName
    required property var taskbar
    function pinned() { return taskbar.pinned.indexOf(entry.appId) >= 0; }
    implicitWidth: 44; implicitHeight: 44

    readonly property var de: entry.appId ? DesktopEntries.heuristicLookup(entry.appId) : null

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: entry.focused ? Theme.surface1 : (mouse.containsMouse ? Theme.surface0 : "transparent")
        opacity: entry.minimized ? 0.5 : 1.0

        IconImage {
            anchors.centerIn: parent
            implicitSize: 28
            source: e.de && e.de.icon ? Quickshell.iconPath(e.de.icon, "application-x-executable")
                                      : Quickshell.iconPath("application-x-executable")
        }

        // indicatore: barretta sotto se finestra aperta; punto se a fuoco
        Rectangle {
            visible: entry.kind === "window"
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: entry.focused ? 14 : 6; height: 2; radius: 1
            color: entry.focused ? Theme.blue : Theme.comment
            Behavior on width { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (m) => {
            if (m.button === Qt.LeftButton) {
                if (entry.kind === "launcher") { if (e.de) e.de.execute(); }
                else HyprWindows.toggle(entry, e.screenName);
            } else if (m.button === Qt.MiddleButton) {
                if (entry.kind === "window") HyprWindows.close(entry.address);
            } else if (m.button === Qt.RightButton) {
                e.menuOpen = true;
            }
        }
    }

    // menu contestuale (Pin aggiunto in Task 6). Si chiude su azione o dopo 4s.
    property bool menuOpen: false
    Timer { id: menuTimer; interval: 4000; onTriggered: e.menuOpen = false }
    onMenuOpenChanged: if (menuOpen) menuTimer.restart()

    Rectangle {
        id: menu
        visible: e.menuOpen
        z: 100
        anchors { bottom: parent.top; horizontalCenter: parent.horizontalCenter }
        width: 160; implicitHeight: col.implicitHeight + 8
        radius: 10; color: Theme.panelBg; border.color: Theme.border; border.width: Theme.borderWidth
        Column {
            id: col; anchors.centerIn: parent; width: parent.width - 8; spacing: 0
            Rectangle {
                width: parent.width; height: 28; radius: 6; color: pm.containsMouse ? Theme.surface0 : "transparent"
                Text { anchors.centerIn: parent
                    text: (pinned() ? "Rimuovi dalla taskbar" : "Aggiungi alla taskbar")
                    color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true
                    onClicked: { taskbar.togglePin(entry.appId); e.menuOpen = false; } }
            }
            // riga "Chiudi" (solo per finestre)
            Rectangle {
                visible: entry.kind === "window"
                width: parent.width; height: 28; radius: 6; color: cm.containsMouse ? Theme.surface0 : "transparent"
                Text { anchors.centerIn: parent; text: "Chiudi"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true
                    onClicked: { HyprWindows.close(entry.address); e.menuOpen = false; } }
            }
        }
    }
}
