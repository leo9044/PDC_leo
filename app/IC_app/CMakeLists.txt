cmake_minimum_required(VERSION 3.16)

project(IC_app VERSION 1.0 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ════════════════════════════════════════════════════════════
# 배포 환경별 경로 설정 (환경변수 우선)
# ════════════════════════════════════════════════════════════
if(DEFINED ENV{DEPLOY_PREFIX})
    set(INSTALL_PREFIX $ENV{DEPLOY_PREFIX})
    message(STATUS "Using DEPLOY_PREFIX from environment: ${INSTALL_PREFIX}")
else()
    # 기본값: 사용자 홈 디렉토리 기준
    set(INSTALL_PREFIX "$ENV{HOME}/DES_Head-Unit/install_folder")
    message(STATUS "Using default DEPLOY_PREFIX: ${INSTALL_PREFIX}")
endif()

# RPATH 설정 (vsomeip, CommonAPI 라이브러리 경로)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${INSTALL_PREFIX}")
set(CMAKE_INSTALL_RPATH "${INSTALL_PREFIX}/lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")

find_package(QT NAMES Qt5 Qt6 REQUIRED COMPONENTS Core Widgets Quick Network)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Quick Network)

# CommonAPI (vsomeip)
find_package(CommonAPI 3.2.0 REQUIRED)
find_package(CommonAPI-SomeIP 3.2.0 REQUIRED)
find_package(vsomeip3 REQUIRED)

# Generated CommonAPI code paths
set(COMMONAPI_GEN_DIR ${CMAKE_SOURCE_DIR}/../../commonapi/generated)
set(COMMONAPI_CORE_DIR ${COMMONAPI_GEN_DIR}/core)
set(COMMONAPI_SOMEIP_DIR ${COMMONAPI_GEN_DIR}/someip)

include_directories(
    ${COMMONAPI_CORE_DIR}
    ${COMMONAPI_SOMEIP_DIR}
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
    ${VSOMEIP_INCLUDE_DIRS}
)

set(PROJECT_SOURCES
        main.cpp
        caninterface.cpp
        caninterface.h
        vehiclecontrolclient.cpp
        vehiclecontrolclient.h
        App.qrc
)

# CommonAPI generated sources (Client uses Proxy)
file(GLOB COMMONAPI_SOMEIP_SOURCES
    "${COMMONAPI_SOMEIP_DIR}/v1/vehiclecontrol/VehicleControlSomeIPProxy.cpp"
    "${COMMONAPI_SOMEIP_DIR}/v1/vehiclecontrol/VehicleControlSomeIPDeployment.cpp"
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(IC_app
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
        ${COMMONAPI_SOMEIP_SOURCES}
    )
else()
    add_executable(IC_app
        ${PROJECT_SOURCES}
        ${COMMONAPI_SOMEIP_SOURCES}
    )
endif()

target_link_libraries(IC_app
    PRIVATE Qt${QT_VERSION_MAJOR}::Core 
            Qt${QT_VERSION_MAJOR}::Widgets 
            Qt${QT_VERSION_MAJOR}::Quick 
            Qt${QT_VERSION_MAJOR}::Network
            CommonAPI
            CommonAPI-SomeIP
            vsomeip3)

if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.IC_app)
endif()
set_target_properties(IC_app PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS IC_app
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(IC_app)
    qt_finalize_executable(IC_app)
endif()