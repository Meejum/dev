/**
 * @file obd2_pids.h
 * Complete OBD-II PID table for Mode 01 (live data)
 * Covers all commonly supported SAE J1979 PIDs
 */

#ifndef OBD2_PIDS_H
#define OBD2_PIDS_H

#include <stdint.h>

struct OBD2_PID {
    uint8_t pid;
    const char *name;
    const char *unit;
    uint8_t bytes;      // Response bytes (1, 2, or 4)
    float scale;        // Multiply raw value by this
    float offset;       // Add after scaling
    float minVal;       // Display minimum
    float maxVal;       // Display maximum
};

// Mode 01 — Live Data PIDs
static const OBD2_PID MODE01_PIDS[] = {
    // Engine
    {0x04, "Engine Load",           "%",     1, 0.3922f,  0,    0, 100},
    {0x05, "Coolant Temp",          "C",     1, 1.0f,    -40,  -40, 215},
    {0x0B, "Intake MAP",            "kPa",   1, 1.0f,     0,    0, 255},
    {0x0C, "Engine RPM",            "rpm",   2, 0.25f,    0,    0, 16383},
    {0x0D, "Vehicle Speed",         "km/h",  1, 1.0f,     0,    0, 255},
    {0x0E, "Timing Advance",        "deg",   1, 0.5f,   -64,  -64, 63.5f},
    {0x0F, "Intake Air Temp",       "C",     1, 1.0f,   -40,  -40, 215},
    {0x10, "MAF Air Flow",          "g/s",   2, 0.01f,    0,    0, 655.35f},
    {0x11, "Throttle Position",     "%",     1, 0.3922f,  0,    0, 100},

    // Fuel System
    {0x06, "Short Fuel Trim B1",    "%",     1, 0.7813f, -100, -100, 99.2f},
    {0x07, "Long Fuel Trim B1",     "%",     1, 0.7813f, -100, -100, 99.2f},
    {0x08, "Short Fuel Trim B2",    "%",     1, 0.7813f, -100, -100, 99.2f},
    {0x09, "Long Fuel Trim B2",     "%",     1, 0.7813f, -100, -100, 99.2f},
    {0x0A, "Fuel Pressure",         "kPa",   1, 3.0f,     0,    0, 765},
    {0x2F, "Fuel Level",            "%",     1, 0.3922f,  0,    0, 100},
    {0x51, "Fuel Type",             "",      1, 1.0f,     0,    0, 23},

    // O2 Sensors
    {0x14, "O2 B1S1 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},
    {0x15, "O2 B1S2 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},
    {0x16, "O2 B1S3 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},
    {0x17, "O2 B1S4 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},
    {0x18, "O2 B2S1 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},
    {0x19, "O2 B2S2 Voltage",       "V",     2, 0.005f,   0,   0, 1.275f},

    // Emissions / Catalyst
    {0x1C, "OBD Standard",          "",      1, 1.0f,     0,    0, 255},
    {0x1F, "Run Time",              "sec",   2, 1.0f,     0,    0, 65535},
    {0x21, "Dist w/ MIL On",        "km",    2, 1.0f,     0,    0, 65535},
    {0x2C, "Commanded EGR",         "%",     1, 0.3922f,  0,    0, 100},
    {0x2D, "EGR Error",             "%",     1, 0.7813f, -100, -100, 99.2f},
    {0x2E, "Commanded Evap Purge",  "%",     1, 0.3922f,  0,    0, 100},
    {0x30, "Warmups Since Clear",   "",      1, 1.0f,     0,    0, 255},
    {0x31, "Dist Since Clear",      "km",    2, 1.0f,     0,    0, 65535},
    {0x33, "Baro Pressure",         "kPa",   1, 1.0f,     0,    0, 255},

    // Catalyst Temps
    {0x3C, "Cat Temp B1S1",         "C",     2, 0.1f,   -40,  -40, 6513.5f},
    {0x3D, "Cat Temp B2S1",         "C",     2, 0.1f,   -40,  -40, 6513.5f},
    {0x3E, "Cat Temp B1S2",         "C",     2, 0.1f,   -40,  -40, 6513.5f},
    {0x3F, "Cat Temp B2S2",         "C",     2, 0.1f,   -40,  -40, 6513.5f},

    // Control Module
    {0x42, "Control Module V",      "V",     2, 0.001f,   0,    0, 65.535f},
    {0x43, "Abs Load Value",        "%",     2, 0.3922f,  0,    0, 25700},
    {0x44, "Cmd Equiv Ratio",       "",      2, 0.0000305f, 0,  0, 2},
    {0x45, "Rel Throttle Pos",      "%",     1, 0.3922f,  0,    0, 100},
    {0x46, "Ambient Air Temp",      "C",     1, 1.0f,   -40,  -40, 215},
    {0x47, "Abs Throttle B",        "%",     1, 0.3922f,  0,    0, 100},
    {0x48, "Abs Throttle C",        "%",     1, 0.3922f,  0,    0, 100},
    {0x49, "Accel Pedal D",         "%",     1, 0.3922f,  0,    0, 100},
    {0x4A, "Accel Pedal E",         "%",     1, 0.3922f,  0,    0, 100},
    {0x4C, "Cmd Throttle",          "%",     1, 0.3922f,  0,    0, 100},
    {0x4D, "Time w/ MIL On",        "min",   2, 1.0f,     0,    0, 65535},
    {0x4E, "Time Since Clear",      "min",   2, 1.0f,     0,    0, 65535},

    // Hybrid / EV
    {0x5B, "Hybrid Batt Pack Life", "%",     1, 0.3922f,  0,    0, 100},
    {0x5C, "Engine Oil Temp",       "C",     1, 1.0f,   -40,  -40, 210},
    {0x5E, "Fuel Rate",             "L/h",   2, 0.05f,    0,    0, 3276.75f},
};

static const int MODE01_PID_COUNT = sizeof(MODE01_PIDS) / sizeof(MODE01_PIDS[0]);

// Decode a raw OBD2 response into a float value
static inline float obd2_decode(const OBD2_PID *pid, const uint8_t *data) {
    uint32_t raw = 0;
    if (pid->bytes == 1) {
        raw = data[0];
    } else if (pid->bytes == 2) {
        raw = (data[0] << 8) | data[1];
    } else if (pid->bytes == 4) {
        raw = ((uint32_t)data[0] << 24) | ((uint32_t)data[1] << 16) |
              ((uint32_t)data[2] << 8)  | data[3];
    }
    return (float)raw * pid->scale + pid->offset;
}

#endif // OBD2_PIDS_H
