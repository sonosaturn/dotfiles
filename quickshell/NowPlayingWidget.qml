import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: w
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-nowplaying"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; right: true }
    margins { top: 52; right: 40 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Player attivo: primo in Playing, altrimenti il primo con un titolo.
    // Scarta i proxy vuoti (es. playerctld senza player reale) → placeholder.
    readonly property var player: {
        var ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        var firstReal = null;
        for (var i = 0; i < ps.length; i++) {
            var p = ps[i];
            if (p.playbackState === MprisPlaybackState.Playing) return p;
            if (!firstReal && p.trackTitle && p.trackTitle.length > 0) firstReal = p;
        }
        return firstReal;
    }
    readonly property bool hasPlayer: player !== null

    // Poll posizione ogni secondo per aggiornare la seek bar
    // ponytail: emettere il segnale forza re-evaluation dei binding su position
    Timer {
        interval: 1000; running: w.hasPlayer; repeat: true
        onTriggered: if (w.player && w.player.positionSupported) w.player.positionChanged()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        // Card ritratto ~3:4 (larghezza ≈ clock +~10%); spazio per la coda in futuro
        implicitWidth: 240
        implicitHeight: 320

        // Placeholder: nessun player
        Column {
            anchors.centerIn: parent
            visible: !w.hasPlayer
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""           // nf-fa-music
                color: Theme.comment
                font.family: Theme.fontFamily; font.pixelSize: 44
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Niente in riproduzione"
                color: Theme.comment
                font.family: Theme.fontFamily; font.pixelSize: 13
            }
        }

        // Now-playing verticale (copertina grande in alto)
        Column {
            id: content
            visible: w.hasPlayer
            anchors { fill: parent; margins: 16 }
            spacing: 8

            // Copertina grande quadrata, centrata
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 176; height: 176; radius: 12
                color: Theme.surface0
                clip: true
                Image {
                    id: artImg
                    anchors.fill: parent
                    source: w.player && w.player.trackArtUrl ? w.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    text: ""       // nf-fa-music
                    color: Theme.comment
                    font.family: Theme.fontFamily; font.pixelSize: 48
                }
            }

            // Titolo
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: w.player ? (w.player.trackTitle || "—") : "—"
                color: Theme.fg; font.family: Theme.fontFamily
                font.pixelSize: 15; font.bold: true
            }
            // Artista
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: w.player ? (w.player.trackArtist || "") : ""
                color: Theme.subtext; font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            // Seek bar
            Rectangle {
                width: parent.width; height: 6; radius: 3
                color: Theme.surface0
                visible: w.player && w.player.lengthSupported && w.player.length > 0
                Rectangle {
                    height: parent.height; radius: 3; color: Theme.blue
                    width: (w.player && w.player.length > 0)
                           ? parent.width * Math.min(w.player.position / w.player.length, 1)
                           : 0
                }
            }

            // Controlli centrati
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 26
                Text {
                    text: ""       // nf-fa-backward (prev)
                    color: Theme.blue; font.pixelSize: 22
                    font.family: Theme.fontFamily
                    MouseArea { anchors.fill: parent
                        onClicked: if (w.player) w.player.previous() }
                }
                Text {
                    text: (w.player && w.player.playbackState === MprisPlaybackState.Playing)
                          ? "" : ""   // pause : play
                    color: Theme.cyan; font.pixelSize: 24
                    font.family: Theme.fontFamily
                    MouseArea { anchors.fill: parent
                        onClicked: if (w.player) w.player.togglePlaying() }
                }
                Text {
                    text: ""       // nf-fa-forward (next)
                    color: Theme.blue; font.pixelSize: 22
                    font.family: Theme.fontFamily
                    MouseArea { anchors.fill: parent
                        onClicked: if (w.player) w.player.next() }
                }
            }
        }
    }
}
