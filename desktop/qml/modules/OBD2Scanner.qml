import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: obd2Page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "🔍 OBD-II LIVE DATA"
                color: "#f59e0b"
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 100; height: 32; radius: 8
                color: "#1e293b"; border.color: "#334155"
                Text {
                    anchors.centerIn: parent
                    text: "⟳ Refresh"
                    color: "#06b6d4"
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Data table
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111827"
            radius: 12
            border.color: "#334155"

            // Table header
            Rectangle {
                id: tableHeader
                width: parent.width
                height: 32
                color: "#1e293b"
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Text { text: "PARAMETER"; color: "#94a3b8"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 200 }
                    Text { text: "VALUE"; color: "#94a3b8"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 100 }
                    Text { text: "UNIT"; color: "#94a3b8"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                    Text { text: "BAR"; color: "#94a3b8"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                }
            }

            // Scrollable PID list
            ListView {
                anchors.top: tableHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                clip: true
                spacing: 2

                model: ListModel {
                    ListElement { name: "Vehicle Speed"; val: "85"; unit: "km/h"; pct: 42 }
                    ListElement { name: "Engine RPM"; val: "2750"; unit: "rpm"; pct: 34 }
                    ListElement { name: "Coolant Temperature"; val: "88"; unit: "°C"; pct: 55 }
                    ListElement { name: "Throttle Position"; val: "42"; unit: "%"; pct: 42 }
                    ListElement { name: "Engine Load"; val: "55"; unit: "%"; pct: 55 }
                    ListElement { name: "Intake Air Temp"; val: "32"; unit: "°C"; pct: 20 }
                    ListElement { name: "MAF Air Flow"; val: "4.52"; unit: "g/s"; pct: 30 }
                    ListElement { name: "Fuel Pressure"; val: "350"; unit: "kPa"; pct: 46 }
                    ListElement { name: "Timing Advance"; val: "14.5"; unit: "°"; pct: 45 }
                    ListElement { name: "Fuel Level"; val: "65"; unit: "%"; pct: 65 }
                    ListElement { name: "Barometric Pressure"; val: "101"; unit: "kPa"; pct: 40 }
                    ListElement { name: "Catalyst Temp B1S1"; val: "420"; unit: "°C"; pct: 60 }
                    ListElement { name: "Control Module Voltage"; val: "14.2"; unit: "V"; pct: 88 }
                    ListElement { name: "Ambient Air Temp"; val: "32"; unit: "°C"; pct: 25 }
                    ListElement { name: "Engine Oil Temp"; val: "95"; unit: "°C"; pct: 45 }
                    ListElement { name: "Fuel Rate"; val: "8.5"; unit: "L/h"; pct: 26 }
                    ListElement { name: "Short Fuel Trim B1"; val: "2.3"; unit: "%"; pct: 52 }
                    ListElement { name: "Long Fuel Trim B1"; val: "-1.5"; unit: "%"; pct: 48 }
                    ListElement { name: "O2 Voltage B1S1"; val: "0.45"; unit: "V"; pct: 35 }
                    ListElement { name: "Run Time"; val: "1842"; unit: "sec"; pct: 18 }
                }

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 0
                    height: 30
                    color: index % 2 === 0 ? "transparent" : "#0f172a"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text { text: name; color: "#f1f5f9"; font.pixelSize: 12; Layout.preferredWidth: 200 }
                        Text { text: val; color: "#06b6d4"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 100 }
                        Text { text: unit; color: "#94a3b8"; font.pixelSize: 11; Layout.preferredWidth: 80 }

                        // Progress bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: "#1e293b"

                            Rectangle {
                                width: parent.width * (pct / 100)
                                height: parent.height
                                radius: 3
                                color: "#06b6d4"
                            }
                        }
                    }
                }
            }
        }
    }
}
