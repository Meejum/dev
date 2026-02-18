/**
 * @file hal_stubs.h
 * Stubs for Arduino/ESP32 APIs used by ui_dashboard.h
 * Only millis() and IRAM_ATTR are needed.
 */
#ifndef HAL_STUBS_H
#define HAL_STUBS_H

#include <cstdint>
#include <ctime>

#ifndef IRAM_ATTR
#define IRAM_ATTR
#endif

static inline unsigned long millis() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long)(ts.tv_sec * 1000UL + ts.tv_nsec / 1000000UL);
}

#endif // HAL_STUBS_H
