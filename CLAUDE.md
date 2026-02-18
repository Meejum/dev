# DashOS — Custom Vehicle Operating System

## Project Overview

DashOS is a hybrid vehicle infotainment system combining:
- **ESP32-S3** (Waveshare Touch-LCD-7B): Real-time CAN/RS485 gateway
- **Raspberry Pi 5**: Main brain running UI, CarPlay, YouTube, Meshtastic
- **Heltec V3**: Meshtastic LoRa mesh radio

## Architecture

### Two Build Modes (ESP32)

| Mode | Command | Purpose |
|------|---------|---------|
| Standalone | `pio run` | LVGL dashboard on 7" display |
| Bridge | `pio run -e esp32s3-bridge` | Headless JSON serial bridge for Pi |

### System Diagram

```
Raspberry Pi 5 (DashOS)
├── Dashboard (gauges, charger monitor)
├── OBD2 Scanner (50+ PIDs, DTC read/clear)
├── Meshtastic (LoRa mesh messaging)
├── CarPlay / YouTube / Maps
├── Settings (BT, WiFi, SD, power)
└── Serial Bridge ↔ ESP32-S3
    ├── CAN bus → OBD2 (500 kbps)
    ├── RS485 → Charger Modbus (9600 baud)
    └── SPI → SD card (CSV logging)
```

## Key Files

### ESP32 Firmware

| File | Purpose |
|------|---------|
| `src/main.cpp` | Dual-mode: standalone LVGL or headless bridge |
| `include/board_config.h` | Pin assignments, CAN/RS485/SD/IGN config |
| `include/obd2_pids.h` | Full OBD2 PID table (50+ PIDs with formulas) |
| `include/obd2_dtc.h` | DTC read/clear (Mode 03/04), P-code decoder |
| `include/serial_protocol.h` | JSON bridge protocol (ESP32 ↔ Pi) |
| `include/sd_logger.h` | SD card init, CSV data logging |
| `include/ui_dashboard.h` | LVGL UI (standalone mode only) |
| `platformio.ini` | Two environments: `esp32s3-lcd-7b`, `esp32s3-bridge` |

### DashOS Pi Application

| File | Purpose |
|------|---------|
| `dashos/main.py` | Entry point, Qt/QML engine, service startup |
| `dashos/qml/Main.qml` | Root layout with sidebar navigation |
| `dashos/qml/modules/*.qml` | Dashboard, OBD2, Meshtastic, DTC, Media, Settings |
| `dashos/qml/components/*.qml` | Gauge, DataRow reusable widgets |
| `dashos/services/serial_bridge.py` | ESP32 USB serial JSON communication |
| `dashos/services/meshtastic_service.py` | Meshtastic BLE/serial messaging |
| `dashos/services/power_manager.py` | Ignition sense, clean shutdown |
| `dashos/config/dashos.conf` | Main configuration |
| `dashos/scripts/install.sh` | Pi installation script |
| `dashos/scripts/setup_autostart.sh` | Kiosk mode auto-start (cage compositor) |
| `dashos/scripts/update_ota.sh` | OTA update from GitHub |

## Building

```bash
# ESP32 Standalone (LVGL display)
pio run

# ESP32 Bridge (headless, for Pi)
pio run -e esp32s3-bridge

# DashOS Pi App (demo mode, no hardware)
cd dashos && python main.py --demo

# DashOS Pi App (fullscreen kiosk)
cd dashos && python main.py --fullscreen

# PC Simulator (BMP screenshot)
cd simulator && mkdir -p build && cd build
cmake .. && make -j$(nproc)
./dashboard_sim [output.bmp]
```

## Serial Bridge Protocol

ESP32 → Pi (500ms interval, newline-delimited JSON):
```json
{"obd":{"spd":85,"rpm":2750,"ect":88,"thr":42,"load":55},"chg":{"v":27.4,"a":28.5,"t1":42,"t2":39,"amb":28,"rate":30.0,"fault":0,"alarm":0},"can":true,"rs485":true,"ts":12345}
```

Pi → ESP32 (commands):
```json
{"cmd":"scan_dtc"}
{"cmd":"clear_dtc"}
{"cmd":"set_current","val":30.0}
{"cmd":"get_supported_pids"}
{"cmd":"shutdown"}
```

## Hardware

- **Board**: Waveshare ESP32-S3-Touch-LCD-7B (1024x600, CAN, RS485)
- **Meshtastic**: Heltec ESP32-S3 V3 (LoRa SX1262)
- **Pi**: Raspberry Pi 5 (8GB recommended)
- **Display**: 7" HDMI capacitive touchscreen (for Pi)
- **Power**: Automotive DC-DC 12V→5V with ignition sense

## Pin Map

| Interface | Pins | Purpose |
|-----------|------|---------|
| CAN/TWAI | GPIO 19/20 | OBD2 (shared with USB, EXIO5=HIGH) |
| RS485 | GPIO 15/16 | Charger Modbus 9600 baud |
| SPI (SD) | GPIO 11/12/13 + EXIO4 | SD card logging |
| I2C | GPIO 8/9 | IO expander + touch |
| IGN Sense | GPIO 6 | Vehicle ignition detect |

## Simulator

The `simulator/` directory contains a standalone PC build rendering to BMP.
- `simulator/main.cpp` — framebuffer display driver, BMP writer
- `simulator/hal_stubs.h` — stubs for `millis()` and `IRAM_ATTR`
- `simulator/lvgl/` — LVGL v8.4.0 source
