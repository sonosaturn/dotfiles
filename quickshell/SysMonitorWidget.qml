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
