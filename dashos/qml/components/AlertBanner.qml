import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: alertBanner

    property string alertText: ""
    property string severity: ""  // "critical" or "warning"
    property bool alertVisible: false

    signal dismissed()

    visible: alertVisible
    height: alertVisible ? 56 : 0
    color: severity === "critical" ? "#7f1d1d" : "#78350f"
    border.color: severity === "critical" ? "#ef4444" : "#f59e0b"
    border.width: 2
    radius: 12

    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Pulse animation for critical alerts
    SequentialAnimation on opacity {
        running: severity === "critical" && alertVisible
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.7; duration: 600 }
        NumberAnimation { from: 0.7; to: 1.0; duration: 600 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 12

        // Alert icon
        Text {
            text: severity === "critical" ? "\u26a0" : "\u26a0"
            font.pixelSize: 22
            color: severity === "critical" ? "#ef4444" : "#f59e0b"
        }

        // Alert text
        Text {
            Layout.fillWidth: true
            text: alertBanner.alertText
            color: "#f1f5f9"
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Dismiss button
        Rectangle {
            width: 80
            height: 32
            radius: 8
            color: severity === "critical" ? "#991b1b" : "#92400e"
            border.color: severity === "critical" ? "#ef4444" : "#f59e0b"

            Text {
                anchors.centerIn: parent
                text: "DISMISS"
                color: "#f1f5f9"
                font.pixelSize: 10
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: alertBanner.dismissed()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
