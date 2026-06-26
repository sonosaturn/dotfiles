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

    anchors { bottom: true; left: true }
    margins { bottom: 40; left: 40 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Player attivo: primo in Playing, altrimenti il primo
    readonly property var player: {
        var ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (var i = 0; i < ps.length; i++)
            if (ps[i].playbackState === MprisPlaybackState.Playing) return ps[i];
        return ps[0];
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
        implicitWidth: 360
        implicitHeight: w.hasPlayer ? (content.implicitHeight + 28) : 60

        // Placeholder: nessun player
        Text {
            anchors.centerIn: parent
            visible: !w.hasPlayer
            //  = nf-fa-music (Nerd Font v3, JetBrainsMono NF U+F001)
            text: "  Niente in riproduzione"
            color: Theme.comment
            font.family: Theme.fontFamily; font.pixelSize: 15
        }

        Row {
            id: content
            visible: w.hasPlayer
            anchors { fill: parent; margins: 14 }
            spacing: 14

            // Copertina (o placeholder nota musicale)
            Rectangle {
                width: 80; height: 80; radius: 10
                color: Theme.surface0
                clip: true
                anchors.verticalCenter: parent.verticalCenter
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
                    //  = nf-fa-music
                    text: ""
                    color: Theme.comment
                    font.family: Theme.fontFamily; font.pixelSize: 28
                }
            }

            Column {
                width: parent.width - 80 - 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: w.player ? (w.player.trackTitle || "—") : "—"
                    color: Theme.fg; font.family: Theme.fontFamily
                    font.pixelSize: 16; font.bold: true
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: w.player ? (w.player.trackArtist || "") : ""
                    color: Theme.subtext; font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                // Controlli: =prev =play =pause =next (nf-fa-*)
                Row {
                    spacing: 18
                    Text {
                        text: ""
                        color: Theme.blue; font.pixelSize: 20
                        font.family: Theme.fontFamily
                        MouseArea { anchors.fill: parent
                            onClicked: if (w.player) w.player.previous() }
                    }
                    Text {
                        text: (w.player && w.player.playbackState === MprisPlaybackState.Playing)
                              ? "" : ""
                        color: Theme.cyan; font.pixelSize: 22
                        font.family: Theme.fontFamily
                        MouseArea { anchors.fill: parent
                            onClicked: if (w.player) w.player.togglePlaying() }
                    }
                    Text {
                        text: ""
                        color: Theme.blue; font.pixelSize: 20
                        font.family: Theme.fontFamily
                        MouseArea { anchors.fill: parent
                            onClicked: if (w.player) w.player.next() }
                    }
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
            }
        }
    }
}
