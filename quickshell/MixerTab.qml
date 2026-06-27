import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Item {
    // bind dei nodi default così volume/mute diventano validi
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 18

        MixerSection {
            label: "Output"
            cpOn: 0xf028          // nf-fa-volume_up
            cpOff: 0xf026         // nf-fa-volume_off
            isSink: true
        }
        MixerSection {
            label: "Input"
            cpOn: 0xf130          // nf-fa-microphone
            cpOff: 0xf131         // nf-fa-microphone_slash
            isSink: false
        }
        Item { Layout.fillHeight: true }
    }
}
