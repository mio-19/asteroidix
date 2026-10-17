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

    // Top: Back Button and Title
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
            text: "Tempo"
            font.pixelSize: Dims.h(4.5)
            font.bold: true
            color: "#e8e2d4"
        }
    }

    // Left buttons: -10, -5
    Column {
        anchors.left: parent.left
        anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Dims.h(5)
        spacing: Dims.h(3)

        Rectangle {
            width: Dims.w(13)
            height: Dims.h(9)
            radius: Dims.h(2)
            color: "#2c2a21"
            border.color: "#4b4739"
            Text {
                anchors.centerIn: parent
                text: "-10"
                font.bold: true
                font.pixelSize: Dims.h(3.8)
                color: "#e8e2d4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    tackEngine.changeTempo(-10)
                    tackEngine.vibrate(15)
                }
            }
        }

        Rectangle {
            width: Dims.w(13)
            height: Dims.h(9)
            radius: Dims.h(2)
            color: "#2c2a21"
            border.color: "#4b4739"
            Text {
                anchors.centerIn: parent
                text: "-5"
                font.bold: true
                font.pixelSize: Dims.h(3.8)
                color: "#e8e2d4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    tackEngine.changeTempo(-5)
                    tackEngine.vibrate(15)
                }
            }
        }
    }

    // Center: BPM Display with -1 and +1
    Item {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Dims.h(5)
        width: Dims.w(36)
        height: Dims.h(26)

        Column {
            anchors.centerIn: parent
            spacing: Dims.h(1)

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(2)

                IconButton {
                    width: Dims.w(8)
                    height: width
                    iconName: "ios-remove"
                    onClicked: {
                        tackEngine.changeTempo(-1)
                        tackEngine.vibrate(12)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tackEngine.tempo.toString()
                    font.pixelSize: Dims.h(9)
                    font.bold: true
                    color: "#dac66f"
                }

                IconButton {
                    width: Dims.w(8)
                    height: width
                    iconName: "ios-add"
                    onClicked: {
                        tackEngine.changeTempo(1)
                        tackEngine.vibrate(12)
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BPM"
                font.pixelSize: Dims.h(3)
                color: "#969080"
            }
        }
    }

    // Right buttons: +5, +10
    Column {
        anchors.right: parent.right
        anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Dims.h(5)
        spacing: Dims.h(3)

        Rectangle {
            width: Dims.w(13)
            height: Dims.h(9)
            radius: Dims.h(2)
            color: "#2c2a21"
            border.color: "#4b4739"
            Text {
                anchors.centerIn: parent
                text: "+5"
                font.bold: true
                font.pixelSize: Dims.h(3.8)
                color: "#e8e2d4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    tackEngine.changeTempo(5)
                    tackEngine.vibrate(15)
                }
            }
        }

        Rectangle {
            width: Dims.w(13)
            height: Dims.h(9)
            radius: Dims.h(2)
            color: "#2c2a21"
            border.color: "#4b4739"
            Text {
                anchors.centerIn: parent
                text: "+10"
                font.bold: true
                font.pixelSize: Dims.h(3.8)
                color: "#e8e2d4"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    tackEngine.changeTempo(10)
                    tackEngine.vibrate(15)
                }
            }
        }
    }

    // Bottom: Tap Tempo Pad
    Rectangle {
        id: tapPad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(5) : Dims.h(2)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Dims.w(56)
        height: Dims.h(13)
        radius: Dims.h(3.5)
        color: tapArea.pressed ? "#534600" : "#2b4e38"
        border.color: tapArea.pressed ? "#dac66f" : "#a9d0b3"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: Dims.w(2)

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(6)
                height: width
                name: "ios-finger-print"
                color: "#c4eccf"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "TAP TEMPO"
                font.bold: true
                font.pixelSize: Dims.h(3.8)
                color: "#c4eccf"
            }
        }

        MouseArea {
            id: tapArea
            anchors.fill: parent
            onPressed: {
                tackEngine.tapTempo()
                tackEngine.vibrate(25)
            }
        }
    }
}
