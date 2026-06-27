import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    GridLayout {
        anchors.fill: parent
        anchors.margins: 4
        columns: 2
        rowSpacing: 10; columnSpacing: 10

        Repeater {
            model: [
                { cp: 0xf023, label: "Blocca",  color: Theme.blue,   cmd: ["loginctl", "lock-session"] },
                { cp: 0xf2f5, label: "Esci",    color: Theme.cyan,   cmd: ["hyprctl", "dispatch", "exit"] },
                { cp: 0xf021, label: "Riavvia", color: Theme.yellow, cmd: ["systemctl", "reboot"] },
                { cp: 0xf011, label: "Spegni",  color: Theme.red,    cmd: ["systemctl", "poweroff"] }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: hover.containsMouse ? Theme.surface1 : Theme.surface0
                border.color: modelData.color
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: String.fromCodePoint(modelData.cp)
                        color: modelData.color
                        font.pixelSize: 26; font.family: Theme.fontFamily
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        color: Theme.subtext
                        font.pixelSize: 12; font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { proc.command = modelData.cmd; proc.running = true; }
                }
            }
        }
    }

    Process { id: proc }
}
