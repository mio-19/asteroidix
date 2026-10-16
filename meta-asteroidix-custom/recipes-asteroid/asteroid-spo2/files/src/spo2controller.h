#ifndef SPO2CONTROLLER_H
#define SPO2CONTROLLER_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <QDateTime>
#include <QSettings>
#include <QList>
#include <QtMath>

#include <qhrmsensor.h>

class SPO2Controller : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool measuring READ measuring NOTIFY measuringChanged)
    Q_PROPERTY(int spo2 READ spo2 NOTIFY spo2Changed)
    Q_PROPERTY(int bpm READ bpm NOTIFY bpmChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString classification READ classification NOTIFY classificationChanged)
    Q_PROPERTY(QString lastMeasurementTime READ lastMeasurementTime NOTIFY lastMeasurementTimeChanged)
    Q_PROPERTY(int lastSpo2 READ lastSpo2 NOTIFY lastSpo2Changed)
    Q_PROPERTY(int lastBpm READ lastBpm NOTIFY lastBpmChanged)
    Q_PROPERTY(bool onWrist READ onWrist NOTIFY onWristChanged)
    Q_PROPERTY(bool pulseBeat READ pulseBeat NOTIFY pulseBeatChanged)

public:
    explicit SPO2Controller(QObject *parent = nullptr);
    ~SPO2Controller() override;

    bool measuring() const { return m_measuring; }
    int spo2() const { return m_spo2; }
    int bpm() const { return m_bpm; }
    int progress() const { return m_progress; }
    QString status() const { return m_status; }
    QString classification() const { return m_classification; }
    QString lastMeasurementTime() const { return m_lastMeasurementTime; }
    int lastSpo2() const { return m_lastSpo2; }
    int lastBpm() const { return m_lastBpm; }
    bool onWrist() const { return m_onWrist; }
    bool pulseBeat() const { return m_pulseBeat; }

    Q_INVOKABLE void startMeasurement();
    Q_INVOKABLE void stopMeasurement();
    Q_INVOKABLE void reset();

signals:
    void measuringChanged();
    void spo2Changed();
    void bpmChanged();
    void progressChanged();
    void statusChanged();
    void classificationChanged();
    void lastMeasurementTimeChanged();
    void lastSpo2Changed();
    void lastBpmChanged();
    void onWristChanged();
    void pulseBeatChanged();
    void measurementCompleted(int spo2, int bpm);

private slots:
    void onMeasurementTick();
    void onHrmReadingChanged();
    void onBeatPulseReset();

private:
    void loadSettings();
    void saveSettings(int spo2, int bpm);
    void updateClassification(int spo2);
    void finalizeMeasurement();

    bool m_measuring;
    int m_spo2;
    int m_bpm;
    int m_progress;
    QString m_status;
    QString m_classification;
    QString m_lastMeasurementTime;
    int m_lastSpo2;
    int m_lastBpm;
    bool m_onWrist;
    bool m_pulseBeat;

    int m_ticks;
    int m_offWristTicks;
    QList<double> m_rRatioSamples;
    QList<int> m_bpmSamples;

    QTimer m_measureTimer;
    QTimer m_beatTimer;
    QHrmSensor *m_hrmSensor;
};

#endif // SPO2CONTROLLER_H
