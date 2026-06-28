// TaskbarPreview.qml — hover popup shown above a TaskbarEntry icon.
// Multi-window: shows one thumbnail per window in entry.windows (max 4 visible).
// Each thumbnail: title + live ScreencopyView or icon fallback (minimized / no capture).
// Clicking a thumbnail surfaces that specific window.
//
// Keep-alive: HoverHandler on popup content cancels the close timer while the
// pointer is over the popup, so the user can move from icon to thumbnail and click.
//
// ponytail: capped at 4 thumbnails. If someone has >4 windows of the same app,
// only the first 4 show. Scrollable overflow only if that ever matters.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

PopupWindow {
    id: root

    required property var  entry       // app group entry (kind:"app", windows:[], …)
    required property var  de          // DesktopEntry or null
    required property Item parentEntry // TaskbarEntry to anchor above

    readonly property int thumbW:       180
    readonly property int thumbSpacing: 8
    readonly property int outerPad:     10
    readonly property int visibleCount: (entry && entry.windows)
                                            ? Math.min(entry.windows.length, 4) : 1

    // Width grows with thumbnail count; height stays fixed.
    implicitWidth:  visibleCount * (thumbW + thumbSpacing) - thumbSpacing + outerPad * 2
    implicitHeight: 208
    color:          "transparent"

    anchor.item:   parentEntry
    anchor.rect.x: parentEntry.width / 2 - implicitWidth / 2
    anchor.rect.y: -(implicitHeight + 8)

    Rectangle {
        anchors.fill: parent
        radius:       Theme.radius
        color:        Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth

        // Keep-alive: while pointer is over the popup, block the close timer.
        HoverHandler {
            onHoveredChanged: {
                parentEntry.popupHovered = hovered;
                if (!hovered) parentEntry.startCloseTimer();
            }
        }

        Row {
            anchors { fill: parent; margins: root.outerPad }
            spacing: root.thumbSpacing

            Repeater {
                model: (entry && entry.windows) ? entry.windows : []

                delegate: Item {
                    id: thumb
                    required property var modelData

                    width:  root.thumbW
                    height: parent.height  // parent = Row, height set by anchor

                    HoverHandler { id: thumbHover }

                    // Title (lascia spazio a dx per la × di chiusura)
                    Text {
                        id: tTitle
                        anchors { top: parent.top; left: parent.left; right: parent.right; rightMargin: 22 }
                        text:           thumb.modelData.title || ""
                        color:          Theme.fg
                        font.family:    Theme.fontFamily
                        font.pixelSize: 12
                        elide:          Text.ElideRight
                    }

                    // Preview area: screencopy or icon fallback
                    Item {
                        id: tPreview
                        anchors {
                            top: tTitle.bottom; topMargin: 6
                            left: parent.left; right: parent.right; bottom: parent.bottom
                        }

                        ScreencopyView {
                            id: tScv
                            anchors.fill:   parent
                            visible:        !thumb.modelData.minimized && tScv.hasContent
                            captureSource:  !thumb.modelData.minimized
                                                ? HyprWindows.toplevelFor(thumb.modelData.address)
                                                : null
                            live:           true
                            constraintSize: Qt.size(root.thumbW - 20, 148)
                        }

                        // icon fallback (minimized or capture unavailable)
                        Item {
                            anchors.fill: parent
                            visible:      thumb.modelData.minimized || !tScv.hasContent

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize:     48
                                visible:          !!(root.de && root.de.icon)
                                source:           root.de && root.de.icon
                                                      ? Quickshell.iconPath(root.de.icon) : ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible:          !(root.de && root.de.icon)
                                text:             String.fromCodePoint(0xF003B)
                                font.family:      Theme.fontFamily
                                font.pixelSize:   48
                                color:            Theme.subtext
                            }
                        }
                    }

                    // Click to surface this specific window
                    MouseArea {
                        anchors.fill:  parent
                        cursorShape:   Qt.PointingHandCursor
                        onClicked: {
                            if (thumb.modelData.minimized)
                                HyprWindows.restore(thumb.modelData.address, parentEntry.screenName);
                            else
                                HyprWindows.focus(thumb.modelData.address);
                            parentEntry.previewOpen = false;
                        }
                    }

                    // × di chiusura (in alto a dx, appare su hover del thumbnail).
                    // Sopra la MouseArea di focus → il click chiude e non fa focus.
                    Rectangle {
                        visible: thumbHover.hovered
                        anchors { top: parent.top; right: parent.right }
                        width: 20; height: 20; radius: 10
                        z: 10
                        color: closeMa.containsMouse ? Theme.red : Theme.surface1
                        Text { anchors.centerIn: parent; text: "✕"
                               color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: HyprWindows.close(thumb.modelData.address)
                        }
                    }
                }
            }
        }
    }
}
