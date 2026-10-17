#pragma once

#include <QObject>
#include <QStringList>
#include <QProcess>
#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class OTADaemon : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.asteroidos.OTA1")

public:
    explicit OTADaemon(QObject *parent = nullptr);
    ~OTADaemon() override;

    bool initDBus();

public Q_SLOTS:
    Q_SCRIPTABLE void SetImageSource(const QString &source);
    Q_SCRIPTABLE QString GetImageSource() const;
    Q_SCRIPTABLE QString GetDefaultImageSource() const;
    Q_SCRIPTABLE QString GetMachineName() const;
    Q_SCRIPTABLE void StartImageUpdate(const QString &source = QString());
    Q_SCRIPTABLE void CancelUpdate();
    Q_SCRIPTABLE void Reboot();

    Q_SCRIPTABLE QString GetState() const;
    Q_SCRIPTABLE QString GetStatusMessage() const;
    Q_SCRIPTABLE int GetProgress() const;
    Q_SCRIPTABLE QString GetCurrentStep() const;
    Q_SCRIPTABLE int GetBatteryLevel() const;
    Q_SCRIPTABLE bool IsCharging() const;
    Q_SCRIPTABLE bool IsNetworkAvailable() const;
    Q_SCRIPTABLE QString GetNetworkType() const;

Q_SIGNALS:
    Q_SCRIPTABLE void stateChanged(const QString &newState);
    Q_SCRIPTABLE void statusMessageChanged(const QString &message);
    Q_SCRIPTABLE void progressChanged(int percent, const QString &step);
    Q_SCRIPTABLE void imageSourceChanged(const QString &newSource);
    Q_SCRIPTABLE void updateFinished(bool success, const QString &error);

private Q_SLOTS:
    void handleDownloadProgress(qint64 received, qint64 total);
    void handleDownloadFinished();
    void handleSyncFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleSyncOutput();

private:
    void setState(const QString &newState);
    void setStatusMessage(const QString &msg);
    void setProgress(int percent, const QString &step);

    void detectMachineName();
    void querySystemStats();
    bool checkPreflight(bool isRemote);

    void startDownload(const QUrl &url);
    void startMountAndSync(const QString &imagePath);
    void cleanupMount();

    QString m_state;
    QString m_statusMessage;
    int m_progress;
    QString m_currentStep;
    QString m_imageSource;
    QString m_machineName;

    int m_batteryLevel;
    bool m_isCharging;
    bool m_networkAvailable;
    QString m_networkType;

    QNetworkAccessManager *m_netManager;
    QNetworkReply *m_downloadReply;
    QFile *m_tempFile;
    QString m_imageFilePath;
    QString m_mountPoint;
    bool m_isTempFile;

    QProcess *m_syncProcess;
};
