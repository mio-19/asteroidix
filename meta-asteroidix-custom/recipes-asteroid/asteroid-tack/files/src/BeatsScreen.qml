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
            text: "Beats & Rhythm"
            font.pixelSize: Dims.h(4.2)
            font.bold: true
            color: "#e8e2d4"
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(6) : Dims.h(2)
        clip: true
        contentWidth: width
        contentHeight: contentCol.height + Dims.h(6)

        Column {
            id: contentCol
            width: parent.width
            spacing: Dims.h(3)

            // Section 1: Beats Count Selector
            Item {
                width: parent.width
                height: Dims.h(14)

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.w(4)

                    IconButton {
                        width: Dims.w(9)
                        height: width
                        iconName: "ios-remove"
                        onClicked: {
                            tackEngine.setBeatsCount(tackEngine.beatsCount - 1)
                            tackEngine.vibrate(15)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tackEngine.beatsCount + " BEATS"
                            font.bold: true
                            font.pixelSize: Dims.h(4.5)
                            color: "#dac66f"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "per measure"
                            font.pixelSize: Dims.h(2.8)
                            color: "#969080"
                        }
                    }

                    IconButton {
                        width: Dims.w(9)
                        height: width
                        iconName: "ios-add"
                        onClicked: {
                            tackEngine.setBeatsCount(tackEngine.beatsCount + 1)
                            tackEngine.vibrate(15)
                        }
                    }
                }
            }

            // Section 2: Beat Accents Grid/Row
            Item {
                width: parent.width
                height: Dims.h(16)

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(4)
                    clip: true
                    contentWidth: accentsRow.width
                    contentHeight: height

                    Row {
                        id: accentsRow
                        spacing: Dims.w(2.5)
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: tackEngine.beatsCount
                            delegate: Rectangle {
                                property int beatIdx: index
                                property int accentType: (index < tackEngine.beatAccents.length) ? tackEngine.beatAccents[index] : 2

                                width: Dims.w(13)
                                height: Dims.h(13)
                                radius: Dims.h(2)

                                color: {
                                    if (accentType === 1) return "#713619" // Strong
                                    if (accentType === 2) return "#4d472a" // Normal
                                    if (accentType === 3) return "#2c2a21" // Sub
                                    return "#1a1a1a"                       // Mute
                                }

                                border.color: {
                                    if (accentType === 1) return "#ffb595"
                                    if (accentType === 2) return "#dac66f"
                                    return "#4b4739"
                                }
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: (index + 1).toString()
                                        font.bold: true
                                        font.pixelSize: Dims.h(3.8)
                                        color: "#e8e2d4"
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: {
                                            if (accentType === 1) return "STRONG"
                                            if (accentType === 2) return "NORM"
                                            if (accentType === 3) return "SUB"
                                            return "MUTE"
                                        }
                                        font.pixelSize: Dims.h(2.2)
                                        color: (accentType === 1) ? "#ffb595" : "#969080"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        tackEngine.cycleBeatAccent(beatIdx)
                                        tackEngine.vibrate(20)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Section 3: Subdivisions Selector
            Item {
                width: parent.width
                height: Dims.h(14)

                Column {
                    anchors.centerIn: parent
                    spacing: Dims.h(1)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Subdivisions"
                        font.pixelSize: Dims.h(3)
                        color: "#969080"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Dims.w(3)

                        Repeater {
                            model: [1, 2, 3, 4]
                            delegate: Rectangle {
                                property int subCount: modelData
                                property bool isSelected: tackEngine.subdivisionsCount === subCount

                                width: Dims.w(12)
                                height: Dims.h(8)
                                radius: Dims.h(1.5)
                                color: isSelected ? "#dac66f" : "#2c2a21"
                                border.color: isSelected ? "#dac66f" : "#4b4739"

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (subCount === 1) return "1/4"
                                        if (subCount === 2) return "1/8"
                                        if (subCount === 3) return "1/12"
                                        return "1/16"
                                    }
                                    font.bold: isSelected
                                    font.pixelSize: Dims.h(3)
                                    color: isSelected ? "#393000" : "#e8e2d4"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        tackEngine.setSubdivisionsCount(subCount)
                                        tackEngine.vibrate(15)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
