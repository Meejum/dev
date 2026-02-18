"""
Serial Bridge Service — ESP32 ↔ Raspberry Pi communication
Reads JSON data from ESP32 over USB serial, sends commands back.

Protocol: Newline-delimited JSON, 115200 baud
"""

import json
import threading
from PySide6.QtCore import QObject, Signal, QThread


class SerialBridge(QObject):
    """Manages serial communication with ESP32 bridge firmware"""

    data_received = Signal(dict)   # Emitted when new vehicle data arrives
    connected = Signal(bool)       # Connection status change
    error = Signal(str)            # Error messages

    def __init__(self, port='/dev/ttyUSB0', baud=115200, parent=None):
        super().__init__(parent)
        self._port = port
        self._baud = baud
        self._serial = None
        self._running = False
        self._thread = None

    def start(self):
        """Start reading serial data in background thread"""
        self._running = True
        self._thread = threading.Thread(target=self._read_loop, daemon=True)
        self._thread.start()

    def stop(self):
        """Stop serial reading"""
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
        if self._serial:
            self._serial.close()

    def send_command(self, cmd, **kwargs):
        """Send a command to ESP32"""
        if not self._serial or not self._serial.is_open:
            return False

        payload = {"cmd": cmd}
        payload.update(kwargs)

        try:
            line = json.dumps(payload) + '\n'
            self._serial.write(line.encode())
            self._serial.flush()
            return True
        except Exception as e:
            self.error.emit(f"Send failed: {e}")
            return False

    def _read_loop(self):
        """Background thread: continuously read serial data"""
        try:
            import serial as pyserial
        except ImportError:
            self.error.emit("pyserial not installed. Run: pip install pyserial")
            return

        while self._running:
            try:
                if not self._serial or not self._serial.is_open:
                    self._connect(pyserial)
                    continue

                line = self._serial.readline()
                if not line:
                    continue

                try:
                    data = json.loads(line.decode().strip())
                    self.data_received.emit(data)
                except (json.JSONDecodeError, UnicodeDecodeError):
                    pass  # Skip malformed lines

            except Exception as e:
                self.error.emit(f"Serial error: {e}")
                self.connected.emit(False)
                if self._serial:
                    try:
                        self._serial.close()
                    except Exception:
                        pass
                    self._serial = None
                import time
                time.sleep(2)  # Retry after 2 seconds

    def _connect(self, pyserial):
        """Try to connect to serial port"""
        import time
        try:
            self._serial = pyserial.Serial(
                self._port,
                self._baud,
                timeout=1
            )
            self.connected.emit(True)
        except Exception as e:
            self.error.emit(f"Connection failed ({self._port}): {e}")
            self.connected.emit(False)
            time.sleep(3)  # Wait before retry
