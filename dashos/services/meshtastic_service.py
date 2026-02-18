"""
Meshtastic Service — Communication with Heltec V3 LoRa node
Supports both BLE and USB serial connection to Meshtastic device.

Uses the official meshtastic Python API (pip install meshtastic)
"""

import threading
import time
from PySide6.QtCore import QObject, Signal, Slot, Property


class MeshMessage:
    """A single Meshtastic message"""
    def __init__(self, sender="", text="", timestamp=0, is_local=False):
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.is_local = is_local


class MeshtasticService(QObject):
    """Manages Meshtastic device communication"""

    message_received = Signal(str, str, int)  # sender, text, timestamp
    connection_changed = Signal(bool)
    node_count_changed = Signal(int)
    error = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._interface = None
        self._connected = False
        self._messages = []
        self._node_count = 0

    def connect_ble(self, address=None):
        """Connect to Meshtastic device via BLE"""
        thread = threading.Thread(target=self._ble_connect, args=(address,), daemon=True)
        thread.start()

    def connect_serial(self, port='/dev/ttyACM0'):
        """Connect to Meshtastic device via USB serial"""
        thread = threading.Thread(target=self._serial_connect, args=(port,), daemon=True)
        thread.start()

    def _ble_connect(self, address):
        """Background BLE connection"""
        try:
            import meshtastic.ble_interface
            self._interface = meshtastic.ble_interface.BLEInterface(address)
            self._setup_callbacks()
            self._connected = True
            self.connection_changed.emit(True)
        except ImportError:
            self.error.emit("meshtastic package not installed. Run: pip install meshtastic")
        except Exception as e:
            self.error.emit(f"BLE connection failed: {e}")
            self.connection_changed.emit(False)

    def _serial_connect(self, port):
        """Background serial connection"""
        try:
            import meshtastic.serial_interface
            self._interface = meshtastic.serial_interface.SerialInterface(port)
            self._setup_callbacks()
            self._connected = True
            self.connection_changed.emit(True)
        except ImportError:
            self.error.emit("meshtastic package not installed. Run: pip install meshtastic")
        except Exception as e:
            self.error.emit(f"Serial connection failed: {e}")
            self.connection_changed.emit(False)

    def _setup_callbacks(self):
        """Set up message receive callbacks"""
        try:
            from pubsub import pub
            pub.subscribe(self._on_receive, "meshtastic.receive")
            pub.subscribe(self._on_connection, "meshtastic.connection.established")
        except ImportError:
            pass

    def _on_receive(self, packet, interface):
        """Handle incoming Meshtastic packet"""
        try:
            if 'decoded' in packet and 'text' in packet['decoded']:
                sender = packet.get('fromId', 'Unknown')
                text = packet['decoded']['text']
                ts = int(time.time())
                msg = MeshMessage(sender=sender, text=text, timestamp=ts)
                self._messages.append(msg)
                self.message_received.emit(sender, text, ts)
        except Exception:
            pass

    def _on_connection(self, interface, topic=None):
        """Handle connection established"""
        self._connected = True
        self.connection_changed.emit(True)
        if hasattr(interface, 'nodes'):
            self._node_count = len(interface.nodes)
            self.node_count_changed.emit(self._node_count)

    @Slot(str)
    def send_message(self, text):
        """Send a text message via Meshtastic mesh"""
        if not self._interface or not self._connected:
            self.error.emit("Not connected to Meshtastic device")
            return

        try:
            self._interface.sendText(text)
            msg = MeshMessage(sender="You", text=text,
                            timestamp=int(time.time()), is_local=True)
            self._messages.append(msg)
            self.message_received.emit("You", text, msg.timestamp)
        except Exception as e:
            self.error.emit(f"Send failed: {e}")

    def disconnect(self):
        """Disconnect from Meshtastic device"""
        if self._interface:
            try:
                self._interface.close()
            except Exception:
                pass
        self._connected = False
        self.connection_changed.emit(False)

    @Property(bool, notify=connection_changed)
    def connected(self):
        return self._connected

    @Property(int, notify=node_count_changed)
    def nodeCount(self):
        return self._node_count
