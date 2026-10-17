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
            text: "Presets"
            font.pixelSize: Dims.h(4.5)
            font.bold: true
            color: "#e8e2d4"
        }

        IconButton {
            anchors.right: parent.right
            anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(4)
            anchors.verticalCenter: parent.verticalCenter
            width: Dims.w(10)
            height: width
            iconName: "ios-add"
            onClicked: {
                tackEngine.addBookmark()
                tackEngine.vibrate(25)
            }
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
        contentHeight: presetsCol.height + Dims.h(8)

        Column {
            id: presetsCol
            width: parent.width
            spacing: Dims.h(2)

            Repeater {
                model: tackEngine.bookmarks
                delegate: Item {
                    id: bmItem
                    property int itemIndex: index
                    property var bm: modelData

                    width: parent.width
                    height: Dims.h(12)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: DeviceSpecs.hasRoundScreen ? Dims.w(76) : Dims.w(86)
                        height: parent.height
                        radius: Dims.h(2.5)
                        color: "#222017"
                        border.color: (tackEngine.tempo === bm.tempo && tackEngine.beatsCount === bm.beats) ? "#dac66f" : "#4b4739"
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Dims.w(5)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Dims.w(3)

                            Text {
                                text: bm.tempo.toString()
                                font.bold: true
                                font.pixelSize: Dims.h(4.8)
                                color: (tackEngine.tempo === bm.tempo && tackEngine.beatsCount === bm.beats) ? "#dac66f" : "#e8e2d4"
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Dims.h(0.5)
                                text: "BPM · " + bm.beats + "/4"
                                font.pixelSize: Dims.h(3)
                                color: "#969080"
                            }
                        }

                        IconButton {
                            anchors.right: parent.right
                            anchors.rightMargin: Dims.w(3)
                            anchors.verticalCenter: parent.verticalCenter
                            width: Dims.w(8)
                            height: width
                            iconName: "ios-trash"
                            onClicked: {
                                tackEngine.deleteBookmark(itemIndex)
                                tackEngine.vibrate(20)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: Dims.w(12)
                            onClicked: {
                                tackEngine.applyBookmark(itemIndex)
                                tackEngine.vibrate(30)
                                root.backRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}
