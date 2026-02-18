import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: dashPage

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ── LEFT: OBD-II Gauges ────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            color: "#111827"
            radius: 12
            border.color: "#334155"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "⚙ OBD-II DATA"
                    color: "#f59e0b"
                    font.pixelSize: 14
                    font.bold: true
                }

                // Gauge grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: 8
                    columnSpacing: 8

                    Gauge {
                        label: "SPEED"
                        unit: "km/h"
                        value: dash.speed
                        maxValue: 200
                        arcColor: "#06b6d4"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "RPM"
                        unit: "rpm"
                        value: dash.rpm
                        maxValue: 8000
                        arcColor: "#f59e0b"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "COOLANT"
                        unit: "°C"
                        value: dash.coolant
                        maxValue: 130
                        arcColor: "#3b82f6"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                    Gauge {
                        label: "THROTTLE"
                        unit: "%"
                        value: dash.throttle
                        maxValue: 100
                        arcColor: "#22c55e"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // Engine Load bar
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "#1e293b"
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Text {
                                text: "ENGINE LOAD"
                                color: "#94a3b8"
                                font.pixelSize: 14
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: dash.load + "%"
                                color: "#06b6d4"
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        // ── RIGHT: Charger Panel ───────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            color: "#111827"
            radius: 12
            border.color: "#334155"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: "🔋 CHARGER"
                    color: "#22c55e"
                    font.pixelSize: 14
                    font.bold: true
                }

                DataRow { label: "BATTERY";   value: dash.battV.toFixed(2) + " V";     valueColor: "#22c55e" }
                DataRow { label: "CURRENT";   value: dash.battI.toFixed(1) + " A";     valueColor: "#f59e0b" }
                DataRow { label: "SET POINT"; value: dash.chargeRate.toFixed(1) + " A"; valueColor: "#3b82f6" }
                DataRow { label: "TEMP T1";   value: dash.tempT1 + " °C";              valueColor: "#06b6d4" }
                DataRow { label: "TEMP T2";   value: dash.tempT2 + " °C";              valueColor: "#06b6d4" }
                DataRow { label: "AMBIENT";   value: dash.tempAmb + " °C";             valueColor: "#94a3b8" }

                Item { Layout.fillHeight: true }

                // Status box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: "#052e16"
                    border.color: "#166534"
                    border.width: 1
                    radius: 10

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: "✓ " + dash.faultText
                        color: "#22c55e"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
