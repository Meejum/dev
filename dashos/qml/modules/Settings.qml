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
            text: "⚙ SETTINGS"
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

                // Connectivity
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: connCol.implicitHeight + 24
                    color: "#111827"; radius: 12; border.color: "#334155"

                    ColumnLayout {
                        id: connCol
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Text { text: "CONNECTIVITY"; color: "#06b6d4"; font.pixelSize: 13; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "WiFi"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text { text: "Connected: MyHotspot"; color: "#22c55e"; font.pixelSize: 12 }
                            Switch {
                                checked: true
                                indicator: Rectangle { width: 44; height: 22; radius: 11; color: parent.checked ? "#22c55e" : "#475569"
                                    Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9" } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Bluetooth"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text { text: "Paired: CarStereo-BT"; color: "#22c55e"; font.pixelSize: 12 }
                            Switch {
                                checked: true
                                indicator: Rectangle { width: 44; height: 22; radius: 11; color: parent.checked ? "#22c55e" : "#475569"
                                    Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f1f5f9" } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Meshtastic"; color: "#94a3b8"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Text { text: "BLE: Heltec V3"; color: "#22c55e"; font.pixelSize: 12 }
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
                            // Logging toggle
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
                            // Update badge
                            Rectangle {
                                visible: dash ? dash.updateAvailable : false
                                width: 70; height: 20; radius: 10
                                color: "#1e3a5f"
                                border.color: "#3b82f6"
                                Text {
                                    anchors.centerIn: parent
                                    text: "NEW"
                                    color: "#60a5fa"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        // Status text
                        Text {
                            Layout.fillWidth: true
                            text: dash ? dash.updateStatus : "Not checked"
                            color: (dash && dash.updateAvailable) ? "#60a5fa" : "#94a3b8"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        // Update log (visible during/after update)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 6
                            color: "#0f172a"
                            visible: dash ? (dash.updateInProgress || dash.updateLog !== "") : false

                            Text {
                                anchors.fill: parent; anchors.margins: 8
                                text: dash ? dash.updateLog : ""
                                color: "#94a3b8"
                                font.pixelSize: 10
                                font.family: "monospace"
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 3
                            }
                        }

                        // Action buttons
                        RowLayout {
                            spacing: 10

                            // Check for updates
                            Rectangle {
                                width: 130; height: 32; radius: 8
                                color: (dash && dash.updateInProgress) ? "#334155" : "#1e293b"
                                border.color: "#3b82f6"
                                opacity: (dash && dash.updateInProgress) ? 0.5 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: (dash && dash.updateInProgress) ? "CHECKING..." : "CHECK UPDATE"
                                    color: "#3b82f6"; font.pixelSize: 11; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: dash ? !dash.updateInProgress : true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                    onClicked: dash.checkForUpdates()
                                }
                            }

                            // Install update (only visible when update available)
                            Rectangle {
                                width: 130; height: 32; radius: 8
                                visible: dash ? dash.updateAvailable : false
                                color: (dash && dash.updateInProgress) ? "#334155" : "#052e16"
                                border.color: "#22c55e"
                                opacity: (dash && dash.updateInProgress) ? 0.5 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: (dash && dash.updateInProgress) ? "UPDATING..." : "INSTALL UPDATE"
                                    color: "#22c55e"; font.pixelSize: 11; font.bold: true
                                }
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
