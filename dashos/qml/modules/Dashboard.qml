import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: dashPage

    // Compass heading helper
    function headingToCardinal(h) {
        var dirs = ["N","NE","E","SE","S","SW","W","NW"]
        return dirs[Math.round(h / 45) % 8]
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // ── LEFT: OBD-II Gauges ────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            color: "#111827"
            radius: 12
            border.color: "#334155"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: "\u2699 OBD-II DATA"
                    color: "#f59e0b"
                    font.pixelSize: 13
                    font.bold: true
                }

                // Gauge grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: 4
                    columnSpacing: 4

                    Gauge {
                        label: "SPEED"
                        unit: "km/h"
                        value: dash ? dash.speed : 0
                        maxValue: 200
                        arcColor: "#06b6d4"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "RPM"
                        unit: "rpm"
                        value: dash ? dash.rpm : 0
                        maxValue: 8000
                        arcColor: "#f59e0b"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "COOLANT"
                        unit: "\u00b0C"
                        value: dash ? dash.coolant : 0
                        maxValue: 130
                        arcColor: (dash && dash.coolant > 100) ? "#ef4444" : "#3b82f6"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "THROTTLE"
                        unit: "%"
                        value: dash ? dash.throttle : 0
                        maxValue: 100
                        arcColor: "#22c55e"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // Engine Load bar
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "#1e293b"
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Text {
                                text: "ENGINE LOAD"
                                color: "#94a3b8"
                                font.pixelSize: 12
                            }
                            Item { Layout.fillWidth: true }

                            // Load bar
                            Rectangle {
                                Layout.preferredWidth: 80
                                height: 8
                                radius: 4
                                color: "#0f172a"

                                Rectangle {
                                    width: parent.width * Math.min((dash ? dash.load : 0) / 100, 1.0)
                                    height: parent.height
                                    radius: 4
                                    color: "#06b6d4"
                                }
                            }

                            Text {
                                text: (dash ? dash.load : 0) + "%"
                                color: "#06b6d4"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        // ── CENTER: Trip Computer + GPS ────────────────
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 180
            spacing: 8

            // Trip Computer
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 3
                color: "#111827"
                radius: 12
                border.color: "#334155"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "\ud83d\udcca TRIP"
                            color: "#06b6d4"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 50; height: 20; radius: 4
                            color: "#1e293b"; border.color: "#334155"
                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: "#94a3b8"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: dash.resetTrip()
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Trip stats
                    TripRow { label: "DIST"; value: dash ? dash.tripDistance.toFixed(1) + " km" : "---"; valueColor: "#06b6d4" }
                    TripRow { label: "TIME"; value: dash ? dash.tripTime : "---"; valueColor: "#f1f5f9" }
                    TripRow { label: "AVG"; value: dash ? dash.tripAvgSpeed.toFixed(0) + " km/h" : "---"; valueColor: "#3b82f6" }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                    TripRow { label: "FUEL"; value: dash ? dash.fuelRate.toFixed(1) + " L/h" : "---"; valueColor: "#f59e0b" }
                    TripRow { label: "ECON"; value: dash ? dash.fuelEconomy.toFixed(1) + " L/100" : "---"; valueColor: "#22c55e" }

                    // Fuel level bar
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "TANK"; color: "#94a3b8"; font.pixelSize: 10 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 60; height: 8; radius: 4; color: "#0f172a"
                            Rectangle {
                                width: parent.width * Math.min((dash ? dash.fuelLevel : 0) / 100, 1.0)
                                height: parent.height; radius: 4
                                color: (dash && dash.fuelLevel < 20) ? "#ef4444" : "#22c55e"
                            }
                        }
                        Text {
                            text: dash ? dash.fuelLevel.toFixed(0) + "%" : "---"
                            color: (dash && dash.fuelLevel < 20) ? "#ef4444" : "#22c55e"
                            font.pixelSize: 11; font.bold: true
                        }
                    }

                    TripRow {
                        label: "DTE"
                        value: dash ? dash.dte.toFixed(0) + " km" : "---"
                        valueColor: (dash && dash.dte < 50) ? "#ef4444" : "#22c55e"
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // GPS Widget
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 2
                color: "#111827"
                radius: 12
                border.color: "#334155"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "\ud83d\udccd GPS"
                            color: "#22c55e"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 50; height: 16; radius: 4
                            color: (dash && dash.gpsFixText !== "No Fix") ? "#052e16" : "#450a0a"
                            Text {
                                anchors.centerIn: parent
                                text: dash ? dash.gpsFixText : "---"
                                color: (dash && dash.gpsFixText !== "No Fix") ? "#22c55e" : "#ef4444"
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    // Coordinates
                    Text {
                        text: dash ? dash.gpsLat.toFixed(4) + "\u00b0" + (dash.gpsLat >= 0 ? "N" : "S") : "---"
                        color: "#f1f5f9"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                    Text {
                        text: dash ? dash.gpsLon.toFixed(4) + "\u00b0" + (dash.gpsLon >= 0 ? "E" : "W") : "---"
                        color: "#f1f5f9"
                        font.pixelSize: 12
                        font.family: "monospace"
                    }

                    // Heading + compass
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "HDG"
                            color: "#94a3b8"
                            font.pixelSize: 10
                        }
                        Text {
                            text: {
                                var h = dash ? dash.gpsHeading : 0
                                return headingToCardinal(h) + " " + Math.round(h) + "\u00b0"
                            }
                            color: "#06b6d4"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        // Mini compass
                        Item {
                            width: 28; height: 28
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: "#1e293b"
                                border.color: "#334155"
                            }
                            Rectangle {
                                width: 3; height: 10; radius: 1.5
                                color: "#ef4444"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 3
                                transformOrigin: Item.Bottom
                                rotation: dash ? -dash.gpsHeading : 0
                                Behavior on rotation { NumberAnimation { duration: 300 } }
                            }
                        }
                    }

                    // Altitude + satellites
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "ALT"; color: "#94a3b8"; font.pixelSize: 10 }
                        Text {
                            text: dash ? dash.gpsAlt.toFixed(0) + "m" : "---"
                            color: "#f1f5f9"; font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "SAT"; color: "#94a3b8"; font.pixelSize: 10 }
                        Text {
                            text: dash ? dash.gpsSatellites.toString() : "0"
                            color: (dash && dash.gpsSatellites >= 4) ? "#22c55e" : "#f59e0b"
                            font.pixelSize: 11; font.bold: true
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ── RIGHT: Charger Panel ───────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            Layout.maximumWidth: 260
            color: "#111827"
            radius: 12
            border.color: "#334155"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    text: "\ud83d\udd0b CHARGER"
                    color: "#22c55e"
                    font.pixelSize: 13
                    font.bold: true
                }

                DataRow { label: "BATTERY";   value: dash ? dash.battV.toFixed(2) + " V" : "---";     valueColor: "#22c55e" }
                DataRow { label: "CURRENT";   value: dash ? dash.battI.toFixed(1) + " A" : "---";     valueColor: "#f59e0b" }
                DataRow { label: "SET POINT"; value: dash ? dash.chargeRate.toFixed(1) + " A" : "---"; valueColor: "#3b82f6" }
                DataRow { label: "TEMP T1";   value: dash ? dash.tempT1 + " \u00b0C" : "---";              valueColor: "#06b6d4" }
                DataRow { label: "TEMP T2";   value: dash ? dash.tempT2 + " \u00b0C" : "---";              valueColor: "#06b6d4" }
                DataRow { label: "AMBIENT";   value: dash ? dash.tempAmb + " \u00b0C" : "---";             valueColor: "#94a3b8" }

                Item { Layout.fillHeight: true }

                // Now Playing mini widget (always visible on dashboard)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: "#0c2d48"
                    border.color: "#1e5a8a"
                    border.width: 1
                    radius: 10
                    visible: dash ? dash.isPlaying : false

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Text {
                            text: "\u266b " + (dash ? dash.trackTitle : "")
                            color: "#f1f5f9"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: dash ? dash.trackArtist : ""
                                color: "#94a3b8"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            // Mini progress bar
                            Rectangle {
                                width: 50; height: 4; radius: 2; color: "#1e293b"
                                Rectangle {
                                    width: parent.width * (dash ? dash.trackProgress : 0)
                                    height: parent.height; radius: 2; color: "#3b82f6"
                                }
                            }
                        }
                    }
                }

                // Status box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#052e16"
                    border.color: "#166534"
                    border.width: 1
                    radius: 10

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: "\u2713 " + (dash ? dash.faultText : "---")
                        color: "#22c55e"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // ── TripRow helper component ──
    component TripRow: RowLayout {
        property string label: ""
        property string value: ""
        property color valueColor: "#f1f5f9"
        Layout.fillWidth: true
        Text { text: label; color: "#94a3b8"; font.pixelSize: 10 }
        Item { Layout.fillWidth: true }
        Text { text: value; color: valueColor; font.pixelSize: 12; font.bold: true }
    }
}
