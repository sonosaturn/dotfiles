import QtQuick
import Quickshell

PopupWindow {
    id: menu
    property var items: []
    property Item anchorItem: null
    property real relX: 0
    property real relY: 0

    anchor.item: anchorItem
    anchor.rect.x: relX
    anchor.rect.y: relY
    implicitWidth: 220
    implicitHeight: col.implicitHeight + 8
    visible: false
    color: "transparent"

    function popup(anchorIt, x, y) {
        menu.anchorItem = anchorIt; menu.relX = x; menu.relY = y; menu.visible = true;
    }
    function close() { menu.visible = false; }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth

        Column {
            id: col
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 0
            Repeater {
                model: menu.items
                delegate: Loader {
                    required property var modelData
                    width: col.width
                    sourceComponent: modelData.separator ? sep : row
                    Component {
                        id: sep
                        Rectangle { width: col.width; height: 7
                            Rectangle { anchors.centerIn: parent; width: parent.width - 12
                                height: 1; color: Theme.surface1 } }
                    }
                    Component {
                        id: row
                        Rectangle {
                            width: col.width; height: 30; radius: 6
                            color: ma.containsMouse ? Theme.surface0 : "transparent"
                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 }
                                text: modelData.label
                                color: modelData.danger ? Theme.red : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: ma; anchors.fill: parent; hoverEnabled: true
                                onClicked: { if (modelData.action) modelData.action(); menu.close(); }
                            }
                        }
                    }
                }
            }
        }
    }
}
