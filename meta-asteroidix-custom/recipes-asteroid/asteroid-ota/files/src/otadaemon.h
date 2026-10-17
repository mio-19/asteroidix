#pragma once

#include <QObject>
#include <QStringList>
#include <QProcess>
#include <QTimer>

class OTADaemon : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.asteroidos.OTA1")

public:
    explicit OTADaemon(QObject *parent = nullptr);
    ~OTADaemon() override;

    bool initDBus();

public Q_SLOTS:
    Q_SCRIPTABLE void CheckForUpdates();
    Q_SCRIPTABLE void StartUpgrade();
    Q_SCRIPTABLE void Reboot();
    Q_SCRIPTABLE QString GetState() const;
    Q_SCRIPTABLE QString GetStatusMessage() const;
    Q_SCRIPTABLE int GetProgress() const;
    Q_SCRIPTABLE QString GetCurrentStep() const;
    Q_SCRIPTABLE int GetUpgradableCount() const;
    Q_SCRIPTABLE QStringList GetUpgradablePackages() const;
    Q_SCRIPTABLE int GetBatteryLevel() const;
    Q_SCRIPTABLE bool IsCharging() const;
    Q_SCRIPTABLE bool IsNetworkAvailable() const;
    Q_SCRIPTABLE QString GetNetworkType() const;

Q_SIGNALS:
    Q_SCRIPTABLE void stateChanged(const QString &newState);
    Q_SCRIPTABLE void statusMessageChanged(const QString &message);
    Q_SCRIPTABLE void progressChanged(int percent, const QString &step);
    Q_SCRIPTABLE void checkFinished(int count, const QStringList &packages, const QString &error);
    Q_SCRIPTABLE void upgradeFinished(bool success, const QString &error);

private Q_SLOTS:
    void handleUpdateFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleListFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleUpgradeFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleUpgradeOutput();

private:
    void setState(const QString &newState);
    void setStatusMessage(const QString &msg);
    void setProgress(int percent, const QString &step);

    bool checkPreflightForUpdate();
    bool checkPreflightForUpgrade();
    void querySystemStats();

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

    QProcess *m_process;
    QString m_collectedOutput;
};
