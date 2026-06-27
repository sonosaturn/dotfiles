import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Item {
    // bind dei nodi default così volume/mute/channels diventano validi
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 22

        MixerRow {
            label: "Output"
            cpOn: 0xf028          // nf-fa-volume_up
            cpOff: 0xf026         // nf-fa-volume_off
            node: Pipewire.defaultAudioSink
        }
        MixerRow {
            label: "Input"
            cpOn: 0xf130          // nf-fa-microphone
            cpOff: 0xf131         // nf-fa-microphone_slash
            node: Pipewire.defaultAudioSource
        }
        Item { Layout.fillHeight: true }
    }
}
