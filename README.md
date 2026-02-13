# ⚡ ESP32-S3-LCD-7B Vehicle Dashboard

**OBD-II + Charger Monitor with LVGL GUI on Waveshare ESP32-S3-Touch-LCD-7B**

![1024×600](https://img.shields.io/badge/Display-1024×600-blue)
![LVGL 8.4](https://img.shields.io/badge/LVGL-v8.4-green)
![PlatformIO](https://img.shields.io/badge/PlatformIO-Ready-orange)
![Firmware](https://img.shields.io/badge/Firmware-v1.0-blue)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)

---

## 📖 Table of Contents
- [Project Overview](#-project-overview)
- [System Architecture](#-system-architecture)
- [Hardware Requirements](#-hardware-requirements)
- [How to Build](#-how-to-build)
- [Flashing Instructions](#-flashing-instructions)
- [Pin Configuration](#-pin-configuration)
- [Debug & Monitoring](#-debug--monitoring)
- [Troubleshooting](#-troubleshooting)
- [Known Issues](#-known-issues)
- [Customization](#-customization)
- [Development](#-development)
- [Resources](#-resources)

---

## 🚀 Project Overview

### What This Does

Displays a real-time vehicle dashboard on a Waveshare 7-inch LCD (1024×600) with dual data acquisition:

**Left Panel (OBD-II via CAN Bus)**
| Metric | Type | Range |
|--------|------|-------|
| 🏎 Speed | Arc Gauge | 0-200 km/h |
| ⚙ RPM | Arc Gauge | 0-8000 rpm |
| 🌡 Coolant Temp | Arc Gauge | 0-120°C |
| 🦶 Throttle | Arc Gauge | 0-100% |
| 📊 Engine Load | Horizontal Bar | 0-100% |

**Right Panel (Charger via RS485)**
| Metric | Type | Range |
|--------|------|-------|
| 🔋 Battery Voltage | Digital | 0-63V |
| ⚡ Charging Current | Digital | 0-50A |
| 🎯 Set Current | Digital | 12-30A |
| 🌡 Temps | Digital | 3 sensors |
| 🚨 Fault Status | Indicator | Real-time |

### Smart Charging Logic

Automatically adjusts charger current based on vehicle parameters:

```
Condition: Speed > 30 km/h AND RPM > 1000 AND
           Coolant Temp (60-100°C) AND Charger Safe
  → Use 30A (Maximum charging)

Otherwise:
  → Use 12A (Safe fallback mode)
```

---

## 🏗️ System Architecture

### Hardware Stack
```
┌─────────────────────────────────────────────────────┐
│         ESP32-S3-DevKit (Main MCU)                  │
│  ✓ Dual Core @ 240MHz  ✓ 16MB Flash  ✓ 320KB RAM  │
└──────────┬──────────────┬──────────────┬────────────┘
           │              │              │
    ┌──────▼────┐  ┌──────▼────┐  ┌─────▼──────┐
    │   CAN TX  │  │  RS485    │  │   LCD RGB  │
    │ (GPIO20)  │  │ (GPIO15/16)│  │   (GPIO)   │
    │           │  │           │  │            │
┌───▼───────────┴──┴───────┬───┴──┴────────────┘
│   Data Sources           │
├───────────────────────────┤
│ • OBD-II Vehicle (CAN)    │
│ • Charger Controller      │
│ • Sensors (I2C)           │
└───────────────────────────┘

Display: Waveshare 7" LCD (1024×600)
Graphics: LVGL 8.4 with custom dashboard UI
```

### Software Stack
```
main.cpp (FreeRTOS tasks)
  ├── CAN Bus Task       (reads OBD-II data)
  ├── RS485 Task         (reads charger status)
  ├── Charging Logic     (calculates current limit)
  ├── Display Task       (LVGL loop @ 30Hz)
  └── Serial Monitor     (debug output @ 115200 baud)

UI Layer (LVGL 8.4)
  ├── Left Panel         (vehicle metrics)
  ├── Right Panel        (charger metrics)
  └── Status Bar         (system info)
```

### Data Flow
```
Vehicle CAN Bus → TWAI Driver → OBD Parser → Data Buffer
                                               ↓
                                        Charging Logic
                                               ↑
Charger RS485 ─→ Serial Driver ─→ Charger Parser → Data Buffer
                                               ↓
                                        LVGL UI Update
                                               ↓
                                        LCD Display (30Hz)
```

---

## 💾 Hardware Requirements

### Minimum Components
- **1x** Waveshare ESP32-S3-Touch-LCD-7B board
- **1x** USB-C cable (for flashing)
- **Optional: CAN transceiver** (MCP2515 or similar for OBD-II)
- **Optional: RS485 transceiver** (MAX485 or similar for charger)

### Supported DC-DC Chargers

#### ✅ WG-BC900M Series (Recommended)

This project is **fully compatible** with the **Wengao WG-BC900M** lithium battery charger:

| Specification | Details |
|---------------|---------|
| **Model** | WG-BC900M (Shenzhen Wengao Electronic) |
| **Protocol** | Modbus RTU (RS485) |
| **Baud Rate** | 9600 bps (8N1) |
| **Input** | Dual Terminal A & B (8-60V) |
| **Output** | 10-120V DC adjustable |
| **Max Current** | 15A per output |
| **Battery Types** | Li-NCM, Li-LFP, Lead-acid (AGM/GEL) |
| **Battery Voltages** | 12V, 16V, 24V, 36V, 48V, 60V, 72V |
| **Features** | Temperature monitoring (3 sensors), Over-voltage/under-voltage protection, Fault detection |

**Why WG-BC900M?**
- ✅ Modbus RTU standard (easy to integrate)
- ✅ Dual charger support (simultaneous A & B ports)
- ✅ 3 temperature sensors (T1, T2, Ta)
- ✅ Comprehensive fault/alarm signals
- ✅ Real-time power monitoring

**Integration Details:**
- Connection: RS485 (GPIO15 TX, GPIO16 RX)
- Default address: 0x01
- Read interval: 200ms (configurable)
- Supported operations: Read voltages, currents, temps, fault status, set charging mode

**Real-Time Data Available:**
```
Terminal A Voltage  (0x0200) - 0-63V range
Terminal A Current  (0x0201) - 0-50A range
Terminal B Voltage  (0x0203) - 0-63V range
Terminal B Current  (0x0204) - 0-50A range
Temperature T1      (0x0206) - Charger internal
Temperature T2      (0x0207) - Battery sensor
Temperature Ta      (0x020E) - Ambient/environment
Power Mode          (0x0208) - Standard/Battery/Custom
Charging Mode       (0x0209) - Forward/Reverse/Auto/Manual/Peripheral
Charging Status     (0x020F) - Pre-charge/CC/CV/Float/Complete
Fault Signal        (0x020A) - Over-voltage, under-voltage, over-temp, short-circuit
```

**Modbus Protocol Summary:**
- Read function: 0x03 (read holding registers)
- Write function: 0x06 (write single register) / 0x10 (write multiple)
- CRC16 validation included
- Full protocol documentation included in project

#### Other Supported Chargers

This project can be adapted for other Modbus RTU chargers:
- **Victron SmartSolar MPPT** (Solar charge controllers)
- **Epever/Epsoltech** (MPPT/PWM controllers)
- **Meanwell** (DIN-rail DC-DC converters with RS485)
- **Custom Modbus devices** (follow WG-BC900M protocol structure)

**To use a different charger:**
1. Obtain the Modbus RTU protocol documentation
2. Map register addresses to your charger
3. Update RS485 read function in `src/main.cpp`
4. Adjust baud rate if different from 9600
5. Test with serial monitor enabled

### Recommended Setup
```
┌─────────────────────────────────────────────────┐
│ Vehicle                                         │
│ ├─ OBD-II Connector ──→ CAN Transceiver ──┐   │
│ └─ WG-BC900M Charger ─→ RS485 Transceiver ├──┐│
└──────────────────────────────────────────┘  ││
                                             ││
                        ┌────────────────────┘│
                        │  GPIO20 (CAN TX)    │
   ESP32-S3-LCD-7B  ────┤  GPIO19 (CAN RX)    │
                        │  GPIO15 (RS485 TX)  │
                        │  GPIO16 (RS485 RX)  │
                        └────────────────────┐ │
                                             ││
                    ┌───────────────────────┘ │
                    ▼                         ▼
              [LCD Display]          [Status LEDs]
```

### Build Artifacts
- **firmware.bin** (723 KB) — Flashable firmware image
- **firmware.elf** (14 MB) — Full debug executable
- **firmware.map** (9 MB) — Symbol map for debugging
- **bootloader.bin** — Boot firmware
- **partitions.bin** — Flash partition table

### Memory Layout After Build
```
RAM:   [=         ] 12.8% (41,816 / 327,680 bytes)
Flash: [=         ] 11.3% (739,634 / 6,553,600 bytes)
```

---

## 📁 Project Structure

```
├── platformio.ini                           ← PlatformIO config
├── src/
│   └── main.cpp                            ← Main app (CAN, RS485, LVGL)
├── include/
│   ├── board_config.h                      ← Pin definitions
│   ├── ui_dashboard.h                      ← LVGL UI layout
│   ├── lv_conf.h                           ← LVGL 8.4 config
│   └── esp_panel_board_custom_conf.h       ← Display panel driver
├── .devcontainer/
│   └── devcontainer.json                   ← GitHub Codespaces
├── .github/workflows/
│   └── build.yml                           ← CI/CD pipeline
├── partitions_16MB_large.csv                ← Flash partition table
└── README.md                                ← This file
```

---

## 🛠 How to Build (3 Options)

### Option A: GitHub Actions (Recommended)

1. Go to **Actions** tab → Latest run
2. Download **firmware-bin** artifact
3. Flash using [ESP Web Flasher](https://web.esptool.io)

### Option B: GitHub Codespaces (Free Online)

```bash
pio run -e esp32s3-lcd-7b
# Download .pio/build/esp32s3-lcd-7b/firmware.bin
```

### Option C: Local VS Code + PlatformIO

```bash
git clone https://github.com/Meejum/ESP32-S3-LCD-7B-Vehicle-Dashboard.git
cd ESP32-S3-LCD-7B-Vehicle-Dashboard

# Build
pio run -e esp32s3-lcd-7b

# Or click Build (✓) in PlatformIO toolbar
```

### Build Commands

```bash
# Clean build
pio run -e esp32s3-lcd-7b --target clean

# Build with verbose output
pio run -e esp32s3-lcd-7b --verbose

# View memory
pio run -e esp32s3-lcd-7b | grep "Memory Usage"
```

---

## 🔌 Flashing Instructions

### Method 1: ESP Web Flasher (Easiest - No Install!)

```
1. Open https://web.esptool.io (Chrome/Edge)
2. Click Connect → Select COM port
3. Set Flash Address: 0x10000
4. Select firmware.bin
5. Click Program
6. Press RESET on board
```

### Method 2: Command Line (esptool.py)

```bash
pip install esptool

# Flash
esptool.py --port /dev/ttyUSB0 --baud 921600 write_flash 0x10000 firmware.bin

# Monitor output
esptool.py --port /dev/ttyUSB0 --baud 115200 monitor
```

### Method 3: PlatformIO

```bash
pio run -e esp32s3-lcd-7b --target upload
```

### Bootloader Mode

If board not detected:
1. Hold **BOOT** button
2. Plug USB-C cable
3. Release **BOOT**
4. Try again

---

## 🔧 Pin Configuration

### Critical: GPIO19/GPIO20 USB/CAN Conflict

⚠️ **This board shares GPIO19/20 between USB and CAN**

| Pin | CAN Mode | USB Mode | Default |
|-----|----------|----------|---------|
| GPIO19 | ✓ CAN RX | ✗ USB | CAN (EXIO5=HIGH) |
| GPIO20 | ✓ CAN TX | ✗ USB | CAN (EXIO5=HIGH) |

**Important**: Use UART USB port (not default USB) for programming when CAN is enabled!

### Pin Mapping

| Function | GPIO | Purpose |
|----------|------|---------|
| CAN TX | GPIO20 | OBD-II requests |
| CAN RX | GPIO19 | Vehicle data |
| RS485 TX | GPIO15 | Charger commands |
| RS485 RX | GPIO16 | Charger status |
| LCD RGB Data | GPIO2,4,5,6,7,11 | Pixel data |
| LCD PCLK | GPIO3 | Pixel clock |
| LCD HSYNC | GPIO46 | H-sync |
| LCD VSYNC | GPIO9 | V-sync |
| LCD DE | GPIO8 | Data enable |
| I2C SDA | GPIO8 | IO Expander |
| I2C SCL | GPIO9 | IO Expander |

### Comparison with T-CAN485

| Function | T-CAN485 | 7B Version | Status |
|----------|----------|-----------|--------|
| CAN TX | GPIO17 | GPIO20 | ⚠️ Changed |
| CAN RX | GPIO18 | GPIO19 | ⚠️ Changed |
| RS485 TX | GPIO22 | GPIO15 | ⚠️ Changed |
| RS485 RX | GPIO21 | GPIO16 | ⚠️ Changed |
| RS485 EN | GPIO19 | (Auto) | ✓ Removed |

---

## 🐛 Debug & Monitoring

### Serial Monitor

```bash
# PlatformIO
pio device monitor --port /dev/ttyUSB0 --baud 115200

# Generic (Linux/Mac)
screen /dev/ttyUSB0 115200

# Python miniterm
python -m serial.tools.miniterm /dev/ttyUSB0 115200
```

### Debug Output Sample

```
[INIT] ESP32-S3-LCD-7B Vehicle Dashboard v1.0
[INIT] CAN Bus: 500 kbaud
[INIT] RS485: 9600 baud
[INIT] Display: 1024x600 @30Hz
[INIT] Memory: RAM=41KB / Flash=740KB

[CAN] ID:0x100 Speed=65km/h RPM=2500
[RS485] Voltage=48.2V Current=25A
[CHARGE] Conditions OK → 30A
[LVGL] Frame time: 33ms

[ERROR] CAN timeout!
[WARNING] Charger fault!
```

### Enable Debug Features

In **main.cpp**:

```cpp
#define DEBUG_CAN 1          // Log CAN messages
#define DEBUG_RS485 1        // Log charger data
#define DEBUG_CHARGING 1     // Log charge logic
#define DEBUG_DISPLAY 1      // Log display updates
```

### Memory Monitoring

```cpp
void check_memory() {
    esp_task_wdt_reset();
    printf("Free heap: %lu bytes\n", esp_get_free_heap_size());
    printf("Min heap: %lu bytes\n", esp_get_minimum_free_heap_size());
    printf("Free PSRAM: %lu bytes\n", esp_spiram_get_free_size());
}
```

---

## ⚠️ Troubleshooting

### Build Failures

#### Error: "undefined reference to `lv_font_montserrat_*'"

**Cause**: Missing font flags in platformio.ini

**Fix**:
```ini
build_flags =
    -DLV_FONT_MONTSERRAT_12=1
    -DLV_FONT_MONTSERRAT_16=1
    -DLV_FONT_MONTSERRAT_24=1
    -DLV_FONT_MONTSERRAT_28=1
    -DLV_FONT_MONTSERRAT_36=1
```

#### Error: "'full_refr' is deprecated"

**Cause**: LVGL v8.4 API change

**Fix** (src/main.cpp:289):
```cpp
// OLD (wrong):
disp_drv.full_refr = 0;

// NEW (correct):
disp_drv.full_refresh = 0;
```

#### Error: "'.sconsign311.tmp' No such file"

**Cause**: Build directory corruption

**Fix**:
```bash
pio run -e esp32s3-lcd-7b --target clean
pio run -e esp32s3-lcd-7b
```

### Flash Failures

#### "Serial port not found"

**Solutions**:
```bash
# Check ports
# Linux: ls /dev/ttyUSB*
# Windows: Device Manager → COM ports
# macOS: ls /dev/tty.usbserial*

# Try bootloader mode:
# 1. Hold BOOT
# 2. Plug USB-C
# 3. Release BOOT
```

#### "Flash write failed"

**Solutions**:
```bash
# Erase all flash
esptool.py --port /dev/ttyUSB0 erase_flash

# Try again
esptool.py --port /dev/ttyUSB0 write_flash 0x10000 firmware.bin
```

### Runtime Issues

#### LCD shows garbage/no display

- Check RGB pin connections (GPIO2,4,5,6,7,11)
- Verify LCD power supply (5V)
- Check LVGL buffer size in lv_conf.h
- View serial monitor for init errors

#### No CAN data (left panel empty)

- Verify GPIO19/20 connections
- Check CAN transceiver power
- Confirm EXIO5 = HIGH for CAN mode
- Check CAN baud rate (500 kbaud)
- Monitor: look for "[CAN]" messages

#### No RS485 data (right panel empty)

- Verify GPIO15/16 connections
- Check charger baud rate (9600)
- Test with RS485 analyzer
- Check protocol (Modbus/custom)
- Monitor: look for "[RS485]" messages

#### Board gets hot

- Reduce refresh rate (max 30Hz)
- Disable unused features
- Check for shorts
- Improve ventilation

---

## 🔧 Customization

### Change Charging Thresholds

Edit **src/main.cpp** - `updateChargingLogic()`:

```cpp
// Modify these conditions:
if (speed > 30 &&              // Change 30 km/h threshold
    rpm > 1000 &&              // Change 1000 rpm threshold
    coolant >= 60 && coolant <= 100 &&  // Change temp range
    charger_safe) {
    setChargerCurrent(30);     // Max current
} else {
    setChargerCurrent(12);     // Safe fallback
}
```

### Enable Touch Support

In **include/esp_panel_board_custom_conf.h**:

```cpp
#define ESP_PANEL_USE_TOUCH  1  // Enable touch input
```

### Change UI Colors

Edit **include/ui_dashboard.h**:

```cpp
#define C_ACCENT  lv_color_hex(0xf59e0b)  // Amber (default)
#define C_BG      lv_color_hex(0x1f2937)  // Dark gray
#define C_TEXT    lv_color_hex(0xffffff)  // White
#define C_GOOD    lv_color_hex(0x10b981)  // Green
#define C_WARN    lv_color_hex(0xf59e0b)  // Amber
#define C_ERROR   lv_color_hex(0xef4444)  // Red
```

### Adjust Display Refresh Rate

In **src/main.cpp**:

```cpp
#define LV_DISP_DEF_REFR_PERIOD 33  // 30 Hz (reduce if slow)
```

### Change CAN Baud Rate

In **src/main.cpp**:

```cpp
can.begin(500000);  // 500 kbaud (default)
// OR
can.begin(250000);  // 250 kbaud (alternative)
```

### Configure WG-BC900M Charger

The project is pre-configured for WG-BC900M chargers. To customize:

**1. Modbus Address:**
```cpp
#define MODBUS_SLAVE_ID 0x01  // Default charger address
#define MODBUS_BAUD 9600      // Default baud rate
```

**2. Read Registers (Real-Time Data):**
```cpp
// Voltage monitoring (divide by 100 for actual value)
float terminalA_voltage = readModbus(0x0200) / 100.0f;  // V
float terminalA_current = readModbus(0x0201) / 100.0f;  // A

// Temperature sensors
int temp_T1 = readModbus(0x0206);  // °C (charger internal)
int temp_T2 = readModbus(0x0207);  // °C (battery)
int temp_Ta = readModbus(0x020E);  // °C (ambient)

// Charging status
int charging_status = readModbus(0x020F);
// 0: DC-DC Mode, 1: Pre-charge, 2: CC, 3: CV, 4: Float, 5: Complete

// Fault detection
int fault_signal = readModbus(0x020A);
// Check bits: Bit0=short-circuit, Bit1=over-voltage, Bit2=under-voltage, etc.
```

**3. Write Registers (Control):**
```cpp
// Set charging mode
writeModbus(0x0403, 0x0002);  // Auto mode (forward/reverse)
writeModbus(0x0403, 0x0001);  // Reverse mode
writeModbus(0x0403, 0x0000);  // Forward mode

// Set battery type
writeModbus(0x0404, 0x0024);  // Terminal A: 48V Li-LFP
writeModbus(0x0405, 0x0024);  // Terminal B: 48V Li-LFP

// Set voltage thresholds
writeModbus(0x0820, 4000);   // Terminal A: 40V min (4000 * 0.01)
writeModbus(0x0822, 5500);   // Terminal A: 55V max (5500 * 0.01)
```

**4. Modbus CRC Calculation:**
The project includes CRC16 validation (included in src/main.cpp):
```cpp
// CRC16 is automatically calculated for all Modbus frames
// Uses Modbus RTU standard polynomial (0xA001)
```

**5. Troubleshooting Charger Communication:**
```bash
# Monitor serial output
pio device monitor --port /dev/ttyUSB0 --baud 115200

# Look for messages like:
# [RS485] Charger connected
# [RS485] TX: 01 03 0200 0001 CRC
# [RS485] RX: 01 03 02 0B86 CRC
# [RS485] Voltage: 29.50V Current: 10.50A
```

### Customize Gauge Ranges

In **src/main.cpp**:

```cpp
// Speed gauge (0-200 km/h)
lv_arc_set_range(speed_gauge, 0, 200);

// RPM gauge (0-8000)
lv_arc_set_range(rpm_gauge, 0, 8000);

// Temperature gauge (0-120°C)
lv_arc_set_range(coolant_gauge, 0, 120);
```

---

## 🚀 Development

### Setup Environment

```bash
# Install PlatformIO
pip install platformio

# Install VSCode extension
# Open VSCode → Extensions → Search "PlatformIO"

# Clone project
git clone https://github.com/Meejum/ESP32-S3-LCD-7B-Vehicle-Dashboard.git
cd ESP32-S3-LCD-7B-Vehicle-Dashboard

# Build
pio run -e esp32s3-lcd-7b
```

### Common Development Tasks

```bash
# Clean build
pio run -e esp32s3-lcd-7b --target clean

# Build for testing
pio run -e esp32s3-lcd-7b

# Upload to board
pio run -e esp32s3-lcd-7b --target upload

# Monitor serial output
pio device monitor --port /dev/ttyUSB0 --baud 115200

# Build + upload + monitor
pio run -e esp32s3-lcd-7b --target upload && pio device monitor
```

### Code Structure

**main.cpp** (~500 lines):
- Initialization code
- CAN read task
- RS485 read task
- Charging logic
- LVGL display loop
- Serial debug output

**ui_dashboard.h** (~300 lines):
- Widget creation
- Style definitions
- Update functions
- Color definitions

**board_config.h** (~100 lines):
- Pin definitions
- Baud rates
- Timeouts

---

## 📊 Performance Specs

| Metric | Value |
|--------|-------|
| Display Refresh | 30 Hz |
| CAN Update Rate | 100 ms |
| RS485 Update Rate | 200 ms |
| Charging Logic Rate | 500 ms |
| CPU Usage | ~40% |
| RAM Usage | 12.8% |
| Flash Usage | 11.3% |
| Display Boot Time | ~2 seconds |

---

## 🔗 Resources

- [Waveshare Wiki - ESP32-S3-Touch-LCD-7B](https://www.waveshare.com/wiki/ESP32-S3-Touch-LCD-7B)
- [LVGL v8 Documentation](https://docs.lvgl.io/8.4/)
- [ESP32 TWAI (CAN) API](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/twai.html)
- [EPS Web Flasher](https://web.esptool.io/)
- [PlatformIO Documentation](https://docs.platformio.org/)
- [Waveshare ESP32-S3-LCD-7B Demo](https://files.waveshare.com/wiki/ESP32-S3-Touch-LCD-7B/ESP32-S3-Touch-LCD-7B-Demo.zip)

---

## 📝 License

MIT — use freely for your projects.

---

## ✅ Changelog

### v1.0 (Current)
- ✅ Initial release
- ✅ OBD-II support via CAN bus
- ✅ Charger monitoring via RS485
- ✅ Smart charging logic
- ✅ LVGL 8.4 UI dashboard
- ✅ Serial monitoring @ 115200 baud
- ✅ GitHub Actions CI/CD
- ✅ Production-ready firmware

---

**Last Updated**: February 2026
**Maintainer**: Meejum
**Status**: Production Ready ✅
