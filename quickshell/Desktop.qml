import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: desk
    required property var modelData
    screen: modelData
    readonly property string screenName: screen ? screen.name : ""

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-desktop"
    exclusionMode: ExclusionMode.Ignore
    // Durante la rinomina inline servono i tasti → Exclusive; altrimenti OnDemand
    // (prende la tastiera solo al click, senza rubarla alle app).
    property int editingCount: 0
    WlrLayershell.keyboardFocus: editingCount > 0 ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    anchors { top: true; bottom: true; left: true; right: true }

    property var selected: ({})   // { name: true }
    function isSel(name) { return selected[name] === true; }
    function clearSel() { selected = ({}); }
    function setSel(name) { var s = {}; s[name] = true; selected = s; }
    function toggleSel(name) {
        var s = {};
        for (var k in selected) s[k] = selected[k];
        if (s[name]) delete s[name]; else s[name] = true;
        selected = s;
    }
    function selectedPaths() {
        var out = [];
        for (var i = 0; i < DesktopModel.files.length; i++)
            if (isSel(DesktopModel.files[i].name)) out.push(DesktopModel.files[i].path);
        return out;
    }

    // slot di griglia (colonne dall'alto in basso, poi colonna successiva)
    readonly property int originX: 20
    readonly property int originY: 20
    readonly property int cellW: 92
    readonly property int cellH: 92
    function slotFor(index) {
        var rows = Math.max(1, Math.floor((height - originY * 2) / cellH));
        var col = Math.floor(index / rows);
        var row = index % rows;
        return { x: originX + col * cellW, y: originY + row * cellH };
    }
    // prima cella di griglia LIBERA (in ordine slotFor), ignorando i nomi: una nuova icona
    // si posa dove c'è spazio, non in ordine alfabetico → niente sovrapposizioni alla creazione
    function firstFreeSlot() {
        var occ = {};
        for (var i = 0; i < DesktopModel.files.length; i++) {
            var p = DesktopState.pos(screenName, DesktopModel.files[i].name);
            if (p) { var s = snap(p.x, p.y); occ[s.x + "," + s.y] = true; }
        }
        for (var k = 0; ; k++) {
            var slot = slotFor(k);
            if (!occ[slot.x + "," + slot.y]) return slot;
        }
    }

    // aggancia una posizione libera allo slot di griglia più vicino
    // ponytail: nessuna anti-collisione sul DROP, due icone possono finire sulla stessa cella;
    //           "Disponi icone" le ridistribuisce. Aggiungere uno scan di occupazione se servirà.
    function snap(x, y) {
        var col = Math.max(0, Math.round((x - originX) / cellW));
        var row = Math.max(0, Math.round((y - originY) / cellH));
        return { x: originX + col * cellW, y: originY + row * cellH };
    }

    // riallinea tutte le icone alla griglia e persiste ("Disponi icone")
    function arrangeIcons() {
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (!it) continue;
            var s = slotFor(it.index);
            it.x = s.x; it.y = s.y;
            DesktopState.setPos(desk.screenName, it.item.name, s.x, s.y);
        }
    }

    // trascina con sé tutte le altre icone selezionate
    function dragSelectedBy(origin, dx, dy) {
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (it && it !== origin && desk.isSel(it.item.name)) { it.x += dx; it.y += dy; }
        }
    }
    // a fine drag: aggancia ogni icona selezionata alla griglia e persiste
    function persistSelected() {
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (it && desk.isSel(it.item.name)) {
                var s = desk.snap(it.x, it.y);
                it.x = s.x; it.y = s.y;
                DesktopState.setPos(desk.screenName, it.item.name, s.x, s.y);
            }
        }
    }

    // nome del file appena creato su QUESTO monitor → da selezionare + rinominare
    // (resta finché la rinomina non viene confermata/annullata, così sopravvive ai
    //  re-build del FolderListModel che ricreano i delegate)
    property bool anyMenuOpen: iconMenu.visible || emptyMenu.visible || confirm.visible
    property double menuOpenedAt: 0
    function closeAllMenus() { iconMenu.close(); emptyMenu.close(); confirm.close(); }
    function markMenuOpen() { desk.menuOpenedAt = Date.now(); }
    property string pendingRename: ""

    // Chiudo i menu su QUALSIASI evento Hyprland (cambio finestra, SUPER+S scratchpad, apertura/
    // ripristino finestra, alt-tab, cambio monitor) — non blocca alcun input (niente focus-grab,
    // la taskbar resta usabile). Il guard di 300ms ignora l'evento di focus generato dall'apertura
    // stessa del menu (il click sul desktop sposta il focus al layer → evento asincrono in ritardo).
    // Guard a 1ms (di fatto disattivato): in pratica l'evento di focus dell'apertura non chiude
    // il menu. Se dovesse SFARFALLARE (menu che si auto-chiude all'apertura) → ALZA il guard:
    // l'evento di apertura misura 3–13ms, soglia sicura ~50ms; SUPER+S intenzionale arriva >200ms.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (desk.anyMenuOpen && Date.now() - desk.menuOpenedAt > 1) desk.closeAllMenus();
        }
    }

    // ── area di lavoro ──
    MouseArea {
        id: bg
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property real sx: 0; property real sy: 0; property bool banding: false

        onPressed: (m) => {
            desk.closeAllMenus();
            if (m.button === Qt.LeftButton) {
                desk.clearSel();
                sx = m.x; sy = m.y; banding = true;
                band.x = m.x; band.y = m.y; band.width = 0; band.height = 0;
            }
        }
        onPositionChanged: (m) => {
            if (!banding) return;
            band.x = Math.min(sx, m.x); band.y = Math.min(sy, m.y);
            band.width = Math.abs(m.x - sx); band.height = Math.abs(m.y - sy);
        }
        onReleased: (m) => {
            if (banding) { banding = false; desk.selectInBand(); band.width = 0; band.height = 0; }
        }
        onClicked: (m) => {
            if (m.button === Qt.RightButton) { emptyMenu.popup(bg, m.x, m.y); desk.markMenuOpen(); }
        }
    }

    Rectangle {
        id: band
        visible: bg.banding && width > 2 && height > 2
        color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.15)
        border.color: Theme.blue; border.width: 1; radius: 2
        z: 50
    }

    function selectInBand() {
        var s = {};
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (!it) continue;
            if (it.x < band.x + band.width && it.x + it.width > band.x &&
                it.y < band.y + band.height && it.y + it.height > band.y)
                s[it.item.name] = true;
        }
        selected = s;
    }

    // ── icone ──
    Repeater {
        id: rep
        model: DesktopModel.files
        delegate: DesktopIcon {
            id: di
            // cattura il modelData del Repeater (altrimenti `modelData` si risolve a
            // desk.modelData = lo SCHERMO, perché Desktop è delegate di Variants).
            // `index` resta iniettato dal Repeater nella property required di DesktopIcon.
            required property var modelData
            item: modelData
            screenName: desk.screenName
            fallbackPos: desk.firstFreeSlot()
            selected: desk.isSel(modelData.name)

            // se questa icona è quella appena creata → selezionala ed entra in rinomina.
            // NON azzeriamo pendingRename qui: i re-build del FolderListModel ricreano i
            // delegate, quindi finché non si conferma/annulla lasciamo che si riattivi.
            onItemChanged: maybeRename()
            Component.onCompleted: maybeRename()
            function maybeRename() {
                if (desk.pendingRename === item.name) { desk.setSel(item.name); Qt.callLater(startRename); }
            }

            onClicked: (m) => {
                if (m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) desk.toggleSel(item.name);
                else if (!desk.isSel(item.name)) desk.setSel(item.name);
            }
            onDoubleClicked: DesktopModel.openItem(item)
            onRightClicked: (gx, gy) => {
                if (!desk.isSel(item.name)) desk.setSel(item.name);
                desk.openIconMenu(di, gx, gy);
            }
            onDragMoved: (dx, dy) => desk.dragSelectedBy(di, dx, dy)
            onDragReleased: desk.persistSelected()
            onEditingStarted: desk.editingCount++
            onEditingEnded: {
                desk.editingCount--;
                if (desk.pendingRename === item.name) desk.pendingRename = "";  // creazione conclusa
            }
        }
    }

    // ── menu icona ──
    ContextMenu { id: iconMenu }
    function openIconMenu(iconItem, gx, gy) {
        desk.closeAllMenus();
        var paths = selectedPaths();
        var one = paths.length === 1;
        var it = iconItem.item;
        iconMenu.items = [
            { label: "Apri", action: function() { DesktopModel.openItem(it); } },
            { separator: true },
            { label: "Rinomina", action: function() { if (one) iconItem.startRename(); } },
            { label: "Copia", action: function() { DesktopModel.setClipboard(paths, "copy"); } },
            { label: "Taglia", action: function() { DesktopModel.setClipboard(paths, "cut"); } },
            { label: "Comprimi", action: function() { DesktopModel.compress(paths); } },
            { separator: true },
            { label: it.isDir ? "Apri terminale qui" : "Mostra in Thunar", action: function() {
                if (it.isDir) DesktopModel.terminalHere(it.path);
                else DesktopModel.showInThunar(it.path); } },
            { separator: true },
            { label: "Elimina (cestino)", action: function() { DesktopModel.trash(paths); desk.clearSel(); } },
            { label: "Elimina definitivamente", danger: true, action: function() {
                confirm.paths = paths; confirm.open(); } }
        ];
        iconMenu.popup(iconItem, gx, gy);
        desk.markMenuOpen();
    }

    // ── menu area vuota ──
    ContextMenu { id: emptyMenu
        items: [
            { label: "Nuova cartella", action: function() { desk.pendingRename = DesktopModel.newFolder(); } },
            { label: "Nuovo file vuoto", action: function() { desk.pendingRename = DesktopModel.newFile(); } },
            { label: "Incolla", action: function() { DesktopModel.paste(); } },
            { separator: true },
            { label: "Disponi icone", action: function() { desk.arrangeIcons(); } },
            { label: "Aggiorna", action: function() { DesktopModel.refresh(); } },
            { separator: true },
            { label: "Cambia sfondo", action: function() { DesktopModel.wallpaperNext(); } }
        ]
    }

    // ── conferma eliminazione definitiva ──
    ContextMenu { id: confirm
        property var paths: []
        function open() {
            items = [
                { label: "Confermi eliminazione definitiva?", action: function() {} },
                { label: "Sì, elimina", danger: true, action: function() {
                    DesktopModel.remove(paths); desk.clearSel(); } },
                { label: "Annulla", action: function() {} }
            ];
            popup(desk.contentItem, desk.width / 2 - 110, desk.height / 2 - 60);
            desk.markMenuOpen();
        }
    }
}
