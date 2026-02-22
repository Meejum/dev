@echo off
REM DashOS Desktop — Windows Launcher
REM Connects to ESP32/LilyGo T-CAN485 via USB serial

echo ===================================
echo  DashOS Desktop - Vehicle Dashboard
echo ===================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Install Python 3.8+ from python.org
    pause
    exit /b 1
)

REM Install dependencies if needed
pip show PySide6 >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    pip install -r "%~dp0requirements.txt"
    echo.
)

REM Launch with arguments passed through
python "%~dp0main.py" %*
pause
