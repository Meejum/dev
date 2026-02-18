"""
Power Manager Service — Vehicle ignition sense and clean shutdown

Monitors ESP32 bridge for ignition state changes.
When ignition goes off, initiates clean Pi shutdown after configurable delay.
"""

import subprocess
import threading
import time
from PySide6.QtCore import QObject, Signal, Slot, Property


class PowerManager(QObject):
    """Manages vehicle power state and Pi shutdown"""

    ignition_changed = Signal(bool)   # True = ACC on, False = off
    shutdown_warning = Signal(int)    # Seconds until shutdown
    shutdown_cancelled = Signal()

    def __init__(self, shutdown_delay=30, parent=None):
        super().__init__(parent)
        self._ignition_on = True
        self._shutdown_delay = shutdown_delay  # seconds after key-off
        self._shutdown_pending = False
        self._shutdown_timer = None

    @Slot(bool)
    def set_ignition_state(self, state):
        """Called when ESP32 reports ignition state change"""
        if state == self._ignition_on:
            return

        self._ignition_on = state
        self.ignition_changed.emit(state)

        if not state:
            # Ignition off — start shutdown countdown
            self._start_shutdown_countdown()
        else:
            # Ignition back on — cancel shutdown
            self._cancel_shutdown()

    def _start_shutdown_countdown(self):
        """Begin countdown to shutdown"""
        self._shutdown_pending = True
        self._shutdown_timer = threading.Thread(
            target=self._countdown, daemon=True
        )
        self._shutdown_timer.start()

    def _countdown(self):
        """Background countdown thread"""
        for remaining in range(self._shutdown_delay, 0, -1):
            if not self._shutdown_pending:
                return
            self.shutdown_warning.emit(remaining)
            time.sleep(1)

        if self._shutdown_pending:
            self._do_shutdown()

    def _cancel_shutdown(self):
        """Cancel pending shutdown"""
        self._shutdown_pending = False
        self.shutdown_cancelled.emit()

    def _do_shutdown(self):
        """Execute system shutdown"""
        try:
            subprocess.run(['sudo', 'shutdown', '-h', 'now'], check=False)
        except Exception:
            pass  # Best effort

    @Slot()
    def shutdown_now(self):
        """Immediate shutdown (from settings UI)"""
        self._do_shutdown()

    @Slot()
    def reboot(self):
        """Reboot system (from settings UI)"""
        try:
            subprocess.run(['sudo', 'reboot'], check=False)
        except Exception:
            pass

    @Property(bool, notify=ignition_changed)
    def ignitionOn(self):
        return self._ignition_on
