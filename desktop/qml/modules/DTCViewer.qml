import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: dtcPage

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header with action buttons
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "⚠ DIAGNOSTIC TROUBLE CODES"
                color: "#f59e0b"
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                width: 100; height: 34; radius: 8
                color: "#1e293b"; border.color: "#06b6d4"
                Text { anchors.centerIn: parent; text: "READ DTCs"; color: "#06b6d4"; font.pixelSize: 11; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: dash.scanDTC(); cursorShape: Qt.PointingHandCursor }
            }
            Rectangle {
                width: 110; height: 34; radius: 8
                color: "#450a0a"; border.color: "#ef4444"
                Text { anchors.centerIn: parent; text: "CLEAR DTCs"; color: "#ef4444"; font.pixelSize: 11; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: dash.clearDTC(); cursorShape: Qt.PointingHandCursor }
            }
        }

        // MIL Status
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#111827"
            radius: 10
            border.color: "#334155"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 20

                Row {
                    spacing: 8
                    Rectangle { width: 14; height: 14; radius: 7; color: "#ef4444"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "MIL: ON"; color: "#ef4444"; font.pixelSize: 14; font.bold: true }
                }
                Text { text: "DTC Count: 3"; color: "#94a3b8"; font.pixelSize: 13 }
                Text { text: "Freeze Frame: Available"; color: "#94a3b8"; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
            }
        }

        // DTC List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111827"
            radius: 12
            border.color: "#334155"

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6

                model: ListModel {
                    ListElement { code: "P0301"; desc: "Cylinder 1 Misfire Detected"; severity: "high" }
                    ListElement { code: "P0420"; desc: "Catalyst Efficiency Below Threshold (Bank 1)"; severity: "medium" }
                    ListElement { code: "P0171"; desc: "System Too Lean (Bank 1)"; severity: "medium" }
                }

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 0
                    height: 60
                    radius: 8
                    color: severity === "high" ? "#1c0a0a" : "#1a1503"
                    border.color: severity === "high" ? "#991b1b" : "#92400e"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16

                        // Code badge
                        Rectangle {
                            width: 70; height: 30; radius: 6
                            color: severity === "high" ? "#450a0a" : "#451a03"
                            Text {
                                anchors.centerIn: parent
                                text: code
                                color: severity === "high" ? "#ef4444" : "#f59e0b"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "monospace"
                            }
                        }

                        // Description
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: desc
                                color: "#f1f5f9"
                                font.pixelSize: 13
                            }
                            Text {
                                text: severity === "high" ? "Severity: HIGH — Immediate attention needed" : "Severity: MEDIUM — Monitor and service soon"
                                color: severity === "high" ? "#ef4444" : "#f59e0b"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
