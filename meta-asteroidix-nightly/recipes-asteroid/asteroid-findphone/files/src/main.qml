import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: findPhone.ringing ? "#8c2f2f" : "#1f4b99"
    outerColor: "#061225"

    BluetoothStatus { id: btStatus }

    StatusPage {
        visible: !btStatus.connected
        icon: "ios-bluetooth"
        text: "Connect your phone"
    }

    Item {
        anchors.fill: parent
        visible: btStatus.connected

        IconButton {
            anchors.centerIn: parent
            width: Dims.w(42)
            height: width
            iconName: findPhone.ringing ? "ios-square" : "ios-volume-high"
            onClicked: findPhone.ringing ? findPhone.stop() : findPhone.ring()
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.h(16)
            width: DeviceSpecs.hasRoundScreen ? Dims.w(70) : Dims.w(80)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: findPhone.status
        }
    }
}
