"""
Data Logger — CSV logging service for DashOS (Pi side)

Logs GPS, trip computer, Meshtastic, and DTC data to the SD card
at a configurable interval. Complements the ESP32-side logger
which handles raw OBD2 and charger data.

Log files:
  /logs/YYYY-MM-DD_gps.csv       — GPS position, heading, altitude
  /logs/YYYY-MM-DD_trip.csv      — Trip computer snapshots
  /logs/YYYY-MM-DD_dtc.csv       — DTC events (scan/clear)
  /logs/YYYY-MM-DD_mesh.csv      — Meshtastic messages
  /logs/YYYY-MM-DD_vehicle.csv   — Full vehicle snapshot (all data)
"""

import os
import csv
import time
from datetime import datetime

from PySide6.QtCore import QObject, QTimer, Signal


class DataLogger(QObject):
    """Logs all DashOS data to CSV files on the SD card"""

    # Signals
    logStatusChanged = Signal(str)
    sdInfoChanged = Signal()

    def __init__(self, log_dir="/media/sdcard/logs", interval_ms=1000, parent=None):
        super().__init__(parent)
        self._log_dir = log_dir
        self._interval_ms = interval_ms
        self._enabled = True
        self._files = {}  # { type: (file, writer) }
        self._last_date = ""
        self._row_count = 0
        self._status = "Idle"

        # SD card info (set from outside or detected)
        self._sd_total_gb = 512.0
        self._sd_used_gb = 13.8
        self._sd_mounted = True

        # Timer
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)

        # Data ref (set by main app)
        self._dash = None

    def set_dash(self, dash):
        """Set reference to DashOSApp for reading current data"""
        self._dash = dash

    def start(self):
        """Start periodic logging"""
        os.makedirs(self._log_dir, exist_ok=True)
        self._timer.start(self._interval_ms)
        self._status = "Logging"
        self.logStatusChanged.emit(self._status)

    def stop(self):
        """Stop logging and close all files"""
        self._timer.stop()
        self._close_all()
        self._status = "Stopped"
        self.logStatusChanged.emit(self._status)

    def set_interval(self, ms):
        """Change logging interval"""
        self._interval_ms = max(100, ms)
        if self._timer.isActive():
            self._timer.setInterval(self._interval_ms)

    def set_enabled(self, enabled):
        """Enable or disable logging"""
        self._enabled = enabled
        if enabled and not self._timer.isActive():
            self.start()
        elif not enabled and self._timer.isActive():
            self.stop()

    @property
    def sd_total_gb(self):
        return self._sd_total_gb

    @property
    def sd_used_gb(self):
        return self._sd_used_gb

    @property
    def sd_free_gb(self):
        return self._sd_total_gb - self._sd_used_gb

    @property
    def sd_mounted(self):
        return self._sd_mounted

    def log_dtc_event(self, event_type, dtc_codes):
        """Log a DTC scan or clear event"""
        w = self._get_writer("dtc", ["timestamp", "event", "codes"])
        if w:
            w.writerow([
                datetime.now().isoformat(),
                event_type,
                ";".join(dtc_codes) if dtc_codes else ""
            ])

    def log_mesh_message(self, sender, message):
        """Log a Meshtastic message"""
        w = self._get_writer("mesh", ["timestamp", "sender", "message"])
        if w:
            w.writerow([
                datetime.now().isoformat(),
                sender,
                message
            ])

    def _tick(self):
        """Periodic callback — log current vehicle snapshot"""
        if not self._enabled or not self._dash:
            return

        self._check_date_rotation()
        self._log_vehicle()
        self._log_gps()
        self._log_trip()

        self._row_count += 1
        # Flush every 30 rows
        if self._row_count % 30 == 0:
            self._flush_all()

    def _log_vehicle(self):
        """Log full vehicle data snapshot"""
        d = self._dash
        w = self._get_writer("vehicle", [
            "timestamp", "speed", "rpm", "coolant", "throttle", "load",
            "batt_v", "batt_i", "set_a", "charge_rate", "charger_en",
            "temp_t1", "temp_t2", "temp_amb",
            "fault", "alarm", "can_ok", "rs485_ok",
            "fuel_rate", "fuel_level", "maf", "iat", "oil_temp",
            "timing_adv", "o2_voltage", "fuel_pres"
        ])
        if w:
            w.writerow([
                datetime.now().isoformat(),
                d._speed, d._rpm, d._coolant, d._throttle, d._load,
                f"{d._batt_v:.2f}", f"{d._batt_i:.2f}",
                f"{d._charge_set:.1f}" if hasattr(d, '_charge_set') else "0",
                f"{d._charge_rate:.1f}",
                1 if d._charger_enabled else 0,
                d._temp_t1, d._temp_t2, d._temp_amb,
                d._fault if hasattr(d, '_fault') else 0,
                d._alarm if hasattr(d, '_alarm') else 0,
                1 if d._can_ok else 0,
                1 if d._rs485_ok else 0,
                f"{d._fuel_rate:.2f}" if hasattr(d, '_fuel_rate') else "",
                f"{d._fuel_level:.1f}" if hasattr(d, '_fuel_level') else "",
                f"{d._maf:.2f}" if hasattr(d, '_maf') else "",
                d._intake_air_temp if hasattr(d, '_intake_air_temp') else "",
                d._oil_temp if hasattr(d, '_oil_temp') else "",
                f"{d._timing_adv:.1f}" if hasattr(d, '_timing_adv') else "",
                f"{d._o2_voltage:.3f}" if hasattr(d, '_o2_voltage') else "",
                d._fuel_pressure if hasattr(d, '_fuel_pressure') else ""
            ])

    def _log_gps(self):
        """Log GPS data"""
        d = self._dash
        if not hasattr(d, '_gps_lat'):
            return
        w = self._get_writer("gps", [
            "timestamp", "lat", "lon", "heading", "alt", "satellites", "fix"
        ])
        if w:
            w.writerow([
                datetime.now().isoformat(),
                f"{d._gps_lat:.6f}", f"{d._gps_lon:.6f}",
                f"{d._gps_heading:.1f}", f"{d._gps_alt:.1f}",
                d._gps_satellites,
                d._gps_fix_text
            ])

    def _log_trip(self):
        """Log trip computer data"""
        d = self._dash
        if not hasattr(d, '_trip_distance'):
            return
        w = self._get_writer("trip", [
            "timestamp", "distance_km", "time", "avg_speed",
            "fuel_economy", "dte_km"
        ])
        if w:
            w.writerow([
                datetime.now().isoformat(),
                f"{d._trip_distance:.1f}",
                d._trip_time,
                f"{d._trip_avg_speed:.1f}",
                f"{d._fuel_economy:.1f}" if hasattr(d, '_fuel_economy') else "",
                f"{d._dte:.0f}" if hasattr(d, '_dte') else ""
            ])

    def _get_writer(self, log_type, headers):
        """Get or create a CSV writer for the given log type"""
        today = datetime.now().strftime("%Y-%m-%d")
        key = f"{today}_{log_type}"

        if key in self._files:
            return self._files[key][1]

        path = os.path.join(self._log_dir, f"{today}_{log_type}.csv")
        is_new = not os.path.exists(path)

        try:
            f = open(path, 'a', newline='')
            writer = csv.writer(f)
            if is_new:
                writer.writerow(headers)
            self._files[key] = (f, writer)
            return writer
        except Exception as e:
            self._status = f"Error: {e}"
            self.logStatusChanged.emit(self._status)
            return None

    def _check_date_rotation(self):
        """Close old files if date changed"""
        today = datetime.now().strftime("%Y-%m-%d")
        if today != self._last_date:
            if self._last_date:
                # Close yesterday's files
                old_keys = [k for k in self._files if not k.startswith(today)]
                for k in old_keys:
                    self._files[k][0].close()
                    del self._files[k]
            self._last_date = today

    def _flush_all(self):
        """Flush all open files to disk"""
        for f, _ in self._files.values():
            try:
                f.flush()
            except Exception:
                pass

    def _close_all(self):
        """Close all open files"""
        for f, _ in self._files.values():
            try:
                f.flush()
                f.close()
            except Exception:
                pass
        self._files.clear()
