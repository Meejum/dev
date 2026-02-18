/**
 * @file sd_logger.h
 * SD Card initialization and CSV data logging
 * Uses SPI interface with IO expander chip select (EXIO4)
 */

#ifndef SD_LOGGER_H
#define SD_LOGGER_H

#include <SPI.h>
#include <SD.h>
#include "board_config.h"

// SD card state
static bool sd_initialized = false;
static File log_file;
static char current_log_path[64] = {0};
static unsigned long last_log_time = 0;
static unsigned long log_interval_ms = 1000;  // Default: log every 1 second

// Forward declare VehicleData (defined in ui_dashboard.h or bridge code)
struct VehicleData;

/**
 * Initialize SD card on SPI bus
 * CS pin is on IO expander EXIO4, must be managed externally
 */
static bool sd_init(ESP_IOExpander *io_exp) {
    // SD CS is on IO expander — we need to use a GPIO for SPI CS
    // The IO expander controls the actual CS line
    // Set EXIO4 high (deselect) first
    if (io_exp) {
        io_exp->digitalWrite(EXIO_SD_CS, HIGH);
    }

    // Initialize SPI for SD card
    SPI.begin(SD_SCK, SD_MISO, SD_MOSI);

    // Try to mount SD card
    // Note: We use GPIO CS pin; the IO expander CS is handled separately
    if (!SD.begin(SS, SPI, 4000000)) {
        Serial.println("[SD] Card mount failed");
        sd_initialized = false;
        return false;
    }

    uint64_t cardSize = SD.cardSize() / (1024 * 1024);
    Serial.printf("[SD] Card mounted: %lluMB\n", cardSize);
    sd_initialized = true;

    // Create logs directory
    if (!SD.exists("/logs")) {
        SD.mkdir("/logs");
    }

    return true;
}

/**
 * Get free space in MB
 */
static uint64_t sd_free_mb() {
    if (!sd_initialized) return 0;
    return (SD.totalBytes() - SD.usedBytes()) / (1024 * 1024);
}

/**
 * Open or rotate log file based on date
 * File naming: /logs/YYYY-MM-DD_obd2.csv
 */
static bool sd_open_log(const char *date_str) {
    char path[64];
    snprintf(path, sizeof(path), "/logs/%s_obd2.csv", date_str);

    // Check if we need to rotate
    if (strcmp(path, current_log_path) == 0 && log_file) {
        return true;  // Same file, still open
    }

    // Close old file
    if (log_file) {
        log_file.close();
    }

    // Open new file (append mode)
    bool is_new = !SD.exists(path);
    log_file = SD.open(path, FILE_APPEND);
    if (!log_file) {
        Serial.printf("[SD] Failed to open %s\n", path);
        return false;
    }

    strncpy(current_log_path, path, sizeof(current_log_path) - 1);

    // Write CSV header if new file
    if (is_new) {
        log_file.println("timestamp_ms,speed,rpm,ect,throttle,load,"
                         "batt_v,batt_i,set_a,temp_t1,temp_t2,temp_amb,"
                         "charge_rate,charger_en,fault,alarm,status,"
                         "fuel_rate,fuel_level,maf,iat,oil_temp,"
                         "timing_adv,o2_voltage,fuel_pres");
    }

    return true;
}

/**
 * Log a data row to CSV
 */
static void sd_log_data(unsigned long timestamp_ms, VehicleData *d) {
    if (!sd_initialized || !log_file) return;

    // Throttle logging rate
    if (timestamp_ms - last_log_time < log_interval_ms) return;
    last_log_time = timestamp_ms;

    char buf[384];
    snprintf(buf, sizeof(buf),
             "%lu,%d,%d,%d,%d,%d,"
             "%.2f,%.2f,%.1f,%d,%d,%d,"
             "%.1f,%d,%u,%u,%u,"
             "%.2f,%.1f,%.2f,%d,%d,"
             "%.1f,%.3f,%d",
             timestamp_ms,
             d->speed, d->rpm, d->ect, d->throttle, d->load,
             d->battV, d->battI, d->setA, d->tempT1, d->tempT2, d->tempAmb,
             d->targetCurrent, d->chargerEnabled ? 1 : 0,
             d->fault, d->alarm, d->status,
             d->fuelRate, d->fuelLevel, d->maf, d->intakeAirTemp, d->oilTemp,
             d->timingAdv, d->o2Voltage, d->fuelPressure);

    log_file.println(buf);

    // Flush periodically (every 10 writes)
    static int write_count = 0;
    if (++write_count >= 10) {
        log_file.flush();
        write_count = 0;
    }
}

/**
 * Log a debug/error message to a separate log file
 */
static void sd_log_debug(const char *msg) {
    if (!sd_initialized) return;

    File f = SD.open("/logs/debug.log", FILE_APPEND);
    if (f) {
        f.printf("[%lu] %s\n", millis(), msg);
        f.close();
    }
}

/**
 * Log a Meshtastic message
 */
static void sd_log_mesh(const char *sender, const char *message) {
    if (!sd_initialized) return;

    File f = SD.open("/logs/meshtastic.log", FILE_APPEND);
    if (f) {
        f.printf("[%lu] %s: %s\n", millis(), sender, message);
        f.close();
    }
}

/**
 * Close all open files (call before power down)
 */
static void sd_close() {
    if (log_file) {
        log_file.flush();
        log_file.close();
    }
    sd_initialized = false;
}

/**
 * Set logging interval
 */
static void sd_set_interval(unsigned long ms) {
    log_interval_ms = ms;
}

#endif // SD_LOGGER_H
