# ESP32-S3-LCD-7B Vehicle Dashboard

## Project Overview

Vehicle dashboard + charger monitor running on Waveshare ESP32-S3-Touch-LCD-7B.
Combines OBD-II via CAN bus, Modbus RTU via RS485, and LVGL 8.4 GUI on a 1024x600 RGB display.

## Architecture

- **Target**: ESP32-S3 (Waveshare ESP32-S3-Touch-LCD-7B)
- **Framework**: Arduino via PlatformIO
- **GUI**: LVGL v8.4.0 — dark industrial theme, 1024x600, 16-bit RGB565
- **Display**: ST7701 RGB LCD via ESP_Panel_Library
- **IO Expander**: CH422G (I2C 0x24) for backlight, LCD power, CAN/USB mux
- **Communication**: CAN bus (TWAI driver) for OBD-II, RS485 (UART1) for Modbus charger

## Key Files

| File | Purpose |
|------|---------|
| `src/main.cpp` | Setup, OBD-II polling, Modbus charger comms, LVGL loop |
| `include/ui_dashboard.h` | LVGL UI — creates and updates all widgets |
| `include/board_config.h` | Pin assignments, I2C/CAN/RS485 config, register map |
| `include/lv_conf.h` | LVGL configuration (fonts, widgets, color depth) |
| `platformio.ini` | Build config, dependencies, board settings |

## Building

```bash
# Firmware (requires PlatformIO)
pio run

# PC Simulator (no hardware needed)
cd simulator && mkdir -p build && cd build
cmake .. && make -j$(nproc)
./dashboard_sim [output.bmp]
```

## Simulator

The `simulator/` directory contains a standalone PC build of the dashboard UI.
It renders to an in-memory framebuffer and writes a BMP screenshot — no SDL2 or display server required.

- `simulator/main.cpp` — entry point, framebuffer display driver, BMP writer
- `simulator/hal_stubs.h` — stubs for `millis()` and `IRAM_ATTR`
- `simulator/lv_conf.h` — LVGL config adapted for PC (no byte swap, manual tick)
- `simulator/lvgl/` — LVGL v8.4.0 source (cloned, not a submodule)

## Data Flow

1. `readAllOBD()` queries ECU via CAN (PIDs: speed, RPM, coolant, throttle, load)
2. `readAllCharger()` reads Modbus registers (voltage, current, temps, faults)
3. `updateChargingLogic()` sets charge rate (12A reduced / 30A full) based on conditions
4. `ui_dashboard_update(&vdata)` refreshes all LVGL widgets with live data
5. `lv_timer_handler()` drives LVGL rendering at ~5ms intervals

## Display Layout

```
┌──────────────────────────────────────────────────────┐
│ [CAN] [RS485]    ⚡ VEHICLE DASHBOARD      UP:00:00  │
├────────────────────────────┬─────────────────────────┤
│  OBD-II DATA               │  CHARGER                │
│  ┌──────┐ ┌──────┐ ┌────┐ │  BATTERY      27.40 V   │
│  │ SPD  │ │ RPM  │ │ECT │ │  CURRENT      28.5 A    │
│  │  85  │ │ 2750 │ │ 88 │ │  SET POINT    30.0 A    │
│  └──────┘ └──────┘ └────┘ │  TEMP T1      42 °C     │
│     ┌──────┐               │  TEMP T2      39 °C     │
│     │ THR  │               │  AMBIENT      28 °C     │
│     │  42  │               │                         │
│     └──────┘               │  ✓ CHARGING FULL RATE   │
│  ENGINE LOAD         55%   │  30A — All systems OK   │
└────────────────────────────┴─────────────────────────┘
```
