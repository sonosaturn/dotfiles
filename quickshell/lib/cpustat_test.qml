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
