cmake_minimum_required(VERSION 3.10)
project(LayoutManagerApp)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt5
find_package(Qt5 COMPONENTS Core Gui Qml Quick REQUIRED)

# Source files
set(SOURCES
    src/main.cpp
)

# Qt Resource file
set(RESOURCES
    qml.qrc
)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${RESOURCES})

# Link Qt libraries
target_link_libraries(${PROJECT_NAME}
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
)

# Install
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
