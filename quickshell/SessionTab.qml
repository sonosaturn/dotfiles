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
                { cp: 0xf023, label: "Blocca",  color: Theme.blue,   confirm: false, cmd: ["loginctl", "lock-session"] },
                { cp: 0xf2f5, label: "Esci",    color: Theme.cyan,   confirm: false, cmd: ["hyprctl", "dispatch", "exit"] },
                { cp: 0xf021, label: "Riavvia", color: Theme.yellow, confirm: true,  cmd: ["systemctl", "reboot"] },
                { cp: 0xf011, label: "Spegni",  color: Theme.red,    confirm: true,  cmd: ["systemctl", "poweroff"] }
            ]
            delegate: Rectangle {
                id: card
                required property var modelData
                property bool armed: false      // confirm: in attesa del secondo click
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: card.armed ? Theme.surface2 : (hover.containsMouse ? Theme.surface1 : Theme.surface0)
                border.color: card.armed ? Theme.orange : modelData.color
                border.width: card.armed ? 2 : 1

                // l'arma si disinnesca da sola dopo 3s
                Timer { id: armTimer; interval: 3000; onTriggered: card.armed = false }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: String.fromCodePoint(card.armed ? 0xf071 : modelData.cp)   // ⚠ in attesa
                        color: card.armed ? Theme.orange : modelData.color
                        font.pixelSize: 26; font.family: Theme.fontFamily
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.armed ? "Confermi?" : modelData.label
                        color: card.armed ? Theme.orange : Theme.subtext
                        font.pixelSize: 12; font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.confirm && !card.armed) {   // primo click = arma
                            card.armed = true;
                            armTimer.restart();
                            return;
                        }
                        armTimer.stop();
                        card.armed = false;
                        proc.command = modelData.cmd;
                        proc.running = true;
                    }
                }
            }
        }
    }

    Process { id: proc }
}
