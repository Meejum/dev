cmake_minimum_required(VERSION 3.14)
project(vehicle_dashboard_sim C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(LVGL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lvgl)
set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/..)

# Tell LVGL to use #include "lv_conf.h" resolved via include path
add_compile_definitions(LV_CONF_INCLUDE_SIMPLE)

# ── LVGL library ──
file(GLOB_RECURSE LVGL_SOURCES ${LVGL_DIR}/src/*.c)

add_library(lvgl STATIC ${LVGL_SOURCES})
target_include_directories(lvgl PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}    # simulator/lv_conf.h found first
    ${LVGL_DIR}
    ${LVGL_DIR}/src
)

# ── Simulator executable ──
add_executable(dashboard_sim main.cpp)

target_include_directories(dashboard_sim PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}    # hal_stubs.h, lv_conf.h
    ${LVGL_DIR}                    # <lvgl.h>
    ${PROJECT_ROOT}/include        # ui_dashboard.h
)

target_link_libraries(dashboard_sim lvgl pthread m)
