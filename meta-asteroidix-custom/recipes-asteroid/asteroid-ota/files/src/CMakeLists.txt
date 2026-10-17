# GUI Application Library (invoked by runscript)
add_library(${CMAKE_PROJECT_NAME}
    main.cpp
    otaclient.cpp
)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES PREFIX "")

asteroid_app_qml_module(${CMAKE_PROJECT_NAME}
    main.qml
)

target_link_libraries(
    ${CMAKE_PROJECT_NAME}
    PUBLIC
    Asteroid::AsteroidApp6
    Qt6::Quick
    Qt6::DBus
)

install(
    TARGETS ${CMAKE_PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# System D-Bus Daemon (runs as root under systemd)
add_executable(asteroid-otad
    otadaemon_main.cpp
    otadaemon.cpp
)

target_link_libraries(
    asteroid-otad
    PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Network
)

install(
    TARGETS asteroid-otad
    DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}
)
