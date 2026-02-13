/**
 * @file main.cpp
 * ESP32-S3-LCD-7B — Vehicle Dashboard + Charger Monitor
 * 
 * Combines:
 *   - OBD-II via CAN bus (TWAI) for vehicle data
 *   - Modbus RTU via RS485 for charger monitoring
 *   - LVGL 8.4 GUI on 1024×600 RGB display
 * 
 * Target: Waveshare ESP32-S3-Touch-LCD-7B
 */

#include <Arduino.h>
#include <lvgl.h>
#include <driver/twai.h>
#include <Wire.h>

// ─── Waveshare display panel library ─────────────────────────
// These handle RGB LCD init, IO expander (CH32V003), backlight
#include <ESP_Panel_Library.h>
#include <ESP_IOExpander_Library.h>

#include "board_config.h"
#include "ui_dashboard.h"

/* ══════════════════════════════════════════════════════════════
 * LVGL DISPLAY BUFFER & DRIVER
 * ══════════════════════════════════════════════════════════════*/
static lv_disp_draw_buf_t draw_buf;
static lv_color_t *buf1 = NULL;
static lv_color_t *buf2 = NULL;
static ESP_Panel *panel = NULL;
static ESP_IOExpander *io_expander = NULL;

#define LVGL_BUF_LINES  40  // Number of lines in draw buffer

// Forward declarations
void lvgl_flush_cb(lv_disp_drv_t *drv, const lv_area_t *area, lv_color_t *color_p);
void lvgl_tick_task(void *arg);

/* ══════════════════════════════════════════════════════════════
 * GLOBAL VEHICLE + CHARGER DATA
 * ══════════════════════════════════════════════════════════════*/
VehicleData vdata;  // Defined in ui_dashboard.h

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

void readAllOBD() {
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

    // RS485 auto-direction — just write
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

    uint8_t resp[8] = {0};  // Initialize buffer
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
    if (vdata.fault & 0x0040) safe = false;    // Over-temp fault
    if (vdata.alarm & 0x0003) safe = false;    // Derating alarm

    float target = 12.0f;  // Default reduced rate
    if (vdata.speed > 30 && vdata.rpm > 1000 &&
        vdata.ect >= 60 && vdata.ect <= 100 && safe) {
        target = 30.0f;    // Full charging rate
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
 * LVGL FLUSH CALLBACK
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

/* ══════════════════════════════════════════════════════════════
 * INIT: DISPLAY + IO EXPANDER + LVGL
 * ══════════════════════════════════════════════════════════════*/
void initDisplay() {
    Serial.println("[INIT] Starting display initialization...");

    // ── Init I2C for IO expander ──
    Wire.begin(I2C_SDA, I2C_SCL, I2C_FREQ);

    // ── Init IO Expander (CH32V003) ──
    // NOTE: The 7B board uses a CH32V003 MCU as IO expander
    // accessed via I2C at address 0x24
    // The ESP32_IO_Expander library handles this
    io_expander = new esp_expander::CH422G(I2C_SDA, I2C_SCL, IO_EXP_ADDR);
    io_expander->init();
    io_expander->begin();

    // Configure IO expander pins
    io_expander->pinMode(EXIO_BACKLIGHT, OUTPUT);
    io_expander->pinMode(EXIO_LCD_VDD, OUTPUT);
    io_expander->pinMode(EXIO_CAN_SEL, OUTPUT);
    io_expander->pinMode(EXIO_SD_CS, OUTPUT);
    io_expander->pinMode(EXIO_TOUCH_RST, OUTPUT);

    // Enable LCD power and backlight
    io_expander->digitalWrite(EXIO_LCD_VDD, HIGH);
    delay(10);
    io_expander->digitalWrite(EXIO_BACKLIGHT, HIGH);

    // ⚠️ Set CAN mode (not USB) — CRITICAL for OBD-II
    io_expander->digitalWrite(EXIO_CAN_SEL, HIGH);
    Serial.println("[INIT] CAN/USB mux set to CAN mode");

    // Touch reset (even if no touch panel, won't hurt)
    io_expander->digitalWrite(EXIO_TOUCH_RST, LOW);
    delay(10);
    io_expander->digitalWrite(EXIO_TOUCH_RST, HIGH);
    delay(50);

    // ── Init ESP_Panel (handles RGB LCD setup) ──
    panel = new ESP_Panel();
    panel->init();
    panel->begin();
    Serial.println("[INIT] LCD panel started (1024×600)");

    // ── Init LVGL ──
    lv_init();

    // Allocate draw buffers in PSRAM
    size_t buf_size = LCD_WIDTH * LVGL_BUF_LINES * sizeof(lv_color_t);
    buf1 = (lv_color_t *)heap_caps_malloc(buf_size, MALLOC_CAP_SPIRAM);
    buf2 = (lv_color_t *)heap_caps_malloc(buf_size, MALLOC_CAP_SPIRAM);

    if (!buf1 || !buf2) {
        Serial.println("[ERROR] Failed to allocate LVGL buffers!");
        // Fallback: single buffer, smaller
        buf_size = LCD_WIDTH * 20 * sizeof(lv_color_t);
        buf1 = (lv_color_t *)malloc(buf_size);
        buf2 = NULL;
    }

    lv_disp_draw_buf_init(&draw_buf, buf1, buf2, LCD_WIDTH * LVGL_BUF_LINES);

    // Register display driver
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

/* ══════════════════════════════════════════════════════════════
 * SETUP
 * ══════════════════════════════════════════════════════════════*/
void setup() {
    Serial.begin(115200);
    delay(300);

    Serial.println("\n══════════════════════════════════════════════");
    Serial.println("  ESP32-S3-LCD-7B Vehicle Dashboard");
    Serial.println("  OBD-II + Charger Monitor + LVGL GUI");
    Serial.println("══════════════════════════════════════════════\n");

    // Init hardware
    initDisplay();
    initCAN();
    initRS485();

    // Build LVGL UI
    ui_dashboard_create();

    Serial.println("\n[OK] Dashboard ready!\n");
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

        readAllOBD();
        readAllCharger();
        updateChargingLogic();

        // Update LVGL labels
        ui_dashboard_update(&vdata);
    }

    // ── LVGL timer handler ──
    lv_timer_handler();
    delay(5);
}
