cmake_minimum_required(VERSION 3.16)
project(VehicleControlTest)

set(CMAKE_CXX_STANDARD 17)

# Find packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(VSOMEIP REQUIRED vsomeip3)
pkg_check_modules(COMMONAPI REQUIRED CommonAPI)
pkg_check_modules(COMMONAPI_SOMEIP REQUIRED CommonAPI-SomeIP)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/generated
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
    ${VSOMEIP_INCLUDE_DIRS}
)

# Generated sources
set(GENERATED_SOURCES
    generated/v1/commonapi/VehicleControlSomeIPProxy.cpp
    generated/v1/commonapi/VehicleControlSomeIPStubAdapter.cpp
    generated/v1/commonapi/VehicleControlSomeIPDeployment.cpp
    generated/core/v1/commonapi/VehicleControlSomeIPProxy.cpp
    generated/core/v1/commonapi/VehicleControlSomeIPStubAdapter.cpp
    generated/core/v1/commonapi/VehicleControlSomeIPDeployment.cpp
)

# Basic test executable  
add_executable(basic_test
    src/BasicTest.cpp
)

# Service executable
add_executable(VehicleControlService
    src/VehicleControlService.cpp
    src/VehicleControlStubImpl.cpp
    ${GENERATED_SOURCES}
)

# Client executable  
add_executable(VehicleControlClient
    src/VehicleControlClient.cpp
    ${GENERATED_SOURCES}
)

# Link libraries
target_link_libraries(VehicleControlService
    ${COMMONAPI_LIBRARIES}
    ${COMMONAPI_SOMEIP_LIBRARIES}
    ${VSOMEIP_LIBRARIES}
    pthread
)

target_link_libraries(VehicleControlClient
    ${COMMONAPI_LIBRARIES}
    ${COMMONAPI_SOMEIP_LIBRARIES}
    ${VSOMEIP_LIBRARIES}
    pthread
)
