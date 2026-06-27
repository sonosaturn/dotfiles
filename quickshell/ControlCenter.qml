import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: cc
    visible: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    // OnDemand: prende il focus solo quando ci clicchi sopra (ESC funziona),
    // senza rubare la tastiera alle altre app finché non interagisci col pannello
    WlrLayershell.keyboardFocus: cc.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // solo il pannello è cliccabile: i click fuori passano alle app sotto (niente modale)
    mask: Region { item: panel }

    property int tab: 0

    // posizione del pannello persistita su disco (sopravvive a restart/relogin di qs)
    FileView {
        id: posFile
        path: Quickshell.statePath("controlcenter-pos.json")
        blockLoading: true            // carica sincrono: posizione pronta al primo toggle
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: pos
            property real px: -1      // -1 = mai spostato → centra
            property real py: -1
        }
    }

    // colloca il pannello: posizione salvata (clampata allo schermo) o centro al primo avvio
    function placePanel() {
        if (content.width <= 0 || content.height <= 0) return;   // finestra non ancora dimensionata
        if (pos.px >= 0) {
            panel.x = Math.max(0, Math.min(pos.px, content.width  - panel.width));
            panel.y = Math.max(0, Math.min(pos.py, content.height - panel.height));
        } else {
            panel.x = (content.width  - panel.width)  / 2;
            panel.y = (content.height - panel.height) / 2;
        }
    }

    function open() {
        if (cc.visible) return;
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === fm.name) { cc.screen = Quickshell.screens[i]; break; }
            }
        }
        cc.visible = true;
        placePanel();
    }

    function toggle() {
        if (cc.visible) { cc.visible = false; return; }
        open();
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "controlcenter"
        onPressed: cc.toggle()
    }

    // apre direttamente sul tab Sessione (usato dall'icona power di Waybar)
    GlobalShortcut {
        appid: "quickshell"
        name: "controlcenter-session"
        onPressed: { cc.tab = 2; cc.open(); }
    }

    Item {
        id: content
        anchors.fill: parent
        focus: cc.visible
        Keys.onEscapePressed: cc.visible = false

        // al primo apri la finestra parte a 0 e viene dimensionata dopo:
        // riposiziona appena le dimensioni reali sono note
        onWidthChanged:  if (cc.visible) placePanel()
        onHeightChanged: if (cc.visible) placePanel()

        Rectangle {
            id: panel
            width: 380
            height: 460
            radius: Theme.radius
            color: Theme.panelBg          // trasparenza identica ai widget
            border.color: Theme.border
            border.width: Theme.borderWidth

            // assorbe i click sul pannello (non propagare al "chiudi")
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // grip: trascina il pannello, salva la posizione al rilascio
                MouseArea {
                    id: grip
                    Layout.fillWidth: true
                    implicitHeight: 16
                    cursorShape: Qt.SizeAllCursor
                    drag.target: panel
                    drag.minimumX: 0
                    drag.maximumX: content.width  - panel.width
                    drag.minimumY: 0
                    drag.maximumY: content.height - panel.height
                    onReleased: { pos.px = panel.x; pos.py = panel.y; }
                    Text {
                        anchors.centerIn: parent
                        text: "• • •"   // ··· maniglia
                        color: Theme.comment
                        font.pixelSize: 14
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            { icon: 0xf028, label: "Audio" },   // volume
                            { icon: 0xf073, label: "Cal" },     // calendario
                            { icon: 0xf011, label: "Sess" }     // power
                        ]
                        delegate: Rectangle {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 10
                            color: cc.tab === index ? Theme.surface1 : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: String.fromCodePoint(modelData.icon) + "  " + modelData.label
                                color: cc.tab === index ? Theme.cyan : Theme.subtext
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                            MouseArea { anchors.fill: parent; onClicked: cc.tab = index }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: cc.tab
                    MixerTab {}
                    CalendarTab {}
                    SessionTab {}
                }
            }
        }
    }
}
