import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Application {
    id: app

    centerColor: {
        if (spo2Controller.measuring)
            return "#8b152b";
        if (spo2Controller.spo2 >= 95)
            return "#117a65";
        if (spo2Controller.spo2 >= 90)
            return "#a04000";
        if (spo2Controller.spo2 > 0)
            return "#922b21";
        return "#3a1020";
    }
    outerColor: "#080205"

    Item {
        anchors.fill: parent

        // Top Title
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Dims.h(6)
            font.pixelSize: Dims.h(4.5)
            font.bold: true
            color: "#ffffff"
            text: "Blood Oxygen"
        }

        // Center Gauge
        OxygenMeter {
            id: meter
            anchors.centerIn: parent
            progress: spo2Controller.progress
            spo2: spo2Controller.spo2
            bpm: spo2Controller.bpm
            measuring: spo2Controller.measuring
            pulseBeat: spo2Controller.pulseBeat
            classification: spo2Controller.classification
        }

        // Action Button
        IconButton {
            id: actionBtn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: statusLabel.top
            anchors.bottomMargin: Dims.h(2)
            width: Dims.w(18)
            height: width
            iconName: spo2Controller.measuring ? "ios-square" : (spo2Controller.spo2 > 0 ? "ios-refresh" : "ios-play")
            onClicked: {
                if (spo2Controller.measuring)
                    spo2Controller.stopMeasurement();
                else
                    spo2Controller.startMeasurement();
            }
        }

        // Bottom Status Label
        Label {
            id: statusLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.h(5)
            width: DeviceSpecs.hasRoundScreen ? Dims.w(75) : Dims.w(85)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: Dims.h(3.8)
            color: spo2Controller.onWrist ? "#cccccc" : "#e67e22"
            text: spo2Controller.status
        }
    }
}
