cmake_minimum_required(VERSION 3.20)

project(
    asteroid-tack
    VERSION 1.0.0
    DESCRIPTION "AsteroidOS Metronome ported from Tack Android (https://github.com/patzly/tack-android)"
)

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp6 REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS DBus Quick)

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

# Install audio sound assets
install(
    DIRECTORY sounds/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/sounds/tack
    FILES_MATCHING PATTERN "*.wav"
)

# Install ngfd event mappings
install(
    DIRECTORY events.d/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/ngfd/events.d
    FILES_MATCHING PATTERN "*.ini"
)

generate_desktop(${CMAKE_SOURCE_DIR} ${CMAKE_PROJECT_NAME})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
