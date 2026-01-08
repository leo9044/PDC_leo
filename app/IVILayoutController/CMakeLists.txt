cmake_minimum_required(VERSION 3.10)
project(IVILayoutController)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ILM (IVI Layer Manager) library paths (NVIDIA Jetson specific)
set(ILM_LIB_PATH "/usr/lib/aarch64-linux-gnu/nvidia/weston-13.0")
set(ILM_INCLUDE_PATH "${CMAKE_SOURCE_DIR}/include")

# Direct library paths (versioned .so files)
set(ILM_CONTROL "${ILM_LIB_PATH}/libilmControl.so.2.3.2")
set(ILM_COMMON "${ILM_LIB_PATH}/libilmCommon.so.2.3.2")
set(ILM_CLIENT "${ILM_LIB_PATH}/libilmClient.so.2.3.2")
set(ILM_INPUT "${ILM_LIB_PATH}/libilmInput.so.2.3.2")

# IVI Layout Controller executable
add_executable(ivi-layout-controller
    src/main.cpp
    src/png_stub.cpp
)

target_include_directories(ivi-layout-controller PRIVATE
    ${ILM_INCLUDE_PATH}
)

target_link_libraries(ivi-layout-controller
    ${ILM_CONTROL}
    ${ILM_COMMON}
    ${ILM_CLIENT}
    wayland-client
    png
    pthread
)

# Installation
install(TARGETS ivi-layout-controller
    RUNTIME DESTINATION /usr/local/bin
)

# Config script installation
install(PROGRAMS
    scripts/setup-ivi-layout.sh
    DESTINATION /usr/local/bin
)
