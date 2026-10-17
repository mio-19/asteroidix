import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: otaClient.state === "upgrading" ? "#143a68" :
                 (otaClient.state === "reboot_required" ? "#1e5c32" :
                 (otaClient.state === "error" ? "#661f1f" : "#1b4d89"))
    outerColor: "#0a1e38"

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: Math.max(parent.height, contentColumn.implicitHeight + (DeviceSpecs.hasRoundScreen ? Dims.h(12) : Dims.h(6)))
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: contentColumn
            width: parent.width
            spacing: Dims.h(2)

            Item {
                width: parent.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(7) : Dims.h(3)
            }

            // Header Icon
            Item {
                width: parent.width
                height: Dims.h(18)

                Rectangle {
                    anchors.centerIn: parent
                    width: Dims.w(16)
                    height: width
                    radius: width / 2
                    color: "white"
                    opacity: 0.15
                }

                Icon {
                    id: statusIcon
                    anchors.centerIn: parent
                    width: Dims.w(12)
                    height: width
                    name: {
                        switch (otaClient.state) {
                        case "checking":
                        case "upgrading":
                            return "ios-sync"
                        case "available":
                            return "ios-cloud-download"
                        case "up_to_date":
                        case "reboot_required":
                            return "ios-checkmark-circle"
                        case "error":
                            return "ios-alert"
                        default:
                            return "ios-sync"
                        }
                    }

                    RotationAnimation on rotation {
                        running: otaClient.state === "checking" || otaClient.state === "upgrading"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1800
                    }
                }
            }

            // Title
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.85
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Dims.h(5)
                font.bold: true
                wrapMode: Text.WordWrap
                text: {
                    switch (otaClient.state) {
                    case "checking":
                        return "Checking Updates"
                    case "up_to_date":
                        return "Up to Date"
                    case "available":
                        return otaClient.upgradableCount + " Updates Ready"
                    case "upgrading":
                        return "Upgrading " + otaClient.progress + "%"
                    case "reboot_required":
                        return "Upgrade Complete!"
                    case "error":
                        return "Update Paused"
                    default:
                        return "AsteroidOS OTA"
                    }
                }
            }

            // Subtitle / Status message
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Dims.h(3.6)
                opacity: 0.85
                wrapMode: Text.WordWrap
                text: otaClient.statusMessage
            }

            // Current step details (during upgrade)
            Label {
                visible: otaClient.state === "upgrading" && otaClient.currentStep !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Dims.h(3.2)
                opacity: 0.7
                elide: Text.ElideMiddle
                text: otaClient.currentStep
            }

            // Progress Bar (during upgrade or checking)
            Item {
                visible: otaClient.state === "upgrading" || otaClient.state === "checking"
                width: parent.width
                height: Dims.h(4)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: Dims.h(1.8)
                    radius: height / 2
                    color: "white"
                    opacity: 0.2

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (otaClient.progress / 100.0)
                        radius: height / 2
                        color: "#2196F3"
                        Behavior on width {
                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }

            // Status badges: Network & Battery
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(3)
                visible: otaClient.state === "idle" || otaClient.state === "available" || otaClient.state === "error"

                Rectangle {
                    height: Dims.h(5)
                    width: netRow.implicitWidth + Dims.w(4)
                    radius: height / 2
                    color: "white"
                    opacity: 0.15

                    Row {
                        id: netRow
                        anchors.centerIn: parent
                        spacing: Dims.w(1.5)
                        Icon {
                            width: Dims.w(4)
                            height: width
                            name: otaClient.networkAvailable ? "ios-wifi" : "ios-close-circle"
                        }
                        Label {
                            font.pixelSize: Dims.h(3)
                            text: otaClient.networkType
                        }
                    }
                }

                Rectangle {
                    height: Dims.h(5)
                    width: batRow.implicitWidth + Dims.w(4)
                    radius: height / 2
                    color: "white"
                    opacity: 0.15

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: Dims.w(1.5)
                        Icon {
                            width: Dims.w(4)
                            height: width
                            name: otaClient.isCharging ? "ios-battery-charging" : "ios-battery-full"
                        }
                        Label {
                            font.pixelSize: Dims.h(3)
                            text: otaClient.batteryLevel + "%"
                        }
                    }
                }
            }

            // Zero Data Loss note
            Item {
                width: parent.width
                height: Dims.h(8)
                visible: otaClient.state === "idle" || otaClient.state === "available"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: parent.height
                    radius: Dims.h(2)
                    color: "black"
                    opacity: 0.25

                    Label {
                        anchors.centerIn: parent
                        width: parent.width * 0.92
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Dims.h(2.8)
                        opacity: 0.9
                        wrapMode: Text.WordWrap
                        text: "Personal data, pairings, alarms & watchfaces are preserved."
                    }
                }
            }

            // Main Action Button
            Item {
                width: parent.width
                height: Dims.h(12)

                Button {
                    id: actionBtn
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: Dims.h(8)

                    visible: otaClient.state !== "upgrading" && otaClient.state !== "checking"

                    text: {
                        switch (otaClient.state) {
                        case "available":
                            return "Install Update"
                        case "up_to_date":
                            return "Check Again"
                        case "reboot_required":
                            return "Reboot Now"
                        case "error":
                            return "Retry"
                        default:
                            return "Check for Updates"
                        }
                    }

                    onClicked: {
                        if (otaClient.state === "available") {
                            remorse.action = "Installing update"
                            remorse.callback = function() { otaClient.startUpgrade() }
                            remorse.start()
                        } else if (otaClient.state === "reboot_required") {
                            remorse.action = "Rebooting watch"
                            remorse.callback = function() { otaClient.rebootWatch() }
                            remorse.start()
                        } else {
                            otaClient.checkForUpdates()
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: DeviceSpecs.hasRoundScreen ? Dims.h(8) : Dims.h(4)
            }
        }
    }

    // Remorse timer for critical actions (install, reboot)
    RemorseTimer {
        id: remorse
        duration: 3500
        cancelText: "Tap to cancel"
        property var callback: null
        onTriggered: {
            if (callback) {
                callback()
            }
        }
    }
}
