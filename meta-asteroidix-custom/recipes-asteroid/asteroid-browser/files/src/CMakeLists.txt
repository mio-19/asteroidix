add_library(${CMAKE_PROJECT_NAME}
    main.cpp
    browsercontroller.cpp
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
    Qt6::Network
)

install(
    TARGETS ${CMAKE_PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
