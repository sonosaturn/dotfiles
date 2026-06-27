import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: cc
    visible: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: cc.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int tab: 0

    function toggle() {
        if (cc.visible) { cc.visible = false; return; }
        const fm = Hyprland.focusedMonitor;
        if (fm) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === fm.name) { cc.screen = Quickshell.screens[i]; break; }
            }
        }
        cc.visible = true;
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "controlcenter"
        onPressed: cc.toggle()
    }

    // sfondo: click fuori dal pannello = chiudi
    MouseArea {
        anchors.fill: parent
        onClicked: cc.visible = false
    }

    Item {
        anchors.fill: parent
        focus: cc.visible
        Keys.onEscapePressed: cc.visible = false

        Rectangle {
            id: panel
            anchors.centerIn: parent
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            { icon: "", label: "Audio" },
                            { icon: "", label: "Luce" },
                            { icon: "", label: "Cal" },
                            { icon: "", label: "Sess" }
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
                                text: modelData.icon + "  " + modelData.label
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
                    LightTab {}
                    CalendarTab {}
                    SessionTab {}
                }
            }
        }
    }
}
