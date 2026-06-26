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
