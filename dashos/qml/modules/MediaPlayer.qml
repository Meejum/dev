import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: mediaPage

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header
        Text {
            text: "\u25b6 MEDIA & CONNECTIVITY"
            color: "#f59e0b"
            font.pixelSize: 16
            font.bold: true
        }

        // ── NOW PLAYING CARD ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: "#111827"
            radius: 16
            border.color: (dash && dash.isPlaying) ? "#1e5a8a" : "#334155"
            border.width: 1
            visible: dash ? dash.isPlaying : false

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Album art placeholder
                Rectangle {
                    width: 68; height: 68; radius: 12
                    color: "#1e293b"

                    Text {
                        anchors.centerIn: parent
                        text: "\ud83c\udfb5"
                        font.pixelSize: 32
                    }
                }

                // Track info + controls
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    // Title + artist
                    Text {
                        text: dash ? dash.trackTitle : ""
                        color: "#f1f5f9"
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: dash ? dash.trackArtist : ""
                        color: "#94a3b8"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Progress bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: {
                                if (!dash) return "0:00"
                                var total = 368  // demo track length
                                var elapsed = Math.floor(dash.trackProgress * total)
                                return Math.floor(elapsed / 60) + ":" + (elapsed % 60 < 10 ? "0" : "") + (elapsed % 60)
                            }
                            color: "#475569"
                            font.pixelSize: 10
                            font.family: "monospace"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: "#1e293b"

                            Rectangle {
                                width: parent.width * (dash ? dash.trackProgress : 0)
                                height: parent.height
                                radius: 3
                                color: "#3b82f6"
                            }
                        }

                        Text {
                            text: dash ? dash.trackDuration : "0:00"
                            color: "#475569"
                            font.pixelSize: 10
                            font.family: "monospace"
                        }
                    }
                }

                // Playback controls
                Row {
                    spacing: 12

                    Repeater {
                        model: [
                            { icon: "\u23ee", size: 20 },
                            { icon: "\u23f8", size: 26 },
                            { icon: "\u23ed", size: 20 }
                        ]

                        Rectangle {
                            width: modelData.size + 16
                            height: modelData.size + 16
                            radius: (modelData.size + 16) / 2
                            color: "#1e293b"
                            border.color: "#334155"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: modelData.size
                                color: "#f1f5f9"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }

        // ── CONNECTION TILES ──
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            // CarPlay tile
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111827"
                radius: 16
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "\ud83d\ude97"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "CarPlay"; color: "#f1f5f9"; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Connect iPhone via USB\nor WiFi to start"; color: "#94a3b8"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 110; height: 32; radius: 8
                        color: "#1e293b"; border.color: "#3b82f6"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "CONNECT"; color: "#3b82f6"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // YouTube tile
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111827"
                radius: 16
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "\ud83d\udcfa"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "YouTube"; color: "#f1f5f9"; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Requires WiFi connection\nStream or play downloaded"; color: "#94a3b8"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 110; height: 32; radius: 8
                        color: "#1e293b"; border.color: "#ef4444"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "OPEN"; color: "#ef4444"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // Bluetooth Audio tile
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111827"
                radius: 16
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "\ud83d\udd0a"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Bluetooth Audio"; color: "#f1f5f9"; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "A2DP source to car stereo\nStream audio wirelessly"; color: "#94a3b8"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 110; height: 32; radius: 8
                        color: "#1e293b"; border.color: "#3b82f6"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "PAIR"; color: "#3b82f6"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // Maps tile
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111827"
                radius: 16
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { text: "\ud83d\uddfa"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Offline Maps"; color: "#f1f5f9"; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "OpenStreetMap navigation\nWorks without internet"; color: "#94a3b8"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 110; height: 32; radius: 8
                        color: "#1e293b"; border.color: "#22c55e"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "NAVIGATE"; color: "#22c55e"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}
