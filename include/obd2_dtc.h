/**
 * @file obd2_dtc.h
 * OBD-II Diagnostic Trouble Code (DTC) support
 * Mode 03: Read stored DTCs
 * Mode 04: Clear DTCs and MIL
 * Mode 07: Read pending DTCs
 */

#ifndef OBD2_DTC_H
#define OBD2_DTC_H

#include <stdint.h>
#include <string.h>
#include <driver/twai.h>

#define MAX_DTCS 32

// DTC category prefixes
static const char DTC_PREFIX[] = {'P', 'C', 'B', 'U'};

struct DTC {
    char code[6];  // e.g., "P0301"
};

struct DTCResult {
    DTC codes[MAX_DTCS];
    int count;
    bool success;
};

// Decode a pair of DTC bytes into a human-readable code (e.g., "P0301")
static inline void decodeDTC(uint8_t byte1, uint8_t byte2, char *out) {
    // First 2 bits = category (P/C/B/U)
    uint8_t category = (byte1 >> 6) & 0x03;
    // Next 2 bits = second digit
    uint8_t digit2 = (byte1 >> 4) & 0x03;
    // Next 4 bits = third digit
    uint8_t digit3 = byte1 & 0x0F;
    // byte2 upper nibble = fourth digit
    uint8_t digit4 = (byte2 >> 4) & 0x0F;
    // byte2 lower nibble = fifth digit
    uint8_t digit5 = byte2 & 0x0F;

    out[0] = DTC_PREFIX[category];
    out[1] = '0' + digit2;
    out[2] = (digit3 < 10) ? ('0' + digit3) : ('A' + digit3 - 10);
    out[3] = (digit4 < 10) ? ('0' + digit4) : ('A' + digit4 - 10);
    out[4] = (digit5 < 10) ? ('0' + digit5) : ('A' + digit5 - 10);
    out[5] = '\0';
}

// Read DTCs using Mode 03 (stored) or Mode 07 (pending)
static DTCResult readDTCs(uint8_t mode) {
    DTCResult result;
    result.count = 0;
    result.success = false;

    // Send DTC request
    twai_message_t tx;
    memset(&tx, 0, sizeof(tx));
    tx.identifier = 0x7DF;
    tx.data_length_code = 8;
    tx.data[0] = 1;     // 1 byte follows
    tx.data[1] = mode;  // 0x03 = stored, 0x07 = pending

    if (twai_transmit(&tx, pdMS_TO_TICKS(100)) != ESP_OK) return result;

    // Collect response frames (may be multi-frame)
    twai_message_t rx;
    unsigned long t0 = millis();
    while (millis() - t0 < 1000 && result.count < MAX_DTCS) {
        if (twai_receive(&rx, pdMS_TO_TICKS(100)) == ESP_OK) {
            if (rx.identifier >= 0x7E8 && rx.identifier <= 0x7EF) {
                // Response: [num_bytes, mode+0x40, DTC1_hi, DTC1_lo, DTC2_hi, DTC2_lo, ...]
                if (rx.data[1] == (mode + 0x40)) {
                    result.success = true;
                    // DTCs start at byte 2, in pairs
                    for (int i = 2; i < 8 && (i + 1) < 8; i += 2) {
                        if (rx.data[i] == 0 && rx.data[i + 1] == 0) continue;
                        if (result.count >= MAX_DTCS) break;
                        decodeDTC(rx.data[i], rx.data[i + 1],
                                  result.codes[result.count].code);
                        result.count++;
                    }
                }
            }
        }
    }

    if (result.count == 0) result.success = true;  // No DTCs is still success
    return result;
}

// Clear DTCs and reset MIL (Mode 04)
// WARNING: This clears all stored DTCs and resets monitors!
static bool clearDTCs() {
    twai_message_t tx;
    memset(&tx, 0, sizeof(tx));
    tx.identifier = 0x7DF;
    tx.data_length_code = 8;
    tx.data[0] = 1;
    tx.data[1] = 0x04;  // Mode 04 = Clear DTCs

    if (twai_transmit(&tx, pdMS_TO_TICKS(100)) != ESP_OK) return false;

    // Wait for confirmation
    twai_message_t rx;
    unsigned long t0 = millis();
    while (millis() - t0 < 2000) {
        if (twai_receive(&rx, pdMS_TO_TICKS(100)) == ESP_OK) {
            if (rx.identifier >= 0x7E8 && rx.identifier <= 0x7EF) {
                if (rx.data[1] == 0x44) return true;  // 0x04 + 0x40
            }
        }
    }
    return false;
}

// Read number of DTCs and MIL status (Mode 01, PID 0x01)
struct MILStatus {
    bool milOn;
    uint8_t dtcCount;
    bool success;
};

static MILStatus readMILStatus() {
    MILStatus status;
    status.milOn = false;
    status.dtcCount = 0;
    status.success = false;

    twai_message_t tx;
    memset(&tx, 0, sizeof(tx));
    tx.identifier = 0x7DF;
    tx.data_length_code = 8;
    tx.data[0] = 2;
    tx.data[1] = 0x01;
    tx.data[2] = 0x01;  // PID 0x01 = Monitor status since DTCs cleared

    if (twai_transmit(&tx, pdMS_TO_TICKS(100)) != ESP_OK) return status;

    twai_message_t rx;
    unsigned long t0 = millis();
    while (millis() - t0 < 500) {
        if (twai_receive(&rx, pdMS_TO_TICKS(100)) == ESP_OK) {
            if (rx.identifier >= 0x7E8 && rx.identifier <= 0x7EF &&
                rx.data[2] == 0x01) {
                status.milOn = (rx.data[3] & 0x80) != 0;
                status.dtcCount = rx.data[3] & 0x7F;
                status.success = true;
                return status;
            }
        }
    }
    return status;
}

// Common DTC descriptions (top 50 codes)
struct DTCDescription {
    const char *code;
    const char *description;
};

static const DTCDescription COMMON_DTCS[] = {
    {"P0100", "MAF Circuit Malfunction"},
    {"P0101", "MAF Circuit Range/Performance"},
    {"P0102", "MAF Circuit Low Input"},
    {"P0110", "Intake Air Temp Circuit Malfunction"},
    {"P0115", "Engine Coolant Temp Circuit Malfunction"},
    {"P0120", "Throttle Position Sensor Malfunction"},
    {"P0130", "O2 Sensor Circuit B1S1"},
    {"P0131", "O2 Sensor Low Voltage B1S1"},
    {"P0133", "O2 Sensor Slow Response B1S1"},
    {"P0135", "O2 Sensor Heater Circuit B1S1"},
    {"P0171", "System Too Lean Bank 1"},
    {"P0172", "System Too Rich Bank 1"},
    {"P0174", "System Too Lean Bank 2"},
    {"P0175", "System Too Rich Bank 2"},
    {"P0300", "Random/Multiple Cylinder Misfire"},
    {"P0301", "Cylinder 1 Misfire Detected"},
    {"P0302", "Cylinder 2 Misfire Detected"},
    {"P0303", "Cylinder 3 Misfire Detected"},
    {"P0304", "Cylinder 4 Misfire Detected"},
    {"P0305", "Cylinder 5 Misfire Detected"},
    {"P0306", "Cylinder 6 Misfire Detected"},
    {"P0325", "Knock Sensor 1 Circuit"},
    {"P0335", "Crankshaft Position Sensor A Circuit"},
    {"P0340", "Camshaft Position Sensor Circuit"},
    {"P0400", "EGR Flow Malfunction"},
    {"P0401", "EGR Insufficient Flow"},
    {"P0420", "Catalyst Efficiency Below Threshold B1"},
    {"P0421", "Warm Up Catalyst Efficiency Below Threshold B1"},
    {"P0430", "Catalyst Efficiency Below Threshold B2"},
    {"P0440", "Evap System Malfunction"},
    {"P0441", "Evap System Incorrect Purge Flow"},
    {"P0442", "Evap System Small Leak Detected"},
    {"P0443", "Evap System Purge Control Valve Circuit"},
    {"P0446", "Evap System Vent Control Circuit"},
    {"P0455", "Evap System Large Leak Detected"},
    {"P0500", "Vehicle Speed Sensor Malfunction"},
    {"P0505", "Idle Air Control System"},
    {"P0507", "Idle Air Control RPM Higher Than Expected"},
    {"P0562", "System Voltage Low"},
    {"P0563", "System Voltage High"},
    {"P0600", "Serial Communication Link"},
    {"P0700", "Transmission Control System"},
    {"P0715", "Input/Turbine Speed Sensor Circuit"},
    {"P0720", "Output Speed Sensor Circuit"},
    {"P0730", "Incorrect Gear Ratio"},
    {"P0741", "Torque Converter Clutch Stuck Off"},
    {"P1000", "OBD II Monitor Testing Not Complete"},
};

static const int COMMON_DTC_COUNT = sizeof(COMMON_DTCS) / sizeof(COMMON_DTCS[0]);

static const char* lookupDTC(const char *code) {
    for (int i = 0; i < COMMON_DTC_COUNT; i++) {
        if (strcmp(code, COMMON_DTCS[i].code) == 0) {
            return COMMON_DTCS[i].description;
        }
    }
    return "Unknown Code";
}

#endif // OBD2_DTC_H
