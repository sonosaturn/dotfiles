import QtQuick
import QtQuick.Layouts

// Una riga del mixer: icona mute (toggle), nome device, %, slider volume.
// node = PwNode (deve essere bindato da un PwObjectTracker nel parent).
ColumnLayout {
    id: row
    property string label: ""
    property int cpOn: 0
    property int cpOff: 0
    property var node: null
    readonly property bool has: node !== null && node.audio !== null

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: String.fromCodePoint((row.has && node.audio.muted) ? row.cpOff : row.cpOn)
            color: (row.has && node.audio.muted) ? Theme.red : Theme.cyan
            font.family: Theme.fontFamily
            font.pixelSize: 16
            MouseArea {
                anchors.fill: parent
                enabled: row.has
                onClicked: node.audio.muted = !node.audio.muted
            }
        }
        Text {
            Layout.fillWidth: true
            text: row.has ? (node.description || node.name || row.label) : (row.label + " — n/d")
            elide: Text.ElideRight
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
        Text {
            text: row.has ? Math.round(node.audio.volume * 100) + "%" : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    VSlider {
        Layout.fillWidth: true
        enabled: row.has
        value: row.has ? node.audio.volume : 0
        onMoved: (v) => { if (row.has) node.audio.volume = v; }
    }
}
