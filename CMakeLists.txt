cmake_minimum_required(VERSION 3.16)

project(DES_Head-Unit VERSION 1.0 LANGUAGES CXX)

# Global settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

message(STATUS "")
message(STATUS "═══════════════════════════════════════════════════════")
message(STATUS "DES Head-Unit Multi-Process Architecture")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "═══════════════════════════════════════════════════════")
message(STATUS "")

# Options
option(BUILD_MEDIA_APP "Build MediaApp process" ON)
option(BUILD_GEAR_APP "Build GearApp process" ON)
option(BUILD_AMBIENT_APP "Build AmbientApp process" ON)
option(BUILD_MAIN_APP "Build HU_MainApp (UI integration)" ON)
option(BUILD_LEGACY_APP "Build legacy HU_app (single process)" ON)

# Subdirectories
if(BUILD_MEDIA_APP)
    message(STATUS "✅ MediaApp will be built")
    add_subdirectory(app/MediaApp)
endif()

if(BUILD_GEAR_APP)
    message(STATUS "✅ GearApp will be built")
    add_subdirectory(app/GearApp)
endif()

if(BUILD_AMBIENT_APP)
    message(STATUS "✅ AmbientApp will be built")
    add_subdirectory(app/AmbientApp)
endif()

if(BUILD_MAIN_APP)
    message(STATUS "✅ HU_MainApp (UI) will be built")
    add_subdirectory(app/HU_MainApp)
endif()

if(BUILD_LEGACY_APP)
    message(STATUS "✅ Legacy HU_app will be built (for reference)")
    # HU_app has its own build system
endif()

message(STATUS "")
message(STATUS "Build configuration complete!")
message(STATUS "Run: make -j$(nproc)")
message(STATUS "═══════════════════════════════════════════════════════")
message(STATUS "")
