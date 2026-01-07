cmake_minimum_required(VERSION 3.16)

project(HU_MainApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# Qt packages
find_package(Qt5 REQUIRED COMPONENTS Core Quick Qml Multimedia Network)

# Boost (required by vSOMEIP)
find_package(Boost 1.74 REQUIRED COMPONENTS system thread filesystem)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# CommonAPI and vSOMEIP paths
set(COMMONAPI_INSTALL_PATH "/home/seam/DES_Head-Unit/install_folder")
set(COMMONAPI_GENERATED_PATH "/home/seam/DES_Head-Unit/commonapi/generated")

include_directories(
    ${COMMONAPI_INSTALL_PATH}/include/CommonAPI-3.2
    ${COMMONAPI_INSTALL_PATH}/include/CommonAPI-SomeIP-3.2
    ${COMMONAPI_INSTALL_PATH}/include
    ${COMMONAPI_GENERATED_PATH}/core
    ${COMMONAPI_GENERATED_PATH}/someip
)

link_directories(
    ${COMMONAPI_INSTALL_PATH}/lib
)

# ═══════════════════════════════════════════════════════════════════
# Source files - HU_MainApp (UI Integration Only)
# ═══════════════════════════════════════════════════════════════════
# NOTE: Manager 파일들은 각 프로세스 폴더에 있습니다:
#   - MediaApp/mediamanager.h/cpp
#   - GearApp/gearmanager.h/cpp, ipcmanager.h/cpp
#   - AmbientApp/ambientmanager.h/cpp
#
# TEMPORARY: vsomeip 통합 전까지 Manager 소스를 빌드에 포함
#            (각 프로세스에서 직접 참조)
#
# TODO: vsomeip 통합 시 Proxy 클래스로 교체:
#   - proxies/MediaProxy.h/cpp
#   - proxies/GearProxy.h/cpp
#   - proxies/AmbientProxy.h/cpp
# ═══════════════════════════════════════════════════════════════════

set(SOURCES
    src/main.cpp

    # Manager 소스
    ../MediaApp/src/mediamanager.cpp
    ../GearApp/src/gearmanager.cpp
    ../AmbientApp/src/ambientmanager.cpp
    ../GearApp/src/ipcmanager.cpp

    # vSOMEIP Communication (MediaControl)
    src/MediaControlStubImpl.cpp
    src/MediaControlClient.cpp

    # CommonAPI Generated Code
    ${COMMONAPI_GENERATED_PATH}/someip/v1/mediacontrol/MediaControlSomeIPProxy.cpp
    ${COMMONAPI_GENERATED_PATH}/someip/v1/mediacontrol/MediaControlSomeIPStubAdapter.cpp
    ${COMMONAPI_GENERATED_PATH}/someip/v1/mediacontrol/MediaControlSomeIPDeployment.cpp
)

set(HEADERS
    # Manager 헤더
    ../MediaApp/src/mediamanager.h
    ../GearApp/src/gearmanager.h
    ../AmbientApp/src/ambientmanager.h
    ../GearApp/src/ipcmanager.h

    # vSOMEIP Communication
    src/MediaControlStubImpl.h
    src/MediaControlClient.h
)

# QML resources
set(QML_RESOURCES
    qml.qrc
)

# Executable
add_executable(HU_MainApp
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

target_link_libraries(HU_MainApp
    Qt5::Core
    Qt5::Quick
    Qt5::Qml
    Qt5::Multimedia
    Qt5::Network
    Boost::system
    Boost::thread
    Boost::filesystem
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)

# Set RPATH to find libraries at runtime
set_target_properties(HU_MainApp PROPERTIES
    INSTALL_RPATH "${COMMONAPI_INSTALL_PATH}/lib"
    BUILD_WITH_INSTALL_RPATH TRUE
    BUILD_RPATH "${COMMONAPI_INSTALL_PATH}/lib"
)

# Install
install(TARGETS HU_MainApp
    RUNTIME DESTINATION bin
)
