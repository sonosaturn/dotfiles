import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: w
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-clock"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; left: true }
    margins { top: 52; left: 40 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        implicitWidth: col.implicitWidth + 48
        implicitHeight: col.implicitHeight + 32

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.blue
                font.family: Theme.fontFamily
                font.pixelSize: 64
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                // es. "ven 26 giu" (locale di sistema = IT)
                text: Qt.formatDateTime(clock.date, "ddd d MMM").toLowerCase()
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }
        }
    }
}
