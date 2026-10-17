/*
 * This file is part of Asteroid Tack (ported from Tack Android).
 * Upstream: https://github.com/patzly/tack-android
 *
 * Copyright (c) 2020-2026 by Patrick Zedler
 * Qt/AsteroidOS port Copyright (c) 2026 AsteroidOS & Asteroidix Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: "#2c2600"
    outerColor: "#110e00"

    preventBlanking: tackEngine.playing && tackEngine.keepAwake

    // Non-Graphical Feedback Daemon bindings for sound and haptics
    NonGraphicalFeedback {
        id: soundTickStrong
        event: "tack-tick-strong"
    }

    NonGraphicalFeedback {
        id: soundTickNormal
        event: "tack-tick-normal"
    }

    NonGraphicalFeedback {
        id: soundTickSub
        event: "tack-tick-sub"
    }

    NonGraphicalFeedback {
        id: hapticClick
        event: "press"
    }

    Connections {
        target: tackEngine
        function onTick(beat, subdivision, tickType) {
            if (tackEngine.beatMode === "both" || tackEngine.beatMode === "sound") {
                if (tickType === 1) {
                    soundTickStrong.play()
                } else if (tickType === 2) {
                    soundTickNormal.play()
                } else if (tickType === 3) {
                    soundTickSub.play()
                }
            }
        }
    }

    property string currentScreen: "main"

    Item {
        anchors.fill: parent

        MainScreen {
            id: mainView
            anchors.fill: parent
            visible: app.currentScreen === "main"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onOpenScreen: function(screenName) {
                app.currentScreen = screenName
            }
        }

        TempoScreen {
            id: tempoView
            anchors.fill: parent
            visible: app.currentScreen === "tempo"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onBackRequested: {
                app.currentScreen = "main"
            }
        }

        BeatsScreen {
            id: beatsView
            anchors.fill: parent
            visible: app.currentScreen === "beats"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onBackRequested: {
                app.currentScreen = "main"
            }
        }

        SettingsScreen {
            id: settingsView
            anchors.fill: parent
            visible: app.currentScreen === "settings"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onBackRequested: {
                app.currentScreen = "main"
            }
        }

        BookmarksScreen {
            id: bookmarksView
            anchors.fill: parent
            visible: app.currentScreen === "bookmarks"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onBackRequested: {
                app.currentScreen = "main"
            }
        }
    }
}
