import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: meshPage

    property int activeTab: 0  // 0 = Messages, 1 = Nodes

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header with tabs
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "\ud83d\udce1 MESHTASTIC"
                color: "#22c55e"
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }

            // Tab buttons
            Row {
                spacing: 6
                Rectangle {
                    width: 90; height: 30; radius: 8
                    color: activeTab === 0 ? "#22c55e" : "#1e293b"
                    border.color: "#334155"
                    Text {
                        anchors.centerIn: parent
                        text: "MESSAGES"
                        color: activeTab === 0 ? "#0a0e17" : "#94a3b8"
                        font.pixelSize: 10; font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: activeTab = 0; cursorShape: Qt.PointingHandCursor }
                }
                Rectangle {
                    width: 70; height: 30; radius: 8
                    color: activeTab === 1 ? "#22c55e" : "#1e293b"
                    border.color: "#334155"
                    Text {
                        anchors.centerIn: parent
                        text: "NODES"
                        color: activeTab === 1 ? "#0a0e17" : "#94a3b8"
                        font.pixelSize: 10; font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: activeTab = 1; cursorShape: Qt.PointingHandCursor }
                }
            }

            Rectangle {
                width: 12; height: 12; radius: 6
                color: "#22c55e"
            }
            Text {
                text: "Heltec V3"
                color: "#94a3b8"
                font.pixelSize: 12
            }
        }

        // ── MESSAGES TAB ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: activeTab === 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

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
                            ListElement { sender: "NodeB-bravo"; msg: "Weather looks clear ahead, 35\u00b0C"; time: "14:35"; isLocal: false }
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

                // Preset quick messages
                Row {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { text: "\u26fd Fuel stop", msg: "Fuel stop needed" },
                            { text: "\u26a0 Slowing", msg: "Slowing down" },
                            { text: "\u2b05 Turn left", msg: "Turning left ahead" },
                            { text: "\u2705 Copy that", msg: "Copy that" },
                            { text: "\ud83c\udfc1 Arrived", msg: "Arrived at destination" }
                        ]

                        Rectangle {
                            width: (meshPage.width - 60) / 5
                            height: 32
                            radius: 8
                            color: "#1e293b"
                            border.color: "#334155"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                color: "#94a3b8"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    messagesModel.append({
                                        sender: "You",
                                        msg: modelData.msg,
                                        time: Qt.formatTime(new Date(), "HH:mm"),
                                        isLocal: true
                                    })
                                    messageList.positionViewAtEnd()
                                    if (dash) dash.sendMeshPreset(modelData.msg)
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
        }

        // ── NODES TAB ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: activeTab === 1

            Rectangle {
                anchors.fill: parent
                color: "#111827"
                radius: 12
                border.color: "#334155"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Table header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: "#1e293b"
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text { text: "NODE"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 140 }
                            Text { text: "SNR"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 60 }
                            Text { text: "RSSI"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 60 }
                            Text { text: "BATT"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 80 }
                            Text { text: "LAST HEARD"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 80 }
                            Text { text: "POSITION"; color: "#94a3b8"; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true }
                        }
                    }

                    // Node list
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: nodeListModel

                        delegate: Rectangle {
                            width: ListView.view ? ListView.view.width : 0
                            height: 40
                            radius: 6
                            color: index % 2 === 0 ? "transparent" : "#0f172a"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                // Node name
                                Row {
                                    Layout.preferredWidth: 140
                                    spacing: 6
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: model.lastHeard === "now" ? "#22c55e" :
                                               model.lastHeard.indexOf("s") >= 0 ? "#22c55e" :
                                               model.lastHeard.indexOf("2m") >= 0 ? "#f59e0b" : "#ef4444"
                                    }
                                    Text {
                                        text: model.nodeId
                                        color: "#f1f5f9"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        width: 126
                                    }
                                }

                                // SNR
                                Text {
                                    Layout.preferredWidth: 60
                                    text: model.snr.toFixed(1) + " dB"
                                    color: model.snr > 5 ? "#22c55e" : model.snr > 0 ? "#f59e0b" : "#ef4444"
                                    font.pixelSize: 11
                                }

                                // RSSI
                                Text {
                                    Layout.preferredWidth: 60
                                    text: model.rssi + " dBm"
                                    color: model.rssi > -80 ? "#22c55e" : model.rssi > -100 ? "#f59e0b" : "#ef4444"
                                    font.pixelSize: 11
                                }

                                // Battery bar
                                Row {
                                    Layout.preferredWidth: 80
                                    spacing: 4
                                    Rectangle {
                                        width: 40; height: 10; radius: 3; color: "#0f172a"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Rectangle {
                                            width: parent.width * Math.min(model.battery / 100, 1.0)
                                            height: parent.height; radius: 3
                                            color: model.battery > 50 ? "#22c55e" : model.battery > 20 ? "#f59e0b" : "#ef4444"
                                        }
                                    }
                                    Text {
                                        text: model.battery + "%"
                                        color: "#94a3b8"
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Last heard
                                Text {
                                    Layout.preferredWidth: 80
                                    text: model.lastHeard
                                    color: "#94a3b8"
                                    font.pixelSize: 11
                                }

                                // Position
                                Text {
                                    Layout.fillWidth: true
                                    text: model.lat.toFixed(3) + "\u00b0, " + model.lon.toFixed(3) + "\u00b0"
                                    color: "#475569"
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Node list model (parsed from JSON)
    ListModel { id: nodeListModel }

    // Parse node list JSON when it changes
    Connections {
        target: dash
        function onNodeListJsonChanged() {
            updateNodeList()
        }
    }

    Component.onCompleted: updateNodeList()

    function updateNodeList() {
        if (!dash) return
        try {
            var nodes = JSON.parse(dash.nodeListJson)
            nodeListModel.clear()
            for (var i = 0; i < nodes.length; i++) {
                nodeListModel.append({
                    nodeId: nodes[i].id || "Unknown",
                    snr: nodes[i].snr || 0,
                    rssi: nodes[i].rssi || 0,
                    battery: nodes[i].battery || 0,
                    lastHeard: nodes[i].lastHeard || "---",
                    lat: nodes[i].lat || 0,
                    lon: nodes[i].lon || 0
                })
            }
        } catch (e) {}
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
        if (dash) dash.sendMeshPreset(msgInput.text)
        msgInput.text = ""
    }
}
