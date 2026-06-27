import QtQuick
import QtQuick.Layouts

Item {
    id: cal
    property var shown: new Date()                  // un giorno qualsiasi del mese mostrato
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()   // 0-11
    property var today: new Date()

    readonly property int firstDow: ((new Date(year, month, 1).getDay() + 6) % 7)  // 0 = Lunedì
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property var monthNames: ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
                                       "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"]

    function addMonth(d) { cal.shown = new Date(cal.year, cal.month + d, 1); }
    function isToday(day) {
        return day === today.getDate() && month === today.getMonth() && year === today.getFullYear();
    }

    // tiene "today" allineato se la dashboard resta aperta a cavallo di mezzanotte
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: cal.today = new Date()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "‹"; color: Theme.cyan; font.pixelSize: 22; font.family: Theme.fontFamily
                MouseArea { anchors.fill: parent; onClicked: cal.addMonth(-1) }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: cal.monthNames[cal.month] + " " + cal.year
                color: Theme.fg; font.pixelSize: 14; font.family: Theme.fontFamily
                MouseArea { anchors.fill: parent; onClicked: cal.shown = new Date() }   // click = torna a oggi
            }
            Text {
                text: "›"; color: Theme.cyan; font.pixelSize: 22; font.family: Theme.fontFamily
                MouseArea { anchors.fill: parent; onClicked: cal.addMonth(1) }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: ["L","M","M","G","V","S","D"]
                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData; color: Theme.comment
                    font.pixelSize: 11; font.family: Theme.fontFamily
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: 42
                delegate: Item {
                    required property int index
                    readonly property int day: index - cal.firstDow + 1
                    readonly property bool inMonth: day >= 1 && day <= cal.daysInMonth
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: width / 2
                        color: (inMonth && cal.isToday(day)) ? Theme.cyan : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: inMonth
                        text: day
                        color: cal.isToday(day) ? Theme.bg : Theme.fg
                        font.pixelSize: 12; font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
