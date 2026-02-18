/**
 * @file main.cpp
 * LVGL PC Simulator — Vehicle Dashboard
 *
 * Renders the dashboard UI to an in-memory framebuffer,
 * then writes it as a BMP file. No SDL2 or display server required.
 *
 * Usage:
 *   ./dashboard_sim [output.bmp]
 *   Default output: dashboard_screenshot.bmp
 */

#include "hal_stubs.h"   // millis() and IRAM_ATTR stubs — must be first

#include <lvgl.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>

// Include the project's existing UI — works as-is
#include "ui_dashboard.h"

/* ══════════════════════════════════════════════════════════════
 * FRAMEBUFFER DISPLAY DRIVER
 * ══════════════════════════════════════════════════════════════*/
#define DISP_HOR_RES  1024
#define DISP_VER_RES  600

static lv_color_t framebuffer[DISP_HOR_RES * DISP_VER_RES];
static lv_disp_draw_buf_t draw_buf;
static lv_color_t buf1[DISP_HOR_RES * 40];

static void flush_cb(lv_disp_drv_t *drv, const lv_area_t *area, lv_color_t *color_p) {
    for (int y = area->y1; y <= area->y2; y++) {
        memcpy(&framebuffer[y * DISP_HOR_RES + area->x1],
               color_p,
               (area->x2 - area->x1 + 1) * sizeof(lv_color_t));
        color_p += (area->x2 - area->x1 + 1);
    }
    lv_disp_flush_ready(drv);
}

/* ══════════════════════════════════════════════════════════════
 * BMP FILE WRITER (RGB565 → 24-bit BMP)
 * ══════════════════════════════════════════════════════════════*/
#pragma pack(push, 1)
struct BMPHeader {
    uint16_t type;          // 'BM'
    uint32_t file_size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t offset;
    uint32_t dib_size;
    int32_t  width;
    int32_t  height;
    uint16_t planes;
    uint16_t bpp;
    uint32_t compression;
    uint32_t image_size;
    int32_t  x_ppm;
    int32_t  y_ppm;
    uint32_t colors_used;
    uint32_t colors_important;
};
#pragma pack(pop)

static bool write_bmp(const char *filename, const lv_color_t *fb, int w, int h) {
    int row_size = w * 3;
    int padding = (4 - (row_size % 4)) % 4;
    int padded_row = row_size + padding;

    BMPHeader hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.type = 0x4D42;  // 'BM'
    hdr.offset = sizeof(BMPHeader);
    hdr.file_size = hdr.offset + padded_row * h;
    hdr.dib_size = 40;
    hdr.width = w;
    hdr.height = -h;  // top-down
    hdr.planes = 1;
    hdr.bpp = 24;
    hdr.image_size = padded_row * h;

    FILE *f = fopen(filename, "wb");
    if (!f) return false;

    fwrite(&hdr, sizeof(hdr), 1, f);

    uint8_t pad[3] = {0, 0, 0};
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            lv_color_t c = fb[y * w + x];
            // Extract RGB from lv_color_t (RGB565)
            uint8_t r = (c.ch.red   << 3) | (c.ch.red   >> 2);
            uint8_t g = (c.ch.green << 2) | (c.ch.green >> 4);
            uint8_t b = (c.ch.blue  << 3) | (c.ch.blue  >> 2);
            // BMP stores BGR
            uint8_t bgr[3] = {b, g, r};
            fwrite(bgr, 3, 1, f);
        }
        if (padding > 0) fwrite(pad, padding, 1, f);
    }

    fclose(f);
    return true;
}

/* ══════════════════════════════════════════════════════════════
 * MOCK DATA
 * ══════════════════════════════════════════════════════════════*/
static void populate_mock_data(VehicleData *d) {
    d->speed    = 85;
    d->rpm      = 2750;
    d->ect      = 88;
    d->throttle = 42;
    d->load     = 55;

    d->battV    = 27.4f;
    d->battI    = 28.5f;
    d->setA     = 30.0f;
    d->targetCurrent = 30.0f;
    d->tempT1   = 42;
    d->tempT2   = 39;
    d->tempAmb  = 28;

    d->fault    = 0;
    d->alarm    = 0;
    d->status   = 0x0001;

    d->canOk    = true;
    d->rs485Ok  = true;
}

/* ══════════════════════════════════════════════════════════════
 * MAIN
 * ══════════════════════════════════════════════════════════════*/
int main(int argc, char *argv[]) {
    const char *output_file = "dashboard_screenshot.bmp";
    if (argc > 1) output_file = argv[1];

    // Initialize LVGL
    lv_init();

    // Set up framebuffer display driver
    lv_disp_draw_buf_init(&draw_buf, buf1, NULL, DISP_HOR_RES * 40);

    static lv_disp_drv_t disp_drv;
    lv_disp_drv_init(&disp_drv);
    disp_drv.hor_res = DISP_HOR_RES;
    disp_drv.ver_res = DISP_VER_RES;
    disp_drv.draw_buf = &draw_buf;
    disp_drv.flush_cb = flush_cb;
    lv_disp_drv_register(&disp_drv);

    // Build the dashboard UI
    ui_dashboard_create();

    // Populate with mock vehicle data
    VehicleData mock;
    populate_mock_data(&mock);
    ui_dashboard_update(&mock);

    // Render: run several LVGL cycles to complete all drawing
    for (int i = 0; i < 200; i++) {
        lv_tick_inc(5);
        lv_timer_handler();
    }

    // Write framebuffer to BMP
    if (write_bmp(output_file, framebuffer, DISP_HOR_RES, DISP_VER_RES)) {
        printf("Screenshot saved: %s (%dx%d)\n", output_file, DISP_HOR_RES, DISP_VER_RES);
    } else {
        fprintf(stderr, "Failed to write %s\n", output_file);
        return 1;
    }

    return 0;
}
