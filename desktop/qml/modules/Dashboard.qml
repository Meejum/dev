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
            Layout.minimumWidth: 340
            color: "#111827"
            radius: 12
            border.color: "#334155"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Header with clock
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "\u2699 OBD-II DATA"
                        color: "#f59e0b"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    // Clock display
                    Column {
                        spacing: 0
                        Text {
                            text: dash ? dash.currentTime : "00:00:00"
                            color: "#f1f5f9"
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "monospace"
                            anchors.right: parent.right
                        }
                        Text {
                            text: dash ? dash.currentDate : ""
                            color: "#475569"
                            font.pixelSize: 8
                            anchors.right: parent.right
                        }
                        Text {
                            text: dash ? dash.timezoneName + " (GMT+" + dash.timezoneOffset.toFixed(0) + ")" : ""
                            color: "#334155"
                            font.pixelSize: 7
                            anchors.right: parent.right
                        }
                    }
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

        // ── CENTER: Trip (Since Start + Since Reset) + GPS ────
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 190
            spacing: 6

            // ── SINCE START (never resets) ──
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
                    anchors.margins: 8
                    spacing: 3

                    Text {
                        text: "\u23f1 SINCE START"
                        color: "#f59e0b"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    TripRow { label: "DRIVE"; value: dash ? dash.startTime : "---"; valueColor: "#f1f5f9" }
                    TripRow { label: "DIST"; value: dash ? dash.startDistance.toFixed(1) + " km" : "---"; valueColor: "#06b6d4" }
                    TripRow { label: "AVG"; value: dash ? dash.startAvgSpeed.toFixed(0) + " km/h" : "---"; valueColor: "#3b82f6" }
                    TripRow { label: "IAT\u00d8"; value: dash ? dash.startIntakeTempAvg.toFixed(0) + " \u00b0C" : "---"; valueColor: "#f59e0b" }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── SINCE RESET (resettable trip) ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 4
                color: "#111827"
                radius: 12
                border.color: "#334155"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "\ud83d\udcca SINCE RESET"
                            color: "#06b6d4"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        // Reset button
                        Rectangle {
                            width: 50; height: 18; radius: 4
                            color: "#1e293b"; border.color: "#ef4444"
                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: "#ef4444"
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

            // ── GPS Widget ──
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
                    anchors.margins: 8
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "\ud83d\udccd GPS"
                            color: "#22c55e"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 46; height: 14; radius: 4
                            color: (dash && dash.gpsFixText !== "No Fix") ? "#052e16" : "#450a0a"
                            Text {
                                anchors.centerIn: parent
                                text: dash ? dash.gpsFixText : "---"
                                color: (dash && dash.gpsFixText !== "No Fix") ? "#22c55e" : "#ef4444"
                                font.pixelSize: 7
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: dash ? dash.gpsLat.toFixed(4) + "\u00b0" + (dash.gpsLat >= 0 ? "N" : "S") : "---"
                        color: "#f1f5f9"
                        font.pixelSize: 11
                        font.family: "monospace"
                    }
                    Text {
                        text: dash ? dash.gpsLon.toFixed(4) + "\u00b0" + (dash.gpsLon >= 0 ? "E" : "W") : "---"
                        color: "#f1f5f9"
                        font.pixelSize: 11
                        font.family: "monospace"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "HDG"; color: "#94a3b8"; font.pixelSize: 9 }
                        Text {
                            text: {
                                var h = dash ? dash.gpsHeading : 0
                                return headingToCardinal(h) + " " + Math.round(h) + "\u00b0"
                            }
                            color: "#06b6d4"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        // Mini compass
                        Item {
                            width: 24; height: 24
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: "#1e293b"
                                border.color: "#334155"
                            }
                            Rectangle {
                                width: 2; height: 8; radius: 1
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

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "ALT"; color: "#94a3b8"; font.pixelSize: 9 }
                        Text {
                            text: dash ? dash.gpsAlt.toFixed(0) + "m" : "---"
                            color: "#f1f5f9"; font.pixelSize: 10
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "SAT"; color: "#94a3b8"; font.pixelSize: 9 }
                        Text {
                            text: dash ? dash.gpsSatellites.toString() : "0"
                            color: (dash && dash.gpsSatellites >= 4) ? "#22c55e" : "#f59e0b"
                            font.pixelSize: 10; font.bold: true
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

                // Header
                Text {
                    text: "\ud83d\udd0b CHARGER"
                    color: {
                        if (!dash) return "#94a3b8"
                        if (dash.chargerMode === "off") return "#ef4444"
                        if (dash.chargerMode === "limit") return "#f59e0b"
                        return "#22c55e"
                    }
                    font.pixelSize: 13
                    font.bold: true
                }

                // ── Three-state charger control: OFF / LIMIT / ON ──
                Row {
                    Layout.fillWidth: true
                    spacing: 4

                    // OFF button
                    Rectangle {
                        width: (parent.width - 8) / 3; height: 28; radius: 6
                        color: (dash && dash.chargerMode === "off") ? "#450a0a" : "#1e293b"
                        border.color: "#ef4444"
                        border.width: (dash && dash.chargerMode === "off") ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "OFF"
                            color: "#ef4444"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dash.setChargerMode("off")
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // LIMIT button
                    Rectangle {
                        width: (parent.width - 8) / 3; height: 28; radius: 6
                        color: (dash && dash.chargerMode === "limit") ? "#422006" : "#1e293b"
                        border.color: "#f59e0b"
                        border.width: (dash && dash.chargerMode === "limit") ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "LIMIT"
                            color: "#f59e0b"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dash.setChargerMode("limit")
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // ON button
                    Rectangle {
                        width: (parent.width - 8) / 3; height: 28; radius: 6
                        color: (dash && dash.chargerMode === "on") ? "#052e16" : "#1e293b"
                        border.color: "#22c55e"
                        border.width: (dash && dash.chargerMode === "on") ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: "ON"
                            color: "#22c55e"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dash.setChargerMode("on")
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                // Limit slider (visible only in LIMIT mode)
                RowLayout {
                    Layout.fillWidth: true
                    visible: dash ? dash.chargerMode === "limit" : false
                    spacing: 4

                    Text { text: "LIM"; color: "#f59e0b"; font.pixelSize: 9 }
                    Slider {
                        Layout.fillWidth: true
                        from: 1; to: 30; value: dash ? dash.chargerLimit : 15; stepSize: 1
                        onMoved: dash.setChargerLimit(value)
                        background: Rectangle {
                            width: parent.availableWidth; height: 4; radius: 2; color: "#1e293b"
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: "#f59e0b" }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 14; height: 14; radius: 7; color: "#f59e0b"
                        }
                    }
                    Text {
                        text: dash ? dash.chargerLimit.toFixed(0) + "A" : "15A"
                        color: "#f59e0b"; font.pixelSize: 10; font.bold: true
                    }
                }

                DataRow { label: "BATTERY";   value: dash ? dash.battV.toFixed(2) + " V" : "---";     valueColor: "#22c55e" }
                DataRow { label: "CURRENT";   value: dash ? dash.battI.toFixed(1) + " A" : "---";     valueColor: "#f59e0b" }
                DataRow { label: "SET POINT"; value: dash ? dash.chargeRate.toFixed(1) + " A" : "---"; valueColor: "#3b82f6" }
                DataRow { label: "TEMP T1";   value: dash ? dash.tempT1 + " \u00b0C" : "---";              valueColor: "#06b6d4" }
                DataRow { label: "TEMP T2";   value: dash ? dash.tempT2 + " \u00b0C" : "---";              valueColor: "#06b6d4" }
                DataRow { label: "AMBIENT";   value: dash ? dash.tempAmb + " \u00b0C" : "---";             valueColor: "#94a3b8" }

                Item { Layout.fillHeight: true }

                // Now Playing mini widget
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
                    color: {
                        if (!dash) return "#052e16"
                        if (dash.chargerMode === "off") return "#1c1917"
                        if (dash.chargerMode === "limit") return "#422006"
                        return "#052e16"
                    }
                    border.color: {
                        if (!dash) return "#166534"
                        if (dash.chargerMode === "off") return "#57534e"
                        if (dash.chargerMode === "limit") return "#92400e"
                        return "#166534"
                    }
                    border.width: 1
                    radius: 10

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: dash ? ("\u2713 " + dash.faultText) : "---"
                        color: {
                            if (!dash) return "#22c55e"
                            if (dash.chargerMode === "off") return "#ef4444"
                            if (dash.chargerMode === "limit") return "#f59e0b"
                            return "#22c55e"
                        }
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
