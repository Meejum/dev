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
            text: "▶ MEDIA & CONNECTIVITY"
            color: "#f59e0b"
            font.pixelSize: 16
            font.bold: true
        }

        // Media tiles
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
                    spacing: 12
                    Text { text: "🚗"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "CarPlay"; color: "#f1f5f9"; font.pixelSize: 18; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Connect iPhone via USB\nor WiFi to start"; color: "#94a3b8"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 120; height: 36; radius: 8
                        color: "#1e293b"; border.color: "#3b82f6"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "CONNECT"; color: "#3b82f6"; font.pixelSize: 12; font.bold: true }
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
                    spacing: 12
                    Text { text: "📺"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "YouTube"; color: "#f1f5f9"; font.pixelSize: 18; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Requires WiFi connection\nStream or play downloaded"; color: "#94a3b8"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 120; height: 36; radius: 8
                        color: "#1e293b"; border.color: "#ef4444"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "OPEN"; color: "#ef4444"; font.pixelSize: 12; font.bold: true }
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
                    spacing: 12
                    Text { text: "🔊"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Bluetooth Audio"; color: "#f1f5f9"; font.pixelSize: 18; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "A2DP source to car stereo\nStream audio wirelessly"; color: "#94a3b8"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 120; height: 36; radius: 8
                        color: "#1e293b"; border.color: "#3b82f6"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "PAIR"; color: "#3b82f6"; font.pixelSize: 12; font.bold: true }
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
                    spacing: 12
                    Text { text: "🗺"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Offline Maps"; color: "#f1f5f9"; font.pixelSize: 18; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "OpenStreetMap navigation\nWorks without internet"; color: "#94a3b8"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                    Rectangle {
                        width: 120; height: 36; radius: 8
                        color: "#1e293b"; border.color: "#22c55e"
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text { anchors.centerIn: parent; text: "NAVIGATE"; color: "#22c55e"; font.pixelSize: 12; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}
