/**
 * @file esp_panel_board_custom_conf.h
 * ESP_Panel board configuration for Waveshare ESP32-S3-Touch-LCD-7B
 * 1024×600 RGB, ST7701 driver, CH32V003 IO expander
 * 
 * Place in include/ — the ESP_Panel library reads this automatically
 */

#ifndef ESP_PANEL_BOARD_CUSTOM_CONF_H
#define ESP_PANEL_BOARD_CUSTOM_CONF_H

/* Use custom board (not a pre-defined one) */
#define ESP_PANEL_BOARD_DEFAULT_USE_SUPPORTED   0
#define ESP_PANEL_BOARD_DEFAULT_USE_CUSTOM       1

/* ── LCD Configuration ────────────────────────────────────── */
#define ESP_PANEL_USE_LCD           1
#define ESP_PANEL_LCD_BUS_TYPE      (4) // RGB bus

// Resolution: 7B = 1024×600
#define ESP_PANEL_LCD_H_RES         1024
#define ESP_PANEL_LCD_V_RES         600
#define ESP_PANEL_LCD_COLOR_BITS    16

// RGB timing
#define ESP_PANEL_LCD_RGB_CLK_HZ        (30 * 1000 * 1000)
#define ESP_PANEL_LCD_RGB_HPW           1
#define ESP_PANEL_LCD_RGB_HBP           160
#define ESP_PANEL_LCD_RGB_HFP           160
#define ESP_PANEL_LCD_RGB_VPW           1
#define ESP_PANEL_LCD_RGB_VBP           23
#define ESP_PANEL_LCD_RGB_VFP           12
#define ESP_PANEL_LCD_RGB_PCLK_ACTIVE_NEG 1
#define ESP_PANEL_LCD_RGB_BOUNCE_BUF_SIZE (1024 * 10)

// RGB data pins (R5 G6 B5 = 16-bit)
#define ESP_PANEL_LCD_RGB_DATA_WIDTH    16
#define ESP_PANEL_LCD_RGB_IO_R0         1   // R3
#define ESP_PANEL_LCD_RGB_IO_R1         2   // R4
#define ESP_PANEL_LCD_RGB_IO_R2         42  // R5
#define ESP_PANEL_LCD_RGB_IO_R3         41  // R6
#define ESP_PANEL_LCD_RGB_IO_R4         40  // R7

#define ESP_PANEL_LCD_RGB_IO_G0         39  // G2
#define ESP_PANEL_LCD_RGB_IO_G1         0   // G3
#define ESP_PANEL_LCD_RGB_IO_G2         45  // G4
#define ESP_PANEL_LCD_RGB_IO_G3         48  // G5
#define ESP_PANEL_LCD_RGB_IO_G4         47  // G6
#define ESP_PANEL_LCD_RGB_IO_G5         21  // G7

#define ESP_PANEL_LCD_RGB_IO_B0         14  // B3
#define ESP_PANEL_LCD_RGB_IO_B1         38  // B4
#define ESP_PANEL_LCD_RGB_IO_B2         18  // B5
#define ESP_PANEL_LCD_RGB_IO_B3         17  // B6
#define ESP_PANEL_LCD_RGB_IO_B4         10  // B7

#define ESP_PANEL_LCD_RGB_IO_HSYNC      46
#define ESP_PANEL_LCD_RGB_IO_VSYNC      3
#define ESP_PANEL_LCD_RGB_IO_DE         5
#define ESP_PANEL_LCD_RGB_IO_PCLK       7

// Disp pin (on IO expander)
#define ESP_PANEL_LCD_RGB_IO_DISP       -1  // Handled by IO expander

/* ── Touch Configuration (disabled for "B" no-touch version) ─ */
#define ESP_PANEL_USE_TOUCH             0
// Set to 1 if you have the touch version:
// #define ESP_PANEL_USE_TOUCH          1
// #define ESP_PANEL_TOUCH_BUS_TYPE     (1) // I2C
// #define ESP_PANEL_TOUCH_I2C_ADDRESS  0x5D // GT911
// #define ESP_PANEL_TOUCH_IO_INT       4

/* ── Backlight ────────────────────────────────────────────── */
#define ESP_PANEL_USE_BACKLIGHT         0   // We control via IO expander manually

#endif // ESP_PANEL_BOARD_CUSTOM_CONF_H
