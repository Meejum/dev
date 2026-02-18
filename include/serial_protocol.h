/**
 * @file serial_protocol.h
 * JSON-based serial protocol for ESP32 ↔ Raspberry Pi communication
 *
 * Protocol: Newline-delimited JSON over UART (115200 baud)
 *
 * ESP32 → Pi (data stream, every 500ms):
 *   {"obd":{...},"chg":{...},"dtc":[...],"sd":{...},"ts":12345}
 *
 * Pi → ESP32 (commands):
 *   {"cmd":"scan_dtc"}
 *   {"cmd":"clear_dtc"}
 *   {"cmd":"set_current","val":30.0}
 *   {"cmd":"set_log_interval","val":1000}
 *   {"cmd":"get_supported_pids"}
 *   {"cmd":"shutdown"}
 */

#ifndef SERIAL_PROTOCOL_H
#define SERIAL_PROTOCOL_H

#include <Arduino.h>
#include "obd2_pids.h"

// Maximum JSON output buffer size
#define JSON_BUF_SIZE 1024
#define CMD_BUF_SIZE  256

// Command types from Pi
enum BridgeCommand {
    CMD_NONE = 0,
    CMD_SCAN_DTC,
    CMD_CLEAR_DTC,
    CMD_SET_CURRENT,
    CMD_SET_LOG_INTERVAL,
    CMD_GET_SUPPORTED_PIDS,
    CMD_SHUTDOWN,
};

struct ParsedCommand {
    BridgeCommand type;
    float floatVal;
    int intVal;
};

// Forward declare
struct VehicleData;

/**
 * Serialize vehicle data to JSON string
 * Writes to provided buffer, returns length
 */
static int serializeData(char *buf, int bufSize, VehicleData *d,
                          const char *dtcCodes[], int dtcCount,
                          bool sdOk, uint64_t sdFreeMB) {
    int len = snprintf(buf, bufSize,
        "{\"obd\":{"
            "\"spd\":%d,\"rpm\":%d,\"ect\":%d,"
            "\"thr\":%d,\"load\":%d"
        "},"
        "\"chg\":{"
            "\"v\":%.2f,\"a\":%.2f,\"set\":%.1f,"
            "\"t1\":%d,\"t2\":%d,\"amb\":%d,"
            "\"rate\":%.1f,\"fault\":%u,\"alarm\":%u,\"status\":%u"
        "}",
        d->speed, d->rpm, d->ect,
        d->throttle, d->load,
        d->battV, d->battI, d->setA,
        d->tempT1, d->tempT2, d->tempAmb,
        d->targetCurrent, d->fault, d->alarm, d->status);

    // Add DTCs if any
    if (dtcCount > 0) {
        len += snprintf(buf + len, bufSize - len, ",\"dtc\":[");
        for (int i = 0; i < dtcCount && i < 32; i++) {
            if (i > 0) len += snprintf(buf + len, bufSize - len, ",");
            len += snprintf(buf + len, bufSize - len, "\"%s\"", dtcCodes[i]);
        }
        len += snprintf(buf + len, bufSize - len, "]");
    }

    // SD status
    len += snprintf(buf + len, bufSize - len,
        ",\"sd\":{\"ok\":%s,\"free_mb\":%llu}",
        sdOk ? "true" : "false", sdFreeMB);

    // Connectivity status
    len += snprintf(buf + len, bufSize - len,
        ",\"can\":%s,\"rs485\":%s",
        d->canOk ? "true" : "false",
        d->rs485Ok ? "true" : "false");

    // Timestamp
    len += snprintf(buf + len, bufSize - len,
        ",\"ts\":%lu}\n", millis());

    return len;
}

/**
 * Parse a command JSON from Pi
 * Simple parser — no external JSON library needed
 */
static ParsedCommand parseCommand(const char *json) {
    ParsedCommand cmd;
    cmd.type = CMD_NONE;
    cmd.floatVal = 0;
    cmd.intVal = 0;

    // Find "cmd" field
    const char *cmdStr = strstr(json, "\"cmd\":");
    if (!cmdStr) return cmd;
    cmdStr += 6;  // Skip "cmd":

    // Skip whitespace and opening quote
    while (*cmdStr == ' ' || *cmdStr == '"') cmdStr++;

    if (strncmp(cmdStr, "scan_dtc", 8) == 0) {
        cmd.type = CMD_SCAN_DTC;
    } else if (strncmp(cmdStr, "clear_dtc", 9) == 0) {
        cmd.type = CMD_CLEAR_DTC;
    } else if (strncmp(cmdStr, "set_current", 11) == 0) {
        cmd.type = CMD_SET_CURRENT;
        // Find "val" field
        const char *valStr = strstr(json, "\"val\":");
        if (valStr) {
            valStr += 6;
            cmd.floatVal = atof(valStr);
        }
    } else if (strncmp(cmdStr, "set_log_interval", 16) == 0) {
        cmd.type = CMD_SET_LOG_INTERVAL;
        const char *valStr = strstr(json, "\"val\":");
        if (valStr) {
            valStr += 6;
            cmd.intVal = atoi(valStr);
        }
    } else if (strncmp(cmdStr, "get_supported_pids", 18) == 0) {
        cmd.type = CMD_GET_SUPPORTED_PIDS;
    } else if (strncmp(cmdStr, "shutdown", 8) == 0) {
        cmd.type = CMD_SHUTDOWN;
    }

    return cmd;
}

/**
 * Send supported PIDs list as JSON
 */
static void sendSupportedPIDs(Stream &serial) {
    serial.print("{\"supported_pids\":[");
    for (int i = 0; i < MODE01_PID_COUNT; i++) {
        if (i > 0) serial.print(",");
        serial.printf("{\"pid\":\"0x%02X\",\"name\":\"%s\",\"unit\":\"%s\"}",
                       MODE01_PIDS[i].pid,
                       MODE01_PIDS[i].name,
                       MODE01_PIDS[i].unit);
    }
    serial.println("]}");
}

/**
 * Read a command line from serial (non-blocking)
 * Returns true when a complete line is available
 */
static bool readCommandLine(Stream &serial, char *buf, int bufSize) {
    static int pos = 0;

    while (serial.available()) {
        char c = serial.read();
        if (c == '\n' || c == '\r') {
            if (pos > 0) {
                buf[pos] = '\0';
                pos = 0;
                return true;
            }
        } else if (pos < bufSize - 1) {
            buf[pos++] = c;
        }
    }
    return false;
}

#endif // SERIAL_PROTOCOL_H
