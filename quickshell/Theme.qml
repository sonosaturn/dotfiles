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
    readonly property color panelBg:  "#991a1b26"   // bg @ ~60% opaco (≈40% trasparente, ARGB)
    readonly property color border:   "#7aa2f7"
    readonly property int   borderWidth: 1
    readonly property int   radius:   18
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
