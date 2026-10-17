cmake_minimum_required(VERSION 3.16)
project(qtvirtualkeyboard_librime LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick VirtualKeyboard)
find_package(PkgConfig REQUIRED)
pkg_check_modules(RIME REQUIRED rime)

add_library(qtvirtualkeyboard_librime MODULE
    qtvirtualkeyboard_librime_plugin.h
    qtvirtualkeyboard_librime_plugin.cpp
    rimeinputmethod.h
    rimeinputmethod.cpp
)

target_include_directories(qtvirtualkeyboard_librime PRIVATE
    ${RIME_INCLUDE_DIRS}
)

target_link_libraries(qtvirtualkeyboard_librime PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::VirtualKeyboard
    ${RIME_LIBRARIES}
)

if(NOT DEFINED QT6_INSTALL_PLUGINS)
    if(DEFINED QT_PLUGINS_DIR)
        set(QT6_INSTALL_PLUGINS "${QT_PLUGINS_DIR}")
    else()
        set(QT6_INSTALL_PLUGINS "lib/qt6/plugins")
    endif()
endif()

install(TARGETS qtvirtualkeyboard_librime
    DESTINATION ${QT6_INSTALL_PLUGINS}/virtualkeyboard
)
