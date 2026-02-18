import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: gauge

    property string label: "GAUGE"
    property string unit: ""
    property int value: 0
    property int maxValue: 100
    property color arcColor: "#06b6d4"

    readonly property real percentage: maxValue > 0 ? Math.min(value / maxValue, 1.0) : 0

    implicitWidth: 130
    implicitHeight: 150

    Column {
        anchors.centerIn: parent
        spacing: 4

        // Arc gauge (drawn with Canvas)
        Item {
            width: 110
            height: 110
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: arcCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()

                    var cx = width / 2
                    var cy = height / 2
                    var r = Math.min(cx, cy) - 8
                    var startAngle = 0.75 * Math.PI  // 135 degrees
                    var endAngle = 2.25 * Math.PI    // 405 degrees
                    var valueAngle = startAngle + (endAngle - startAngle) * gauge.percentage

                    // Background arc
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, endAngle, false)
                    ctx.lineWidth = 8
                    ctx.strokeStyle = "#1e293b"
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // Value arc
                    if (gauge.percentage > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, valueAngle, false)
                        ctx.lineWidth = 8
                        ctx.strokeStyle = gauge.arcColor
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                }

                Connections {
                    target: gauge
                    function onPercentageChanged() { arcCanvas.requestPaint() }
                }

                Component.onCompleted: requestPaint()
            }

            // Center value
            Text {
                anchors.centerIn: parent
                text: gauge.value
                color: "#f1f5f9"
                font.pixelSize: 24
                font.bold: true
            }
        }

        // Label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.label + (gauge.unit ? " " + gauge.unit : "")
            color: "#94a3b8"
            font.pixelSize: 11
        }
    }
}
