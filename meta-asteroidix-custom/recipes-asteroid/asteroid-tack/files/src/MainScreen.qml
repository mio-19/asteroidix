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

Item {
    id: root
    anchors.fill: parent

    signal openScreen(string screenName)

    // Flash background effect on beat
    Rectangle {
        id: beatFlashOverlay
        anchors.fill: parent
        color: tackEngine.isStrongBeat ? "#713619" : "#534600"
        opacity: 0.0
        z: 0

        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: beatFlashOverlay; property: "opacity"; to: 0.45; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: beatFlashOverlay; property: "opacity"; to: 0.0; duration: 160; easing.type: Easing.InQuad }
        }

        Connections {
            target: tackEngine
            function onBeatPulse(strong) {
                if (tackEngine.flashScreen && tackEngine.playing) {
                    flashAnim.restart()
                }
            }
        }
    }

    // Top: Settings button
    IconButton {
        id: settingsBtn
        anchors.top: parent.top
        anchors.topMargin: DeviceSpecs.hasRoundScreen ? Dims.h(4) : Dims.h(2)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Dims.w(11)
        height: width
        iconName: "ios-settings"
        z: 2
        onClicked: root.openScreen("settings")
    }

    // Left-top: Beats configuration button
    IconButton {
        id: beatsBtn
        anchors.left: parent.left
        anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
        anchors.top: parent.top
        anchors.topMargin: Dims.h(22)
        width: Dims.w(12)
        height: width
        iconName: "ios-musical-notes"
        z: 2
        onClicked: root.openScreen("beats")
    }

    // Left-bottom: Tap tempo button
    IconButton {
        id: tapBtn
        anchors.left: parent.left
        anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(22)
        width: Dims.w(12)
        height: width
        iconName: "ios-finger-print"
        z: 2
        onClicked: {
            tackEngine.tapTempo()
            tackEngine.vibrate(20)
        }
    }

    // Right-top: Bookmarks button
    IconButton {
        id: bookmarksBtn
        anchors.right: parent.right
        anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
        anchors.top: parent.top
        anchors.topMargin: Dims.h(22)
        width: Dims.w(12)
        height: width
        iconName: "ios-bookmarks"
        z: 2
        onClicked: root.openScreen("bookmarks")
    }

    // Right-bottom: Beat Mode toggle (both -> vibrate -> sound)
    IconButton {
        id: modeBtn
        anchors.right: parent.right
        anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(3)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(22)
        width: Dims.w(12)
        height: width
        iconName: {
            if (tackEngine.beatMode === "vibrate") return "ios-volume-mute"
            if (tackEngine.beatMode === "sound")   return "ios-volume-high"
            return "ios-pulse"
        }
        z: 2
        onClicked: {
            if (tackEngine.beatMode === "both") {
                tackEngine.beatMode = "vibrate"
            } else if (tackEngine.beatMode === "vibrate") {
                tackEngine.beatMode = "sound"
            } else {
                tackEngine.beatMode = "both"
            }
            tackEngine.vibrate(25)
        }
    }

    // Center: Tempo Display Card
    Item {
        id: tempoCard
        anchors.centerIn: parent
        width: Dims.w(44)
        height: Dims.h(28)
        z: 2

        Rectangle {
            anchors.fill: parent
            radius: Dims.h(4)
            color: tackEngine.playing ? "#2c2600" : "#222017"
            border.color: tackEngine.playing ? "#dac66f" : "#4b4739"
            border.width: 2

            MouseArea {
                anchors.fill: parent
                onClicked: root.openScreen("tempo")
            }

            Column {
                anchors.centerIn: parent
                spacing: -Dims.h(1)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tackEngine.tempo.toString()
                    font.pixelSize: Dims.h(12)
                    font.bold: true
                    color: tackEngine.playing ? "#dac66f" : "#e8e2d4"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "BPM"
                    font.pixelSize: Dims.h(3.2)
                    font.bold: true
                    color: "#969080"
                }
            }
        }
    }

    // Beats dots row below Tempo Card
    Row {
        id: beatsRow
        anchors.top: tempoCard.bottom
        anchors.topMargin: Dims.h(2)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Dims.w(1.8)
        z: 2

        Repeater {
            model: Math.min(tackEngine.beatsCount, 12)
            delegate: Rectangle {
                id: dot
                property int beatIndex: index + 1
                property bool isCurrent: tackEngine.playing && (tackEngine.currentBeat === beatIndex)
                property int accent: (beatIndex <= tackEngine.beatAccents.length) ? tackEngine.beatAccents[index] : 2

                width: isCurrent ? Dims.w(3.2) : Dims.w(2.4)
                height: width
                radius: width / 2

                color: {
                    if (isCurrent) {
                        return (accent === 1) ? "#ffb595" : "#dac66f"
                    }
                    if (accent === 1) return "#beab57"
                    if (accent === 4) return "#333333"
                    return "#555246"
                }

                border.color: (accent === 1) ? "#ffb595" : "transparent"
                border.width: (accent === 1 && !isCurrent) ? 1 : 0

                scale: isCurrent ? 1.3 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 80 } }
            }
        }
    }

    // Bottom: Play / Pause Button
    IconButton {
        id: playBtn
        anchors.bottom: parent.bottom
        anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(5) : Dims.h(2)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Dims.w(16)
        height: width
        iconName: tackEngine.playing ? "ios-square" : "ios-play"
        z: 2
        onClicked: {
            tackEngine.togglePlaying()
            tackEngine.vibrate(35)
        }
    }
}
