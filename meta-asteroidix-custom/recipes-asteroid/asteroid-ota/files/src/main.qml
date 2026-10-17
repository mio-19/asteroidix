import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: otaClient.state === "syncing" || otaClient.state === "downloading" ? "#143a68" :
                 (otaClient.state === "reboot_required" ? "#1e5c32" :
                 (otaClient.state === "error" ? "#661f1f" : "#1b4d89"))
    outerColor: "#0a1e38"

    property int sourceIndex: 0
    readonly property var sources: [
        { name: "Official Nightly", url: otaClient.defaultSource },
        { name: "Local File", url: "/tmp/asteroid-image.ext4" },
        { name: "Custom Host", url: "http://192.168.2.1:8000/asteroid-image.ext4" }
    ]

    function cycleSource() {
        sourceIndex = (sourceIndex + 1) % sources.length
        otaClient.imageSource = sources[sourceIndex].url
    }

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
                height: Dims.h(16)

                Rectangle {
                    anchors.centerIn: parent
                    width: Dims.w(15)
                    height: width
                    radius: width / 2
                    color: "white"
                    opacity: 0.15
                }

                Icon {
                    id: statusIcon
                    anchors.centerIn: parent
                    width: Dims.w(11)
                    height: width
                    name: {
                        switch (otaClient.state) {
                        case "downloading":
                            return "ios-cloud-download"
                        case "syncing":
                            return "ios-sync"
                        case "reboot_required":
                            return "ios-checkmark-circle"
                        case "error":
                            return "ios-alert"
                        default:
                            return "ios-disc"
                        }
                    }

                    RotationAnimation on rotation {
                        running: otaClient.state === "downloading" || otaClient.state === "syncing"
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
                font.pixelSize: Dims.h(4.8)
                font.bold: true
                wrapMode: Text.WordWrap
                text: {
                    switch (otaClient.state) {
                    case "downloading":
                        return "Downloading Image"
                    case "syncing":
                        return "Applying OS Image"
                    case "reboot_required":
                        return "Image Installed!"
                    case "error":
                        return "Update Failed"
                    default:
                        return "Image OTA Update"
                    }
                }
            }

            // Subtitle / Status message
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Dims.h(3.4)
                opacity: 0.85
                wrapMode: Text.WordWrap
                text: otaClient.statusMessage
            }

            // Current step details (during download / sync)
            Label {
                visible: (otaClient.state === "downloading" || otaClient.state === "syncing") && otaClient.currentStep !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Dims.h(3.0)
                opacity: 0.75
                elide: Text.ElideMiddle
                text: otaClient.currentStep
            }

            // Progress Bar
            Item {
                visible: otaClient.state === "downloading" || otaClient.state === "syncing"
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

            // Image Source Selector Card (visible when idle or error)
            Item {
                visible: otaClient.state === "idle" || otaClient.state === "error"
                width: parent.width
                height: Dims.h(13)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: parent.height
                    radius: Dims.h(2)
                    color: "black"
                    opacity: 0.35

                    MouseArea {
                        anchors.fill: parent
                        onClicked: app.cycleSource()
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        spacing: Dims.h(0.5)

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Dims.w(2)
                            Icon {
                                width: Dims.w(3.5)
                                height: width
                                name: "ios-swap"
                            }
                            Label {
                                font.pixelSize: Dims.h(3)
                                font.bold: true
                                text: "Source: " + sources[sourceIndex].name
                            }
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Dims.h(2.4)
                            opacity: 0.75
                            elide: Text.ElideMiddle
                            text: otaClient.imageSource
                        }
                    }
                }
            }

            // Status badges: Network & Battery
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(3)
                visible: otaClient.state === "idle" || otaClient.state === "error"

                Rectangle {
                    height: Dims.h(4.8)
                    width: netRow.implicitWidth + Dims.w(4)
                    radius: height / 2
                    color: "white"
                    opacity: 0.15

                    Row {
                        id: netRow
                        anchors.centerIn: parent
                        spacing: Dims.w(1.5)
                        Icon {
                            width: Dims.w(3.8)
                            height: width
                            name: otaClient.networkAvailable ? "ios-wifi" : "ios-close-circle"
                        }
                        Label {
                            font.pixelSize: Dims.h(2.8)
                            text: otaClient.networkType
                        }
                    }
                }

                Rectangle {
                    height: Dims.h(4.8)
                    width: batRow.implicitWidth + Dims.w(4)
                    radius: height / 2
                    color: "white"
                    opacity: 0.15

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: Dims.w(1.5)
                        Icon {
                            width: Dims.w(3.8)
                            height: width
                            name: otaClient.isCharging ? "ios-battery-charging" : "ios-battery-full"
                        }
                        Label {
                            font.pixelSize: Dims.h(2.8)
                            text: otaClient.batteryLevel + "%"
                        }
                    }
                }
            }

            // Zero Data Loss Guarantee card
            Item {
                width: parent.width
                height: Dims.h(7.5)
                visible: otaClient.state === "idle"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: parent.height
                    radius: Dims.h(1.8)
                    color: "black"
                    opacity: 0.25

                    Label {
                        anchors.centerIn: parent
                        width: parent.width * 0.92
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Dims.h(2.6)
                        opacity: 0.9
                        wrapMode: Text.WordWrap
                        text: "Loops-mounts complete OS image. User data in /home/ceres is preserved."
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

                    visible: otaClient.state !== "downloading" && otaClient.state !== "syncing"

                    text: {
                        switch (otaClient.state) {
                        case "reboot_required":
                            return "Reboot Now"
                        case "error":
                            return "Retry"
                        default:
                            return "Install Image OTA"
                        }
                    }

                    onClicked: {
                        if (otaClient.state === "reboot_required") {
                            remorse.action = "Rebooting watch"
                            remorse.callback = function() { otaClient.rebootWatch() }
                            remorse.start()
                        } else {
                            remorse.action = "Starting Image OTA"
                            remorse.callback = function() { otaClient.startImageUpdate() }
                            remorse.start()
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

    // Remorse timer for critical actions
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
