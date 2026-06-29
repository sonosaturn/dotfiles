import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: icon
    required property var item
    required property string screenName
    required property int index
    property var fallbackPos: ({ x: 20, y: 20 })
    property bool selected: false
    property bool editing: false

    readonly property int cellW: 92
    readonly property int cellH: 92
    width: cellW; height: cellH

    signal clicked(var mouse)
    signal doubleClicked()
    signal rightClicked(real gx, real gy)

    // immagini → anteprima del file stesso; cartelle/altri → icona freedesktop (vuota se
    // non risolta → fallback glifo Nerd Font, come TaskbarEntry)
    readonly property bool isImage: /\.(png|jpe?g|gif|bmp|webp|svg)$/i.test(item.name)
    readonly property string iconName: item.isDir ? "folder" : "text-x-generic"
    readonly property string iconSrc: isImage ? "" : Quickshell.iconPath(iconName, true)

    // posizione: salvata o fallback griglia (assegnata dal genitore)
    Component.onCompleted: {
        var p = DesktopState.pos(screenName, item.name);
        icon.x = p ? p.x : fallbackPos.x;
        icon.y = p ? p.y : fallbackPos.y;
        if (!p) DesktopState.setPos(screenName, item.name, icon.x, icon.y);
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: icon.selected ? Theme.surface1 : (hover.hovered ? Theme.surface0 : "transparent")
        opacity: icon.selected ? 0.9 : (hover.hovered ? 0.6 : 1.0)
        border.color: icon.selected ? Theme.blue : "transparent"
        border.width: 1
    }
    HoverHandler { id: hover }

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // thumbnail / icona
        Item {
            width: parent.width; height: 48
            Image {
                anchors.centerIn: parent
                visible: icon.isImage
                source: icon.isImage ? "file://" + item.path : ""
                sourceSize.width: 48; sourceSize.height: 48
                fillMode: Image.PreserveAspectFit; asynchronous: true
            }
            IconImage {
                anchors.centerIn: parent
                visible: !icon.isImage && icon.iconSrc !== ""
                implicitSize: 44
                source: icon.iconSrc
            }
            Text {
                anchors.centerIn: parent
                visible: !icon.isImage && icon.iconSrc === ""
                text: String.fromCodePoint(item.isDir ? 0xF024B : 0xF0214) // nf-md-folder / file
                font.family: Theme.fontFamily; font.pixelSize: 36
                color: Theme.subtext
            }
        }

        // etichetta (oppure editor inline)
        Text {
            id: label
            visible: !icon.editing
            width: parent.width
            text: item.name
            color: Theme.fg
            font.family: Theme.fontFamily; font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
        }
        Rectangle {
            visible: icon.editing
            width: parent.width; height: 34; radius: 4
            color: Theme.bgDark; border.color: Theme.blue; border.width: 1
            TextInput {
                id: editor
                anchors.fill: parent; anchors.margins: 3
                color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11
                wrapMode: TextInput.Wrap; verticalAlignment: TextInput.AlignVCenter
                onEditingFinished: icon.commitRename()
                Keys.onEscapePressed: icon.editing = false
            }
        }
    }

    function startRename() {
        editor.text = item.name;
        icon.editing = true;
        editor.forceActiveFocus();
        editor.selectAll();
    }
    function commitRename() {
        if (!icon.editing) return;
        icon.editing = false;
        if (editor.text && editor.text !== item.name)
            DesktopModel.rename(item.path, editor.text);
    }

    MouseArea {
        anchors.fill: parent
        enabled: !icon.editing
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property bool moved: false
        drag.target: icon
        drag.threshold: 6
        onPressed: (m) => { moved = false; if (m.button === Qt.LeftButton) icon.clicked(m); }
        onPositionChanged: if (drag.active) moved = true
        onReleased: (m) => {
            if (m.button === Qt.LeftButton && moved)
                DesktopState.setPos(icon.screenName, item.name, icon.x, icon.y);
        }
        onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) icon.doubleClicked(); }
        onClicked: (m) => { if (m.button === Qt.RightButton) icon.rightClicked(m.x, m.y); }
    }
}
