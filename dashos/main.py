#!/usr/bin/env python3
"""
DashOS — Custom Vehicle Operating System
Main entry point for the Raspberry Pi application

Launches Qt/QML UI with modular vehicle dashboard, OBD2 scanner,
Meshtastic messaging, CarPlay, YouTube, and settings.

Usage:
    python main.py                  # Normal launch
    python main.py --demo           # Demo mode with simulated data
    python main.py --fullscreen     # Kiosk mode (no window decorations)
"""

import sys
import os
import signal
import argparse
import json

from PySide6.QtCore import QUrl, QTimer, Property, Signal, Slot, QObject
from PySide6.QtGui import QGuiApplication, QFont
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

# Add parent directory for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from services.serial_bridge import SerialBridge
from services.meshtastic_service import MeshtasticService
from services.power_manager import PowerManager


class DashOSApp(QObject):
    """Main application controller exposed to QML"""

    # Signals for QML property updates
    speedChanged = Signal()
    rpmChanged = Signal()
    coolantChanged = Signal()
    throttleChanged = Signal()
    loadChanged = Signal()
    battVChanged = Signal()
    battIChanged = Signal()
    chargeRateChanged = Signal()
    tempT1Changed = Signal()
    tempT2Changed = Signal()
    tempAmbChanged = Signal()
    canOkChanged = Signal()
    rs485OkChanged = Signal()
    faultTextChanged = Signal()
    uptimeChanged = Signal()

    def __init__(self, demo_mode=False):
        super().__init__()
        self._demo_mode = demo_mode

        # Vehicle data
        self._speed = 0
        self._rpm = 0
        self._coolant = 0
        self._throttle = 0
        self._load = 0
        self._batt_v = 0.0
        self._batt_i = 0.0
        self._charge_rate = 12.0
        self._temp_t1 = 0
        self._temp_t2 = 0
        self._temp_amb = 0
        self._can_ok = False
        self._rs485_ok = False
        self._fault_text = "Initializing..."
        self._uptime = "00:00:00"

        # Services
        self._serial_bridge = None
        self._meshtastic = None
        self._power_mgr = None

        if not demo_mode:
            self._init_services()
        else:
            self._init_demo()

    def _init_services(self):
        """Initialize real hardware services"""
        config_path = os.path.join(os.path.dirname(__file__), 'config', 'dashos.conf')
        config = self._load_config(config_path)

        self._serial_bridge = SerialBridge(
            port=config.get('serial_port', '/dev/ttyUSB0'),
            baud=int(config.get('serial_baud', '115200'))
        )
        self._serial_bridge.data_received.connect(self._on_vehicle_data)
        self._serial_bridge.start()

        self._meshtastic = MeshtasticService()
        self._power_mgr = PowerManager()

    def _init_demo(self):
        """Initialize demo mode with simulated data"""
        self._demo_timer = QTimer()
        self._demo_timer.timeout.connect(self._demo_tick)
        self._demo_timer.start(500)
        self._demo_counter = 0

    def _demo_tick(self):
        """Generate simulated data for demo mode"""
        import math
        self._demo_counter += 1
        t = self._demo_counter * 0.5

        self._speed = int(60 + 40 * math.sin(t * 0.3))
        self.speedChanged.emit()
        self._rpm = int(2000 + 1500 * math.sin(t * 0.5))
        self.rpmChanged.emit()
        self._coolant = int(80 + 10 * math.sin(t * 0.1))
        self.coolantChanged.emit()
        self._throttle = int(30 + 30 * math.sin(t * 0.7))
        self.throttleChanged.emit()
        self._load = int(40 + 20 * math.sin(t * 0.4))
        self.loadChanged.emit()
        self._batt_v = 27.0 + 1.5 * math.sin(t * 0.2)
        self.battVChanged.emit()
        self._batt_i = 25.0 + 5.0 * math.sin(t * 0.3)
        self.battIChanged.emit()
        self._charge_rate = 30.0
        self.chargeRateChanged.emit()
        self._temp_t1 = int(38 + 5 * math.sin(t * 0.15))
        self.tempT1Changed.emit()
        self._temp_t2 = int(35 + 4 * math.sin(t * 0.12))
        self.tempT2Changed.emit()
        self._temp_amb = 32
        self.tempAmbChanged.emit()
        self._can_ok = True
        self.canOkChanged.emit()
        self._rs485_ok = True
        self.rs485OkChanged.emit()
        self._fault_text = "CHARGING FULL RATE\n30A — All systems normal"
        self.faultTextChanged.emit()

        secs = int(t)
        self._uptime = f"{secs // 3600:02d}:{(secs // 60) % 60:02d}:{secs % 60:02d}"
        self.uptimeChanged.emit()

    def _on_vehicle_data(self, data):
        """Handle incoming vehicle data from ESP32"""
        obd = data.get('obd', {})
        chg = data.get('chg', {})

        if 'spd' in obd:
            self._speed = obd['spd']
            self.speedChanged.emit()
        if 'rpm' in obd:
            self._rpm = obd['rpm']
            self.rpmChanged.emit()
        if 'ect' in obd:
            self._coolant = obd['ect']
            self.coolantChanged.emit()
        if 'thr' in obd:
            self._throttle = obd['thr']
            self.throttleChanged.emit()
        if 'load' in obd:
            self._load = obd['load']
            self.loadChanged.emit()
        if 'v' in chg:
            self._batt_v = chg['v']
            self.battVChanged.emit()
        if 'a' in chg:
            self._batt_i = chg['a']
            self.battIChanged.emit()
        if 'rate' in chg:
            self._charge_rate = chg['rate']
            self.chargeRateChanged.emit()
        if 't1' in chg:
            self._temp_t1 = chg['t1']
            self.tempT1Changed.emit()
        if 't2' in chg:
            self._temp_t2 = chg['t2']
            self.tempT2Changed.emit()
        if 'amb' in chg:
            self._temp_amb = chg['amb']
            self.tempAmbChanged.emit()

        self._can_ok = data.get('can', False)
        self.canOkChanged.emit()
        self._rs485_ok = data.get('rs485', False)
        self.rs485OkChanged.emit()

    @staticmethod
    def _load_config(path):
        """Load key=value config file"""
        config = {}
        if os.path.exists(path):
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        k, v = line.split('=', 1)
                        config[k.strip()] = v.strip()
        return config

    # ── QML Properties ──────────────────────────────────────
    @Property(int, notify=speedChanged)
    def speed(self): return self._speed

    @Property(int, notify=rpmChanged)
    def rpm(self): return self._rpm

    @Property(int, notify=coolantChanged)
    def coolant(self): return self._coolant

    @Property(int, notify=throttleChanged)
    def throttle(self): return self._throttle

    @Property(int, notify=loadChanged)
    def load(self): return self._load

    @Property(float, notify=battVChanged)
    def battV(self): return self._batt_v

    @Property(float, notify=battIChanged)
    def battI(self): return self._batt_i

    @Property(float, notify=chargeRateChanged)
    def chargeRate(self): return self._charge_rate

    @Property(int, notify=tempT1Changed)
    def tempT1(self): return self._temp_t1

    @Property(int, notify=tempT2Changed)
    def tempT2(self): return self._temp_t2

    @Property(int, notify=tempAmbChanged)
    def tempAmb(self): return self._temp_amb

    @Property(bool, notify=canOkChanged)
    def canOk(self): return self._can_ok

    @Property(bool, notify=rs485OkChanged)
    def rs485Ok(self): return self._rs485_ok

    @Property(str, notify=faultTextChanged)
    def faultText(self): return self._fault_text

    @Property(str, notify=uptimeChanged)
    def uptime(self): return self._uptime

    # ── QML Slots (callable from UI) ────────────────────────
    @Slot()
    def scanDTC(self):
        if self._serial_bridge:
            self._serial_bridge.send_command('scan_dtc')

    @Slot()
    def clearDTC(self):
        if self._serial_bridge:
            self._serial_bridge.send_command('clear_dtc')

    @Slot(float)
    def setChargeCurrent(self, amps):
        if self._serial_bridge:
            self._serial_bridge.send_command('set_current', val=amps)


def main():
    parser = argparse.ArgumentParser(description='DashOS Vehicle Operating System')
    parser.add_argument('--demo', action='store_true', help='Run in demo mode with simulated data')
    parser.add_argument('--fullscreen', action='store_true', help='Run in fullscreen kiosk mode')
    parser.add_argument('--screenshot', type=str, metavar='FILE',
                        help='Capture screenshot to FILE after rendering, then exit')
    parser.add_argument('--screenshot-all', type=str, metavar='DIR',
                        help='Capture screenshots of all pages to DIR, then exit')
    args = parser.parse_args()

    # Handle Ctrl+C gracefully
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QGuiApplication(sys.argv)
    app.setApplicationName("DashOS")
    app.setOrganizationName("DashOS")

    # Create main controller
    dash = DashOSApp(demo_mode=args.demo)

    # Load QML UI
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("dash", dash)

    qml_path = os.path.join(os.path.dirname(__file__), 'qml', 'Main.qml')
    engine.load(QUrl.fromLocalFile(qml_path))

    if not engine.rootObjects():
        print("[ERROR] Failed to load QML UI")
        sys.exit(1)

    root = engine.rootObjects()[0]

    # Force window size (offscreen platform may ignore QML width/height)
    from PySide6.QtCore import QSize
    root.setWidth(1024)
    root.setHeight(600)
    root.setMinimumSize(QSize(1024, 600))

    # Fullscreen mode for kiosk
    if args.fullscreen:
        root.showFullScreen()

    def grab_window_image():
        """Grab window screenshot with fallback for different Qt backends"""
        try:
            return root.grabWindow()
        except AttributeError:
            screen = app.primaryScreen()
            if screen:
                pixmap = screen.grabWindow(0)
                return pixmap.toImage()
            return None

    # Screenshot mode: capture after UI renders, then exit
    if args.screenshot:
        def request_grab():
            img = grab_window_image()
            if img:
                out_path = os.path.abspath(args.screenshot)
                img.save(out_path)
                print(f"Screenshot saved: {out_path} ({img.width()}x{img.height()})")
            else:
                print("[ERROR] No screen available for screenshot")
            app.quit()

        # Allow 3 seconds for QML to fully render and demo data to populate
        QTimer.singleShot(3000, request_grab)

    # Screenshot-all mode: cycle through all pages and capture each
    if args.screenshot_all:
        out_dir = os.path.abspath(args.screenshot_all)
        os.makedirs(out_dir, exist_ok=True)

        page_names = ["dashboard", "obd2_scanner", "meshtastic", "dtc_viewer", "media_player", "settings"]
        stack_view = root.findChild(QObject, "stackView")

        def capture_all_pages():
            page_idx = [0]  # mutable counter for closure

            def capture_next():
                if page_idx[0] > 0:
                    # Save screenshot of the previous page (rendered by now)
                    prev = page_idx[0] - 1
                    img = grab_window_image()
                    if img:
                        out_path = os.path.join(out_dir, f"{page_names[prev]}.png")
                        img.save(out_path)
                        w = img.width()
                        h = img.height()
                        print(f"  [{prev+1}/6] {out_path} ({w}x{h})")

                if page_idx[0] < len(page_names):
                    # Switch to the next page
                    stack_view.setProperty("currentIndex", page_idx[0])
                    page_idx[0] += 1
                    # Wait 500ms for page to render before capturing
                    QTimer.singleShot(500, capture_next)
                else:
                    print(f"All {len(page_names)} screenshots saved to {out_dir}/")
                    app.quit()

            capture_next()

        # Allow 3 seconds for initial QML render + demo data
        QTimer.singleShot(3000, capture_all_pages)

    sys.exit(app.exec())


if __name__ == '__main__':
    main()
