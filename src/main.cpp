/**
 * @file main.cpp
 * ESP32-S3-LCD-7B — Vehicle Dashboard + Charger Monitor
 *
 * Two build modes:
 *   BRIDGE_MODE=1 — Headless serial bridge for Raspberry Pi (DashOS)
 *   BRIDGE_MODE=0 — Standalone LVGL dashboard on 7" display (default)
 *
 * Combines:
 *   - OBD-II via CAN bus (TWAI) — full scanner with 50+ PIDs
 *   - Modbus RTU via RS485 for charger monitoring
 *   - SD card CSV data logging
 *   - (Bridge mode) JSON serial protocol to Raspberry Pi
 *   - (Standalone) LVGL 8.4 GUI on 1024×600 RGB display
 *
 * Target: Waveshare ESP32-S3-Touch-LCD-7B
 */

#include <Arduino.h>
#include <driver/twai.h>
#include <Wire.h>

#include "board_config.h"
#include "obd2_pids.h"
#include "obd2_dtc.h"

#ifndef BRIDGE_MODE
#define BRIDGE_MODE 0
#endif

#if !BRIDGE_MODE
// ─── Standalone display mode ─────────────────────────
#include <lvgl.h>
#include <ESP_Panel_Library.h>
#include <ESP_IOExpander_Library.h>
#include "ui_dashboard.h"

static lv_disp_draw_buf_t draw_buf;
static lv_color_t *buf1 = NULL;
static lv_color_t *buf2 = NULL;
static ESP_Panel *panel = NULL;
#endif

#if BRIDGE_MODE
// ─── Bridge mode — serial protocol ──────────────────
#include "serial_protocol.h"
static char json_buf[JSON_BUF_SIZE];
static char cmd_buf[CMD_BUF_SIZE];

// DTC storage for bridge mode
static DTCResult stored_dtcs;
static bool dtc_scan_requested = false;
static bool dtc_clear_requested = false;
#endif

// ─── IO Expander (needed in both modes for CAN mux) ──
#include <ESP_IOExpander_Library.h>
static ESP_IOExpander *io_expander = NULL;

/* ══════════════════════════════════════════════════════════════
 * GLOBAL VEHICLE + CHARGER DATA
 * ══════════════════════════════════════════════════════════════*/
#if BRIDGE_MODE
// Minimal VehicleData for bridge mode (no LVGL dependency)
struct VehicleData {
    int speed = -1, rpm = -1, ect = -1, throttle = -1, load = -1;
    float battV = 0, battI = 0, setA = 12.0f, targetCurrent = 12.0f;
    int tempT1 = 0, tempT2 = 0, tempAmb = 0;
    uint16_t fault = 0, alarm = 0, status = 0;
    bool canOk = false, rs485Ok = false;
    // Extended OBD fields
    float fuelRate = -1;       // L/h (PID 0x5E)
    float fuelLevel = -1;      // % (PID 0x2F)
    float maf = -1;            // g/s (PID 0x10)
    int intakeAirTemp = -40;   // °C (PID 0x0F)
    int oilTemp = -40;         // °C (PID 0x5C)
    float timingAdv = 0;       // degrees (PID 0x0E)
    float o2Voltage = -1;      // V (PID 0x14)
    int fuelPressure = -1;     // kPa (PID 0x0A)
};
#endif

VehicleData vdata;

/* ══════════════════════════════════════════════════════════════
 * MODBUS CRC16 CALCULATION
 * ══════════════════════════════════════════════════════════════*/
uint16_t modbusCRC(uint8_t *buf, uint16_t len) {
    uint16_t crc = 0xFFFF;
    for (uint16_t i = 0; i < len; i++) {
        crc ^= buf[i];
        for (uint8_t j = 0; j < 8; j++) {
            if (crc & 1) crc = (crc >> 1) ^ 0xA001;
            else crc >>= 1;
        }
    }
    return (crc >> 8) | (crc << 8);
}

/* ══════════════════════════════════════════════════════════════
 * OBD-II VIA CAN (TWAI)
 * ══════════════════════════════════════════════════════════════*/
int queryOBD(uint8_t pid, int responseBytes) {
    twai_message_t tx;
    memset(&tx, 0, sizeof(tx));
    tx.identifier = 0x7DF;
    tx.data_length_code = 8;
    tx.data[0] = 2;
    tx.data[1] = 1;
    tx.data[2] = pid;

    if (twai_transmit(&tx, pdMS_TO_TICKS(80)) != ESP_OK) return -1;

    twai_message_t rx;
    unsigned long t0 = millis();
    while (millis() - t0 < 200) {
        if (twai_receive(&rx, pdMS_TO_TICKS(50)) == ESP_OK) {
            if (rx.identifier >= 0x7E8 && rx.identifier <= 0x7EF && rx.data[2] == pid) {
                vdata.canOk = true;
                if (responseBytes == 1) return rx.data[3];
                if (responseBytes == 2) return (rx.data[3] << 8) | rx.data[4];
            }
        }
    }
    return -1;
}

// Read core OBD2 PIDs (fast — for dashboard display)
void readCoreOBD() {
    vdata.speed = queryOBD(PID_SPEED, 1);

    int rawRPM = queryOBD(PID_RPM, 2);
    vdata.rpm = rawRPM >= 0 ? rawRPM / 4 : -1;

    int rawECT = queryOBD(PID_COOLANT, 1);
    vdata.ect = rawECT >= 0 ? rawECT - 40 : -1;

    int rawThrot = queryOBD(PID_THROTTLE, 1);
    vdata.throttle = rawThrot >= 0 ? (rawThrot * 100) / 255 : -1;

    int rawLoad = queryOBD(PID_LOAD, 1);
    vdata.load = rawLoad >= 0 ? (rawLoad * 100) / 255 : -1;
}

// Read extended OBD2 PIDs (for trip computer, fuel, diagnostics)
void readExtendedOBD() {
    // Fuel Rate (PID 0x5E) — 2 bytes, scale 0.05
    int rawFuelRate = queryOBD(0x5E, 2);
    vdata.fuelRate = rawFuelRate >= 0 ? rawFuelRate * 0.05f : -1;

    // Fuel Level (PID 0x2F) — 1 byte, scale 100/255
    int rawFuelLvl = queryOBD(0x2F, 1);
    vdata.fuelLevel = rawFuelLvl >= 0 ? (rawFuelLvl * 100.0f) / 255.0f : -1;

    // MAF Air Flow (PID 0x10) — 2 bytes, scale 0.01
    int rawMAF = queryOBD(0x10, 2);
    vdata.maf = rawMAF >= 0 ? rawMAF * 0.01f : -1;

    // Intake Air Temp (PID 0x0F) — 1 byte, offset -40
    int rawIAT = queryOBD(0x0F, 1);
    vdata.intakeAirTemp = rawIAT >= 0 ? rawIAT - 40 : -40;

    // Engine Oil Temp (PID 0x5C) — 1 byte, offset -40
    int rawOilT = queryOBD(0x5C, 1);
    vdata.oilTemp = rawOilT >= 0 ? rawOilT - 40 : -40;

    // Timing Advance (PID 0x0E) — 1 byte, scale 0.5, offset -64
    int rawTiming = queryOBD(0x0E, 1);
    vdata.timingAdv = rawTiming >= 0 ? rawTiming * 0.5f - 64.0f : 0;

    // O2 Voltage B1S1 (PID 0x14) — 2 bytes, scale 0.005
    int rawO2 = queryOBD(0x14, 2);
    vdata.o2Voltage = rawO2 >= 0 ? (rawO2 >> 8) * 0.005f : -1;

    // Fuel Pressure (PID 0x0A) — 1 byte, scale 3
    int rawFuelPres = queryOBD(0x0A, 1);
    vdata.fuelPressure = rawFuelPres >= 0 ? rawFuelPres * 3 : -1;
}

/* ══════════════════════════════════════════════════════════════
 * MODBUS RS485 — CHARGER COMMUNICATION
 * ══════════════════════════════════════════════════════════════*/
bool readRegister(uint16_t addr, uint16_t *val) {
    uint8_t req[8] = {
        0x01, 0x03,
        (uint8_t)(addr >> 8), (uint8_t)(addr & 0xFF),
        0x00, 0x01,
        0, 0
    };
    uint16_t crc = modbusCRC(req, 6);
    req[6] = crc & 0xFF;
    req[7] = crc >> 8;

    Serial1.write(req, 8);
    Serial1.flush();

    uint8_t resp[7] = {0};
    int len = 0;
    unsigned long t0 = millis();
    while (len < 7 && millis() - t0 < 200) {
        if (Serial1.available()) resp[len++] = Serial1.read();
    }

    if (len != 7 || resp[0] != 0x01 || resp[1] != 0x03 || resp[2] != 0x02) return false;

    crc = modbusCRC(resp, 5);
    if (resp[5] != (crc & 0xFF) || resp[6] != (crc >> 8)) return false;

    *val = (resp[3] << 8) | resp[4];
    vdata.rs485Ok = true;
    return true;
}

bool setCurrent(float amp) {
    uint16_t val = (uint16_t)(amp * 100 + 0.5f);
    uint8_t buf[8] = {
        0x01, 0x06,
        (uint8_t)(REG_SET_CURR >> 8), (uint8_t)(REG_SET_CURR & 0xFF),
        (uint8_t)(val >> 8), (uint8_t)(val & 0xFF),
        0, 0
    };
    uint16_t crc = modbusCRC(buf, 6);
    buf[6] = crc & 0xFF;
    buf[7] = crc >> 8;

    Serial1.write(buf, 8);
    Serial1.flush();

    uint8_t resp[8] = {0};
    int len = 0;
    unsigned long t0 = millis();
    while (len < 8 && millis() - t0 < 200) {
        if (Serial1.available()) resp[len++] = Serial1.read();
    }
    return (len == 8 && resp[0] == 0x01 && resp[1] == 0x06);
}

void readAllCharger() {
    uint16_t v;
    if (readRegister(REG_B_VOLT, &v))    vdata.battV   = v * 0.01f;
    if (readRegister(REG_B_CURR, &v))    vdata.battI   = v * 0.01f;
    if (readRegister(REG_TEMP_T1, &v))   vdata.tempT1  = v;
    if (readRegister(REG_TEMP_T2, &v))   vdata.tempT2  = v;
    if (readRegister(REG_TEMP_AMB, &v))  vdata.tempAmb = v;
    readRegister(REG_FAULT, &vdata.fault);
    readRegister(REG_ALARM, &vdata.alarm);
    readRegister(REG_STATUS, &vdata.status);
}

/* ══════════════════════════════════════════════════════════════
 * SMART CHARGING LOGIC
 * ══════════════════════════════════════════════════════════════*/
static float lastSetCurrent = -1;

void updateChargingLogic() {
    bool safe = true;
    if (vdata.tempT1 > 80 || vdata.tempT2 > 80 || vdata.tempAmb > 80) safe = false;
    if (vdata.battV < 24.0f || vdata.battV > 29.6f) safe = false;
    if (vdata.fault & 0x0040) safe = false;
    if (vdata.alarm & 0x0003) safe = false;

    float target = 12.0f;
    if (vdata.speed > 30 && vdata.rpm > 1000 &&
        vdata.ect >= 60 && vdata.ect <= 100 && safe) {
        target = 30.0f;
    }

    vdata.targetCurrent = target;

    if (target != lastSetCurrent) {
        if (setCurrent(target)) {
            lastSetCurrent = target;
            vdata.setA = target;
        }
    }
}

/* ══════════════════════════════════════════════════════════════
 * INIT: IO EXPANDER + CAN MUX (both modes)
 * ══════════════════════════════════════════════════════════════*/
void initIOExpander() {
    Wire.begin(I2C_SDA, I2C_SCL, I2C_FREQ);

    io_expander = new esp_expander::CH422G(I2C_SDA, I2C_SCL, IO_EXP_ADDR);
    io_expander->init();
    io_expander->begin();

    io_expander->pinMode(EXIO_CAN_SEL, OUTPUT);
    io_expander->pinMode(EXIO_SD_CS, OUTPUT);

    // Set CAN mode (not USB) — CRITICAL for OBD-II
    io_expander->digitalWrite(EXIO_CAN_SEL, HIGH);
    Serial.println("[INIT] CAN/USB mux set to CAN mode");
}

#if !BRIDGE_MODE
/* ══════════════════════════════════════════════════════════════
 * STANDALONE MODE: DISPLAY + LVGL
 * ══════════════════════════════════════════════════════════════*/
void lvgl_flush_cb(lv_disp_drv_t *drv, const lv_area_t *area, lv_color_t *color_p) {
    if (panel) {
        panel->getLcd()->drawBitmap(
            area->x1, area->y1,
            area->x2 - area->x1 + 1,
            area->y2 - area->y1 + 1,
            (const uint8_t *)color_p
        );
    }
    lv_disp_flush_ready(drv);
}

void initDisplay() {
    Serial.println("[INIT] Starting display initialization...");

    io_expander->pinMode(EXIO_BACKLIGHT, OUTPUT);
    io_expander->pinMode(EXIO_LCD_VDD, OUTPUT);
    io_expander->pinMode(EXIO_TOUCH_RST, OUTPUT);

    io_expander->digitalWrite(EXIO_LCD_VDD, HIGH);
    delay(10);
    io_expander->digitalWrite(EXIO_BACKLIGHT, HIGH);

    io_expander->digitalWrite(EXIO_TOUCH_RST, LOW);
    delay(10);
    io_expander->digitalWrite(EXIO_TOUCH_RST, HIGH);
    delay(50);

    panel = new ESP_Panel();
    panel->init();
    panel->begin();
    Serial.println("[INIT] LCD panel started (1024x600)");

    lv_init();

    size_t buf_size = LCD_WIDTH * 40 * sizeof(lv_color_t);
    buf1 = (lv_color_t *)heap_caps_malloc(buf_size, MALLOC_CAP_SPIRAM);
    buf2 = (lv_color_t *)heap_caps_malloc(buf_size, MALLOC_CAP_SPIRAM);

    if (!buf1 || !buf2) {
        Serial.println("[ERROR] Failed to allocate LVGL buffers!");
        buf_size = LCD_WIDTH * 20 * sizeof(lv_color_t);
        buf1 = (lv_color_t *)malloc(buf_size);
        buf2 = NULL;
    }

    lv_disp_draw_buf_init(&draw_buf, buf1, buf2, LCD_WIDTH * 40);

    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    disp_drv.hor_res = LCD_WIDTH;
    disp_drv.ver_res = LCD_HEIGHT;
    disp_drv.draw_buf = &draw_buf;
    disp_drv.flush_cb = lvgl_flush_cb;
    disp_drv.full_refresh = 0;
    lv_disp_drv_register(&disp_drv);

    Serial.println("[INIT] LVGL initialized");
}
#endif

/* ══════════════════════════════════════════════════════════════
 * INIT: CAN BUS (TWAI)
 * ══════════════════════════════════════════════════════════════*/
void initCAN() {
    twai_general_config_t g_config = TWAI_GENERAL_CONFIG_DEFAULT(CAN_TX_PIN, CAN_RX_PIN, TWAI_MODE_NORMAL);
    twai_timing_config_t t_config = CAN_SPEED;
    twai_filter_config_t f_config = TWAI_FILTER_CONFIG_ACCEPT_ALL();

    if (twai_driver_install(&g_config, &t_config, &f_config) == ESP_OK) {
        if (twai_start() == ESP_OK) {
            Serial.println("[INIT] CAN bus started (500 kbps)");
            return;
        }
    }
    Serial.println("[ERROR] CAN bus init failed!");
}

/* ══════════════════════════════════════════════════════════════
 * INIT: RS485 (UART1)
 * ══════════════════════════════════════════════════════════════*/
void initRS485() {
    Serial1.begin(RS485_BAUD, SERIAL_8N1, RS485_RX_PIN, RS485_TX_PIN);
    Serial.println("[INIT] RS485 started (9600 baud, auto-dir)");
}

#if BRIDGE_MODE
/* ══════════════════════════════════════════════════════════════
 * BRIDGE MODE: Process commands from Pi
 * ══════════════════════════════════════════════════════════════*/
void processCommand(ParsedCommand &cmd) {
    switch (cmd.type) {
        case CMD_SCAN_DTC:
            stored_dtcs = readDTCs(0x03);
            Serial.printf("{\"dtc_scan\":{\"count\":%d,\"codes\":[", stored_dtcs.count);
            for (int i = 0; i < stored_dtcs.count; i++) {
                if (i > 0) Serial.print(",");
                Serial.printf("\"%s\"", stored_dtcs.codes[i].code);
            }
            Serial.println("]}}");
            break;

        case CMD_CLEAR_DTC:
            if (clearDTCs()) {
                Serial.println("{\"dtc_clear\":\"ok\"}");
                stored_dtcs.count = 0;
            } else {
                Serial.println("{\"dtc_clear\":\"failed\"}");
            }
            break;

        case CMD_SET_CURRENT:
            if (setCurrent(cmd.floatVal)) {
                lastSetCurrent = cmd.floatVal;
                vdata.setA = cmd.floatVal;
                Serial.printf("{\"set_current\":\"ok\",\"val\":%.1f}\n", cmd.floatVal);
            } else {
                Serial.println("{\"set_current\":\"failed\"}");
            }
            break;

        case CMD_GET_SUPPORTED_PIDS:
            sendSupportedPIDs(Serial);
            break;

        case CMD_SET_LOG_INTERVAL:
            Serial.printf("{\"log_interval\":%d}\n", cmd.intVal);
            break;

        case CMD_SHUTDOWN:
            Serial.println("{\"shutdown\":\"acknowledged\"}");
            delay(100);
            esp_deep_sleep_start();
            break;

        default:
            break;
    }
}
#endif

/* ══════════════════════════════════════════════════════════════
 * SETUP
 * ══════════════════════════════════════════════════════════════*/
void setup() {
    Serial.begin(BRIDGE_BAUD);
    delay(300);

#if BRIDGE_MODE
    Serial.println("{\"boot\":\"DashOS ESP32 Bridge v1.0\"}");
    Serial.println("{\"mode\":\"bridge\",\"baud\":115200}");
#else
    Serial.println("\n==============================================");
    Serial.println("  ESP32-S3-LCD-7B Vehicle Dashboard");
    Serial.println("  OBD-II + Charger Monitor + LVGL GUI");
    Serial.println("==============================================\n");
#endif

    // Init IO expander (both modes need it for CAN mux)
    initIOExpander();

#if !BRIDGE_MODE
    // Init display + LVGL (standalone mode only)
    initDisplay();
#endif

    // Init CAN bus + RS485 (both modes)
    initCAN();
    initRS485();

#if !BRIDGE_MODE
    // Build LVGL UI
    ui_dashboard_create();
    Serial.println("\n[OK] Dashboard ready!\n");
#else
    Serial.println("{\"status\":\"ready\",\"can\":true,\"rs485\":true}");
#endif
}

/* ══════════════════════════════════════════════════════════════
 * MAIN LOOP
 * ══════════════════════════════════════════════════════════════*/
void loop() {
    // ── Poll data every 500ms ──
    static unsigned long lastPoll = 0;
    if (millis() - lastPoll >= 500) {
        lastPoll = millis();

        vdata.canOk = false;
        vdata.rs485Ok = false;

        readCoreOBD();
        readExtendedOBD();
        readAllCharger();
        updateChargingLogic();

#if BRIDGE_MODE
        // Send JSON data to Pi
        const char *dtcPtrs[MAX_DTCS];
        for (int i = 0; i < stored_dtcs.count; i++) {
            dtcPtrs[i] = stored_dtcs.codes[i].code;
        }
        serializeData(json_buf, JSON_BUF_SIZE, &vdata,
                      dtcPtrs, stored_dtcs.count, false, 0);
        Serial.print(json_buf);
#else
        // Update LVGL labels
        ui_dashboard_update(&vdata);
#endif
    }

#if BRIDGE_MODE
    // ── Check for commands from Pi ──
    if (readCommandLine(Serial, cmd_buf, CMD_BUF_SIZE)) {
        ParsedCommand cmd = parseCommand(cmd_buf);
        if (cmd.type != CMD_NONE) {
            processCommand(cmd);
        }
    }
    delay(1);  // Minimal delay in bridge mode
#else
    // ── LVGL timer handler ──
    lv_timer_handler();
    delay(5);
#endif
}
