import QtQuick

// Slider orizzontale a tema Tokyo Night. value 0..1, emette moved(v) durante il drag.
Item {
    id: root
    property real value: 0
    property bool enabled: true
    signal moved(real v)
    implicitHeight: 22

    function setFromX(mx) {
        root.moved(Math.max(0, Math.min(1, mx / width)));
    }

    Rectangle {                       // binario
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface1
        opacity: root.enabled ? 1 : 0.4

        Rectangle {                   // riempimento blue→cyan
            width: parent.width * root.value
            height: parent.height
            radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.blue }
                GradientStop { position: 1; color: Theme.cyan }
            }
        }
    }

    Rectangle {                       // manopola
        width: 14; height: 14; radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.value * parent.width - width / 2))
        color: Theme.fg
        border.color: Theme.blue
        border.width: 2
        visible: root.enabled
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onPressed: (m) => root.setFromX(m.x)
        onPositionChanged: (m) => { if (pressed) root.setFromX(m.x); }
    }
}
