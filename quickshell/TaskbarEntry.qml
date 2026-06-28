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

    // hover / keep-alive state
    property bool previewOpen: false
    property bool popupHovered: false
    function startCloseTimer() { closeTimer.restart() }

    onPreviewOpenChanged: { if (!previewOpen) popupHovered = false }

    Timer {
        id: hoverTimer
        interval: 400
        onTriggered: { if (mouse.containsMouse && entry.kind === "app") e.previewOpen = true }
    }
    Timer {
        id: closeTimer
        interval: 200
        // ponytail: double-guard so moving icon→popup within 200ms keeps it open
        onTriggered: { if (!mouse.containsMouse && !e.popupHovered) e.previewOpen = false }
    }

    // Stack hint — painted first so it appears behind the main icon (count > 1 only)
    Rectangle {
        visible: entry.kind === "app" && entry.count > 1
        x: 4; y: 4
        width:  parent.width  - 4
        height: parent.height - 4
        radius: 10
        color: "transparent"
        border.color: Theme.comment
        border.width: 1
        opacity: 0.6
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: entry.focused ? Theme.surface1 : (mouse.containsMouse ? Theme.surface0 : "transparent")
        opacity: (entry.kind === "app" && entry.allMinimized) ? 0.5 : 1.0

        IconImage {
            anchors.centerIn: parent
            implicitSize: 28
            visible: !!(e.de && e.de.icon)
            source: e.de && e.de.icon ? Quickshell.iconPath(e.de.icon) : ""
        }
        Text {
            anchors.centerIn: parent
            visible: !(e.de && e.de.icon)
            text: String.fromCodePoint(0xF003B) // ponytail: nf-md-application glyph for iconless entries
            font.family: Theme.fontFamily
            font.pixelSize: 22
            color: Theme.subtext
        }

        // indicatore: barretta sotto se app aperta; allargata/blu se a fuoco
        Rectangle {
            visible: entry.kind === "app"
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
        onEntered: { if (entry.kind === "app") hoverTimer.restart() }
        onExited:  { hoverTimer.stop(); closeTimer.restart() }
        onClicked: (m) => {
            if (m.button === Qt.LeftButton) {
                if (entry.kind === "launcher") {
                    if (e.de) e.de.execute();
                } else if (entry.count === 1) {
                    var w = entry.windows[0];
                    if (w.minimized)     HyprWindows.restore(w.address, e.screenName);
                    else if (w.focused)  HyprWindows.minimize(w.address);
                    else                 HyprWindows.focus(w.address);
                } else {
                    // count > 1: apri subito il preview; l'utente sceglie la finestra
                    e.previewOpen = true;
                }
            } else if (m.button === Qt.MiddleButton) {
                // count > 1: no-op (non indoviniamo quale chiudere)
                if (entry.kind === "app" && entry.count === 1)
                    HyprWindows.close(entry.windows[0].address);
            } else if (m.button === Qt.RightButton) {
                e.menuOpen = true;
            }
        }
    }

    // menu contestuale
    property bool menuOpen: false
    Timer { id: menuTimer; interval: 4000; onTriggered: e.menuOpen = false }
    onMenuOpenChanged: if (menuOpen) menuTimer.restart()

    TaskbarPreview {
        visible:     e.previewOpen && !e.menuOpen
        entry:       e.entry
        de:          e.de
        parentEntry: e
    }

    PopupWindow {
        id: menu
        visible: e.menuOpen
        anchor.item: e
        anchor.rect.x: e.width / 2 - implicitWidth / 2
        anchor.rect.y: -(implicitHeight + 8)
        implicitWidth: 180; implicitHeight: col.implicitHeight + 8
        color: "transparent"
      Rectangle {
        anchors.fill: parent
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
            // riga Chiudi / Chiudi tutte (solo per app group, non launcher)
            Rectangle {
                visible: entry.kind === "app"
                width: parent.width; height: 28; radius: 6; color: cm.containsMouse ? Theme.surface0 : "transparent"
                Text { anchors.centerIn: parent
                    text: entry.count === 1 ? "Chiudi" : "Chiudi tutte"
                    color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (entry.count === 1) {
                            HyprWindows.close(entry.windows[0].address);
                        } else {
                            for (var i = 0; i < entry.windows.length; i++)
                                HyprWindows.close(entry.windows[i].address);
                        }
                        e.menuOpen = false;
                    }
                }
            }
        }
      }
    }
}
