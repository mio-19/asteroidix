/*
 * Copyright (C) 2016 - Florent Revest <revestflo@gmail.com>
 *               2020 - MagneFire
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import Nemo.Configuration

Item {
    id: main
    anchors.fill: parent

    ConfigurationValue {
        id: bestScoreConf
        key: "/org/asteroidos/2048/bestScore"
        defaultValue: 0
    }

    Item {
        id: logic

        property int score: 0
        property alias bestScore: bestScoreConf.value

        property int rows: 4
        property int cols: 4

        // The game field matrix
        property var cells: []

        // Empty grid indices for spawn tracking
        property var emptyGridCells: []

        function movePossible() {
            for (var x = 0; x < rows; x++) {
                for (var y = 0; y < cols - 1; y++) {
                    if (cells[x][y] === cells[x][y + 1])
                        return true
                }
            }
            for (var x = 0; x < rows - 1; x++) {
                for (var y = 0; y < cols; y++) {
                    if (cells[x][y] === cells[x + 1][y])
                        return true
                }
            }
            return false
        }

        function moveCell(x1, y1, x2, y2) {
            var cell1 = cells[x1][y1]
            var cell2 = cells[x2][y2]

            // Cannot move onto an existing cell with a different value
            if ((cell1 !== 0 && cell2 !== 0) && cell1 !== cell2)
                return false

            // Move to empty spot or combine with same value
            if ((cell1 !== 0 && cell1 === cell2) || (cell1 !== 0 && cell2 === 0)) {
                cells[x1][y1] = 0

                for (var i = 0; i < logic.rows * logic.cols; i++) {
                    var item = cellsGrid.itemAt(i)
                    if (!item || item.x1 === -1 || item.y1 === -1) continue
                    if (item.x1 === x1 && item.y1 === y1) {
                        item.x1 = x2
                        item.y1 = y2
                        animationTimer.start()
                        break
                    }
                }
            }

            // Combine matching cells
            if (cell1 !== 0 && cell1 === cell2) {
                cells[x2][y2] *= 2
                score += cells[x2][y2]
                if (score > bestScore) {
                    bestScore = score
                }

                for (var j = 0; j < logic.rows * logic.cols; j++) {
                    var itm = cellsGrid.itemAt(j)
                    if (!itm || itm.x1 === -1 || itm.y1 === -1) continue
                    if (itm.x1 === x2 && itm.y1 === y2) {
                        itm.val = cells[x2][y2]
                        itm.pop = true
                    }
                }
                return false
            }

            // Cell moves to empty position
            if (cell1 !== 0 && cell2 === 0) {
                cells[x2][y2] = cell1
                return true
            }
            return true
        }

        function move(gesture) {
            if (animationTimer.running) return

            if (gesture === "left" || gesture === "up") {
                for (var x = 0; x < rows; x++) {
                    for (var y = 0; y < cols; y++) {
                        for (var j = y + 1; j < rows; j++) {
                            if (gesture === "left") {
                                if (!moveCell(j, x, y, x))
                                    break
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break
                            }
                        }
                    }
                }
            }

            if (gesture === "right" || gesture === "down") {
                for (var x = 0; x < rows; x++) {
                    for (var y = cols - 1; y >= 0; y--) {
                        for (var j = y - 1; j >= 0; j--) {
                            if (gesture === "right") {
                                if (!moveCell(j, x, y, x))
                                    break
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break
                            }
                        }
                    }
                }
            }
        }

        function randCell() {
            var emptyCells = []
            for (var x = 0; x < rows; x++) {
                for (var y = 0; y < cols; y++) {
                    if (cells[x][y] === 0) {
                        emptyCells.push([x, y])
                    }
                }
            }
            if (!emptyCells.length) return

            var emptyCell = emptyCells[Math.floor(Math.random() * emptyCells.length)]
            var cx = emptyCell[0]
            var cy = emptyCell[1]
            cells[cx][cy] = (Math.random() < 0.9) ? 2 : 4

            if (emptyGridCells.length > 0) {
                var emptyGrid = emptyGridCells.shift()
                var gridItem = cellsGrid.itemAt(emptyGrid)
                if (gridItem) {
                    gridItem.animateMove = false
                    gridItem.val = cells[cx][cy]
                    gridItem.x1 = cx
                    gridItem.y1 = cy
                    gridItem.animateMove = true
                }
            }

            if ((emptyCells.length <= 1) && !movePossible()) {
                console.log("2048: No more valid moves! Game over.")
                bestScore = Math.max(bestScore, score)
                gameOver.visible = true
            }
        }

        function removeDuplicateGridCells() {
            for (var i = 0; i < rows * cols; i++) {
                var itmI = cellsGrid.itemAt(i)
                if (!itmI || itmI.x1 === -1 || itmI.y1 === -1) continue

                for (var j = i + 1; j < rows * cols; j++) {
                    var itmJ = cellsGrid.itemAt(j)
                    if (!itmJ || itmJ.x1 === -1 || itmJ.y1 === -1) continue
                    if (itmI.x1 === itmJ.x1 && itmI.y1 === itmJ.y1) {
                        itmJ.animateMove = false
                        itmJ.val = 0
                        itmJ.x1 = -1
                        itmJ.y1 = -1
                        emptyGridCells.push(j)
                    }
                }
            }
        }

        function reset() {
            gameOver.visible = false
            cells = []
            for (var i = 0; i < rows; i++) {
                cells[i] = []
                for (var j = 0; j < cols; j++) {
                    cells[i][j] = 0
                }
            }
            score = 0
            emptyGridCells = []
            for (var k = 0; k < rows * cols; k++) {
                emptyGridCells.push(k)
                var itm = cellsGrid.itemAt(k)
                if (itm) {
                    itm.x1 = -1
                    itm.y1 = -1
                    itm.val = 0
                }
            }
            randCell()
            randCell()
        }

        Timer {
            id: animationTimer
            interval: 200
            repeat: false
            onTriggered: {
                logic.removeDuplicateGridCells()
                logic.randCell()
            }
        }
    }

    Item {
        id: scoreBoard
        anchors.fill: parent

        // Top Score Header Pill
        Rectangle {
            x: (parent.width - width) / 2
            y: parent.height * 0.02
            width: parent.width * 0.35
            height: parent.height * 0.12
            radius: 4
            color: "#bbada0"

            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.1
                width: parent.width
                color: "#eee4da"
                text: "SCORE"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.1
                width: parent.width
                color: "#ffffff"
                text: logic.score
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
            }
        }

        // Bottom Best Score Footer Pill
        Rectangle {
            x: (parent.width - width) / 2
            y: parent.height * 0.86
            width: parent.width * 0.35
            height: parent.height * 0.12
            radius: 4
            color: "#bbada0"

            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.1
                width: parent.width
                color: "#ffffff"
                text: logic.bestScore
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.1
                width: parent.width
                color: "#eee4da"
                text: "BEST"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11
            }
        }
    }

    Rectangle {
        id: board
        // Inscribed square calculation fits both circular and rectangular smartwatch screens
        property int fieldWidth: Math.floor(Math.sqrt(Math.pow(parent.width, 2) / 2))
        property int fieldHeight: Math.floor(Math.sqrt(Math.pow(parent.height, 2) / 2))
        property int fieldMarginWidth: Math.max(0, Math.floor((parent.width - fieldWidth) / 2))
        property int fieldMarginHeight: Math.max(0, Math.floor((parent.height - fieldHeight) / 2))

        anchors {
            right: parent.right
            left: parent.left
            bottom: parent.bottom
            top: parent.top
            leftMargin: fieldMarginWidth
            rightMargin: fieldMarginWidth
            topMargin: fieldMarginHeight
            bottomMargin: fieldMarginHeight
        }
        color: "#bbada0"
        radius: 6

        Grid {
            id: grid
            anchors.fill: parent
            anchors.margins: 4
            columns: 4
            rows: 4

            Repeater {
                model: grid.columns * grid.rows

                Rectangle {
                    width: grid.width / grid.columns
                    height: grid.height / grid.rows
                    color: "transparent"

                    Rectangle {
                        radius: 4
                        anchors.fill: parent
                        anchors.margins: 3
                        color: "#60eee4da"
                    }
                }
            }
        }

        Repeater {
            id: cellsGrid
            model: grid.columns * grid.rows

            Rectangle {
                property bool animateMove: true
                property int x1: -1
                property int y1: -1
                property int val: 0
                property bool pop: false
                width: (grid.width / grid.columns) - 6
                height: (grid.height / grid.rows) - 6
                x: 4 + 3 + x1 * (grid.width / grid.columns)
                y: 4 + 3 + y1 * (grid.height / grid.rows)
                color: val === 2    ? "#eee4da" :
                       val === 4    ? "#ede0c8" :
                       val === 8    ? "#f2b179" :
                       val === 16   ? "#f59563" :
                       val === 32   ? "#f67c5f" :
                       val === 64   ? "#f65e3b" :
                       val === 128  ? "#edcf72" :
                       val === 256  ? "#edcc61" :
                       val === 512  ? "#edc850" :
                       val === 1024 ? "#edc53f" :
                                      "#edc22e"
                scale: val ? (pop ? 1.15 : 1.0) : 0.0
                radius: 4
                visible: (x1 !== -1 && y1 !== -1)
                onScaleChanged: if (scale >= 1.15) pop = false

                Behavior on x { enabled: animateMove; NumberAnimation { duration: 100 } }
                Behavior on y { enabled: animateMove; NumberAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.fill: parent
                    color: val <= 4 ? "#776e65" : "#f9f6f2"
                    text: parent.val ? parent.val : ""
                    scale: parent.scale
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: val <= 9    ? height * 0.55 :
                                    val <= 99   ? height * 0.48 :
                                    val <= 999  ? height * 0.38 :
                                                  height * 0.30
                }
            }
        }
    }

    MouseArea {
        width: board.width
        height: board.height
        anchors.centerIn: board

        property int threshold: Math.max(15, Math.floor(width * 0.08))
        property string gesture: ""
        property int initialX: 0
        property int initialY: 0
        property int deltaX: 0
        property int deltaY: 0

        onPressed: (mouse) => {
            gesture = ""
            initialX = mouse.x
            initialY = mouse.y
            deltaX = 0
            deltaY = 0
        }

        onPositionChanged: (mouse) => {
            deltaX = mouse.x - initialX
            deltaY = mouse.y - initialY
        }

        onReleased: (mouse) => {
            deltaX = mouse.x - initialX
            deltaY = mouse.y - initialY
            var absX = Math.abs(deltaX)
            var absY = Math.abs(deltaY)

            if (absX < threshold && absY < threshold) return

            if (absX > absY) {
                gesture = (deltaX > 0) ? "right" : "left"
            } else {
                gesture = (deltaY > 0) ? "down" : "up"
            }

            if (gesture !== "") {
                logic.move(gesture)
            }
        }
    }

    Item {
        focus: true
        Keys.onPressed: (event) => {
            event.accepted = true
            if (event.key === Qt.Key_Right) {
                logic.move("right")
            } else if (event.key === Qt.Key_Left) {
                logic.move("left")
            } else if (event.key === Qt.Key_Down) {
                logic.move("down")
            } else if (event.key === Qt.Key_Up) {
                logic.move("up")
            }
        }
    }

    Rectangle {
        id: gameOver
        anchors.fill: parent
        visible: false
        opacity: visible ? 0.92 : 0.0
        color: "#ede0c8"
        z: 100

        Behavior on opacity { NumberAnimation { duration: 250 } }

        Text {
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.28
            width: parent.width
            color: "#776e65"
            text: "Game Over"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Math.floor(parent.height * 0.09)
        }

        Rectangle {
            color: "#8f7a66"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.height * 0.12
            width: parent.width * 0.44
            height: parent.height * 0.15
            radius: 5

            Text {
                anchors.centerIn: parent
                color: "#f9f6f2"
                text: "Try Again"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Math.floor(parent.height * 0.38)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: logic.reset()
            }
        }
    }

    Component.onCompleted: {
        logic.reset()
    }
}
