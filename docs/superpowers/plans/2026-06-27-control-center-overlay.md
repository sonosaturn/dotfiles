# Control Center overlay (Fase 9b) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere un overlay control center on-demand (toggle SUPER+D) a schede su Quickshell: mixer audio, luce notturna + DND, calendario, sessione.

**Architecture:** Una `PanelWindow` Quickshell su layer Overlay che copre il monitor attivo con sfondo trasparente; dentro un pannello a schede centrato (tab bar + StackLayout). Toggle via `GlobalShortcut` nativo legato a un keybind Hyprland. Ogni scheda è un file QML flat separato. La luce notturna e il DND si appoggiano a tool esterni già/da installare (hyprsunset, mako); il mixer usa il servizio Pipewire nativo di Quickshell.

**Tech Stack:** Quickshell 0.3.0 (QML/Qt6), Quickshell.Services.Pipewire, Quickshell.Hyprland, Quickshell.Io, hyprsunset 0.3.3, mako, QtQuick.Controls, qml6 (self-check).

## Global Constraints

- Tema Tokyo Night: riusare SEMPRE il singleton `Theme` (auto-registrato, nessun import). Nessun colore hardcoded.
- **Trasparenza identica ai widget esistenti**: il pannello usa `Theme.panelBg` (nessun nuovo valore alpha).
- File **flat** in `~/dotfiles/quickshell/` (un file per componente), come la Fase 9a. Niente sottocartelle nuove.
- `~/dotfiles` è symlinkato in `~/.config` → modifiche ai file dotfiles sono live. Verificare il symlink prima di assumere.
- Glifi Nerd Font inseriti **per codepoint** (l'editing può azzerare i glifi PUA — lezione Fase 9a). Font: `JetBrainsMono Nerd Font`.
- Commit git in `~/dotfiles` con messaggio chiaro dopo ogni task. NON committare i binari/`~/Videos`.
- Dopo ogni modifica a Hyprland: `hyprctl reload` deve dare 0 errori. Dopo ogni modifica QML: `qs` riavviato senza errori in console.
- Coda Spotify e slider luminosità DDC: **fuori scope** (decisi in brainstorming).

---

## Task 1: Backend luce notturna (hyprsunset) + DND (mako)

Risolve per primo l'interfaccia incerta di hyprsunset, così le tab UI si appoggiano a comandi già verificati.

**Files:**
- Create: `~/dotfiles/hypr/hyprsunset.conf` (symlink target → `~/.config/hypr/hyprsunset.conf`)
- Modify: `~/dotfiles/hypr/conf/autostart.conf` (avvio daemon hyprsunset)
- Modify: `~/dotfiles/mako/config` (modo do-not-disturb)

**Interfaces:**
- Produces (comandi che le tab UI useranno):
  - Luce ON: `hyprctl hyprsunset temperature 4000`
  - Luce OFF: `hyprctl hyprsunset identity`
  - DND toggle: `makoctl mode -t do-not-disturb`
  - DND query: `makoctl mode` → stdout contiene `do-not-disturb` se attivo

- [ ] **Step 1: Installare hyprsunset**

```bash
sudo pacman -S --noconfirm hyprsunset
hyprsunset --help    # conferma i sottocomandi/flag disponibili
```
Expected: pacchetto installato; `--help` mostra l'uso. **Confermare** che l'IPC `hyprctl hyprsunset temperature|identity` e la sintassi config sotto corrispondano alla versione installata (0.3.x). Se differiscono, adeguare i comandi qui e nelle Task 5.

- [ ] **Step 2: Scrivere il config con schedule automatico**

Create `~/dotfiles/hypr/hyprsunset.conf`:
```ini
# Luce notturna automatica (Tokyo Night ricing — Fase 9b)
max-gamma = 100

# Mattina: nessun filtro (luce neutra)
profile {
    time = 7:00
    identity = true
}

# Sera: filtro caldo (meno luce blu)
profile {
    time = 20:00
    temperature = 4000
}
```
> Se la versione installata usa una sintassi diversa per i profili (verificata allo Step 1), adeguare mantenendo: neutro alle 7:00, caldo 4000K alle 20:00.

- [ ] **Step 3: Creare il symlink del config**

```bash
ln -sf ~/dotfiles/hypr/hyprsunset.conf ~/.config/hypr/hyprsunset.conf
ls -l ~/.config/hypr/hyprsunset.conf   # deve puntare a ~/dotfiles/...
```
Expected: symlink corretto. (Se `~/.config/hypr` è già un symlink di cartella a `~/dotfiles/hypr`, il file è già esposto: in tal caso saltare il `ln` e verificarne solo la presenza.)

- [ ] **Step 4: Aggiungere hyprsunset all'autostart**

In `~/dotfiles/hypr/conf/autostart.conf`, aggiungere accanto agli altri `exec-once`:
```ini
exec-once = hyprsunset
```

- [ ] **Step 5: Avviare il daemon e verificare l'IPC manuale**

```bash
hyprsunset &           # avvia il daemon per il test in corso
sleep 1
hyprctl hyprsunset temperature 4000   # lo schermo deve diventare visibilmente caldo
sleep 2
hyprctl hyprsunset identity           # lo schermo torna neutro
```
Expected: variazione di temperatura colore osservabile e ripristino. Se i comandi falliscono, correggere con la sintassi reale dello Step 1.

- [ ] **Step 6: Aggiungere il modo DND a mako**

In `~/dotfiles/mako/config`, in fondo al file, aggiungere:
```ini
[mode=do-not-disturb]
invisible=1
```

- [ ] **Step 7: Ricaricare mako e verificare il toggle DND**

```bash
makoctl reload
makoctl mode -t do-not-disturb     # attiva
makoctl mode                       # stdout deve elencare: do-not-disturb
notify-send "test" "non deve apparire"   # nessun popup
makoctl mode -t do-not-disturb     # disattiva
makoctl mode                       # do-not-disturb NON elencato
notify-send "test" "ora appare"          # popup visibile
```
Expected: con DND attivo nessun popup; `makoctl mode` riflette lo stato.

- [ ] **Step 8: Commit**

```bash
cd ~/dotfiles && git add hypr/hyprsunset.conf hypr/conf/autostart.conf mako/config && \
git commit -m "feat(9b): backend luce notturna (hyprsunset) + DND mako"
```

---

## Task 2: Finestra overlay + tab bar + toggle SUPER+D (con stub tab)

**Files:**
- Create: `~/dotfiles/quickshell/ControlCenter.qml`
- Create: `~/dotfiles/quickshell/MixerTab.qml` (stub)
- Create: `~/dotfiles/quickshell/LightTab.qml` (stub)
- Create: `~/dotfiles/quickshell/CalendarTab.qml` (stub)
- Create: `~/dotfiles/quickshell/SessionTab.qml` (stub)
- Modify: `~/dotfiles/quickshell/shell.qml` (monta ControlCenter)
- Modify: `~/dotfiles/hypr/conf/keybinds.conf` (bind SUPER+D)

**Interfaces:**
- Produces: tipo `ControlCenter` con `function toggle()`, proprietà `int tab`. Tipi `MixerTab`, `LightTab`, `CalendarTab`, `SessionTab` (Item radice) montati nello StackLayout in quest'ordine (indici 0..3).
- Consumes: `GlobalShortcut` (appid `quickshell`, name `controlcenter`) ↔ keybind Hyprland `quickshell:controlcenter`.

- [ ] **Step 1: Creare gli stub delle 4 tab**

Ogni file `~/dotfiles/quickshell/{Mixer,Light,Calendar,Session}Tab.qml` con questo contenuto (cambiando solo il testo):
```qml
import QtQuick

Item {
    Text {
        anchors.centerIn: parent
        text: "Mixer (stub)"        // -> "Luce", "Calendario", "Sessione" negli altri
        color: Theme.subtext
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
```

- [ ] **Step 2: Creare la finestra overlay**

Create `~/dotfiles/quickshell/ControlCenter.qml`:
```qml
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
```
> Codepoint icone usati: `` volume (nf-fa-volume_up), `` luna (nf-fa-moon_o), `` calendario (nf-fa-calendar), `` power (nf-fa-power_off). Verificare che rendano nel font; in caso, reinserire per codepoint.

- [ ] **Step 3: Montare l'overlay in shell.qml**

In `~/dotfiles/quickshell/shell.qml`, dentro `ShellRoot`, aggiungere dopo gli altri widget:
```qml
    ControlCenter { }
```
(Non riceve `screen`: lo imposta da sé in `toggle()`.)

- [ ] **Step 4: Aggiungere il keybind Hyprland**

In `~/dotfiles/hypr/conf/keybinds.conf`, nella sezione bind, aggiungere:
```ini
bind = SUPER, D, global, quickshell:controlcenter
```

- [ ] **Step 5: Ricaricare e verificare**

```bash
hyprctl reload                # 0 errori
pkill qs; sleep 1; qs >/tmp/qs.log 2>&1 &    # riavvia quickshell
sleep 2; grep -i error /tmp/qs.log || echo "qs ok"
```
Poi manualmente:
- Premere **SUPER+D** mentre il focus è su DP-3 → l'overlay compare **su DP-3**; ripetere con focus su DP-4 → compare su DP-4.
- Cliccare le 4 tab → cambia l'evidenziazione e il contenuto stub.
- **ESC** chiude; **click fuori dal pannello** chiude; click sul pannello NON chiude.
- Il pannello ha la **stessa trasparenza** dei widget (confronto a vista).

Expected: tutti i punti sopra verificati.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles && git add quickshell/ControlCenter.qml quickshell/MixerTab.qml quickshell/LightTab.qml quickshell/CalendarTab.qml quickshell/SessionTab.qml quickshell/shell.qml hypr/conf/keybinds.conf && \
git commit -m "feat(9b): overlay control center, tab bar e toggle SUPER+D (stub tab)"
```

---

## Task 3: Calendario (con self-check qml6)

**Files:**
- Create: `~/dotfiles/quickshell/lib/calendar.js`
- Create: `~/dotfiles/quickshell/lib/calendar_test.qml`
- Modify: `~/dotfiles/quickshell/CalendarTab.qml` (sostituisce lo stub)

**Interfaces:**
- Produces: `lib/calendar.js` con `daysInMonth(y, m)` (m 0-based) e `firstWeekdayMon(y, m)` (0=lunedì).

- [ ] **Step 1: Scrivere il test che fallisce**

Create `~/dotfiles/quickshell/lib/calendar_test.qml`:
```qml
import QtQuick
import "calendar.js" as Cal

QtObject {
    Component.onCompleted: {
        // giorni nel mese (m 0-based)
        if (Cal.daysInMonth(2026, 5) !== 30) { console.error("FAIL: giugno 2026 != 30"); Qt.exit(1); }
        if (Cal.daysInMonth(2024, 1) !== 29) { console.error("FAIL: feb 2024 (bisestile) != 29"); Qt.exit(1); }
        if (Cal.daysInMonth(2025, 1) !== 28) { console.error("FAIL: feb 2025 != 28"); Qt.exit(1); }
        // primo giorno (lunedì=0): 1 gennaio 2024 era lunedì
        if (Cal.firstWeekdayMon(2024, 0) !== 0) { console.error("FAIL: 1 gen 2024 != lunedì"); Qt.exit(1); }
        // 1 marzo 2026 era domenica -> indice 6
        if (Cal.firstWeekdayMon(2026, 2) !== 6) { console.error("FAIL: 1 mar 2026 != domenica"); Qt.exit(1); }
        console.log("PASS calendar");
        Qt.exit(0);
    }
}
```

- [ ] **Step 2: Eseguire il test per vederlo fallire**

```bash
cd ~/dotfiles/quickshell/lib && qml6 calendar_test.qml
```
Expected: errore (file `calendar.js` inesistente / funzioni non definite).

- [ ] **Step 3: Implementare calendar.js**

Create `~/dotfiles/quickshell/lib/calendar.js`:
```javascript
.pragma library

// Numero di giorni nel mese. m è 0-based (0=gennaio).
function daysInMonth(y, m) {
    return new Date(y, m + 1, 0).getDate();
}

// Indice del primo giorno del mese con lunedì=0 ... domenica=6.
function firstWeekdayMon(y, m) {
    var d = new Date(y, m, 1).getDay();   // 0=domenica .. 6=sabato
    return (d + 6) % 7;
}
```

- [ ] **Step 4: Eseguire il test per vederlo passare**

```bash
cd ~/dotfiles/quickshell/lib && qml6 calendar_test.qml
```
Expected: `PASS calendar`, exit 0.

- [ ] **Step 5: Implementare la tab calendario**

Replace `~/dotfiles/quickshell/CalendarTab.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "lib/calendar.js" as Cal

Item {
    id: root
    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-based

    readonly property var monthNames: ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
        "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"]

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; } else viewMonth--;
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; } else viewMonth++;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // header: < Mese Anno >
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: ""; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 14
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.prevMonth() }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: ""; color: Theme.subtext; font.family: Theme.fontFamily; font.pixelSize: 14
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.nextMonth() }
            }
        }

        // intestazioni giorni
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: ["L","M","M","G","V","S","D"]
                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.comment
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            // celle: offset vuoto + giorni
            Repeater {
                model: Cal.firstWeekdayMon(root.viewYear, root.viewMonth) + Cal.daysInMonth(root.viewYear, root.viewMonth)
                delegate: Item {
                    required property int index
                    readonly property int offset: Cal.firstWeekdayMon(root.viewYear, root.viewMonth)
                    readonly property int day: index - offset + 1
                    readonly property bool isDay: index >= offset
                    readonly property bool isToday: isDay
                        && day === root.today.getDate()
                        && root.viewMonth === root.today.getMonth()
                        && root.viewYear === root.today.getFullYear()
                    Layout.fillWidth: true
                    implicitHeight: 26
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24; height: 24; radius: 12
                        color: parent.isToday ? Theme.blue : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.isDay ? parent.parent.day : ""
                            color: parent.parent.isToday ? Theme.bg : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
```
> Codepoint frecce: `` chevron-left, `` chevron-right.

- [ ] **Step 6: Verificare nell'overlay**

```bash
pkill qs; sleep 1; qs >/tmp/qs.log 2>&1 & sleep 2; grep -i error /tmp/qs.log || echo "qs ok"
```
SUPER+D → tab Calendario: mese corrente, oggi evidenziato in blu, frecce cambiano mese (con rollover anno a gennaio/dicembre).

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles && git add quickshell/lib/calendar.js quickshell/lib/calendar_test.qml quickshell/CalendarTab.qml && \
git commit -m "feat(9b): tab calendario + self-check qml6"
```

---

## Task 4: Mixer audio (Pipewire)

**Files:**
- Modify: `~/dotfiles/quickshell/MixerTab.qml` (sostituisce lo stub)

**Interfaces:**
- Consumes: `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink`, `Pipewire.nodes`, `PwObjectTracker`).

- [ ] **Step 1: Implementare la tab mixer**

Replace `~/dotfiles/quickshell/MixerTab.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    // riga volume riutilizzabile
    component VolumeRow: RowLayout {
        property string label
        property var node
        visible: node !== null && node !== undefined && node.audio !== null
        spacing: 8
        Text {
            text: label
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 92
            elide: Text.ElideRight
        }
        Slider {
            Layout.fillWidth: true
            from: 0; to: 1
            value: node && node.audio ? node.audio.volume : 0
            onMoved: if (node && node.audio) node.audio.volume = value
        }
        Text {
            text: node && node.audio ? Math.round(node.audio.volume * 100) + "%" : "--"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }

    // tieni "ready" i nodi audio (default sink + stream applicazioni)
    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            var vals = Pipewire.nodes.values;
            for (var i = 0; i < vals.length; i++) {
                if (vals[i].isStream && vals[i].audio) list.push(vals[i]);
            }
            return list;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        VolumeRow {
            Layout.fillWidth: true
            label: "Master"
            node: Pipewire.defaultAudioSink
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surface1 }

        // stream per-app
        Repeater {
            model: Pipewire.nodes
            delegate: VolumeRow {
                required property var modelData
                Layout.fillWidth: true
                node: modelData
                label: modelData && modelData.properties
                    ? (modelData.properties["application.name"] || modelData.name || "app")
                    : (modelData ? modelData.name : "")
                visible: modelData && modelData.isStream && modelData.audio
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            Layout.fillWidth: true
            text: "Apri pavucontrol"
            onClicked: Quickshell.execDetached(["pavucontrol"])
        }
    }
}
```
> Nota API: se `Pipewire.nodes.values` / il filtro stream non corrispondono alla 0.3.0, adeguare al modello reale (`Pipewire.nodes` resta un ObjectModel iterabile). Il criterio resta: master = `defaultAudioSink`, per-app = nodi con `isStream && audio`.

- [ ] **Step 2: Verificare con audio attivo**

```bash
pkill qs; sleep 1; qs >/tmp/qs.log 2>&1 & sleep 2; grep -i error /tmp/qs.log || echo "qs ok"
```
Avviare un player (es. Spotify/Firefox con audio). SUPER+D → tab Audio:
- slider **Master** muove il volume di sistema (confronta con `wpctl get-volume @DEFAULT_AUDIO_SINK@`);
- compare uno slider **per-app** per ogni sorgente che suona; muoverlo cambia il volume di quell'app;
- bottone **pavucontrol** apre l'app.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles && git add quickshell/MixerTab.qml && \
git commit -m "feat(9b): tab mixer audio (Pipewire master + per-app)"
```

---

## Task 5: Tab Luce notturna + DND

**Files:**
- Modify: `~/dotfiles/quickshell/LightTab.qml` (sostituisce lo stub)

**Interfaces:**
- Consumes (da Task 1): `hyprctl hyprsunset temperature 4000` / `identity`; `makoctl mode -t do-not-disturb`; `makoctl mode`.
- Consumes: `Quickshell.Io` (`Process`, `StdioCollector`).

- [ ] **Step 1: Implementare la tab**

Replace `~/dotfiles/quickshell/LightTab.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    property bool nightOn: false
    property bool dndOn: false

    // toggle riutilizzabile (pill)
    component ToggleRow: RowLayout {
        property string label
        property string sub: ""
        property bool on: false
        signal toggled()
        spacing: 8
        ColumnLayout {
            spacing: 2
            Text { text: label; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 13 }
            Text {
                text: sub; visible: sub !== ""
                color: Theme.comment; font.family: Theme.fontFamily; font.pixelSize: 10
            }
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            implicitWidth: 46; implicitHeight: 24; radius: 12
            color: on ? Theme.blue : Theme.surface1
            Rectangle {
                width: 18; height: 18; radius: 9; color: Theme.fg
                anchors.verticalCenter: parent.verticalCenter
                x: on ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120 } }
            }
            MouseArea { anchors.fill: parent; onClicked: toggled() }
        }
    }

    Process { id: nightProc }
    Process {
        id: dndToggleProc
        command: ["makoctl", "mode", "-t", "do-not-disturb"]
        onExited: dndQuery.running = true
    }
    Process {
        id: dndQuery
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: root.dndOn = this.text.indexOf("do-not-disturb") !== -1
        }
    }

    function setNight(on) {
        nightProc.command = on
            ? ["hyprctl", "hyprsunset", "temperature", "4000"]
            : ["hyprctl", "hyprsunset", "identity"];
        nightProc.running = true;
        root.nightOn = on;
    }

    Component.onCompleted: dndQuery.running = true   // stato DND iniziale

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        ToggleRow {
            Layout.fillWidth: true
            label: "Luce notturna"
            sub: "auto 20:00–07:00"
            on: root.nightOn
            onToggled: root.setNight(!root.nightOn)
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surface1 }

        ToggleRow {
            Layout.fillWidth: true
            label: "Non disturbare"
            sub: "silenzia le notifiche"
            on: root.dndOn
            onToggled: dndToggleProc.running = true
        }

        Item { Layout.fillHeight: true }
    }
}
```
> Il toggle luce è un override manuale; lo schedule automatico resta gestito dal daemon hyprsunset (Task 1). Lo stato `nightOn` è interno (l'IPC hyprsunset non espone una query affidabile dello stato corrente).

- [ ] **Step 2: Verificare**

```bash
pkill qs; sleep 1; qs >/tmp/qs.log 2>&1 & sleep 2; grep -i error /tmp/qs.log || echo "qs ok"
```
SUPER+D → tab Luce:
- toggle **Luce notturna** ON → schermo caldo; OFF → neutro;
- toggle **Non disturbare** ON → `makoctl mode` elenca `do-not-disturb` e `notify-send test` non mostra popup; OFF → popup torna; lo stato dello switch riflette `makoctl mode` all'apertura.

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles && git add quickshell/LightTab.qml && \
git commit -m "feat(9b): tab luce notturna + DND"
```

---

## Task 6: Tab Sessione + verifica integrata finale

**Files:**
- Modify: `~/dotfiles/quickshell/SessionTab.qml` (sostituisce lo stub)

**Interfaces:**
- Consumes: `Quickshell.execDetached`; comandi sessione (`loginctl`, `hyprctl`, `systemctl`).

- [ ] **Step 1: Implementare la tab**

Replace `~/dotfiles/quickshell/SessionTab.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    component SessionBtn: Rectangle {
        property string icon
        property string label
        property var action
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radius
        color: hov.hovered ? Theme.surface1 : Theme.surface0
        HoverHandler { id: hov }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: icon; color: Theme.cyan; font.family: Theme.fontFamily; font.pixelSize: 22
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: label; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 12
            }
        }
        MouseArea { anchors.fill: parent; onClicked: action() }
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 10
        columnSpacing: 10

        SessionBtn {
            icon: ""; label: "Lock"        // nf-fa-lock
            action: function() { Quickshell.execDetached(["loginctl", "lock-session"]) }
        }
        SessionBtn {
            icon: ""; label: "Logout"      // nf-fa-sign_out
            action: function() { Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
        }
        SessionBtn {
            icon: ""; label: "Reboot"      // nf-fa-refresh
            action: function() { Quickshell.execDetached(["systemctl", "reboot"]) }
        }
        SessionBtn {
            icon: ""; label: "Shutdown"    // nf-fa-power_off
            action: function() { Quickshell.execDetached(["systemctl", "poweroff"]) }
        }
    }
}
```
> Codepoint: `` lock, `` sign-out, `` refresh/reboot, `` power-off.

- [ ] **Step 2: Verificare la tab Sessione**

```bash
pkill qs; sleep 1; qs >/tmp/qs.log 2>&1 & sleep 2; grep -i error /tmp/qs.log || echo "qs ok"
```
SUPER+D → tab Sessione: 4 bottoni con hover. Testare **Lock** (deve partire hyprlock → sbloccare). NON cliccare Reboot/Shutdown/Logout durante il test (azioni distruttive) — verificare solo che rendano e abbiano hover.

- [ ] **Step 3: Verifica integrata finale**

- `hyprctl reload` → 0 errori.
- `pkill qs; qs &` → console senza errori.
- SUPER+D dal monitor attivo (testare da entrambi DP-3 e DP-4).
- Giro completo delle 4 tab: Audio (slider funzionano), Luce (entrambi i toggle), Calendario (oggi evidenziato + navigazione mesi), Sessione (Lock).
- ESC e click-fuori chiudono; trasparenza del pannello == widget.
- Screenshot di verifica: `~/dotfiles/hypr/scripts/screenshot.sh region` (o grim) per l'utente.

- [ ] **Step 4: Commit + aggiornare RICING.md**

Aggiornare `~/RICING.md`: spuntare la Fase 9b nella sezione Fase 9 e aggiungere una riga al Log modifiche (data 2026-06-27, riassunto control center).
```bash
cd ~/dotfiles && git add quickshell/SessionTab.qml && \
git commit -m "feat(9b): tab sessione + control center completo"
```
(RICING.md è in `~/`, fuori dal repo dotfiles: aggiornarlo ma non includerlo nel commit dotfiles.)

---

## Self-Review (esito)

- **Spec coverage:** Audio→T4, Luce+schedule→T1+T5, DND→T1+T5, Calendario→T3, Sessione→T6, finestra/overlay/monitor-attivo/ESC/click-fuori/SUPER+D→T2, trasparenza=panelBg→T2 (Global Constraints), hyprsunset install/config→T1, mako mode→T1, self-check calendario→T3. Luminosità DDC e coda Spotify: esclusi per design. ✔ nessuna lacuna.
- **Placeholder scan:** ogni step ha comandi/codice concreti; gli stub di T2 sono deliberati e sostituiti in T3–T6. ✔
- **Type consistency:** `ControlCenter.toggle()`/`tab`; ordine StackLayout Mixer/Light/Calendar/Session coerente con gli indici tab; `calendar.js` espone `daysInMonth`/`firstWeekdayMon` usati identici in test e CalendarTab; `VolumeRow`/`ToggleRow`/`SessionBtn` definiti e usati nello stesso file. ✔
- **Rischi noti segnalati:** interfaccia hyprsunset (IPC/config) da confermare allo Step 1 di T1; API Pipewire 0.3.0 da adeguare in T4 se diverge. Entrambi con criterio di fallback esplicito.
