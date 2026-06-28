pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: hw
    property var windows: []

    function _appId(tl) {
        if (tl.wayland && tl.wayland.appId) return tl.wayland.appId;
        if (tl.lastIpcObject && tl.lastIpcObject.class) return tl.lastIpcObject.class;
        return "";
    }

    function rebuild() {
        var out = [];
        var ts = Hyprland.toplevels.values;
        for (var i = 0; i < ts.length; i++) {
            var tl = ts[i];
            out.push({
                address: tl.address,
                appId: _appId(tl),
                title: tl.title,
                monitorName: tl.monitor ? tl.monitor.name : "",
                activated: tl.activated,
                minimized: tl.workspace ? (tl.workspace.name === "special:minimized") : false
            });
        }
        hw.windows = out;
    }

    Connections { target: Hyprland.toplevels; function onValuesChanged() { hw.rebuild() } }
    Connections { target: Hyprland; function onRawEvent(event) { hw.rebuild() } }
    Component.onCompleted: rebuild()

    function focus(address)    { Hyprland.dispatch("focuswindow address:" + address) }
    function minimize(address) { Hyprland.dispatch("movetoworkspacesilent special:minimized,address:" + address) }
    function close(address)    { Hyprland.dispatch("closewindow address:" + address) }

    function restore(address, monitorName) {
        var ws = -1, ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++)
            if (ms[i].name === monitorName && ms[i].activeWorkspace) { ws = ms[i].activeWorkspace.id; break; }
        if (ws >= 0) Hyprland.dispatch("movetoworkspacesilent " + ws + ",address:" + address);
        Hyprland.dispatch("focuswindow address:" + address);
    }

    function toggle(entry, monitorName) {
        if (entry.minimized) restore(entry.address, monitorName);
        else if (entry.focused) minimize(entry.address);
        else focus(entry.address);
    }

    function minimizeActive() { if (Hyprland.activeToplevel) minimize(Hyprland.activeToplevel.address) }

    function anyFullscreenOn(monitorName) {
        var ts = Hyprland.toplevels.values;
        for (var i = 0; i < ts.length; i++) {
            var tl = ts[i];
            if (tl.monitor && tl.monitor.name === monitorName && tl.wayland && tl.wayland.fullscreen) return true;
        }
        return false;
    }
}
