import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: meshPage

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "📡 MESHTASTIC"
                color: "#22c55e"
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 12; height: 12; radius: 6
                color: "#22c55e"
            }
            Text {
                text: "Connected: Heltec V3"
                color: "#94a3b8"
                font.pixelSize: 12
            }
        }

        // Message list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111827"
            radius: 12
            border.color: "#334155"

            ListView {
                id: messageList
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6

                model: ListModel {
                    id: messagesModel
                    ListElement { sender: "NodeA-alpha"; msg: "Hey convoy, turn left at exit 5"; time: "14:32"; isLocal: false }
                    ListElement { sender: "You"; msg: "Copy that, right behind you"; time: "14:33"; isLocal: true }
                    ListElement { sender: "NodeB-bravo"; msg: "Weather looks clear ahead, 35°C"; time: "14:35"; isLocal: false }
                    ListElement { sender: "NodeC-charlie"; msg: "Rest stop in 20km, fuel getting low"; time: "14:38"; isLocal: false }
                    ListElement { sender: "You"; msg: "Roger, let's stop there"; time: "14:39"; isLocal: true }
                }

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 0
                    height: msgCol.implicitHeight + 16
                    radius: 10
                    color: isLocal ? "#0c2d48" : "#1e293b"
                    border.color: isLocal ? "#1e5a8a" : "#334155"
                    border.width: 1

                    Column {
                        id: msgCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: sender
                                color: isLocal ? "#06b6d4" : "#f59e0b"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: time
                                color: "#475569"
                                font.pixelSize: 10
                            }
                        }
                        Text {
                            text: msg
                            color: "#f1f5f9"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }

        // Message input
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#1e293b"
                radius: 10
                border.color: "#334155"

                TextInput {
                    id: msgInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#f1f5f9"
                    font.pixelSize: 14
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Type message..."
                        color: "#475569"
                        font.pixelSize: 14
                        visible: !msgInput.text && !msgInput.activeFocus
                    }

                    Keys.onReturnPressed: sendMessage()
                }
            }

            Rectangle {
                width: 70; height: 40; radius: 10
                color: "#22c55e"
                Text {
                    anchors.centerIn: parent
                    text: "SEND"
                    color: "#0a0e17"
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: sendMessage()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    function sendMessage() {
        if (msgInput.text.trim().length === 0) return
        messagesModel.append({
            sender: "You",
            msg: msgInput.text,
            time: Qt.formatTime(new Date(), "HH:mm"),
            isLocal: true
        })
        messageList.positionViewAtEnd()
        msgInput.text = ""
    }
}
