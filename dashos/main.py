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
import math
import time

# Must set offscreen screen size BEFORE Qt is imported
# Device: Waveshare 7" Touch LCD — 1024x600 native resolution
DASHOS_WIDTH = 1024
DASHOS_HEIGHT = 600
if os.environ.get('QT_QPA_PLATFORM') == 'offscreen':
    os.environ['QT_QPA_OFFSCREEN_SCREEN_SIZE'] = f'{DASHOS_WIDTH}x{DASHOS_HEIGHT}'

from PySide6.QtCore import QUrl, QTimer, Property, Signal, Slot, QObject
from PySide6.QtGui import QGuiApplication, QFont
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

# Add parent directory for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from services.serial_bridge import SerialBridge
from services.meshtastic_service import MeshtasticService
from services.power_manager import PowerManager
from services.update_service import UpdateService


class DashOSApp(QObject):
    """Main application controller exposed to QML"""

    # ── Vehicle data signals ──
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

    # ── GPS signals ──
    gpsLatChanged = Signal()
    gpsLonChanged = Signal()
    gpsHeadingChanged = Signal()
    gpsAltChanged = Signal()
    gpsSatellitesChanged = Signal()
    gpsFixTextChanged = Signal()

    # ── Trip computer signals ──
    tripDistanceChanged = Signal()
    tripTimeChanged = Signal()
    tripAvgSpeedChanged = Signal()
    fuelRateChanged = Signal()
    fuelEconomyChanged = Signal()
    fuelLevelChanged = Signal()
    dteChanged = Signal()

    # ── Alert signals ──
    alertTextChanged = Signal()
    alertSeverityChanged = Signal()
    alertVisibleChanged = Signal()

    # ── Advanced OBD signals ──
    mafChanged = Signal()
    intakeTempChanged = Signal()
    oilTempChanged = Signal()
    timingAdvanceChanged = Signal()
    o2VoltageChanged = Signal()
    fuelPressureChanged = Signal()

    # ── Media signals ──
    trackTitleChanged = Signal()
    trackArtistChanged = Signal()
    trackProgressChanged = Signal()
    trackDurationChanged = Signal()
    isPlayingChanged = Signal()

    # ── Charger enable signal ──
    chargerEnabledChanged = Signal()

    # ── Mode signals ──
    hudModeChanged = Signal()
    drivingModeChanged = Signal()

    # ── Meshtastic node signals ──
    nodeListJsonChanged = Signal()

    # ── Update signals ──
    updateAvailableChanged = Signal()
    updateStatusChanged = Signal()
    updateInProgressChanged = Signal()
    updateLogChanged = Signal()

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
        self._charger_enabled = True

        # GPS data
        self._gps_lat = 0.0
        self._gps_lon = 0.0
        self._gps_heading = 0.0
        self._gps_alt = 0.0
        self._gps_satellites = 0
        self._gps_fix_text = "No Fix"

        # Trip computer
        self._trip_distance = 0.0
        self._trip_time_secs = 0
        self._trip_time = "00:00:00"
        self._trip_avg_speed = 0.0
        self._fuel_rate = 0.0
        self._fuel_economy = 0.0
        self._fuel_level = 65.0
        self._dte = 0.0
        self._trip_start = time.time()
        self._last_tick = time.time()
        self._tank_capacity = 55.0  # liters (configurable)

        # Alert system
        self._alert_text = ""
        self._alert_severity = ""
        self._alert_visible = False
        self._active_dtcs = []
        self._alert_suppressed_until = 0  # timestamp for dismiss cooldown

        # Advanced OBD
        self._maf = 0.0
        self._intake_temp = 0
        self._oil_temp = 0
        self._timing_advance = 0.0
        self._o2_voltage = 0.0
        self._fuel_pressure = 0

        # Media / Now Playing
        self._track_title = ""
        self._track_artist = ""
        self._track_progress = 0.0
        self._track_duration = "0:00"
        self._is_playing = False

        # Modes
        self._hud_mode = False
        self._driving_mode = False

        # Meshtastic nodes
        self._node_list_json = "[]"

        # Update state
        self._update_available = False
        self._update_status = "Not checked"
        self._update_in_progress = False
        self._update_log = ""

        # Services
        self._serial_bridge = None
        self._meshtastic = None
        self._power_mgr = None
        self._update_service = None

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

        # Update service
        self._update_service = UpdateService(
            repo_url=config.get('ota_repo', ''),
            branch=config.get('ota_branch', 'main')
        )
        self._update_service.updateAvailable.connect(self._on_update_available)
        self._update_service.updateStatus.connect(self._on_update_status)
        self._update_service.updateInProgress.connect(self._on_update_in_progress)
        self._update_service.updateLog.connect(self._on_update_log)
        self._update_service.start()

        # GPS polling timer (try gpsd every second)
        self._gps_timer = QTimer()
        self._gps_timer.timeout.connect(self._poll_gps)
        self._gps_timer.start(1000)

    def _init_demo(self):
        """Initialize demo mode with simulated data"""
        self._demo_timer = QTimer()
        self._demo_timer.timeout.connect(self._demo_tick)
        self._demo_timer.start(500)
        self._demo_counter = 0
        self._last_tick = time.time()

        # Demo media playlist
        self._demo_playlist = [
            ("Highway Star", "Deep Purple", "6:08", 368),
            ("Radar Love", "Golden Earring", "6:26", 386),
            ("Born to Run", "Bruce Springsteen", "4:30", 270),
            ("Drive", "The Cars", "3:55", 235),
        ]
        self._demo_track_idx = 0

    def _demo_tick(self):
        """Generate simulated data for demo mode"""
        self._demo_counter += 1
        t = self._demo_counter * 0.5
        now = time.time()
        dt = now - self._last_tick
        self._last_tick = now

        # ── Vehicle data ──
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

        # ── Advanced OBD (demo) ──
        self._maf = 4.5 + 2.0 * math.sin(t * 0.4)
        self.mafChanged.emit()
        self._intake_temp = int(30 + 5 * math.sin(t * 0.08))
        self.intakeTempChanged.emit()
        self._oil_temp = int(90 + 8 * math.sin(t * 0.06))
        self.oilTempChanged.emit()
        self._timing_advance = 14.0 + 4.0 * math.sin(t * 0.3)
        self.timingAdvanceChanged.emit()
        self._o2_voltage = 0.45 + 0.4 * math.sin(t * 0.8)
        self.o2VoltageChanged.emit()
        self._fuel_pressure = int(340 + 20 * math.sin(t * 0.2))
        self.fuelPressureChanged.emit()
        self._fuel_rate = 6.0 + 4.0 * math.sin(t * 0.25)
        self.fuelRateChanged.emit()
        self._fuel_level = max(0, 65.0 - t * 0.02)
        self.fuelLevelChanged.emit()

        # ── GPS (demo: simulate driving in Dubai) ──
        base_lat = 25.2048
        base_lon = 55.2708
        self._gps_lat = base_lat + 0.01 * math.sin(t * 0.05)
        self._gps_lon = base_lon + 0.01 * math.cos(t * 0.05)
        self._gps_heading = (math.degrees(math.atan2(
            math.cos(t * 0.05), -math.sin(t * 0.05))) + 360) % 360
        self._gps_alt = 12.0 + 2.0 * math.sin(t * 0.02)
        self._gps_satellites = 8 + int(2 * math.sin(t * 0.1))
        self._gps_fix_text = "3D Fix"
        self.gpsLatChanged.emit()
        self.gpsLonChanged.emit()
        self.gpsHeadingChanged.emit()
        self.gpsAltChanged.emit()
        self.gpsSatellitesChanged.emit()
        self.gpsFixTextChanged.emit()

        # ── Trip Computer ──
        self._trip_time_secs = int(t)
        h = self._trip_time_secs // 3600
        m = (self._trip_time_secs // 60) % 60
        s = self._trip_time_secs % 60
        self._trip_time = f"{h:02d}:{m:02d}:{s:02d}"
        self.tripTimeChanged.emit()

        self._trip_distance += (self._speed / 3600.0) * dt
        self.tripDistanceChanged.emit()

        if self._trip_time_secs > 0:
            self._trip_avg_speed = self._trip_distance / (self._trip_time_secs / 3600.0)
        self.tripAvgSpeedChanged.emit()

        if self._speed > 5:
            self._fuel_economy = (self._fuel_rate / self._speed) * 100.0
        self.fuelEconomyChanged.emit()

        if self._fuel_economy > 0:
            remaining_fuel = (self._fuel_level / 100.0) * self._tank_capacity
            self._dte = remaining_fuel / (self._fuel_economy / 100.0)
        self.dteChanged.emit()

        # ── Alert System ──
        self._active_dtcs = ["P0301"]  # Demo: always have a misfire code
        self._check_alerts()

        # ── Media (demo playlist) ──
        track = self._demo_playlist[self._demo_track_idx]
        title, artist, dur_str, dur_secs = track
        if self._track_title != title:
            self._track_title = title
            self._track_artist = artist
            self._track_duration = dur_str
            self._is_playing = True
            self.trackTitleChanged.emit()
            self.trackArtistChanged.emit()
            self.trackDurationChanged.emit()
            self.isPlayingChanged.emit()

        track_elapsed = t % dur_secs
        self._track_progress = track_elapsed / dur_secs
        self.trackProgressChanged.emit()

        if int(t) % dur_secs == dur_secs - 1 and self._demo_counter % 2 == 0:
            self._demo_track_idx = (self._demo_track_idx + 1) % len(self._demo_playlist)

        # ── Driving mode ──
        was_driving = self._driving_mode
        self._driving_mode = self._speed > 10
        if was_driving != self._driving_mode:
            self.drivingModeChanged.emit()

        # ── Meshtastic nodes (demo, update every 5 seconds) ──
        if self._demo_counter % 10 == 1:
            nodes = [
                {"id": "NodeA-alpha", "short": "Alpha", "snr": 8.5, "rssi": -75,
                 "battery": 92, "lastHeard": "2m ago",
                 "lat": base_lat + 0.005, "lon": base_lon + 0.003},
                {"id": "NodeB-bravo", "short": "Bravo", "snr": 5.2, "rssi": -89,
                 "battery": 67, "lastHeard": "30s ago",
                 "lat": base_lat - 0.002, "lon": base_lon + 0.008},
                {"id": "NodeC-charlie", "short": "Charlie", "snr": 3.1, "rssi": -102,
                 "battery": 34, "lastHeard": "5m ago",
                 "lat": base_lat + 0.008, "lon": base_lon - 0.004},
                {"id": "Heltec-V3 (You)", "short": "You", "snr": 0, "rssi": 0,
                 "battery": 85, "lastHeard": "now",
                 "lat": self._gps_lat, "lon": self._gps_lon},
            ]
            self._node_list_json = json.dumps(nodes)
            self.nodeListJsonChanged.emit()

    def _check_alerts(self):
        """Evaluate alert conditions and update alert state"""
        if time.time() < self._alert_suppressed_until:
            return

        alerts = []

        # Overheat
        if self._coolant > 110:
            alerts.append(("OVERHEAT: Coolant " + str(self._coolant) + "\u00b0C — Pull over immediately", "critical"))
        elif self._coolant > 100:
            alerts.append(("HIGH COOLANT: " + str(self._coolant) + "\u00b0C — Monitor closely", "warning"))

        # Low fuel
        if self._fuel_level < 10:
            alerts.append((f"CRITICAL FUEL: {self._fuel_level:.0f}% remaining — Find station now", "critical"))
        elif self._fuel_level < 20:
            alerts.append((f"LOW FUEL: {self._fuel_level:.0f}% — Plan refueling", "warning"))

        # Low battery voltage
        if 0 < self._batt_v < 11.5:
            alerts.append((f"LOW VOLTAGE: {self._batt_v:.1f}V — Check alternator", "critical"))

        # Oil temp
        if self._oil_temp > 130:
            alerts.append(("HIGH OIL TEMP: " + str(self._oil_temp) + "\u00b0C", "critical"))

        # Active DTCs — misfire codes
        for dtc in self._active_dtcs:
            if dtc.startswith("P03"):
                alerts.append(("MISFIRE DETECTED: " + dtc + " — Reduce load", "critical"))
                break

        # Overspeed
        if self._speed > 160:
            alerts.append(("OVERSPEED: " + str(self._speed) + " km/h", "warning"))

        if alerts:
            critical = [a for a in alerts if a[1] == "critical"]
            if critical:
                self._alert_text = critical[0][0]
                self._alert_severity = "critical"
            else:
                self._alert_text = alerts[0][0]
                self._alert_severity = "warning"

            if not self._alert_visible:
                self._alert_visible = True
                self.alertVisibleChanged.emit()
            self.alertTextChanged.emit()
            self.alertSeverityChanged.emit()
        else:
            if self._alert_visible:
                self._alert_visible = False
                self._alert_text = ""
                self._alert_severity = ""
                self.alertVisibleChanged.emit()
                self.alertTextChanged.emit()
                self.alertSeverityChanged.emit()

    def _poll_gps(self):
        """Poll gpsd for GPS data (real mode only)"""
        try:
            from gpsdclient import GPSDClient
            with GPSDClient() as client:
                for result in client.dict_stream(convert_datetime=False):
                    if result["class"] == "TPV":
                        self._gps_lat = result.get("lat", 0.0)
                        self._gps_lon = result.get("lon", 0.0)
                        self._gps_heading = result.get("track", 0.0)
                        self._gps_alt = result.get("alt", 0.0)
                        mode = result.get("mode", 0)
                        self._gps_fix_text = {0: "No Fix", 1: "No Fix", 2: "2D Fix", 3: "3D Fix"}.get(mode, "Unknown")
                        self.gpsLatChanged.emit()
                        self.gpsLonChanged.emit()
                        self.gpsHeadingChanged.emit()
                        self.gpsAltChanged.emit()
                        self.gpsFixTextChanged.emit()
                        break
                    elif result["class"] == "SKY":
                        sats = result.get("satellites", [])
                        self._gps_satellites = sum(1 for s in sats if s.get("used", False))
                        self.gpsSatellitesChanged.emit()
                        break
        except Exception:
            pass  # GPS not available

    def _on_vehicle_data(self, data):
        """Handle incoming vehicle data from ESP32"""
        obd = data.get('obd', {})
        chg = data.get('chg', {})

        # Core OBD fields
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

        # Charger fields
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
        if 'en' in chg:
            en = bool(chg['en'])
            if en != self._charger_enabled:
                self._charger_enabled = en
                self.chargerEnabledChanged.emit()

        self._can_ok = data.get('can', False)
        self.canOkChanged.emit()
        self._rs485_ok = data.get('rs485', False)
        self.rs485OkChanged.emit()

        # Extended OBD fields
        if 'fuel_rate' in obd:
            self._fuel_rate = obd['fuel_rate']
            self.fuelRateChanged.emit()
        if 'fuel_lvl' in obd:
            self._fuel_level = obd['fuel_lvl']
            self.fuelLevelChanged.emit()
        if 'maf' in obd:
            self._maf = obd['maf']
            self.mafChanged.emit()
        if 'iat' in obd:
            self._intake_temp = obd['iat']
            self.intakeTempChanged.emit()
        if 'oil_t' in obd:
            self._oil_temp = obd['oil_t']
            self.oilTempChanged.emit()
        if 'timing' in obd:
            self._timing_advance = obd['timing']
            self.timingAdvanceChanged.emit()
        if 'o2v' in obd:
            self._o2_voltage = obd['o2v']
            self.o2VoltageChanged.emit()
        if 'fuel_pres' in obd:
            self._fuel_pressure = obd['fuel_pres']
            self.fuelPressureChanged.emit()

        # DTCs
        if 'dtc' in data:
            self._active_dtcs = data['dtc']

        # Trip computer update (real mode)
        now = time.time()
        dt = now - self._last_tick
        self._last_tick = now

        self._trip_time_secs = int(now - self._trip_start)
        h = self._trip_time_secs // 3600
        m = (self._trip_time_secs // 60) % 60
        s = self._trip_time_secs % 60
        self._trip_time = f"{h:02d}:{m:02d}:{s:02d}"
        self.tripTimeChanged.emit()

        if self._speed > 0:
            self._trip_distance += (self._speed / 3600.0) * dt
            self.tripDistanceChanged.emit()

        if self._trip_time_secs > 0:
            self._trip_avg_speed = self._trip_distance / (self._trip_time_secs / 3600.0)
            self.tripAvgSpeedChanged.emit()

        if self._speed > 5 and self._fuel_rate > 0:
            self._fuel_economy = (self._fuel_rate / self._speed) * 100.0
            self.fuelEconomyChanged.emit()

        if self._fuel_economy > 0 and self._fuel_level > 0:
            remaining = (self._fuel_level / 100.0) * self._tank_capacity
            self._dte = remaining / (self._fuel_economy / 100.0)
            self.dteChanged.emit()

        # Alert check
        self._check_alerts()

        # Driving mode
        was_driving = self._driving_mode
        self._driving_mode = self._speed > 10
        if was_driving != self._driving_mode:
            self.drivingModeChanged.emit()

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

    @Property(bool, notify=chargerEnabledChanged)
    def chargerEnabled(self): return self._charger_enabled

    @Property(str, notify=faultTextChanged)
    def faultText(self): return self._fault_text

    @Property(str, notify=uptimeChanged)
    def uptime(self): return self._uptime

    # GPS
    @Property(float, notify=gpsLatChanged)
    def gpsLat(self): return self._gps_lat

    @Property(float, notify=gpsLonChanged)
    def gpsLon(self): return self._gps_lon

    @Property(float, notify=gpsHeadingChanged)
    def gpsHeading(self): return self._gps_heading

    @Property(float, notify=gpsAltChanged)
    def gpsAlt(self): return self._gps_alt

    @Property(int, notify=gpsSatellitesChanged)
    def gpsSatellites(self): return self._gps_satellites

    @Property(str, notify=gpsFixTextChanged)
    def gpsFixText(self): return self._gps_fix_text

    # Trip computer
    @Property(float, notify=tripDistanceChanged)
    def tripDistance(self): return self._trip_distance

    @Property(str, notify=tripTimeChanged)
    def tripTime(self): return self._trip_time

    @Property(float, notify=tripAvgSpeedChanged)
    def tripAvgSpeed(self): return self._trip_avg_speed

    @Property(float, notify=fuelRateChanged)
    def fuelRate(self): return self._fuel_rate

    @Property(float, notify=fuelEconomyChanged)
    def fuelEconomy(self): return self._fuel_economy

    @Property(float, notify=fuelLevelChanged)
    def fuelLevel(self): return self._fuel_level

    @Property(float, notify=dteChanged)
    def dte(self): return self._dte

    # Alerts
    @Property(str, notify=alertTextChanged)
    def alertText(self): return self._alert_text

    @Property(str, notify=alertSeverityChanged)
    def alertSeverity(self): return self._alert_severity

    @Property(bool, notify=alertVisibleChanged)
    def alertVisible(self): return self._alert_visible

    # Advanced OBD
    @Property(float, notify=mafChanged)
    def maf(self): return self._maf

    @Property(int, notify=intakeTempChanged)
    def intakeTemp(self): return self._intake_temp

    @Property(int, notify=oilTempChanged)
    def oilTemp(self): return self._oil_temp

    @Property(float, notify=timingAdvanceChanged)
    def timingAdvance(self): return self._timing_advance

    @Property(float, notify=o2VoltageChanged)
    def o2Voltage(self): return self._o2_voltage

    @Property(int, notify=fuelPressureChanged)
    def fuelPressure(self): return self._fuel_pressure

    # Media
    @Property(str, notify=trackTitleChanged)
    def trackTitle(self): return self._track_title

    @Property(str, notify=trackArtistChanged)
    def trackArtist(self): return self._track_artist

    @Property(float, notify=trackProgressChanged)
    def trackProgress(self): return self._track_progress

    @Property(str, notify=trackDurationChanged)
    def trackDuration(self): return self._track_duration

    @Property(bool, notify=isPlayingChanged)
    def isPlaying(self): return self._is_playing

    # Modes
    @Property(bool, notify=hudModeChanged)
    def hudMode(self): return self._hud_mode

    @Property(bool, notify=drivingModeChanged)
    def drivingMode(self): return self._driving_mode

    # Meshtastic nodes
    @Property(str, notify=nodeListJsonChanged)
    def nodeListJson(self): return self._node_list_json

    # Update
    @Property(bool, notify=updateAvailableChanged)
    def updateAvailable(self): return self._update_available

    @Property(str, notify=updateStatusChanged)
    def updateStatus(self): return self._update_status

    @Property(bool, notify=updateInProgressChanged)
    def updateInProgress(self): return self._update_in_progress

    @Property(str, notify=updateLogChanged)
    def updateLog(self): return self._update_log

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

    @Slot()
    def toggleCharger(self):
        """Toggle DC charger on/off"""
        self._charger_enabled = not self._charger_enabled
        self.chargerEnabledChanged.emit()
        if self._serial_bridge:
            self._serial_bridge.send_command('enable_charger', val=1 if self._charger_enabled else 0)

    @Slot()
    def resetTrip(self):
        """Reset trip computer"""
        self._trip_distance = 0.0
        self._trip_time_secs = 0
        self._trip_time = "00:00:00"
        self._trip_avg_speed = 0.0
        self._trip_start = time.time()
        self._last_tick = time.time()
        self.tripDistanceChanged.emit()
        self.tripTimeChanged.emit()
        self.tripAvgSpeedChanged.emit()

    @Slot()
    def toggleHUD(self):
        """Toggle HUD mode"""
        self._hud_mode = not self._hud_mode
        self.hudModeChanged.emit()

    @Slot()
    def dismissAlert(self):
        """Dismiss current alert for 30 seconds"""
        self._alert_visible = False
        self._alert_suppressed_until = time.time() + 30
        self.alertVisibleChanged.emit()

    @Slot(str)
    def sendMeshPreset(self, text):
        """Send a preset Meshtastic message"""
        if self._meshtastic:
            self._meshtastic.send_message(text)

    # ── Update callbacks ──

    def _on_update_available(self, available):
        self._update_available = available
        self.updateAvailableChanged.emit()

    def _on_update_status(self, status):
        self._update_status = status
        self.updateStatusChanged.emit()

    def _on_update_in_progress(self, in_progress):
        self._update_in_progress = in_progress
        self.updateInProgressChanged.emit()

    def _on_update_log(self, log_line):
        self._update_log = log_line
        self.updateLogChanged.emit()

    @Slot()
    def checkForUpdates(self):
        """Manually trigger update check"""
        if self._update_service:
            self._update_service.checkForUpdates()

    @Slot()
    def applyUpdate(self):
        """Apply available update"""
        if self._update_service:
            self._update_service.applyUpdate()


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

    # Force window size to match device resolution
    from PySide6.QtCore import QSize
    root.setWidth(DASHOS_WIDTH)
    root.setHeight(DASHOS_HEIGHT)
    root.setMinimumSize(QSize(DASHOS_WIDTH, DASHOS_HEIGHT))

    # Fullscreen mode for kiosk
    if args.fullscreen:
        root.showFullScreen()

    def grab_window_image():
        """Grab window screenshot at device resolution (1024x600)"""
        screen = app.primaryScreen()
        if screen:
            # Grab the entire screen content
            pixmap = screen.grabWindow(0)
            img = pixmap.toImage()
            if img and not img.isNull():
                # Scale to exact device resolution if offscreen platform differs
                if img.width() != DASHOS_WIDTH or img.height() != DASHOS_HEIGHT:
                    from PySide6.QtCore import Qt
                    img = img.scaled(DASHOS_WIDTH, DASHOS_HEIGHT,
                                     Qt.IgnoreAspectRatio, Qt.SmoothTransformation)
                return img
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
