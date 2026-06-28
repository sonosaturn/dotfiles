import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "lib/taskmodel.js" as TM

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-taskbar"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors { left: true; right: true; bottom: true }
    implicitHeight: Theme.taskbarHeight

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool fullscreenHere: HyprWindows.anyFullscreenOn(bar.screenName)
    property bool hovered: false
    readonly property bool revealed: hovered && !fullscreenHere
    onRevealedChanged: TaskbarState.setRevealed(bar.screenName, revealed)

    readonly property var entries: TM.deriveEntries(HyprWindows.windows, bar.pinned, bar.screenName)

    // ponytail: revealStrip is a sibling of content (not a child) so its window-space coords
    // are stable: always at y = [height-3, height]. Brief put it inside content which placed it
    // at window-y = content.y + 53 = 106 when hidden (outside the 56px window → dead mask).
    mask: Region { item: bar.revealed ? content : revealStrip }

    // Fixed 3-px strip at the true bottom of the window — always in window-space
    Item {
        id: revealStrip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 3
    }

    // Bar-level hover handler — detects entry into the revealStrip area when hidden
    HoverHandler {
        id: hh
        onHoveredChanged: { if (hh.hovered) bar.hovered = true; else hideTimer.restart(); }
    }

    property var pinned: pinAdapter.pinned
    FileView {
        id: pinFile
        path: Quickshell.statePath("taskbar-pins.json")
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        JsonAdapter { id: pinAdapter; property var pinned: [] }
    }
    function togglePin(appId) {
        var arr = pinAdapter.pinned.slice();
        var i = arr.indexOf(appId);
        if (i >= 0) arr.splice(i, 1); else arr.push(appId);
        pinAdapter.pinned = arr;
    }

    // Sliding content — avoids anchors.fill conflict with manual y
    Item {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        height: bar.height
        y: bar.revealed ? 0 : (bar.height - 3)
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Theme.panelBg
            radius: Theme.radius
            border.color: Theme.border
            border.width: Theme.borderWidth

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 6
                StartButton {}
                Repeater {
                    model: bar.entries
                    delegate: TaskbarEntry {
                        required property var modelData
                        entry: modelData
                        screenName: bar.screenName
                        taskbar: bar
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    Timer { id: hideTimer; interval: 600; onTriggered: bar.hovered = hh.hovered }
}
