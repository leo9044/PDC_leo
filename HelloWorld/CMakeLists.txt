cmake_minimum_required(VERSION 3.10)
project(HelloWorld VERSION 1.0.0)

set(PRJ_NAME HelloWorld)
set(CMAKE_VERBOSE_MAKEFILE on)

# Logging options
OPTION(USE_FILE "Set to OFF to disable file logging" OFF )
OPTION(USE_CONSOLE "Set to OFF to disable console logging" OFF )
IF(USE_FILE)
  add_definitions(-DUSE_FILE)
ENDIF()
IF(USE_CONSOLE)
  add_definitions(-DUSE_CONSOLE)
ENDIF()

SET(MAX_LOG_LEVEL "DEBUG" CACHE STRING "maximum log level")
add_definitions(-DCOMMONAPI_LOGLEVEL=COMMONAPI_LOGLEVEL_${MAX_LOG_LEVEL})

# Compiler flags
if (MSVC)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_CRT_SECURE_NO_WARNINGS /EHsc /wd\\\"4503\\\"")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_CRT_SECURE_NO_WARNINGS /wd\\\"4503\\\"")
else()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -Wall -O0 -std=c++11 -D_GLIBCXX_USE_NANOSLEEP -DLINUX")
endif()

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif()

# CommonAPI options
OPTION(USE_INSTALLED_COMMONAPI "Use installed CommonAPI" ON)

if("${USE_INSTALLED_COMMONAPI}" STREQUAL "ON")
    FIND_PACKAGE(CommonAPI 3.2.0 REQUIRED CONFIG)
else()
    FIND_PACKAGE(CommonAPI 3.2.0 REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
endif()

# SOME/IP
find_package(CommonAPI-SomeIP 3.2.0 REQUIRED)
find_package(vsomeip3 3.1.0 REQUIRED)

# Paths - 모든 경로를 변수로 관리
set(PRJ_SRC_PATH src)
set(PRJ_SRC_GEN_ROOT /home/leo/SEA-ME/DES_Head-Unit/src-gen)
set(PRJ_SRC_GEN_COMMONAPI_SOMEIP_PATH ${PRJ_SRC_GEN_ROOT}/someip/v0/commonapi/examples)

set(PRJ_NAME_CLIENT ${PRJ_NAME}Client)
set(PRJ_NAME_SERVICE ${PRJ_NAME}Service)

# Generated sources
FILE(GLOB PRJ_PROXY_GEN_SRCS ${PRJ_SRC_GEN_COMMONAPI_SOMEIP_PATH}/*Proxy.cpp)
FILE(GLOB PRJ_STUB_GEN_SRCS ${PRJ_SRC_GEN_COMMONAPI_SOMEIP_PATH}/*Stub*.cpp)
FILE(GLOB PRJ_DEPLOYMENT_SRCS ${PRJ_SRC_GEN_COMMONAPI_SOMEIP_PATH}/*Deployment.cpp)
# If you have your own StubImpl.cpp in src, include it
FILE(GLOB PRJ_STUB_IMPL_SRCS ${PRJ_SRC_PATH}/*StubImpl.cpp)

# Application sources
set(PRJ_CLIENT_SRCS ${PRJ_SRC_PATH}/${PRJ_NAME_CLIENT}.cpp ${PRJ_PROXY_GEN_SRCS} ${PRJ_DEPLOYMENT_SRCS})
set(PRJ_SERVICE_SRCS ${PRJ_SRC_PATH}/${PRJ_NAME_SERVICE}.cpp ${PRJ_STUB_GEN_SRCS} ${PRJ_STUB_IMPL_SRCS} ${PRJ_DEPLOYMENT_SRCS})

# Build Client
add_executable(${PRJ_NAME_CLIENT} ${PRJ_CLIENT_SRCS})

# Client의 include 디렉토리 설정 (모던 CMake 방식)
target_include_directories(${PRJ_NAME_CLIENT}
    PRIVATE
        ${PRJ_SRC_GEN_ROOT}/core
        ${PRJ_SRC_GEN_ROOT}/someip
        ${COMMONAPI_INCLUDE_DIRS}
        ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
        ${VSOMEIP_INCLUDE_DIRS}
)

target_link_libraries(${PRJ_NAME_CLIENT} 
    PRIVATE
        CommonAPI
        CommonAPI-SomeIP 
        vsomeip3
        pthread
)

# Build Service
add_executable(${PRJ_NAME_SERVICE} ${PRJ_SERVICE_SRCS})

# Service의 include 디렉토리 설정 (모던 CMake 방식)
target_include_directories(${PRJ_NAME_SERVICE}
    PRIVATE
        ${PRJ_SRC_GEN_ROOT}/core
        ${PRJ_SRC_GEN_ROOT}/someip
        ${COMMONAPI_INCLUDE_DIRS}
        ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
        ${VSOMEIP_INCLUDE_DIRS}
)

target_link_libraries(${PRJ_NAME_SERVICE} 
    PRIVATE
        CommonAPI
        CommonAPI-SomeIP 
        vsomeip3
        pthread
)

# Build SOME/IP library (optional)
if(PRJ_SOMEIP_LIB_SRCS)
    FILE(GLOB PRJ_SOMEIP_LIB_SRCS ${PRJ_SRC_GEN_COMMONAPI_SOMEIP_PATH}/*cpp)
    add_library(${PRJ_NAME}-someip SHARED ${PRJ_SOMEIP_LIB_SRCS})
    target_link_libraries(${PRJ_NAME}-someip CommonAPI-SomeIP vsomeip3)
endif()
