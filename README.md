# ⚡ ESP32-S3-LCD-7B Vehicle Dashboard

**OBD-II + Charger Monitor with LVGL GUI on Waveshare ESP32-S3-Touch-LCD-7B**

![1024×600](https://img.shields.io/badge/Display-1024×600-blue)
![LVGL 8.4](https://img.shields.io/badge/LVGL-v8.4-green)
![PlatformIO](https://img.shields.io/badge/PlatformIO-Ready-orange)

---

## 🚀 What This Does

Displays a real-time vehicle dashboard on the 7-inch LCD:

| Left Panel (OBD-II via CAN) | Right Panel (Charger via RS485) |
|---|---|
| 🏎 Speed (km/h) arc gauge | 🔋 Battery Voltage |
| ⚙ RPM arc gauge | ⚡ Charging Current |
| 🌡 Coolant Temp arc gauge | 🎯 Current Set Point |
| 🦶 Throttle % arc gauge | 🌡 Temps (T1, T2, Ambient) |
| 📊 Engine Load bar | 🚨 Fault/Alarm Status |

**Smart charging logic:** Automatically adjusts charger current (12A → 30A) based on vehicle speed, RPM, coolant temp, and charger health.

---

## 📁 Project Structure

```
├── platformio.ini                  ← PlatformIO config (board, libs, flags)
├── src/
│   └── main.cpp                    ← Main app (CAN, RS485, loop)
├── include/
│   ├── board_config.h              ← All pin definitions
│   ├── ui_dashboard.h              ← LVGL UI layout + update
│   ├── lv_conf.h                   ← LVGL configuration
│   └── esp_panel_board_custom_conf.h ← Display panel config
├── .devcontainer/
│   └── devcontainer.json           ← GitHub Codespaces config
├── .github/workflows/
│   └── build.yml                   ← Auto-compile on push
└── README.md
```

---

## 🛠 How to Build (3 Options)

### Option A: GitHub Actions (Fully Online — Recommended)

1. **Push this repo to GitHub**
2. GitHub Actions will **automatically compile** on every push
3. Go to **Actions** tab → click latest run → download `firmware-bin` artifact
4. Flash the `.bin` file using [ESP Web Flasher](https://web.esptool.io)

### Option B: GitHub Codespaces (Online VS Code)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for environment setup (~2 min)
3. Open terminal and run:
   ```bash
   pio run -e esp32s3-lcd-7b
   ```
4. Download `.pio/build/esp32s3-lcd-7b/firmware.bin`
5. Flash via [ESP Web Flasher](https://web.esptool.io)

### Option C: Local VS Code + PlatformIO

1. Install [VS Code](https://code.visualstudio.com) + [PlatformIO extension](https://platformio.org/install/ide?install=vscode)
2. Clone this repo and open folder in VS Code
3. PlatformIO will auto-install dependencies
4. Click **Build** (✓ checkmark) in bottom toolbar
5. Click **Upload** (→ arrow) to flash directly

---

## 🔌 Flashing with ESP Web Flasher (No Install!)

1. Go to **https://web.esptool.io** in Chrome/Edge
2. Connect your ESP32-S3-LCD-7B via USB-C (UART port)
3. Click **Connect** → select the serial port
4. Set flash address: **0x10000**
5. Upload **firmware.bin**
6. Click **Program**
7. Press **RESET** on the board

> ⚠️ If board isn't detected: Hold **BOOT** → plug USB → release **BOOT**

---

## ⚠️ Critical Hardware Notes

### CAN / USB Pin Conflict
GPIO19 and GPIO20 are **shared** between USB and CAN bus.
- `EXIO5 = HIGH` → **CAN mode** (for OBD-II) ← This project uses this
- `EXIO5 = LOW` → **USB mode**
- **You must use the UART USB port** for programming when CAN is active!

### RS485 Auto-Direction
The 7B board has **automatic RS485 direction switching**.
No DE/RE enable pin is needed — just TX/RX.

### Pin Mapping (vs original T-CAN485)

| Function | T-CAN485 (old) | ESP32-S3-LCD-7B (new) |
|----------|----------------|----------------------|
| CAN TX | GPIO17 | GPIO20 ⚠️ |
| CAN RX | GPIO18 | GPIO19 ⚠️ |
| RS485 TX | GPIO22 | GPIO15 |
| RS485 RX | GPIO21 | GPIO16 |
| RS485 EN | GPIO19 | Not needed (auto) |
| I2C SDA | — | GPIO8 |
| I2C SCL | — | GPIO9 |

---

## 🔧 Customization

### Change Charging Thresholds
Edit `updateChargingLogic()` in `src/main.cpp`:
```cpp
// Speed > 30, RPM > 1000, ECT in range, charger safe → 30A
// Otherwise → 12A fallback
```

### Enable Touch (if you have touch version)
In `include/esp_panel_board_custom_conf.h`:
```cpp
#define ESP_PANEL_USE_TOUCH  1
```

### Change UI Colors
Edit color defines in `include/ui_dashboard.h`:
```cpp
#define C_ACCENT  lv_color_hex(0xf59e0b)  // Change amber to any color
```

---

## 📚 Resources

- [Waveshare Wiki - ESP32-S3-Touch-LCD-7B](https://www.waveshare.com/wiki/ESP32-S3-Touch-LCD-7B)
- [LVGL v8 Documentation](https://docs.lvgl.io/8.4/)
- [ESP32 TWAI (CAN) API](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/twai.html)
- [Waveshare Demo Package](https://files.waveshare.com/wiki/ESP32-S3-Touch-LCD-7B/ESP32-S3-Touch-LCD-7B-Demo.zip)

---

## 📝 License

MIT — use freely for your projects.
