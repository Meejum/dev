import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "DashOS"
    color: "#0a0e17"

    // Dark theme colors (matching ESP32 LVGL theme)
    readonly property color cBg: "#0a0e17"
    readonly property color cCard: "#111827"
    readonly property color cSurface: "#1e293b"
    readonly property color cBorder: "#334155"
    readonly property color cAccent: "#f59e0b"
    readonly property color cGreen: "#22c55e"
    readonly property color cRed: "#ef4444"
    readonly property color cBlue: "#3b82f6"
    readonly property color cCyan: "#06b6d4"
    readonly property color cText: "#f1f5f9"
    readonly property color cDim: "#94a3b8"
    readonly property color cMuted: "#475569"

    // Driving mode state
    readonly property bool isDriving: dash ? dash.drivingMode : false

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── SIDEBAR ────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 70
            Layout.fillHeight: true
            color: cCard

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 4

                // DashOS logo
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\u26a1"
                    font.pixelSize: 28
                    color: cAccent
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "DASH"
                    font.pixelSize: 9
                    font.bold: true
                    color: cAccent
                    font.letterSpacing: 2
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: cBorder; Layout.margins: 8 }

                // Module buttons
                Repeater {
                    model: [
                        { icon: "\ud83c\udfce", label: "DASH", page: 0 },
                        { icon: "\ud83d\udd0d", label: "OBD2", page: 1 },
                        { icon: "\ud83d\udce1", label: "MESH", page: 2 },
                        { icon: "\u26a0", label: "DTC", page: 3 },
                        { icon: "\u25b6", label: "MEDIA", page: 4 },
                        { icon: "\u2699", label: "SET", page: 5 }
                    ]

                    delegate: Rectangle {
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 58
                        Layout.alignment: Qt.AlignHCenter
                        radius: 12
                        color: stackView.currentIndex === modelData.page ? cSurface : "transparent"
                        border.color: stackView.currentIndex === modelData.page ? cBorder : "transparent"
                        border.width: 1

                        // Driving mode: dim Settings button
                        opacity: (isDriving && modelData.page === 5) ? 0.3 : 1.0

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Driving mode lockdown: block Settings at speed
                                if (isDriving && modelData.page === 5) return
                                stackView.currentIndex = modelData.page
                            }
                            cursorShape: (isDriving && modelData.page === 5) ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.pixelSize: 22
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: 8
                                font.bold: true
                                color: stackView.currentIndex === modelData.page ? cText : cDim
                                font.letterSpacing: 1
                            }
                        }

                        // Update notification badge on Settings icon
                        Rectangle {
                            visible: modelData.page === 5 && (dash ? dash.updateAvailable : false)
                            width: 10; height: 10; radius: 5
                            color: "#3b82f6"
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 4
                            anchors.rightMargin: 4

                            SequentialAnimation on opacity {
                                running: visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 800 }
                                NumberAnimation { to: 1.0; duration: 800 }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // HUD Mode button
                Rectangle {
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignHCenter
                    radius: 8
                    color: (dash && dash.hudMode) ? cAccent : cSurface
                    border.color: cBorder

                    Text {
                        anchors.centerIn: parent
                        text: "HUD"
                        font.pixelSize: 10
                        font.bold: true
                        color: (dash && dash.hudMode) ? cBg : cDim
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dash.toggleHUD()
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Driving mode indicator
                Rectangle {
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignHCenter
                    radius: 4
                    color: isDriving ? "#052e16" : "transparent"
                    border.color: isDriving ? "#166534" : "transparent"
                    visible: isDriving

                    Text {
                        anchors.centerIn: parent
                        text: "DRIVE"
                        font.pixelSize: 8
                        font.bold: true
                        color: cGreen
                    }
                }

                // Status indicators
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: dash && dash.canOk ? cGreen : cMuted
                    }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: dash && dash.rs485Ok ? cGreen : cMuted
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: dash ? dash.uptime : "00:00:00"
                    font.pixelSize: 8
                    color: cMuted
                }
            }
        }

        // ── MAIN CONTENT ───────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                id: stackView
                objectName: "stackView"
                anchors.fill: parent

                // Page 0: Dashboard
                Loader { source: "modules/Dashboard.qml" }
                // Page 1: OBD2 Scanner
                Loader { source: "modules/OBD2Scanner.qml" }
                // Page 2: Meshtastic
                Loader { source: "modules/Meshtastic.qml" }
                // Page 3: DTC Diagnostics
                Loader { source: "modules/DTCViewer.qml" }
                // Page 4: Media (CarPlay/YouTube)
                Loader { source: "modules/MediaPlayer.qml" }
                // Page 5: Settings
                Loader { source: "modules/Settings.qml" }
            }

            // ── ALERT BANNER OVERLAY ──
            AlertBanner {
                id: alertOverlay
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                z: 100

                alertText: dash ? dash.alertText : ""
                severity: dash ? dash.alertSeverity : ""
                alertVisible: dash ? dash.alertVisible : false

                onDismissed: dash.dismissAlert()
            }

            // ── HUD MODE OVERLAY ──
            Rectangle {
                id: hudOverlay
                anchors.fill: parent
                z: 200
                visible: dash ? dash.hudMode : false
                color: "#000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: dash.toggleHUD()
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    // Speed — massive font
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dash ? dash.speed : "0"
                        font.pixelSize: 180
                        font.bold: true
                        color: "#ffffff"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "km/h"
                        font.pixelSize: 28
                        color: "#94a3b8"
                    }

                    Item { width: 1; height: 20 }

                    // RPM bar
                    Rectangle {
                        width: 500
                        height: 20
                        radius: 10
                        color: "#1e293b"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: parent.width * Math.min((dash ? dash.rpm : 0) / 8000, 1.0)
                            height: parent.height
                            radius: 10
                            color: (dash && dash.rpm > 6000) ? "#ef4444" : "#f59e0b"
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (dash ? dash.rpm : "0") + " RPM"
                        font.pixelSize: 20
                        color: "#94a3b8"
                    }
                }

                // Tap to exit hint
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 20
                    text: "TAP TO EXIT HUD"
                    font.pixelSize: 12
                    color: "#475569"
                }

                // GPS + time in HUD
                Row {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 20

                    Text {
                        text: {
                            var h = dash ? dash.gpsHeading : 0
                            var dirs = ["N","NE","E","SE","S","SW","W","NW"]
                            return dirs[Math.round(h / 45) % 8] + " " + Math.round(h) + "\u00b0"
                        }
                        font.pixelSize: 18
                        color: "#06b6d4"
                    }
                    Text {
                        text: dash ? dash.uptime : "00:00:00"
                        font.pixelSize: 18
                        color: "#475569"
                    }
                }

                // Fuel level in HUD
                Row {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "\u26fd"
                        font.pixelSize: 18
                    }
                    Text {
                        text: dash ? dash.fuelLevel.toFixed(0) + "%" : "---"
                        font.pixelSize: 18
                        color: (dash && dash.fuelLevel < 20) ? "#ef4444" : "#22c55e"
                        font.bold: true
                    }
                }
            }
        }
    }
}
