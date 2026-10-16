add_library(${CMAKE_PROJECT_NAME}
    main.cpp
    spo2controller.cpp
)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES PREFIX "")

asteroid_app_qml_module(${CMAKE_PROJECT_NAME}
    main.qml
    OxygenMeter.qml
)

target_link_libraries(
    ${CMAKE_PROJECT_NAME}
    PUBLIC
    Asteroid::AsteroidApp6
    Qt6::DBus
    Qt6::Quick
    Qt6::Sensors
)

install(
    TARGETS ${CMAKE_PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
