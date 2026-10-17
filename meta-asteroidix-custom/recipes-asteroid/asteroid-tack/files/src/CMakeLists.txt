add_library(${CMAKE_PROJECT_NAME}
    main.cpp
    tackengine.cpp
    tempotap.cpp
)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES PREFIX "")

asteroid_app_qml_module(${CMAKE_PROJECT_NAME}
    main.qml
    MainScreen.qml
    BeatsScreen.qml
    TempoScreen.qml
    SettingsScreen.qml
    BookmarksScreen.qml
)

target_link_libraries(
    ${CMAKE_PROJECT_NAME}
    PUBLIC
    Asteroid::AsteroidApp6
    Qt6::DBus
    Qt6::Quick
)

install(
    TARGETS ${CMAKE_PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
