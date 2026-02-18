import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dataRow

    property string label: "LABEL"
    property string value: "--"
    property color valueColor: "#f1f5f9"

    Layout.fillWidth: true
    implicitHeight: 36
    color: "#1e293b"
    opacity: 0.6
    radius: 8

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
            text: dataRow.label
            color: "#94a3b8"
            font.pixelSize: 13
        }
        Item { Layout.fillWidth: true }
        Text {
            text: dataRow.value
            color: dataRow.valueColor
            font.pixelSize: 15
            font.bold: true
        }
    }
}
