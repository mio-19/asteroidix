import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: "#1b3a57"
    outerColor: "#0a1824"

    Item {
        anchors.fill: parent

        // Top navigation bar
        Item {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Dims.h(16)
            z: 10

            IconButton {
                anchors.left: parent.left
                anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(4)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(12)
                height: width
                iconName: "ios-arrow-back"
                enabled: browserController.canGoBack
                opacity: enabled ? 1.0 : 0.3
                onClicked: browserController.goBack()
            }

            Label {
                anchors.centerIn: parent
                width: DeviceSpecs.hasRoundScreen ? Dims.w(50) : Dims.w(60)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Dims.h(4.5)
                font.bold: true
                color: "#e0f0ff"
                text: browserController.pageTitle
            }

            IconButton {
                anchors.right: parent.right
                anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(10) : Dims.w(4)
                anchors.verticalCenter: parent.verticalCenter
                width: Dims.w(12)
                height: width
                iconName: browserController.loading ? "ios-close" : "ios-refresh"
                onClicked: browserController.loading ? browserController.stop() : browserController.reload()
            }
        }

        // Loading indicator
        Rectangle {
            id: progressIndicator
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Dims.h(1)
            color: "transparent"
            visible: browserController.loading

            Rectangle {
                anchors.fill: parent
                color: "#4da6ff"
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: browserController.loading
                    PropertyAnimation { from: 0.2; to: 1.0; duration: 500 }
                    PropertyAnimation { from: 1.0; to: 0.2; duration: 500 }
                }
            }
        }

        // Web view scrollable area
        Flickable {
            id: flickable
            anchors.top: topBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Dims.h(2)
            anchors.leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(12) : Dims.w(5)
            anchors.rightMargin: DeviceSpecs.hasRoundScreen ? Dims.w(12) : Dims.w(5)
            anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(10) : Dims.h(4)
            clip: true
            contentWidth: width
            contentHeight: contentText.paintedHeight + Dims.h(15)

            Text {
                id: contentText
                width: parent.width
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                color: "#f0f4f8"
                linkColor: "#4da6ff"
                font.pixelSize: Dims.h(4.2)
                text: browserController.pageContent
                onLinkActivated: function(link) {
                    browserController.load(link);
                }
            }
        }

        // Bottom quick bookmarks button
        IconButton {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: DeviceSpecs.hasRoundScreen ? Dims.h(2) : Dims.h(1)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Dims.w(10)
            height: width
            iconName: "ios-bookmarks"
            onClicked: {
                browserController.load("https://asteroidos.org");
            }
        }
    }
}
