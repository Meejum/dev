/**
 * @file board_config.h
 * Hardware pin definitions for ESP32-S3-Touch-LCD-7B
 * Waveshare 1024×600 7-inch IPS display
 */

#ifndef BOARD_CONFIG_H
#define BOARD_CONFIG_H

#include <driver/gpio.h>

/* ════════════════════════════════════════════════════════════════
 * DISPLAY — RGB Interface (ST7701 driver)
 * ════════════════════════════════════════════════════════════════*/
#define LCD_WIDTH       1024
#define LCD_HEIGHT      600
#define LCD_PCLK_HZ     (30 * 1000 * 1000)  // 30 MHz max for 7B

// RGB data pins
#define LCD_R3   GPIO_NUM_1
#define LCD_R4   GPIO_NUM_2
#define LCD_R5   GPIO_NUM_42
#define LCD_R6   GPIO_NUM_41
#define LCD_R7   GPIO_NUM_40

#define LCD_G2   GPIO_NUM_39
#define LCD_G3   GPIO_NUM_0
#define LCD_G4   GPIO_NUM_45
#define LCD_G5   GPIO_NUM_48
#define LCD_G6   GPIO_NUM_47
#define LCD_G7   GPIO_NUM_21

#define LCD_B3   GPIO_NUM_14
#define LCD_B4   GPIO_NUM_38
#define LCD_B5   GPIO_NUM_18
#define LCD_B6   GPIO_NUM_17
#define LCD_B7   GPIO_NUM_10

// Sync/control pins
#define LCD_HSYNC   GPIO_NUM_46
#define LCD_VSYNC   GPIO_NUM_3
#define LCD_DE      GPIO_NUM_5
#define LCD_PCLK    GPIO_NUM_7

// Timing (ST7701 @ 1024×600)
#define LCD_H_RES       1024
#define LCD_V_RES       600
#define LCD_HSYNC_PW    1
#define LCD_HBP         160
#define LCD_HFP         160
#define LCD_VSYNC_PW    1
#define LCD_VBP         23
#define LCD_VFP         12

/* ════════════════════════════════════════════════════════════════
 * I2C BUS — shared by touch + IO expander
 * ════════════════════════════════════════════════════════════════*/
#define I2C_SDA     GPIO_NUM_8
#define I2C_SCL     GPIO_NUM_9
#define I2C_FREQ    400000

/* ════════════════════════════════════════════════════════════════
 * TOUCH — GT911 (optional, "B" version may not have it)
 * ════════════════════════════════════════════════════════════════*/
#define TOUCH_IRQ   GPIO_NUM_4
// TOUCH_RST is on IO expander EXIO1

/* ════════════════════════════════════════════════════════════════
 * IO EXPANDER — CH32V003 (on I2C bus)
 * Controls: backlight, touch reset, SD CS, CAN/USB mux
 * ════════════════════════════════════════════════════════════════*/
#define IO_EXP_ADDR     0x24    // I2C address

// EXIO pin assignments
#define EXIO_TOUCH_RST  1       // EXIO1 — Touch reset
#define EXIO_BACKLIGHT  2       // EXIO2 — LCD backlight enable
#define EXIO_SD_CS      4       // EXIO4 — TF card chip select
#define EXIO_CAN_SEL    5       // EXIO5 — HIGH=CAN, LOW=USB
#define EXIO_LCD_VDD    6       // EXIO6 — LCD VCOM voltage enable

/* ════════════════════════════════════════════════════════════════
 * CAN BUS — OBD-II (shared with USB!)
 * ⚠️ Must set EXIO5=HIGH to enable CAN mode
 * ════════════════════════════════════════════════════════════════*/
#define CAN_TX_PIN  GPIO_NUM_20     // ⚠️ Shared with USB_DP
#define CAN_RX_PIN  GPIO_NUM_19     // ⚠️ Shared with USB_DN
#define CAN_SPEED   TWAI_TIMING_CONFIG_500KBITS()

/* ════════════════════════════════════════════════════════════════
 * RS485 — Modbus Charger Communication
 * Auto direction switching — no DE/RE pin needed!
 * ════════════════════════════════════════════════════════════════*/
#define RS485_TX_PIN    GPIO_NUM_15
#define RS485_RX_PIN    GPIO_NUM_16
#define RS485_BAUD      9600

/* ════════════════════════════════════════════════════════════════
 * TF CARD — SPI interface
 * ════════════════════════════════════════════════════════════════*/
#define SD_MOSI     GPIO_NUM_11
#define SD_SCK      GPIO_NUM_12
#define SD_MISO     GPIO_NUM_13
// SD_CS on IO expander EXIO4

/* ════════════════════════════════════════════════════════════════
 * USB — Shared with CAN!
 * ════════════════════════════════════════════════════════════════*/
#define USB_DN  GPIO_NUM_19     // Shared with CAN_RX
#define USB_DP  GPIO_NUM_20     // Shared with CAN_TX

/* ════════════════════════════════════════════════════════════════
 * OBD-II PID DEFINITIONS
 * ════════════════════════════════════════════════════════════════*/
#define PID_RPM          0x0C
#define PID_SPEED        0x0D
#define PID_COOLANT      0x05
#define PID_THROTTLE     0x11
#define PID_LOAD         0x04

/* ════════════════════════════════════════════════════════════════
 * CHARGER MODBUS REGISTER MAP
 * ════════════════════════════════════════════════════════════════*/
#define REG_A_VOLT      0x0200  // × 0.01 = Volts
#define REG_A_CURR      0x0201  // × 0.01 = Amps
#define REG_B_VOLT      0x0203  // × 0.01 = Volts (battery)
#define REG_B_CURR      0x0204  // × 0.01 = Amps (battery)
#define REG_TEMP_T1     0x0206  // °C
#define REG_TEMP_T2     0x0207  // °C
#define REG_FAULT       0x020A  // Fault flags
#define REG_ALARM       0x020B  // Alarm flags
#define REG_TEMP_AMB    0x020E  // Ambient °C
#define REG_STATUS      0x020F  // Status word
#define REG_SET_CURR    0x081E  // Write: set current (× 100)

#endif // BOARD_CONFIG_H
