/**
 * @file ui_dashboard.h
 * LVGL Dashboard UI for Vehicle + Charger Monitor
 * Layout: 1024×600 dark industrial theme
 * 
 * Left panel:  OBD-II gauges (Speed, RPM, Coolant, Throttle)
 * Right panel: Charger data (Battery V, Current, Temps, Faults)
 * Top bar:     CAN/RS485 status LEDs, title, uptime
 */

#ifndef UI_DASHBOARD_H
#define UI_DASHBOARD_H

#include <lvgl.h>

/* ══════════════════════════════════════════════════════════════
 * DATA STRUCTURE — shared between main.cpp and UI
 * ══════════════════════════════════════════════════════════════*/
struct VehicleData {
    // OBD-II
    int speed    = -1;
    int rpm      = -1;
    int ect      = -1;
    int throttle = -1;
    int load     = -1;
    // Charger
    float battV  = 0;
    float battI  = 0;
    float setA   = 12.0f;
    float targetCurrent = 12.0f;
    int tempT1   = 0;
    int tempT2   = 0;
    int tempAmb  = 0;
    uint16_t fault  = 0;
    uint16_t alarm  = 0;
    uint16_t status = 0;
    // Status
    bool canOk   = false;
    bool rs485Ok = false;
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

/* ══════════════════════════════════════════════════════════════
 * COLOR PALETTE — Dark Industrial Theme
 * ══════════════════════════════════════════════════════════════*/
#define C_BG        lv_color_hex(0x0a0e17)
#define C_CARD      lv_color_hex(0x111827)
#define C_SURFACE   lv_color_hex(0x1e293b)
#define C_BORDER    lv_color_hex(0x334155)
#define C_ACCENT    lv_color_hex(0xf59e0b)  // Amber
#define C_GREEN     lv_color_hex(0x22c55e)
#define C_RED       lv_color_hex(0xef4444)
#define C_BLUE      lv_color_hex(0x3b82f6)
#define C_CYAN      lv_color_hex(0x06b6d4)
#define C_TEXT      lv_color_hex(0xf1f5f9)
#define C_DIM       lv_color_hex(0x94a3b8)
#define C_MUTED     lv_color_hex(0x475569)

/* ══════════════════════════════════════════════════════════════
 * UI OBJECT HANDLES
 * ══════════════════════════════════════════════════════════════*/
static lv_obj_t *arc_speed, *arc_rpm, *arc_ect, *arc_throttle;
static lv_obj_t *lbl_speed_val, *lbl_rpm_val, *lbl_ect_val, *lbl_throttle_val;
static lv_obj_t *lbl_load;

static lv_obj_t *lbl_battV, *lbl_battI, *lbl_setA;
static lv_obj_t *lbl_t1, *lbl_t2, *lbl_amb;
static lv_obj_t *lbl_fault_status;

static lv_obj_t *led_can, *led_rs485;
static lv_obj_t *lbl_uptime;

/* ══════════════════════════════════════════════════════════════
 * STYLES
 * ══════════════════════════════════════════════════════════════*/
static lv_style_t style_card;
static lv_style_t style_arc_bg;
static lv_style_t style_data_row;
static bool styles_initialized = false;

static void init_styles() {
    if (styles_initialized) return;
    styles_initialized = true;

    // Card panel style
    lv_style_init(&style_card);
    lv_style_set_bg_color(&style_card, C_CARD);
    lv_style_set_border_color(&style_card, C_BORDER);
    lv_style_set_border_width(&style_card, 1);
    lv_style_set_radius(&style_card, 12);
    lv_style_set_pad_all(&style_card, 10);

    // Data row style
    lv_style_init(&style_data_row);
    lv_style_set_bg_color(&style_data_row, C_SURFACE);
    lv_style_set_bg_opa(&style_data_row, LV_OPA_60);
    lv_style_set_radius(&style_data_row, 8);
    lv_style_set_pad_hor(&style_data_row, 12);
    lv_style_set_pad_ver(&style_data_row, 6);
    lv_style_set_border_width(&style_data_row, 0);
}

/* ══════════════════════════════════════════════════════════════
 * HELPER: Create a gauge arc with center value label
 * Returns the value label for later updates
 * ══════════════════════════════════════════════════════════════*/
static lv_obj_t* create_gauge(lv_obj_t *parent, lv_obj_t **arc_out,
                               lv_color_t color, const char *name,
                               int arc_size) {
    // Container
    lv_obj_t *cont = lv_obj_create(parent);
    lv_obj_set_size(cont, arc_size + 20, arc_size + 40);
    lv_obj_set_style_bg_opa(cont, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(cont, 0, 0);
    lv_obj_set_style_pad_all(cont, 0, 0);
    lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_flex_align(cont, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);

    // Arc
    lv_obj_t *arc = lv_arc_create(cont);
    lv_obj_set_size(arc, arc_size, arc_size);
    lv_arc_set_range(arc, 0, 100);
    lv_arc_set_value(arc, 0);
    lv_arc_set_bg_angles(arc, 135, 405);
    lv_obj_set_style_arc_color(arc, C_SURFACE, LV_PART_MAIN);
    lv_obj_set_style_arc_color(arc, color, LV_PART_INDICATOR);
    lv_obj_set_style_arc_width(arc, 8, LV_PART_MAIN);
    lv_obj_set_style_arc_width(arc, 8, LV_PART_INDICATOR);
    lv_obj_set_style_arc_rounded(arc, true, LV_PART_INDICATOR);
    lv_obj_remove_style(arc, NULL, LV_PART_KNOB);
    *arc_out = arc;

    // Value label centered on arc
    lv_obj_t *lbl_val = lv_label_create(arc);
    lv_label_set_text(lbl_val, "--");
    lv_obj_set_style_text_color(lbl_val, C_TEXT, 0);
    lv_obj_set_style_text_font(lbl_val, &lv_font_montserrat_24, 0);
    lv_obj_center(lbl_val);

    // Name label below
    lv_obj_t *lbl_name = lv_label_create(cont);
    lv_label_set_text(lbl_name, name);
    lv_obj_set_style_text_color(lbl_name, C_DIM, 0);
    lv_obj_set_style_text_font(lbl_name, &lv_font_montserrat_12, 0);

    return lbl_val;
}

/* ══════════════════════════════════════════════════════════════
 * HELPER: Create a data row label (for charger panel)
 * ══════════════════════════════════════════════════════════════*/
static lv_obj_t* create_data_row(lv_obj_t *parent, const char *label_text,
                                  lv_color_t value_color) {
    lv_obj_t *row = lv_obj_create(parent);
    lv_obj_set_size(row, LV_PCT(100), LV_SIZE_CONTENT);
    lv_obj_add_style(row, &style_data_row, 0);
    lv_obj_set_flex_flow(row, LV_FLEX_FLOW_ROW);
    lv_obj_set_flex_align(row, LV_FLEX_ALIGN_SPACE_BETWEEN, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);

    // Label
    lv_obj_t *lbl = lv_label_create(row);
    lv_label_set_text(lbl, label_text);
    lv_obj_set_style_text_color(lbl, C_DIM, 0);
    lv_obj_set_style_text_font(lbl, &lv_font_montserrat_14, 0);

    // Value
    lv_obj_t *val = lv_label_create(row);
    lv_label_set_text(val, "--");
    lv_obj_set_style_text_color(val, value_color, 0);
    lv_obj_set_style_text_font(val, &lv_font_montserrat_16, 0);

    return val;
}

/* ══════════════════════════════════════════════════════════════
 * BUILD THE DASHBOARD UI
 * ══════════════════════════════════════════════════════════════*/
void ui_dashboard_create() {
    init_styles();

    lv_obj_t *scr = lv_scr_act();
    lv_obj_set_style_bg_color(scr, C_BG, 0);

    /* ─── TOP STATUS BAR ─────────────────────────────────── */
    lv_obj_t *topbar = lv_obj_create(scr);
    lv_obj_set_size(topbar, 1024, 40);
    lv_obj_set_pos(topbar, 0, 0);
    lv_obj_set_style_bg_color(topbar, C_SURFACE, 0);
    lv_obj_set_style_radius(topbar, 0, 0);
    lv_obj_set_style_border_width(topbar, 0, 0);
    lv_obj_set_style_pad_hor(topbar, 16, 0);
    lv_obj_set_flex_flow(topbar, LV_FLEX_FLOW_ROW);
    lv_obj_set_flex_align(topbar, LV_FLEX_ALIGN_SPACE_BETWEEN, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);

    // CAN status
    lv_obj_t *can_group = lv_obj_create(topbar);
    lv_obj_set_size(can_group, LV_SIZE_CONTENT, LV_SIZE_CONTENT);
    lv_obj_set_style_bg_opa(can_group, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(can_group, 0, 0);
    lv_obj_set_style_pad_all(can_group, 0, 0);
    lv_obj_set_flex_flow(can_group, LV_FLEX_FLOW_ROW);
    lv_obj_set_flex_align(can_group, LV_FLEX_ALIGN_START, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_pad_column(can_group, 6, 0);

    led_can = lv_led_create(can_group);
    lv_obj_set_size(led_can, 12, 12);
    lv_led_set_color(led_can, C_GREEN);
    lv_led_off(led_can);

    lv_obj_t *l = lv_label_create(can_group);
    lv_label_set_text(l, "CAN");
    lv_obj_set_style_text_color(l, C_DIM, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_12, 0);

    led_rs485 = lv_led_create(can_group);
    lv_obj_set_size(led_rs485, 12, 12);
    lv_led_set_color(led_rs485, C_GREEN);
    lv_led_off(led_rs485);

    l = lv_label_create(can_group);
    lv_label_set_text(l, "RS485");
    lv_obj_set_style_text_color(l, C_DIM, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_12, 0);

    // Title
    l = lv_label_create(topbar);
    lv_label_set_text(l, LV_SYMBOL_CHARGE " VEHICLE DASHBOARD");
    lv_obj_set_style_text_color(l, C_ACCENT, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_16, 0);

    // Uptime
    lbl_uptime = lv_label_create(topbar);
    lv_label_set_text(lbl_uptime, "UP: 00:00:00");
    lv_obj_set_style_text_color(lbl_uptime, C_MUTED, 0);
    lv_obj_set_style_text_font(lbl_uptime, &lv_font_montserrat_12, 0);

    /* ─── MAIN AREA ──────────────────────────────────────── */
    lv_obj_t *main_row = lv_obj_create(scr);
    lv_obj_set_size(main_row, 1024, 556);
    lv_obj_set_pos(main_row, 0, 42);
    lv_obj_set_style_bg_opa(main_row, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(main_row, 0, 0);
    lv_obj_set_flex_flow(main_row, LV_FLEX_FLOW_ROW);
    lv_obj_set_style_pad_all(main_row, 8, 0);
    lv_obj_set_style_pad_column(main_row, 8, 0);

    /* ─── LEFT PANEL: OBD-II ─────────────────────────────── */
    lv_obj_t *left = lv_obj_create(main_row);
    lv_obj_set_flex_grow(left, 3);
    lv_obj_set_height(left, LV_PCT(100));
    lv_obj_add_style(left, &style_card, 0);
    lv_obj_set_flex_flow(left, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_style_pad_gap(left, 4, 0);

    // Section header
    l = lv_label_create(left);
    lv_label_set_text(l, LV_SYMBOL_SETTINGS "  OBD-II DATA");
    lv_obj_set_style_text_color(l, C_ACCENT, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_14, 0);

    // Gauge grid
    lv_obj_t *gauge_grid = lv_obj_create(left);
    lv_obj_set_size(gauge_grid, LV_PCT(100), LV_SIZE_CONTENT);
    lv_obj_set_flex_grow(gauge_grid, 1);
    lv_obj_set_style_bg_opa(gauge_grid, LV_OPA_TRANSP, 0);
    lv_obj_set_style_border_width(gauge_grid, 0, 0);
    lv_obj_set_style_pad_all(gauge_grid, 0, 0);
    lv_obj_set_flex_flow(gauge_grid, LV_FLEX_FLOW_ROW_WRAP);
    lv_obj_set_flex_align(gauge_grid, LV_FLEX_ALIGN_SPACE_EVENLY, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);

    lbl_speed_val    = create_gauge(gauge_grid, &arc_speed,    C_CYAN,   "SPEED km/h", 120);
    lbl_rpm_val      = create_gauge(gauge_grid, &arc_rpm,      C_ACCENT, "RPM",        120);
    lbl_ect_val      = create_gauge(gauge_grid, &arc_ect,      C_BLUE,   "COOLANT \xC2\xB0""C", 120);
    lbl_throttle_val = create_gauge(gauge_grid, &arc_throttle,  C_GREEN,  "THROTTLE %", 120);

    // Engine load bar at bottom
    lv_obj_t *load_row = lv_obj_create(left);
    lv_obj_set_size(load_row, LV_PCT(100), LV_SIZE_CONTENT);
    lv_obj_add_style(load_row, &style_data_row, 0);
    lv_obj_set_flex_flow(load_row, LV_FLEX_FLOW_ROW);
    lv_obj_set_flex_align(load_row, LV_FLEX_ALIGN_SPACE_BETWEEN, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);

    l = lv_label_create(load_row);
    lv_label_set_text(l, "ENGINE LOAD");
    lv_obj_set_style_text_color(l, C_DIM, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_14, 0);

    lbl_load = lv_label_create(load_row);
    lv_label_set_text(lbl_load, "--%");
    lv_obj_set_style_text_color(lbl_load, C_CYAN, 0);
    lv_obj_set_style_text_font(lbl_load, &lv_font_montserrat_20, 0);

    /* ─── RIGHT PANEL: CHARGER ───────────────────────────── */
    lv_obj_t *right = lv_obj_create(main_row);
    lv_obj_set_flex_grow(right, 2);
    lv_obj_set_height(right, LV_PCT(100));
    lv_obj_add_style(right, &style_card, 0);
    lv_obj_set_flex_flow(right, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_style_pad_gap(right, 5, 0);

    // Section header
    l = lv_label_create(right);
    lv_label_set_text(l, LV_SYMBOL_BATTERY_FULL "  CHARGER");
    lv_obj_set_style_text_color(l, C_GREEN, 0);
    lv_obj_set_style_text_font(l, &lv_font_montserrat_14, 0);

    // Charger data rows
    lbl_battV = create_data_row(right, "BATTERY",  C_GREEN);
    lbl_battI = create_data_row(right, "CURRENT",  C_ACCENT);
    lbl_setA  = create_data_row(right, "SET POINT", C_BLUE);
    lbl_t1    = create_data_row(right, "TEMP T1",  C_CYAN);
    lbl_t2    = create_data_row(right, "TEMP T2",  C_CYAN);
    lbl_amb   = create_data_row(right, "AMBIENT",  C_DIM);

    // Fault / status box at bottom
    lv_obj_t *status_box = lv_obj_create(right);
    lv_obj_set_size(status_box, LV_PCT(100), LV_SIZE_CONTENT);
    lv_obj_set_style_bg_color(status_box, lv_color_hex(0x052e16), 0);
    lv_obj_set_style_border_color(status_box, lv_color_hex(0x166534), 0);
    lv_obj_set_style_border_width(status_box, 1, 0);
    lv_obj_set_style_radius(status_box, 10, 0);
    lv_obj_set_style_pad_all(status_box, 10, 0);

    lbl_fault_status = lv_label_create(status_box);
    lv_label_set_text(lbl_fault_status, LV_SYMBOL_OK " INITIALIZING...");
    lv_obj_set_style_text_color(lbl_fault_status, C_GREEN, 0);
    lv_obj_set_style_text_font(lbl_fault_status, &lv_font_montserrat_14, 0);
    lv_obj_set_width(lbl_fault_status, LV_PCT(100));
    lv_label_set_long_mode(lbl_fault_status, LV_LABEL_LONG_WRAP);
}

/* ══════════════════════════════════════════════════════════════
 * UPDATE THE DASHBOARD WITH LIVE DATA
 * ══════════════════════════════════════════════════════════════*/
void ui_dashboard_update(VehicleData *d) {
    char buf[48];

    // ── OBD-II Gauges ──
    int spd = d->speed >= 0 ? d->speed : 0;
    snprintf(buf, sizeof(buf), "%d", spd);
    lv_label_set_text(lbl_speed_val, buf);
    lv_arc_set_value(arc_speed, spd * 100 / 200);  // 0-200 km/h max range

    int rpm = d->rpm >= 0 ? d->rpm : 0;
    snprintf(buf, sizeof(buf), "%d", rpm);
    lv_label_set_text(lbl_rpm_val, buf);
    lv_arc_set_value(arc_rpm, rpm * 100 / 8000);

    int ect = d->ect >= -40 ? d->ect : 0;
    snprintf(buf, sizeof(buf), "%d", ect);
    lv_label_set_text(lbl_ect_val, buf);
    lv_arc_set_value(arc_ect, (ect + 40) * 100 / 160);  // 0-120°C range (OBD raw: 0-160)

    int throt = d->throttle >= 0 ? d->throttle : 0;
    snprintf(buf, sizeof(buf), "%d", throt);
    lv_label_set_text(lbl_throttle_val, buf);
    lv_arc_set_value(arc_throttle, throt);

    // Load
    snprintf(buf, sizeof(buf), "%d%%", d->load >= 0 ? d->load : 0);
    lv_label_set_text(lbl_load, buf);

    // ── Charger Data ──
    snprintf(buf, sizeof(buf), "%.2f V", d->battV);
    lv_label_set_text(lbl_battV, buf);

    snprintf(buf, sizeof(buf), "%.1f A", d->battI);
    lv_label_set_text(lbl_battI, buf);

    snprintf(buf, sizeof(buf), "%.1f A", d->setA);
    lv_label_set_text(lbl_setA, buf);

    snprintf(buf, sizeof(buf), "%d \xC2\xB0""C", d->tempT1);
    lv_label_set_text(lbl_t1, buf);

    snprintf(buf, sizeof(buf), "%d \xC2\xB0""C", d->tempT2);
    lv_label_set_text(lbl_t2, buf);

    snprintf(buf, sizeof(buf), "%d \xC2\xB0""C", d->tempAmb);
    lv_label_set_text(lbl_amb, buf);

    // ── Status LEDs ──
    if (d->canOk)   lv_led_on(led_can);   else lv_led_off(led_can);
    if (d->rs485Ok) lv_led_on(led_rs485); else lv_led_off(led_rs485);

    // ── Uptime ──
    unsigned long sec = millis() / 1000;
    snprintf(buf, sizeof(buf), "UP: %02lu:%02lu:%02lu", sec / 3600, (sec / 60) % 60, sec % 60);
    lv_label_set_text(lbl_uptime, buf);

    // ── Fault Status ──
    bool hasFault = (d->fault & 0x0040) != 0;
    bool hasAlarm = (d->alarm & 0x0003) != 0;
    bool overTemp = d->tempT1 > 80 || d->tempT2 > 80;

    lv_obj_t *box = lv_obj_get_parent(lbl_fault_status);

    if (hasFault || hasAlarm) {
        lv_label_set_text(lbl_fault_status, LV_SYMBOL_WARNING " FAULT DETECTED\nCheck charger!");
        lv_obj_set_style_text_color(lbl_fault_status, C_RED, 0);
        lv_obj_set_style_bg_color(box, lv_color_hex(0x450a0a), 0);
        lv_obj_set_style_border_color(box, lv_color_hex(0x991b1b), 0);
    } else if (overTemp) {
        lv_label_set_text(lbl_fault_status, LV_SYMBOL_WARNING " OVER TEMP\nCharging reduced");
        lv_obj_set_style_text_color(lbl_fault_status, C_ACCENT, 0);
        lv_obj_set_style_bg_color(box, lv_color_hex(0x451a03), 0);
        lv_obj_set_style_border_color(box, lv_color_hex(0x92400e), 0);
    } else if (d->targetCurrent >= 30.0f) {
        lv_label_set_text(lbl_fault_status, LV_SYMBOL_OK " CHARGING FULL RATE\n30A — All systems normal");
        lv_obj_set_style_text_color(lbl_fault_status, C_GREEN, 0);
        lv_obj_set_style_bg_color(box, lv_color_hex(0x052e16), 0);
        lv_obj_set_style_border_color(box, lv_color_hex(0x166534), 0);
    } else {
        lv_label_set_text(lbl_fault_status, LV_SYMBOL_OK " CHARGING REDUCED\n12A — Waiting for conditions");
        lv_obj_set_style_text_color(lbl_fault_status, C_ACCENT, 0);
        lv_obj_set_style_bg_color(box, lv_color_hex(0x451a03), 0);
        lv_obj_set_style_border_color(box, lv_color_hex(0x78350f), 0);
    }
}

#endif // UI_DASHBOARD_H
