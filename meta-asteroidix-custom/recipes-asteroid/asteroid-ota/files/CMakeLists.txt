cmake_minimum_required(VERSION 3.20)

project(
    asteroid-ota
    VERSION 1.0.0
    DESCRIPTION "AsteroidOS OTA System Update Application"
)

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp6 REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Core Quick DBus Network)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(Asteroid6CMakeSettings)
include(Asteroid6Translations)

add_subdirectory(src)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/runscript.in
    ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}
    @ONLY
)

install(
    PROGRAMS ${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/org.asteroidos.OTA1.conf
    DESTINATION ${CMAKE_INSTALL_DATADIR}/dbus-1/system.d
)

if(NOT DEFINED SYSTEMD_SYSTEM_UNITDIR)
    set(SYSTEMD_SYSTEM_UNITDIR "/lib/systemd/system")
endif()

install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/asteroid-otad.service
    DESTINATION ${SYSTEMD_SYSTEM_UNITDIR}
)

generate_desktop(${CMAKE_SOURCE_DIR} ${CMAKE_PROJECT_NAME})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
