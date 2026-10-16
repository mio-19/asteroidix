import QtQuick
import org.asteroid.controls
import org.asteroid.utils

Item {
    id: meter

    property int progress: 0
    property int spo2: 0
    property int bpm: 0
    property bool measuring: false
    property bool pulseBeat: false
    property string classification: ""

    width: Dims.w(70)
    height: width

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = (width / 2) - Dims.w(3);
            var lineWidth = Dims.w(2.5);

            // Background track ring
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
            ctx.lineWidth = lineWidth;
            ctx.strokeStyle = "rgba(255, 255, 255, 0.12)";
            ctx.stroke();

            // Progress / SpO2 arc
            var fraction = 0;
            var strokeColor = "#3498db";

            if (meter.measuring) {
                fraction = meter.progress / 100.0;
                strokeColor = "#e74c3c";
            } else if (meter.spo2 > 0) {
                // Map SpO2 80% - 100% to full circle arc
                fraction = Math.max(0.05, Math.min(1.0, (meter.spo2 - 70) / 30.0));
                if (meter.spo2 >= 95)
                    strokeColor = "#2ecc71";
                else if (meter.spo2 >= 90)
                    strokeColor = "#f39c12";
                else
                    strokeColor = "#e74c3c";
            }

            if (fraction > 0) {
                var startAngle = -Math.PI / 2;
                var endAngle = startAngle + (fraction * 2 * Math.PI);

                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.strokeStyle = strokeColor;
                ctx.stroke();
            }
        }
    }

    onProgressChanged: canvas.requestPaint()
    onSpo2Changed: canvas.requestPaint()
    onMeasuringChanged: canvas.requestPaint()

    Column {
        anchors.centerIn: parent
        spacing: Dims.h(1)

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Dims.h(12)
            font.bold: true
            color: {
                if (meter.measuring)
                    return "#e74c3c";
                if (meter.spo2 >= 95)
                    return "#2ecc71";
                if (meter.spo2 >= 90)
                    return "#f39c12";
                if (meter.spo2 > 0)
                    return "#e74c3c";
                return "#ffffff";
            }
            text: {
                if (meter.measuring)
                    return meter.progress + "%";
                if (meter.spo2 > 0)
                    return meter.spo2 + "%";
                return "--%";
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Dims.h(4.5)
            color: "#aaaaaa"
            text: meter.measuring ? "MEASURING" : "SpO₂"
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Dims.w(1.5)
            visible: meter.bpm > 0

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "♥"
                font.pixelSize: Dims.h(4.5)
                color: "#e74c3c"
                scale: meter.pulseBeat ? 1.35 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 120 }
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Dims.h(4)
                color: "#dddddd"
                text: meter.bpm + " bpm"
            }
        }
    }
}
