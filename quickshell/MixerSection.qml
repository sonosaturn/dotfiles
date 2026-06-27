import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Sezione mixer per un verso (output o input): riga del device di default
// (mute/nome/%/slider) + lista espandibile dei device per sceglierne uno.
ColumnLayout {
    id: sec
    property string label: ""
    property int cpOn: 0
    property int cpOff: 0
    property bool isSink: true                 // true = output (sink), false = input (source)
    readonly property var node: isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
    readonly property bool has: node !== null && node.audio !== null
    property bool expanded: false

    function devName(n) {
        return (n.description && n.description.length > 0) ? n.description
             : (n.nickname && n.nickname.length > 0) ? n.nickname
             : n.name;
    }

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {                                  // toggle mute
            text: String.fromCodePoint((sec.has && node.audio.muted) ? sec.cpOff : sec.cpOn)
            color: (sec.has && node.audio.muted) ? Theme.red : Theme.cyan
            font.family: Theme.fontFamily
            font.pixelSize: 16
            MouseArea {
                anchors.fill: parent
                enabled: sec.has
                onClicked: node.audio.muted = !node.audio.muted
            }
        }
        Text {                                  // nome device (click = espandi lista)
            Layout.fillWidth: true
            text: sec.has ? sec.devName(node) : (sec.label + " — n/d")
            elide: Text.ElideRight
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 12
            MouseArea { anchors.fill: parent; onClicked: sec.expanded = !sec.expanded }
        }
        Text {                                  // percentuale
            text: sec.has ? Math.round(node.audio.volume * 100) + "%" : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
        Text {                                  // chevron
            text: sec.expanded ? "▴" : "▾"
            color: Theme.comment
            font.family: Theme.fontFamily
            font.pixelSize: 14
            MouseArea { anchors.fill: parent; onClicked: sec.expanded = !sec.expanded }
        }
    }

    VSlider {
        Layout.fillWidth: true
        enabled: sec.has
        value: sec.has ? node.audio.volume : 0
        onMoved: (v) => { if (sec.has) node.audio.volume = v; }
    }

    ColumnLayout {                              // lista device selezionabili
        Layout.fillWidth: true
        Layout.leftMargin: 24
        spacing: 2
        visible: sec.expanded

        Repeater {
            model: Pipewire.nodes
            delegate: Text {
                required property var modelData
                // solo device hardware del verso giusto (no stream di app)
                readonly property bool match: modelData.audio !== null
                    && modelData.isSink === sec.isSink && !modelData.isStream
                readonly property bool current: modelData === sec.node
                visible: match
                Layout.fillWidth: true
                text: (current ? "● " : "○ ") + sec.devName(modelData)
                elide: Text.ElideRight
                color: current ? Theme.cyan : Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 11
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (sec.isSink) Pipewire.preferredDefaultAudioSink = modelData;
                        else            Pipewire.preferredDefaultAudioSource = modelData;
                        sec.expanded = false;
                    }
                }
            }
        }
    }
}
