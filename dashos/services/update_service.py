"""
Update Service — GitHub OTA update checker and installer for DashOS

Periodically checks the configured GitHub repo for new commits.
Notifies the UI when an update is available, and can trigger
the update process on demand.
"""

import os
import subprocess
import threading
import time

from PySide6.QtCore import QObject, Signal, QTimer


class UpdateService(QObject):
    """Background service that checks GitHub for DashOS updates"""

    # Signals for QML binding
    updateAvailable = Signal(bool)     # True when a newer commit exists
    updateStatus = Signal(str)         # Status text ("Checking...", "Up to date", etc.)
    updateInProgress = Signal(bool)    # True while update is being applied
    updateLog = Signal(str)            # Live output from update process

    CHECK_INTERVAL_MS = 15 * 60 * 1000  # Check every 15 minutes

    def __init__(self, repo_url="", branch="main", dashos_dir="", parent=None):
        super().__init__(parent)
        self._repo_url = repo_url
        self._branch = branch
        self._dashos_dir = dashos_dir or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self._has_update = False
        self._status = "Not checked"
        self._in_progress = False
        self._remote_commit = ""
        self._local_commit = ""
        self._remote_message = ""

        # Periodic check timer
        self._timer = QTimer(self)
        self._timer.timeout.connect(self.checkForUpdates)

    def start(self):
        """Start periodic update checking"""
        # Initial check after 30 seconds (let app settle)
        QTimer.singleShot(30000, self.checkForUpdates)
        self._timer.start(self.CHECK_INTERVAL_MS)

    def stop(self):
        """Stop periodic checking"""
        self._timer.stop()

    def checkForUpdates(self):
        """Check GitHub for new commits (runs git fetch in background thread)"""
        if self._in_progress:
            return
        self._set_status("Checking for updates...")
        thread = threading.Thread(target=self._check_remote, daemon=True)
        thread.start()

    def applyUpdate(self):
        """Apply the available update (runs in background thread)"""
        if self._in_progress or not self._has_update:
            return
        self._in_progress = True
        self.updateInProgress.emit(True)
        self._set_status("Updating...")
        thread = threading.Thread(target=self._run_update, daemon=True)
        thread.start()

    def _check_remote(self):
        """Background: fetch remote and compare commits"""
        try:
            git_dir = self._find_git_dir()
            if not git_dir:
                self._set_status("No git repo found")
                return

            # Fetch latest from remote
            result = subprocess.run(
                ["git", "fetch", "origin", self._branch],
                cwd=git_dir, capture_output=True, text=True, timeout=30
            )
            if result.returncode != 0:
                self._set_status("Fetch failed: " + result.stderr.strip()[:80])
                return

            # Get local HEAD
            result = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=git_dir, capture_output=True, text=True, timeout=5
            )
            self._local_commit = result.stdout.strip()[:7]

            # Get remote HEAD
            result = subprocess.run(
                ["git", "rev-parse", f"origin/{self._branch}"],
                cwd=git_dir, capture_output=True, text=True, timeout=5
            )
            self._remote_commit = result.stdout.strip()[:7]

            # Get remote commit message
            result = subprocess.run(
                ["git", "log", f"origin/{self._branch}", "-1", "--format=%s"],
                cwd=git_dir, capture_output=True, text=True, timeout=5
            )
            self._remote_message = result.stdout.strip()[:100]

            # Count commits behind
            result = subprocess.run(
                ["git", "rev-list", "--count", f"HEAD..origin/{self._branch}"],
                cwd=git_dir, capture_output=True, text=True, timeout=5
            )
            behind = int(result.stdout.strip()) if result.stdout.strip().isdigit() else 0

            if behind > 0:
                self._has_update = True
                self.updateAvailable.emit(True)
                self._set_status(
                    f"Update available ({behind} commit{'s' if behind > 1 else ''}): "
                    f"{self._remote_message}"
                )
            else:
                self._has_update = False
                self.updateAvailable.emit(False)
                self._set_status(f"Up to date ({self._local_commit})")

        except subprocess.TimeoutExpired:
            self._set_status("Check timed out — no network?")
        except Exception as e:
            self._set_status(f"Check failed: {str(e)[:60]}")

    def _run_update(self):
        """Background: pull changes and restart"""
        try:
            git_dir = self._find_git_dir()
            if not git_dir:
                self._set_status("No git repo found")
                self._in_progress = False
                self.updateInProgress.emit(False)
                return

            # Pull latest
            self.updateLog.emit("Pulling latest changes...")
            result = subprocess.run(
                ["git", "pull", "origin", self._branch],
                cwd=git_dir, capture_output=True, text=True, timeout=60
            )
            self.updateLog.emit(result.stdout)
            if result.returncode != 0:
                self.updateLog.emit("Pull failed: " + result.stderr)
                self._set_status("Update failed — see log")
                self._in_progress = False
                self.updateInProgress.emit(False)
                return

            # Try installing dependencies if requirements.txt exists
            req_path = os.path.join(git_dir, "requirements.txt")
            if os.path.exists(req_path):
                self.updateLog.emit("Updating dependencies...")
                subprocess.run(
                    ["pip3", "install", "--break-system-packages", "-r", req_path],
                    cwd=git_dir, capture_output=True, text=True, timeout=120
                )

            self.updateLog.emit("Update complete! Restart to apply.")
            self._has_update = False
            self.updateAvailable.emit(False)
            self._set_status("Updated! Restart to apply")
            self._in_progress = False
            self.updateInProgress.emit(False)

        except subprocess.TimeoutExpired:
            self.updateLog.emit("Update timed out")
            self._set_status("Update timed out")
            self._in_progress = False
            self.updateInProgress.emit(False)
        except Exception as e:
            self.updateLog.emit(f"Error: {e}")
            self._set_status(f"Update failed: {str(e)[:60]}")
            self._in_progress = False
            self.updateInProgress.emit(False)

    def _find_git_dir(self):
        """Find the git repository root"""
        # Check if dashos dir itself is in a git repo
        check = self._dashos_dir
        for _ in range(5):
            if os.path.isdir(os.path.join(check, ".git")):
                return check
            parent = os.path.dirname(check)
            if parent == check:
                break
            check = parent
        return None

    def _set_status(self, text):
        """Update status text and emit signal"""
        self._status = text
        self.updateStatus.emit(text)
