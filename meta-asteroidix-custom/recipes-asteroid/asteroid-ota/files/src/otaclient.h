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
    Q_PROPERTY(int upgradableCount READ upgradableCount NOTIFY upgradableCountChanged)
    Q_PROPERTY(QStringList upgradablePackages READ upgradablePackages NOTIFY upgradablePackagesChanged)
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
    int upgradableCount() const { return m_upgradableCount; }
    QStringList upgradablePackages() const { return m_upgradablePackages; }
    int batteryLevel() const { return m_batteryLevel; }
    bool isCharging() const { return m_isCharging; }
    bool networkAvailable() const { return m_networkAvailable; }
    QString networkType() const { return m_networkType; }

public Q_SLOTS:
    void checkForUpdates();
    void startUpgrade();
    void rebootWatch();
    void refresh();

Q_SIGNALS:
    void stateChanged();
    void statusMessageChanged();
    void progressChanged();
    void currentStepChanged();
    void upgradableCountChanged();
    void upgradablePackagesChanged();
    void statsChanged();

private Q_SLOTS:
    void onStateChanged(const QString &newState);
    void onStatusMessageChanged(const QString &msg);
    void onProgressChanged(int percent, const QString &step);
    void onCheckFinished(int count, const QStringList &packages, const QString &error);
    void onUpgradeFinished(bool success, const QString &error);

private:
    void fetchDaemonState();

    QString m_state;
    QString m_statusMessage;
    int m_progress;
    QString m_currentStep;
    int m_upgradableCount;
    QStringList m_upgradablePackages;
    int m_batteryLevel;
    bool m_isCharging;
    bool m_networkAvailable;
    QString m_networkType;

    QDBusInterface *m_iface;
};
