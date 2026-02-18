/**
 * @file lv_conf.h
 * LVGL v8.4 configuration for PC simulator (framebuffer mode)
 * Based on the ESP32 project's include/lv_conf.h with 3 changes:
 *   - LV_COLOR_16_SWAP = 0 (native byte order on PC)
 *   - LV_TICK_CUSTOM = 0 (manual lv_tick_inc)
 *   - LV_ATTRIBUTE_FAST_MEM = empty (no IRAM_ATTR on PC)
 */

#ifndef LV_CONF_H
#define LV_CONF_H

#include <stdint.h>

/* ════════════════════════════════════════════════════════════════
 * COLOR SETTINGS
 * ════════════════════════════════════════════════════════════════*/
#define LV_COLOR_DEPTH          16
#define LV_COLOR_16_SWAP        0       /* CHANGED: 0 for native PC byte order */
#define LV_COLOR_SCREEN_TRANSP  0
#define LV_COLOR_MIX_ROUND_OFS  128
#define LV_COLOR_CHROMA_KEY     lv_color_hex(0x00ff00)

/* ════════════════════════════════════════════════════════════════
 * MEMORY SETTINGS
 * ════════════════════════════════════════════════════════════════*/
#define LV_MEM_CUSTOM           1
#if LV_MEM_CUSTOM == 1
    #define LV_MEM_CUSTOM_INCLUDE   <stdlib.h>
    #define LV_MEM_CUSTOM_ALLOC     malloc
    #define LV_MEM_CUSTOM_FREE      free
    #define LV_MEM_CUSTOM_REALLOC   realloc
#endif

#define LV_MEM_BUF_MAX_NUM     16
#define LV_MEMCPY_MEMSET_STD   1

/* ════════════════════════════════════════════════════════════════
 * HAL SETTINGS
 * ════════════════════════════════════════════════════════════════*/
#define LV_DISP_DEF_REFR_PERIOD    30   /* ms */
#define LV_INDEV_DEF_READ_PERIOD   30   /* ms */

#define LV_TICK_CUSTOM             0    /* CHANGED: manual lv_tick_inc() */

#define LV_DPI_DEF                 130

/* ════════════════════════════════════════════════════════════════
 * FEATURE CONFIGURATION
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_LOG      0
#define LV_USE_ASSERT_NULL          1
#define LV_USE_ASSERT_MALLOC        1
#define LV_USE_ASSERT_STYLE         0
#define LV_USE_ASSERT_MEM_INTEGRITY 0
#define LV_USE_ASSERT_OBJ           0

#define LV_ATTRIBUTE_FAST_MEM               /* CHANGED: empty (no IRAM_ATTR) */

/* ════════════════════════════════════════════════════════════════
 * FONT CONFIGURATION
 * ════════════════════════════════════════════════════════════════*/
#define LV_FONT_MONTSERRAT_8    0
#define LV_FONT_MONTSERRAT_10   0
#define LV_FONT_MONTSERRAT_12   1
#define LV_FONT_MONTSERRAT_14   1
#define LV_FONT_MONTSERRAT_16   1
#define LV_FONT_MONTSERRAT_18   0
#define LV_FONT_MONTSERRAT_20   1
#define LV_FONT_MONTSERRAT_22   0
#define LV_FONT_MONTSERRAT_24   1
#define LV_FONT_MONTSERRAT_26   0
#define LV_FONT_MONTSERRAT_28   1
#define LV_FONT_MONTSERRAT_30   0
#define LV_FONT_MONTSERRAT_32   0
#define LV_FONT_MONTSERRAT_34   0
#define LV_FONT_MONTSERRAT_36   1
#define LV_FONT_MONTSERRAT_38   0
#define LV_FONT_MONTSERRAT_40   0
#define LV_FONT_MONTSERRAT_42   0
#define LV_FONT_MONTSERRAT_44   0
#define LV_FONT_MONTSERRAT_46   0
#define LV_FONT_MONTSERRAT_48   0

#define LV_FONT_MONTSERRAT_12_SUBPX 0
#define LV_FONT_MONTSERRAT_28_COMPRESSED 0
#define LV_FONT_DEJAVU_16_PERSIAN_HEBREW 0
#define LV_FONT_SIMSUN_16_CJK   0
#define LV_FONT_UNSCII_8        0
#define LV_FONT_UNSCII_16       0
#define LV_FONT_CUSTOM_DECLARE

#define LV_FONT_DEFAULT          &lv_font_montserrat_14
#define LV_FONT_FMT_TXT_LARGE   0
#define LV_USE_FONT_COMPRESSED   0
#define LV_USE_FONT_SUBPX       0
#define LV_FONT_SUBPX_BGR       0

/* ════════════════════════════════════════════════════════════════
 * TEXT SETTINGS
 * ════════════════════════════════════════════════════════════════*/
#define LV_TXT_ENC              LV_TXT_ENC_UTF8
#define LV_TXT_BREAK_CHARS      " ,.;:-_"
#define LV_TXT_LINE_BREAK_LONG_LEN 0
#define LV_TXT_LINE_BREAK_LONG_PRE_MIN_LEN 3
#define LV_TXT_LINE_BREAK_LONG_POST_MIN_LEN 3
#define LV_TXT_COLOR_CMD        "#"
#define LV_USE_BIDI             0
#define LV_USE_ARABIC_PERSIAN_CHARS 0

/* ════════════════════════════════════════════════════════════════
 * WIDGET USAGE
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_ARC              1
#define LV_USE_BAR              1
#define LV_USE_BTN              1
#define LV_USE_BTNMATRIX        1
#define LV_USE_CANVAS           0
#define LV_USE_CHECKBOX         1
#define LV_USE_DROPDOWN         1
#define LV_USE_IMG              1
#define LV_USE_LABEL            1
#define LV_USE_LINE             1
#define LV_USE_ROLLER           1
#define LV_USE_SLIDER           1
#define LV_USE_SWITCH           1
#define LV_USE_TEXTAREA         1
#define LV_USE_TABLE            1

/* Extra widgets */
#define LV_USE_ANIMIMG          0
#define LV_USE_CALENDAR         0
#define LV_USE_CHART            1
#define LV_USE_COLORWHEEL       0
#define LV_USE_IMGBTN           0
#define LV_USE_KEYBOARD         0
#define LV_USE_LED              1
#define LV_USE_LIST             1
#define LV_USE_MENU             0
#define LV_USE_METER            1
#define LV_USE_MSGBOX           1
#define LV_USE_SPAN             0
#define LV_USE_SPINBOX          0
#define LV_USE_SPINNER          1
#define LV_USE_TABVIEW          0
#define LV_USE_TILEVIEW         0
#define LV_USE_WIN              0

/* ════════════════════════════════════════════════════════════════
 * THEMES
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_THEME_DEFAULT    1
#define LV_THEME_DEFAULT_DARK   1
#define LV_THEME_DEFAULT_GROW   0
#define LV_THEME_DEFAULT_TRANSITION_TIME 80
#define LV_USE_THEME_BASIC      1

/* ════════════════════════════════════════════════════════════════
 * LAYOUTS
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_FLEX             1
#define LV_USE_GRID             1

/* ════════════════════════════════════════════════════════════════
 * DEMOS (disabled)
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_DEMO_WIDGETS     0
#define LV_USE_DEMO_BENCHMARK   0
#define LV_USE_DEMO_STRESS      0
#define LV_USE_DEMO_MUSIC       0
#define LV_BUILD_EXAMPLES       0

/* ════════════════════════════════════════════════════════════════
 * OTHERS
 * ════════════════════════════════════════════════════════════════*/
#define LV_USE_SNAPSHOT         0
#define LV_USE_MONKEY           0
#define LV_USE_GRIDNAV          0
#define LV_USE_FRAGMENT          0
#define LV_USE_IMGFONT          0
#define LV_USE_IME_PINYIN       0
#define LV_USE_GPU_STM32_DMA2D  0
#define LV_USE_GPU_NXP_PXP      0
#define LV_USE_GPU_NXP_VG_LITE  0
#define LV_USE_GPU_SDL          0

#endif /* LV_CONF_H */
