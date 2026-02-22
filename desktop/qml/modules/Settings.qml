import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: settingsPage

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            text: "\u2699 SETTINGS"
            color: "#f59e0b"
            font.pixelSize: 16
            font.bold: true
        }

        // Settings sections
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: settingsCol.implicitHeight
            clip: true

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: 12

                // ── SERIAL PORT (Desktop-specific) ──
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: serialCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: serialCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "SERIAL PORT"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }
                            Item { Layout.fillWidth: true }

                            // Connection status badge
                            Rectangle {
                                width: 90; height: 20; radius: 10
                                color: (dash && dash.serialConnected) ? "#052e16" : "#450a0a"
                                border.color: (dash && dash.serialConnected) ? "#22c55e" : "#ef4444"
                                Text {
                                    anchors.centerIn: parent
                                    text: (dash && dash.serialConnected) ? "CONNECTED" : "DISCONNECTED"
                                    color: (dash && dash.serialConnected) ? "#22c55e" : "#ef4444"
                                    font.pixelSize: 8; font.bold: true
                                }
                            }
                        }

                        // Status text
                        Text {
                            text: dash ? dash.serialStatus : "---"
                            color: (dash && dash.serialConnected) ? "#22c55e" : "#94a3b8"
                            font.pixelSize: 12
                        }

                        // Port selection
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Port"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }

                            // Refresh ports button
                            Rectangle {
                                width: 70; height: 26; radius: 6
                                color: "#1e293b"; border.color: "#06b6d4"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u21bb SCAN"
                                    color: "#06b6d4"; font.pixelSize: 9; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dash.refreshPorts()
                                }
                            }
                        }

                        // Available ports list
                        Repeater {
                            id: portRepeater
                            model: {
                                try { return dash ? JSON.parse(dash.availablePorts) : [] }
                                catch(e) { return [] }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40; radius: 6
                                color: (dash && dash.serialPort === modelData.device) ? "#052e16" : "#1e293b"
                                border.color: (dash && dash.serialPort === modelData.device) ? "#22c55e" : "#334155"

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 8

                                    // USB icon
                                    Text {
                                        text: "\u2b58"
                                        font.pixelSize: 14
                                        color: (dash && dash.serialPort === modelData.device) ? "#22c55e" : "#94a3b8"
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.device
                                            color: (dash && dash.serialPort === modelData.device) ? "#22c55e" : "#f1f5f9"
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: "monospace"
                                        }
                                        Text {
                                            text: modelData.description
                                            color: "#475569"; font.pixelSize: 10
                                        }
                                    }

                                    Text {
                                        text: (dash && dash.serialPort === modelData.device) ? "ACTIVE" : ""
                                        color: "#22c55e"; font.pixelSize: 9; font.bold: true
                                        visible: dash && dash.serialPort === modelData.device
                                    }

                                    // Connect button
                                    Rectangle {
                                        width: 75; height: 24; radius: 4
                                        visible: !(dash && dash.serialPort === modelData.device)
                                        color: "#0f172a"; border.color: "#3b82f6"
                                        Text { anchors.centerIn: parent; text: "CONNECT"; color: "#3b82f6"; font.pixelSize: 9; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dash.changeSerialPort(modelData.device)
                                        }
                                    }
                                }
                            }
                        }

                        // No ports found message
                        Text {
                            visible: {
                                try {
                                    var ports = dash ? JSON.parse(dash.availablePorts) : []
                                    return ports.length === 0
                                } catch(e) { return true }
                            }
                            text: "No serial ports detected. Connect your ESP32 or USB-RS485 adapter."
                            color: "#475569"
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Baud rate selector
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Baud Rate"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: [
                                        { label: "9600", baud: 9600 },
                                        { label: "115200", baud: 115200 },
                                        { label: "256000", baud: 256000 }
                                    ]
                                    Rectangle {
                                        width: 60; height: 26; radius: 6
                                        color: (dash && dash.serialBaud === modelData.baud) ? "#06b6d4" : "#1e293b"
                                        border.color: "#334155"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: (dash && dash.serialBaud === modelData.baud) ? "#0a0e17" : "#94a3b8"
                                            font.pixelSize: 10
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dash.changeSerialBaud(modelData.baud)
                                        }
                                    }
                                }
                            }
                        }

                        // Supported devices info
                        Text {
                            text: "Supported: ESP32-S3, LilyGo T-CAN485, USB-RS485 (CP2102/CH340/FTDI)"
                            color: "#334155"; font.pixelSize: 10
                        }
                    }
                }

                // Timezone
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: tzCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: tzCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "TIME & TIMEZONE"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Current Time"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: dash ? dash.currentTime : "00:00:00"
                                color: "#f1f5f9"; font.pixelSize: 16; font.bold: true
                                font.family: "monospace"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Date"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: dash ? dash.currentDate : ""
                                color: "#f1f5f9"; font.pixelSize: 13
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Timezone"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: dash ? dash.timezoneName + " (GMT+" + dash.timezoneOffset.toFixed(0) + ")" : "---"
                                color: "#06b6d4"; font.pixelSize: 12; font.bold: true
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "Dubai +4", offset: 4.0 },
                                    { label: "Riyadh +3", offset: 3.0 },
                                    { label: "London 0", offset: 0.0 },
                                    { label: "Mumbai +5.5", offset: 5.5 },
                                    { label: "Tokyo +9", offset: 9.0 },
                                    { label: "NY -5", offset: -5.0 }
                                ]

                                Rectangle {
                                    width: 80; height: 26; radius: 6
                                    color: (dash && dash.timezoneOffset === modelData.offset) ? "#06b6d4" : "#1e293b"
                                    border.color: "#334155"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: (dash && dash.timezoneOffset === modelData.offset) ? "#0a0e17" : "#94a3b8"
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dash.setTimezone(modelData.offset)
                                    }
                                }
                            }
                        }
                    }
                }

                // Data Logging
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sdCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: sdCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "DATA LOGGING"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "CSV Data Logging"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 44; height: 22; radius: 11
                                color: (dash && dash.loggingEnabled) ? "#22c55e" : "#475569"
                                Rectangle {
                                    x: (dash && dash.loggingEnabled) ? parent.width - width - 3 : 3
                                    y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9"
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dash.toggleLogging()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Log Interval"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: ["1s", "5s", "10s"]
                                    Rectangle {
                                        width: 40; height: 26; radius: 6
                                        color: index === 0 ? "#06b6d4" : "#1e293b"
                                        border.color: "#334155"
                                        Text { anchors.centerIn: parent; text: modelData; color: index === 0 ? "#0a0e17" : "#94a3b8"; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Log Location: ~/DashOS/logs/"
                            color: "#475569"
                            font.pixelSize: 11
                        }

                        Text {
                            text: "Disk Free: " + (dash ? dash.sdFreeGb.toFixed(1) : "---") + " GB / " + (dash ? dash.sdTotalGb.toFixed(0) : "---") + " GB"
                            color: (dash && dash.sdFreeGb < 10) ? "#ef4444" : "#475569"
                            font.pixelSize: 11
                        }
                    }
                }

                // System Info
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sysCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: sysCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "SYSTEM"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }
                        Text { text: "DashOS Desktop v1.0.0"; color: "#94a3b8"; font.pixelSize: 12 }
                        Text {
                            text: "Serial: " + (dash ? (dash.serialConnected ? dash.serialPort + " (" + dash.serialBaud + " baud)" : "Not connected") : "---")
                            color: (dash && dash.serialConnected) ? "#22c55e" : "#94a3b8"
                            font.pixelSize: 12
                        }
                        Text { text: "Uptime: " + (dash ? dash.uptime : "00:00:00"); color: "#94a3b8"; font.pixelSize: 12 }
                        Text {
                            text: "Platform: " + Qt.platform.os
                            color: "#475569"; font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
