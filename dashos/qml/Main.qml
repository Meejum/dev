import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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
                    text: "⚡"
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
                        { icon: "🏎", label: "DASH", page: 0 },
                        { icon: "🔍", label: "OBD2", page: 1 },
                        { icon: "📡", label: "MESH", page: 2 },
                        { icon: "⚠", label: "DTC", page: 3 },
                        { icon: "▶", label: "MEDIA", page: 4 },
                        { icon: "⚙", label: "SET", page: 5 }
                    ]

                    delegate: Rectangle {
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 58
                        Layout.alignment: Qt.AlignHCenter
                        radius: 12
                        color: stackView.currentIndex === modelData.page ? cSurface : "transparent"
                        border.color: stackView.currentIndex === modelData.page ? cBorder : "transparent"
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            onClicked: stackView.currentIndex = modelData.page
                            cursorShape: Qt.PointingHandCursor
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
                    }
                }

                Item { Layout.fillHeight: true }

                // Status indicators
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: dash.canOk ? cGreen : cMuted
                    }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: dash.rs485Ok ? cGreen : cMuted
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: dash.uptime
                    font.pixelSize: 8
                    color: cMuted
                }
            }
        }

        // ── MAIN CONTENT ───────────────────────────────
        StackLayout {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true

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
    }
}
