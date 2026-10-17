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

    signal backRequested()

    // Header
    Item {
        id: header
        anchors.top: parent.top
        anchors.topMargin: DeviceSpecs.hasRoundScreen ? Dims.h(4) : Dims.h(2)
        anchors.left: parent.left
        anchors.right: parent.right
        height: Dims.h(12)

        IconButton {
            anchors.left: parent.left
            anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(4)
            anchors.verticalCenter: parent.verticalCenter
            width: Dims.w(10)
            height: width
            iconName: "ios-arrow-back"
            onClicked: root.backRequested()
        }

        Label {
            anchors.centerIn: parent
            text: "Settings"
            font.pixelSize: Dims.h(4.5)
            font.bold: true
            color: "#e8e2d4"
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(8) : Dims.h(2)
        clip: true
        contentWidth: width
        contentHeight: settingsCol.height + Dims.h(10)

        Column {
            id: settingsCol
            width: parent.width
            spacing: Dims.h(2)

            // Sound Pack Selector
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                height: Dims.h(12)
                radius: Dims.h(2.5)
                color: "#222017"
                border.color: "#4b4739"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Dims.w(4)

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Sound"
                            font.pixelSize: Dims.h(3.6)
                            font.bold: true
                            color: "#e8e2d4"
                        }
                        Text {
                            text: tackEngine.soundPack.toUpperCase()
                            font.pixelSize: Dims.h(2.6)
                            color: "#dac66f"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (tackEngine.soundPack === "wood") {
                            tackEngine.soundPack = "mechanical"
                        } else if (tackEngine.soundPack === "mechanical") {
                            tackEngine.soundPack = "sine"
                        } else if (tackEngine.soundPack === "sine") {
                            tackEngine.soundPack = "hands"
                        } else {
                            tackEngine.soundPack = "wood"
                        }
                        tackEngine.vibrate(20)
                    }
                }
            }

            // Haptic Intensity Selector
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                height: Dims.h(12)
                radius: Dims.h(2.5)
                color: "#222017"
                border.color: "#4b4739"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Dims.w(4)

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Haptics"
                            font.pixelSize: Dims.h(3.6)
                            font.bold: true
                            color: "#e8e2d4"
                        }
                        Text {
                            text: tackEngine.vibrationIntensity.toUpperCase()
                            font.pixelSize: Dims.h(2.6)
                            color: "#dac66f"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (tackEngine.vibrationIntensity === "auto") {
                            tackEngine.vibrationIntensity = "strong"
                        } else if (tackEngine.vibrationIntensity === "strong") {
                            tackEngine.vibrationIntensity = "soft"
                        } else {
                            tackEngine.vibrationIntensity = "auto"
                        }
                        tackEngine.vibrate(35)
                    }
                }
            }

            // Flash Screen Toggle
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                height: Dims.h(12)
                radius: Dims.h(2.5)
                color: "#222017"
                border.color: "#4b4739"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Dims.w(4)

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Flash Screen"
                            font.pixelSize: Dims.h(3.6)
                            font.bold: true
                            color: "#e8e2d4"
                        }
                        Text {
                            text: tackEngine.flashScreen ? "ENABLED" : "DISABLED"
                            font.pixelSize: Dims.h(2.6)
                            color: tackEngine.flashScreen ? "#a9d0b3" : "#969080"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        tackEngine.flashScreen = !tackEngine.flashScreen
                        tackEngine.vibrate(20)
                    }
                }
            }

            // Keep Screen Awake Toggle
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                height: Dims.h(12)
                radius: Dims.h(2.5)
                color: "#222017"
                border.color: "#4b4739"
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: Dims.w(4)

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Keep Awake"
                            font.pixelSize: Dims.h(3.6)
                            font.bold: true
                            color: "#e8e2d4"
                        }
                        Text {
                            text: tackEngine.keepAwake ? "ENABLED" : "DISABLED"
                            font.pixelSize: Dims.h(2.6)
                            color: tackEngine.keepAwake ? "#a9d0b3" : "#969080"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        tackEngine.keepAwake = !tackEngine.keepAwake
                        tackEngine.vibrate(20)
                    }
                }
            }

            // Attribution & About Card
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                height: Dims.h(20)
                radius: Dims.h(2.5)
                color: "#1a1811"
                border.color: "#383428"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width - Dims.w(6)
                    spacing: Dims.h(1)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Ported from Tack Android"
                        font.bold: true
                        font.pixelSize: Dims.h(3)
                        color: "#dac66f"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "github.com/patzly/tack-android"
                        font.pixelSize: Dims.h(2.4)
                        color: "#969080"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Copyright Patrick Zedler (GPL-3.0)"
                        font.pixelSize: Dims.h(2.2)
                        color: "#6b675b"
                    }
                }
            }
        }
    }
}
