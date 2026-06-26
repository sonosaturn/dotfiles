# Fase 9a — Widget desktop Quickshell — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tre widget desktop (orologio+data, now-playing MPRIS, system monitor) in Quickshell/QML su DP-4, tema Tokyo Night, layer `bottom`, conviventi con Waybar.

**Architecture:** Una config Quickshell in `~/dotfiles/quickshell/` (symlink → `~/.config/quickshell/`). `shell.qml` (root `ShellRoot`) trova lo schermo DP-4 e istanzia tre `PanelWindow` indipendenti, uno per widget. Un singleton `Theme.qml` centralizza la palette. La sola logica non-UI (CPU% da delta `/proc/stat`) sta in `lib/cpustat.js`, testabile a parte con `qml6`.

**Tech Stack:** Quickshell 0.3.0 (QML/Qt6), MPRIS (`Quickshell.Services.Mpris`), `Quickshell.Io` (Process), `playerctl`/Spotify, `nvidia-smi`, `/proc`, `/sys/class/hwmon`.

## Global Constraints

- Tema **Tokyo Night** verbatim (hex da `~/RICING.md`): bg `#1a1b26`, bg_dark `#16161e`, surface0 `#292e42`, surface1 `#414868`, fg `#c0caf5`, subtext `#a9b1d6`, comment `#565f89`, blue `#7aa2f7`, cyan `#7dcfff`, teal `#2ac3de`, magenta `#bb9af7`, green `#9ece6a`, orange `#ff9e64`, yellow `#e0af68`, red `#f7768e`.
- Font: **"JetBrainsMono Nerd Font"**.
- Solo monitor **DP-4** (fallback al primo schermo se assente).
- Layer **`bottom`**, nessuna zona di esclusione (i widget non riservano spazio, vengono coperti dalle finestre).
- **Non** toccare Waybar né altri file fuori da `~/dotfiles/quickshell/`, `~/dotfiles/hypr/conf/autostart.conf`, `~/RICING.md`.
- Config in `~/dotfiles`, symlink in `~/.config`. Ogni task finisce con un commit nel repo `~/dotfiles`.
- Repo git = `~/dotfiles`. Tutti i `git` vanno eseguiti lì.

---

## File Structure

- `~/dotfiles/quickshell/Theme.qml` — singleton palette + costanti stile.
- `~/dotfiles/quickshell/shell.qml` — entry `ShellRoot`, lookup DP-4, istanzia i widget.
- `~/dotfiles/quickshell/ClockWidget.qml` — PanelWindow orologio+data.
- `~/dotfiles/quickshell/SysMonitorWidget.qml` — PanelWindow CPU/RAM/GPU+temp.
- `~/dotfiles/quickshell/NowPlayingWidget.qml` — PanelWindow MPRIS.
- `~/dotfiles/quickshell/lib/cpustat.js` — parsing + calcolo CPU% (logica pura).
- `~/dotfiles/quickshell/lib/cpustat_test.qml` — self-check di `cpustat.js`.
- `~/dotfiles/hypr/conf/autostart.conf` — aggiungere `exec-once = qs`.
- `~/RICING.md` — spuntare Fase 9 dashboard (parte 9a).

---

## Task 1: Scaffolding (Theme + shell + symlink + autostart)

**Files:**
- Create: `~/dotfiles/quickshell/Theme.qml`
- Create: `~/dotfiles/quickshell/shell.qml`
- Modify: `~/dotfiles/hypr/conf/autostart.conf`

**Interfaces:**
- Produces: singleton `Theme` con proprietà colore (`bg`, `blue`, `cyan`, `fg`, `subtext`, `green`, `magenta`, `red`, ecc.), `panelBg` (color ARGB ~90%), `radius` (int 18), `border` (color), `borderWidth` (int), `fontFamily` (string). `shell.qml` espone `root.targetScreen` (ShellScreen DP-4 o primo).

- [ ] **Step 1: Scrivere `Theme.qml`** (singleton)

```qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Palette Tokyo Night
    readonly property color bg:       "#1a1b26"
    readonly property color bgDark:   "#16161e"
    readonly property color surface0: "#292e42"
    readonly property color surface1: "#414868"
    readonly property color fg:       "#c0caf5"
    readonly property color subtext:  "#a9b1d6"
    readonly property color comment:  "#565f89"
    readonly property color blue:     "#7aa2f7"
    readonly property color cyan:     "#7dcfff"
    readonly property color teal:     "#2ac3de"
    readonly property color magenta:  "#bb9af7"
    readonly property color green:    "#9ece6a"
    readonly property color orange:   "#ff9e64"
    readonly property color yellow:   "#e0af68"
    readonly property color red:      "#f7768e"

    // Stile pannelli "cozy"
    readonly property color panelBg:  "#e61a1b26"   // bg @ ~90% (ARGB)
    readonly property color border:   "#7aa2f7"
    readonly property int   borderWidth: 1
    readonly property int   radius:   18
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
```

- [ ] **Step 2: Scrivere `shell.qml`** (entry, nessun widget ancora)

```qml
import Quickshell
import QtQuick

ShellRoot {
    id: root

    // Schermo DP-4, fallback al primo disponibile
    readonly property var targetScreen: {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === "DP-4")
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Component.onCompleted: console.log("quickshell: targetScreen =",
        root.targetScreen ? root.targetScreen.name : "none")
}
```

- [ ] **Step 3: Creare il symlink config**

Run:
```bash
ln -sfn ~/dotfiles/quickshell ~/.config/quickshell
ls -l ~/.config/quickshell
```
Expected: `~/.config/quickshell -> /home/xsaturn/dotfiles/quickshell`

- [ ] **Step 4: Verificare che `qs` carichi senza errori**

Run:
```bash
timeout 4 qs -c quickshell 2>&1 | head -20; echo "exit ok"
```
Expected: log `quickshell: targetScreen = DP-4` (o nome del primo schermo), nessun errore QML (`QQmlComponent`/`ReferenceError`). Il processo viene terminato dal `timeout` (atteso).

- [ ] **Step 5: Aggiungere l'autostart Hyprland**

Aggiungere in `~/dotfiles/hypr/conf/autostart.conf` (dopo gli altri `exec-once`, vicino a waybar):
```conf
exec-once = qs   # Quickshell: widget desktop (Fase 9a)
```

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles && git add quickshell/Theme.qml quickshell/shell.qml hypr/conf/autostart.conf && git commit -m "feat(fase9a): scaffolding Quickshell (Theme Tokyo Night + shell + autostart)"
```

---

## Task 2: ClockWidget (orologio + data, top-right DP-4)

**Files:**
- Create: `~/dotfiles/quickshell/ClockWidget.qml`
- Modify: `~/dotfiles/quickshell/shell.qml`

**Interfaces:**
- Consumes: `Theme.*`, `root.targetScreen`.
- Produces: tipo `ClockWidget` con proprietà `screen` (ShellScreen).

- [ ] **Step 1: Scrivere `ClockWidget.qml`**

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: w
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-clock"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; right: true }
    margins { top: 40; right: 40 }
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
```

- [ ] **Step 2: Istanziare il widget in `shell.qml`**

Aggiungere dentro `ShellRoot { ... }`, dopo `Component.onCompleted`:
```qml
    ClockWidget { screen: root.targetScreen }
```

- [ ] **Step 3: Verifica visiva**

Run:
```bash
timeout 5 qs -c quickshell 2>&1 | head -20
```
Expected: nessun errore QML. In esecuzione reale (`qs &`) compare in alto a destra su DP-4 un pannello arrotondato semi-trasparente con ora grande blu e data sotto. Verificare a occhio (orario corretto, bordo blue, font Nerd).

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles && git add quickshell/ClockWidget.qml quickshell/shell.qml && git commit -m "feat(fase9a): ClockWidget (ora+data, top-right DP-4)"
```

---

## Task 3: Logica CPU% (`cpustat.js`) con self-check

**Files:**
- Create: `~/dotfiles/quickshell/lib/cpustat.js`
- Test: `~/dotfiles/quickshell/lib/cpustat_test.qml`

**Interfaces:**
- Produces: `cpustat.js` con `parseCpu(line) -> {idle:int, total:int}` e `percent(prev, cur) -> int` (0–100). `prev`/`cur` sono oggetti restituiti da `parseCpu`.

- [ ] **Step 1: Scrivere il test (`cpustat_test.qml`) che fallisce**

```qml
import QtQuick
import "cpustat.js" as Cpu

QtObject {
    Component.onCompleted: {
        // Snapshot noti di /proc/stat (riga "cpu  ..."):
        //   campi: user nice system idle iowait irq softirq ...
        var a = Cpu.parseCpu("cpu  100 0 100 700 0 0 0 0 0 0"); // total 900, idle 700
        var b = Cpu.parseCpu("cpu  150 0 150 800 0 0 0 0 0 0"); // total 1100, idle 800
        // delta total=200, delta idle=100 -> busy 100/200 = 50%
        var pct = Cpu.percent(a, b);
        if (pct !== 50) { console.error("FAIL: atteso 50, ottenuto " + pct); Qt.exit(1); }
        // guard: delta nullo -> 0, niente NaN/divisione per zero
        if (Cpu.percent(a, a) !== 0) { console.error("FAIL: guard delta=0"); Qt.exit(1); }
        console.log("PASS cpustat");
        Qt.exit(0);
    }
}
```

- [ ] **Step 2: Eseguire il test e verificare che fallisca**

Run:
```bash
QT_QPA_PLATFORM=offscreen qml6 ~/dotfiles/quickshell/lib/cpustat_test.qml; echo "rc=$?"
```
Expected: errore (file `cpustat.js` inesistente o `parseCpu is not a function`), `rc=1` o errore di import.

- [ ] **Step 3: Implementare `cpustat.js`**

```js
.pragma library

// Riga "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
function parseCpu(line) {
    var parts = line.trim().split(/\s+/);
    var nums = [];
    for (var i = 1; i < parts.length; i++) {     // salta "cpu"
        var n = parseInt(parts[i], 10);
        nums.push(isNaN(n) ? 0 : n);
    }
    var idle = (nums[3] || 0) + (nums[4] || 0);  // idle + iowait
    var total = 0;
    for (var j = 0; j < nums.length; j++) total += nums[j];
    return { idle: idle, total: total };
}

// Percentuale di occupazione tra due snapshot, arrotondata 0..100.
function percent(prev, cur) {
    var dt = cur.total - prev.total;
    var di = cur.idle - prev.idle;
    if (dt <= 0) return 0;
    var p = Math.round((1 - di / dt) * 100);
    return p < 0 ? 0 : (p > 100 ? 100 : p);
}
```

- [ ] **Step 4: Eseguire il test e verificare che passi**

Run:
```bash
QT_QPA_PLATFORM=offscreen qml6 ~/dotfiles/quickshell/lib/cpustat_test.qml; echo "rc=$?"
```
Expected: stampa `PASS cpustat`, `rc=0`.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add quickshell/lib/cpustat.js quickshell/lib/cpustat_test.qml && git commit -m "feat(fase9a): logica CPU% da /proc/stat + self-check (qml6)"
```

---

## Task 4: SysMonitorWidget (CPU/RAM/GPU + temp, top-left DP-4)

**Files:**
- Create: `~/dotfiles/quickshell/SysMonitorWidget.qml`
- Modify: `~/dotfiles/quickshell/shell.qml`

**Interfaces:**
- Consumes: `Theme.*`, `root.targetScreen`, `cpustat.js` (`parseCpu`, `percent`).
- Produces: tipo `SysMonitorWidget` con proprietà `screen`.

Dati raccolti via `Process` (Quickshell.Io) ogni 2s:
- CPU: `cat /proc/stat` → prima riga → `Cpu.parseCpu` → `Cpu.percent(prev, cur)`.
- RAM: `cat /proc/meminfo` → `(MemTotal-MemAvailable)/MemTotal*100`.
- GPU+tempGPU: `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits` → `"37, 55"`.
- tempCPU: legge il primo `temp*_input` dell'hwmon il cui `name == coretemp` (risolto via shell, non indice fisso).

- [ ] **Step 1: Scrivere `SysMonitorWidget.qml`**

```qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "lib/cpustat.js" as Cpu

PanelWindow {
    id: w
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-sysmon"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; left: true }
    margins { top: 40; left: 40 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    property int cpuPct: 0
    property int ramPct: 0
    property int gpuPct: 0
    property string cpuTemp: "--"
    property string gpuTemp: "--"
    property var _prevCpu: null

    Timer {
        interval: 2000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: { pCpu.running = true; pMem.running = true; pGpu.running = true; pCtemp.running = true }
    }

    // CPU% da /proc/stat
    Process {
        id: pCpu
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.split("\n")[0];
                var cur = Cpu.parseCpu(line);
                if (w._prevCpu) w.cpuPct = Cpu.percent(w._prevCpu, cur);
                w._prevCpu = cur;
            }
        }
    }

    // RAM% da /proc/meminfo
    Process {
        id: pMem
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                var total = 0, avail = 0;
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var m = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)/);
                    if (m) { if (m[1] === "MemTotal") total = +m[2]; else avail = +m[2]; }
                }
                w.ramPct = total > 0 ? Math.round((1 - avail / total) * 100) : 0;
            }
        }
    }

    // GPU util + temp da nvidia-smi
    Process {
        id: pGpu
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu",
                  "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split(",");
                if (p.length >= 2) { w.gpuPct = parseInt(p[0]) || 0; w.gpuTemp = p[1].trim(); }
                else { w.gpuTemp = "--"; }
            }
        }
        onExited: (code) => { if (code !== 0) { w.gpuPct = 0; w.gpuTemp = "--"; } }
    }

    // CPU temp: risolve l'hwmon coretemp (indice non fisso) e legge il primo temp*_input
    Process {
        id: pCtemp
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do [ \"$(cat $d/name 2>/dev/null)\" = coretemp ] && cat \"$d\"/temp1_input 2>/dev/null && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim());
                w.cpuTemp = isNaN(v) ? "--" : Math.round(v / 1000).toString();
            }
        }
    }

    component StatRow: Row {
        property string label: ""
        property int pct: 0
        property color accent: Theme.blue
        spacing: 8
        Text { width: 36; text: label; color: Theme.subtext
               font.family: Theme.fontFamily; font.pixelSize: 14 }
        Rectangle {  // barra
            width: 90; height: 8; radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.surface0
            Rectangle { width: parent.width * Math.min(pct,100)/100; height: parent.height
                        radius: 4; color: accent }
        }
        Text { width: 40; horizontalAlignment: Text.AlignRight
               text: pct + "%"; color: Theme.fg
               font.family: Theme.fontFamily; font.pixelSize: 14 }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        implicitWidth: col.implicitWidth + 40
        implicitHeight: col.implicitHeight + 32

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 8
            StatRow { label: "CPU"; pct: w.cpuPct; accent: Theme.blue }
            StatRow { label: "RAM"; pct: w.ramPct; accent: Theme.green }
            StatRow { label: "GPU"; pct: w.gpuPct; accent: Theme.magenta }
            Text {
                text: " " + w.cpuTemp + "°C   " + w.gpuTemp + "°C"
                color: Theme.orange
                font.family: Theme.fontFamily; font.pixelSize: 14
            }
        }
    }
}
```

- [ ] **Step 2: Istanziare in `shell.qml`**

Aggiungere dentro `ShellRoot { ... }`:
```qml
    SysMonitorWidget { screen: root.targetScreen }
```

- [ ] **Step 3: Verifica**

Run:
```bash
timeout 6 qs -c quickshell 2>&1 | head -30
```
Expected: nessun errore QML. In esecuzione reale: in alto a sinistra compaiono CPU/RAM/GPU con barre che si muovono e la riga temperature (numeri plausibili, GPU ~ quella di `nvidia-smi`). Confronto rapido:
```bash
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits
```

- [ ] **Step 4: Commit**

```bash
cd ~/dotfiles && git add quickshell/SysMonitorWidget.qml quickshell/shell.qml && git commit -m "feat(fase9a): SysMonitorWidget (CPU/RAM/GPU + temp)"
```

---

## Task 5: NowPlayingWidget (MPRIS, bottom-left) + chiusura

**Files:**
- Create: `~/dotfiles/quickshell/NowPlayingWidget.qml`
- Modify: `~/dotfiles/quickshell/shell.qml`
- Modify: `~/RICING.md`

**Interfaces:**
- Consumes: `Theme.*`, `root.targetScreen`, `Quickshell.Services.Mpris`.
- Produces: tipo `NowPlayingWidget` con proprietà `screen`.

Player attivo: si sceglie il primo player MPRIS in `Playing`, altrimenti il primo disponibile. Copertina via `Image { source: player.trackArtUrl }` (Spotify = URL https caricabile diretto). Nessun player → placeholder.

- [ ] **Step 1: Scrivere `NowPlayingWidget.qml`**

```qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: w
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-nowplaying"
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; left: true }
    margins { bottom: 40; left: 40 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // Player attivo: primo in Playing, altrimenti il primo
    readonly property var player: {
        var ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (var i = 0; i < ps.length; i++)
            if (ps[i].playbackState === MprisPlaybackState.Playing) return ps[i];
        return ps[0];
    }
    readonly property bool hasPlayer: player !== null

    // Poll posizione per la seek bar
    Timer {
        interval: 1000; running: w.hasPlayer; repeat: true
        onTriggered: if (w.player && w.player.positionSupported) w.player.positionChanged()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panelBg
        border.color: Theme.border
        border.width: Theme.borderWidth
        implicitWidth: 360
        implicitHeight: content.implicitHeight + 28

        // Placeholder: nessun player
        Text {
            anchors.centerIn: parent
            visible: !w.hasPlayer
            text: " Niente in riproduzione"
            color: Theme.comment
            font.family: Theme.fontFamily; font.pixelSize: 15
        }

        Row {
            id: content
            visible: w.hasPlayer
            anchors { fill: parent; margins: 14 }
            spacing: 14

            // Copertina (o placeholder nota musicale)
            Rectangle {
                width: 80; height: 80; radius: 10
                color: Theme.surface0
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    anchors.fill: parent
                    source: w.player && w.player.trackArtUrl ? w.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !parent.children[0] || parent.children[0].status !== Image.Ready
                    text: ""; color: Theme.comment
                    font.family: Theme.fontFamily; font.pixelSize: 28
                }
            }

            Column {
                width: parent.width - 80 - 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: w.player ? (w.player.trackTitle || "—") : "—"
                    color: Theme.fg; font.family: Theme.fontFamily
                    font.pixelSize: 16; font.bold: true
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: w.player ? (w.player.trackArtist || "") : ""
                    color: Theme.subtext; font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                // Controlli
                Row {
                    spacing: 18
                    property var p: w.player
                    Text { text: "玲"; color: Theme.blue; font.pixelSize: 20
                           font.family: Theme.fontFamily
                           MouseArea { anchors.fill: parent
                               onClicked: if (parent.parent.p) parent.parent.p.previous() } }
                    Text {
                        text: (w.player && w.player.playbackState === MprisPlaybackState.Playing) ? "" : ""
                        color: Theme.cyan; font.pixelSize: 22
                        font.family: Theme.fontFamily
                        MouseArea { anchors.fill: parent
                            onClicked: if (parent.parent.p) parent.parent.p.togglePlaying() } }
                    Text { text: "怜"; color: Theme.blue; font.pixelSize: 20
                           font.family: Theme.fontFamily
                           MouseArea { anchors.fill: parent
                               onClicked: if (parent.parent.p) parent.parent.p.next() } }
                }

                // Seek bar
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Theme.surface0
                    visible: w.player && w.player.lengthSupported && w.player.length > 0
                    Rectangle {
                        height: parent.height; radius: 3; color: Theme.blue
                        width: (w.player && w.player.length > 0)
                               ? parent.width * Math.min(w.player.position / w.player.length, 1)
                               : 0
                    }
                }
            }
        }
    }
}
```

> `ponytail:` i glifi nei controlli/placeholder (⏮ ⏯ ⏭ ♪) sono Nerd Font; se l'editor li azzera, reinserirli per codepoint come già fatto per Waybar (vedi Log RICING 2026-06-26). Codepoint: prev `U+F0CB1`?? usare quelli effettivi del set installato. In dubbio: testo "⏮ ⏯ ⏭".

- [ ] **Step 2: Istanziare in `shell.qml`**

Aggiungere dentro `ShellRoot { ... }`:
```qml
    NowPlayingWidget { screen: root.targetScreen }
```

- [ ] **Step 3: Verifica**

Run:
```bash
timeout 6 qs -c quickshell 2>&1 | head -30
```
Expected: nessun errore QML. Con Spotify/qualsiasi player MPRIS in riproduzione (`playerctl metadata` per conferma), in basso a sinistra compaiono copertina, titolo, artista, controlli cliccabili (prev/play-pause/next funzionano) e seek bar che avanza. Senza player: placeholder "Niente in riproduzione".

```bash
playerctl metadata 2>/dev/null || echo "nessun player attivo"
```

- [ ] **Step 4: Aggiornare `~/RICING.md`**

Spuntare in Fase 9 la voce dashboard (parte 9a) e aggiungere una riga al Log:
```markdown
- **2026-06-26** — Fase 9a (widget desktop Quickshell) ✅: installato Quickshell 0.3.0; config in ~/dotfiles/quickshell (symlink). Theme.qml singleton Tokyo Night; 3 PanelWindow su layer bottom su DP-4 — ClockWidget (ora+data), SysMonitorWidget (CPU%/RAM%/GPU% + temp CPU coretemp/GPU nvidia-smi, poll 2s, CPU% in lib/cpustat.js con self-check qml6), NowPlayingWidget (MPRIS: copertina, controlli, seek bar). Autostart exec-once=qs. Convive con Waybar. Resta Fase 9b: overlay SUPER+D a schede.
```
E cambiare la riga `- [ ] Dashboard/widget (eww o AGS/Astal)` in:
```markdown
- [x] **Widget desktop (Quickshell)** ✅ Fase 9a — orologio/data, now-playing MPRIS, system monitor su DP-4. (overlay a schede = Fase 9b, ancora da fare)
```

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles && git add quickshell/NowPlayingWidget.qml quickshell/shell.qml && git commit -m "feat(fase9a): NowPlayingWidget (MPRIS: copertina, controlli, seek bar)"
```
Poi (RICING.md non è nel repo dotfiles — è in ~):
```bash
echo "RICING.md aggiornato (vive in ~/, fuori dal repo dotfiles)"
```

---

## Self-Review (compilato in fase di scrittura)

- **Copertura spec:** scaffolding+Theme (T1) ✓ · clock (T2) ✓ · CPU% logica+test (T3) ✓ · sysmon CPU/RAM/GPU/temp+errori (T4) ✓ · now-playing MPRIS+placeholder (T5) ✓ · layer bottom/DP-4/fallback (T1+ogni widget) ✓ · autostart (T1) ✓ · convivenza Waybar (vincolo, nessun file Waybar toccato) ✓.
- **Fuori scope confermato:** overlay a schede, calendario, meteo, visualizer → Fase 9b.
- **Note di fragilità note:** indice hwmon risolto per nome (non fisso); glifi Nerd Font da reinserire per codepoint se l'editor li azzera; API Quickshell 0.3 (`StdioCollector.onStreamFinished`, `Mpris.players.values`, `positionSupported`/`lengthSupported`) — se un nome differisse nella 0.3.0 installata, adeguarlo in fase di esecuzione (verifica con `qs` log).
- **Tipi coerenti:** `parseCpu`/`percent` usati identici in T3 e T4; `root.targetScreen` e `screen` coerenti T1–T5.
```
