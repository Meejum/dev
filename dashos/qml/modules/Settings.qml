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

                // Display
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: displayCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: displayCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "DISPLAY"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Brightness"; color: "#94a3b8"; font.pixelSize: 13 }
                            Slider {
                                Layout.fillWidth: true
                                from: 10; to: 100; value: 80; stepSize: 5
                                background: Rectangle { width: parent.availableWidth; height: 4; radius: 2; color: "#1e293b"; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                    Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: "#06b6d4" }
                                }
                                handle: Rectangle { x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: parent.topPadding + parent.availableHeight / 2 - height / 2; width: 18; height: 18; radius: 9; color: "#f1f5f9" }
                            }
                            Text { text: "80%"; color: "#f1f5f9"; font.pixelSize: 13 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Auto-dim at night"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Switch {
                                checked: true
                                indicator: Rectangle {
                                    width: 44; height: 22; radius: 11
                                    color: parent.checked ? "#22c55e" : "#475569"
                                    Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9" }
                                }
                            }
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

                        // Timezone quick-select buttons
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

                // WiFi with scan
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: wifiCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: wifiCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "WIFI"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }
                            Item { Layout.fillWidth: true }
                            // Scan button
                            Rectangle {
                                width: 70; height: 24; radius: 6
                                color: (dash && dash.wifiScanning) ? "#334155" : "#1e293b"
                                border.color: "#06b6d4"
                                Text {
                                    anchors.centerIn: parent
                                    text: (dash && dash.wifiScanning) ? "SCANNING" : "SCAN"
                                    color: "#06b6d4"; font.pixelSize: 9; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dash ? !dash.wifiScanning : true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    onClicked: dash.scanWifi()
                                }
                            }
                            Switch {
                                checked: dash ? dash.wifiConnected : false
                                indicator: Rectangle { width: 44; height: 22; radius: 11; color: parent.checked ? "#22c55e" : "#475569"
                                    Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9" } }
                            }
                        }

                        // Connected network
                        RowLayout {
                            Layout.fillWidth: true
                            visible: dash ? dash.wifiConnected : false
                            Text { text: "Connected:"; color: "#94a3b8"; font.pixelSize: 12 }
                            Text { text: dash ? dash.wifiConnectedName : ""; color: "#22c55e"; font.pixelSize: 12; font.bold: true }
                        }

                        // WiFi scan results
                        Repeater {
                            model: {
                                try { return dash ? JSON.parse(dash.wifiList) : [] }
                                catch(e) { return [] }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36; radius: 6
                                color: modelData.connected ? "#052e16" : "#1e293b"
                                border.color: modelData.connected ? "#22c55e" : "#334155"

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 8

                                    // Signal strength icon
                                    Text {
                                        text: modelData.signal > -60 ? "\u2588\u2587\u2586\u2585" :
                                              modelData.signal > -75 ? "\u2588\u2587\u2586" :
                                              modelData.signal > -85 ? "\u2588\u2587" : "\u2588"
                                        color: modelData.signal > -60 ? "#22c55e" : modelData.signal > -75 ? "#f59e0b" : "#ef4444"
                                        font.pixelSize: 8
                                    }

                                    Text {
                                        text: modelData.ssid
                                        color: modelData.connected ? "#22c55e" : "#f1f5f9"
                                        font.pixelSize: 12
                                        font.bold: modelData.connected
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.secured ? "\ud83d\udd12" : ""
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        text: modelData.connected ? "CONNECTED" : ""
                                        color: "#22c55e"; font.pixelSize: 9; font.bold: true
                                        visible: modelData.connected
                                    }

                                    // Connect button
                                    Rectangle {
                                        width: 65; height: 22; radius: 4
                                        visible: !modelData.connected
                                        color: "#0f172a"; border.color: "#3b82f6"
                                        Text { anchors.centerIn: parent; text: "CONNECT"; color: "#3b82f6"; font.pixelSize: 8; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dash.connectWifi(modelData.ssid)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Bluetooth with scan
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: btCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: btCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "BLUETOOTH"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 70; height: 24; radius: 6
                                color: (dash && dash.btScanning) ? "#334155" : "#1e293b"
                                border.color: "#06b6d4"
                                Text {
                                    anchors.centerIn: parent
                                    text: (dash && dash.btScanning) ? "SCANNING" : "SCAN"
                                    color: "#06b6d4"; font.pixelSize: 9; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dash ? !dash.btScanning : true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    onClicked: dash.scanBluetooth()
                                }
                            }
                            Switch {
                                checked: dash ? dash.btConnected : false
                                indicator: Rectangle { width: 44; height: 22; radius: 11; color: parent.checked ? "#22c55e" : "#475569"
                                    Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9" } }
                            }
                        }

                        // Connected device
                        RowLayout {
                            Layout.fillWidth: true
                            visible: dash ? dash.btConnected : false
                            Text { text: "Paired:"; color: "#94a3b8"; font.pixelSize: 12 }
                            Text { text: dash ? dash.btConnectedName : ""; color: "#22c55e"; font.pixelSize: 12; font.bold: true }
                        }

                        // Meshtastic
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Meshtastic"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text { text: "BLE: Heltec V3"; color: "#22c55e"; font.pixelSize: 12 }
                        }

                        // Bluetooth scan results
                        Repeater {
                            model: {
                                try { return dash ? JSON.parse(dash.btList) : [] }
                                catch(e) { return [] }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36; radius: 6
                                color: modelData.connected ? "#052e16" : "#1e293b"
                                border.color: modelData.connected ? "#22c55e" : "#334155"

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 8

                                    // Device type icon
                                    Text {
                                        text: modelData.type === "audio" ? "\ud83d\udd0a" :
                                              modelData.type === "phone" ? "\ud83d\udcf1" :
                                              modelData.type === "obd" ? "\ud83d\ude97" : "\u2b1b"
                                        font.pixelSize: 14
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.name
                                            color: modelData.connected ? "#22c55e" : "#f1f5f9"
                                            font.pixelSize: 12
                                            font.bold: modelData.connected
                                        }
                                        Text {
                                            text: modelData.addr
                                            color: "#475569"; font.pixelSize: 8
                                            font.family: "monospace"
                                        }
                                    }

                                    Text {
                                        text: modelData.connected ? "PAIRED" : ""
                                        color: "#22c55e"; font.pixelSize: 9; font.bold: true
                                        visible: modelData.connected
                                    }

                                    Rectangle {
                                        width: 55; height: 22; radius: 4
                                        visible: !modelData.connected
                                        color: "#0f172a"; border.color: "#3b82f6"
                                        Text { anchors.centerIn: parent; text: "PAIR"; color: "#3b82f6"; font.pixelSize: 8; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dash.connectBluetooth(modelData.addr)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // SD Card & Logging
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
                            Text { text: "SD Card Logging"; color: "#94a3b8"; font.pixelSize: 13 }
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
                            text: "SD Free Space: " + (dash ? dash.sdFreeGb.toFixed(1) : "---") + " GB / " + (dash ? dash.sdTotalGb.toFixed(1) : "---") + " GB"
                            color: (dash && dash.sdFreeGb < 10) ? "#ef4444" : "#475569"
                            font.pixelSize: 11
                        }
                    }
                }

                // Software Update
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: updateCol.implicitHeight + 24
                    color: "#111827"; radius: 12
                    border.color: (dash && dash.updateAvailable) ? "#3b82f6" : "#334155"
                    border.width: (dash && dash.updateAvailable) ? 2 : 1

                    ColumnLayout {
                        id: updateCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "SOFTWARE UPDATE"; color: "#3b82f6"; font.pixelSize: 13; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                visible: dash ? dash.updateAvailable : false
                                width: 70; height: 20; radius: 10
                                color: "#1e3a5f"; border.color: "#3b82f6"
                                Text { anchors.centerIn: parent; text: "NEW"; color: "#60a5fa"; font.pixelSize: 9; font.bold: true }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: dash ? dash.updateStatus : "Not checked"
                            color: (dash && dash.updateAvailable) ? "#60a5fa" : "#94a3b8"
                            font.pixelSize: 12; wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 130; height: 32; radius: 8
                                color: (dash && dash.updateInProgress) ? "#334155" : "#1e293b"
                                border.color: "#3b82f6"
                                opacity: (dash && dash.updateInProgress) ? 0.5 : 1.0
                                Text { anchors.centerIn: parent; text: (dash && dash.updateInProgress) ? "CHECKING..." : "CHECK UPDATE"; color: "#3b82f6"; font.pixelSize: 11; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dash ? !dash.updateInProgress : true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    onClicked: dash.checkForUpdates()
                                }
                            }

                            Rectangle {
                                width: 130; height: 32; radius: 8
                                visible: dash ? dash.updateAvailable : false
                                color: "#052e16"; border.color: "#22c55e"
                                Text { anchors.centerIn: parent; text: "INSTALL UPDATE"; color: "#22c55e"; font.pixelSize: 11; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dash ? (!dash.updateInProgress && dash.updateAvailable) : false
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    onClicked: dash.applyUpdate()
                                }
                            }
                        }
                    }
                }

                // System
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sysCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: sysCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "SYSTEM"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }
                        Text { text: "DashOS v1.0.0"; color: "#94a3b8"; font.pixelSize: 12 }
                        Text { text: "ESP32 Bridge: Connected (115200 baud)"; color: "#22c55e"; font.pixelSize: 12 }
                        Text { text: "Uptime: " + (dash ? dash.uptime : "00:00:00"); color: "#94a3b8"; font.pixelSize: 12 }

                        RowLayout {
                            spacing: 12
                            Rectangle {
                                width: 80; height: 32; radius: 8; color: "#1e293b"; border.color: "#f59e0b"
                                Text { anchors.centerIn: parent; text: "REBOOT"; color: "#f59e0b"; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                            }
                            Rectangle {
                                width: 100; height: 32; radius: 8; color: "#450a0a"; border.color: "#ef4444"
                                Text { anchors.centerIn: parent; text: "SHUTDOWN"; color: "#ef4444"; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
        }
    }
}
