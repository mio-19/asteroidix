#pragma once

#include <QObject>
#include <QStringList>
#include <QDBusInterface>

class OTAClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString currentStep READ currentStep NOTIFY currentStepChanged)
    Q_PROPERTY(QString imageSource READ imageSource WRITE setImageSource NOTIFY imageSourceChanged)
    Q_PROPERTY(QString machineName READ machineName NOTIFY machineNameChanged)
    Q_PROPERTY(QString defaultSource READ defaultSource NOTIFY machineNameChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY statsChanged)
    Q_PROPERTY(bool isCharging READ isCharging NOTIFY statsChanged)
    Q_PROPERTY(bool networkAvailable READ networkAvailable NOTIFY statsChanged)
    Q_PROPERTY(QString networkType READ networkType NOTIFY statsChanged)

public:
    explicit OTAClient(QObject *parent = nullptr);

    QString state() const { return m_state; }
    QString statusMessage() const { return m_statusMessage; }
    int progress() const { return m_progress; }
    QString currentStep() const { return m_currentStep; }
    QString imageSource() const { return m_imageSource; }
    QString machineName() const { return m_machineName; }
    QString defaultSource() const { return m_defaultSource; }
    int batteryLevel() const { return m_batteryLevel; }
    bool isCharging() const { return m_isCharging; }
    bool networkAvailable() const { return m_networkAvailable; }
    QString networkType() const { return m_networkType; }

public Q_SLOTS:
    void setImageSource(const QString &source);
    void startImageUpdate(const QString &source = QString());
    void cancelUpdate();
    void rebootWatch();
    void refresh();

Q_SIGNALS:
    void stateChanged();
    void statusMessageChanged();
    void progressChanged();
    void currentStepChanged();
    void imageSourceChanged();
    void machineNameChanged();
    void statsChanged();

private Q_SLOTS:
    void onStateChanged(const QString &newState);
    void onStatusMessageChanged(const QString &msg);
    void onProgressChanged(int percent, const QString &step);
    void onImageSourceChanged(const QString &newSource);
    void onUpdateFinished(bool success, const QString &error);

private:
    void fetchDaemonState();

    QString m_state;
    QString m_statusMessage;
    int m_progress;
    QString m_currentStep;
    QString m_imageSource;
    QString m_machineName;
    QString m_defaultSource;
    int m_batteryLevel;
    bool m_isCharging;
    bool m_networkAvailable;
    QString m_networkType;

    QDBusInterface *m_iface;
};
