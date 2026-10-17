#include "otadaemon.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusInterface>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QTextStream>
#include <QDebug>
#include <QUrl>
#include <QNetworkRequest>
#include <sys/statvfs.h>
#include <unistd.h>

OTADaemon::OTADaemon(QObject *parent)
    : QObject(parent)
    , m_state(QStringLiteral("idle"))
    , m_statusMessage(QStringLiteral("Ready to update"))
    , m_progress(0)
    , m_currentStep(QString())
    , m_batteryLevel(100)
    , m_isCharging(true)
    , m_networkAvailable(false)
    , m_networkType(QStringLiteral("None"))
    , m_netManager(nullptr)
    , m_downloadReply(nullptr)
    , m_tempFile(nullptr)
    , m_mountPoint(QStringLiteral("/mnt/ota_rootfs"))
    , m_isTempFile(false)
    , m_syncProcess(nullptr)
{
    detectMachineName();
    m_imageSource = GetDefaultImageSource();
    m_netManager = new QNetworkAccessManager(this);
    querySystemStats();
}

OTADaemon::~OTADaemon()
{
    cleanupMount();
    if (m_syncProcess && m_syncProcess->state() != QProcess::NotRunning) {
        m_syncProcess->kill();
        m_syncProcess->waitForFinished(1000);
    }
}

bool OTADaemon::initDBus()
{
    QDBusConnection connection = QDBusConnection::systemBus();
    if (!connection.isConnected()) {
        qWarning() << "Cannot connect to System D-Bus:" << connection.lastError().message();
        return false;
    }

    if (!connection.registerService(QStringLiteral("org.asteroidos.OTA1"))) {
        qWarning() << "Cannot register D-Bus service org.asteroidos.OTA1:" << connection.lastError().message();
        return false;
    }

    if (!connection.registerObject(QStringLiteral("/org/asteroidos/OTA1"), this,
                                   QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals)) {
        qWarning() << "Cannot register D-Bus object /org/asteroidos/OTA1:" << connection.lastError().message();
        return false;
    }

    qInfo() << "OTADaemon successfully registered on System D-Bus org.asteroidos.OTA1";
    return true;
}

void OTADaemon::detectMachineName()
{
    m_machineName = QStringLiteral("hoki");

    QFile machFile(QStringLiteral("/etc/machine-name"));
    if (machFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString name = QString::fromUtf8(machFile.readAll()).trimmed();
        if (!name.isEmpty()) {
            m_machineName = name;
            return;
        }
    }

    QFile osRelease(QStringLiteral("/etc/os-release"));
    if (osRelease.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&osRelease);
        QString line;
        while (in.readLineInto(&line)) {
            if (line.startsWith(QStringLiteral("OPENEMBEDDED_MACHINE="))) {
                m_machineName = line.section(QLatin1Char('='), 1).remove(QLatin1Char('"')).trimmed();
                return;
            }
        }
    }
}

QString OTADaemon::GetMachineName() const
{
    return m_machineName;
}

QString OTADaemon::GetDefaultImageSource() const
{
    return QStringLiteral("https://release.asteroidos.org/nightlies/%1/asteroid-image-%1.ext4").arg(m_machineName);
}

void OTADaemon::SetImageSource(const QString &source)
{
    if (m_imageSource != source && !source.isEmpty()) {
        m_imageSource = source;
        Q_EMIT imageSourceChanged(m_imageSource);
    }
}

QString OTADaemon::GetImageSource() const
{
    return m_imageSource;
}

void OTADaemon::setState(const QString &newState)
{
    if (m_state != newState) {
        m_state = newState;
        Q_EMIT stateChanged(m_state);
    }
}

void OTADaemon::setStatusMessage(const QString &msg)
{
    if (m_statusMessage != msg) {
        m_statusMessage = msg;
        Q_EMIT statusMessageChanged(m_statusMessage);
    }
}

void OTADaemon::setProgress(int percent, const QString &step)
{
    m_progress = qBound(0, percent, 100);
    m_currentStep = step;
    Q_EMIT progressChanged(m_progress, m_currentStep);
}

QString OTADaemon::GetState() const { return m_state; }
QString OTADaemon::GetStatusMessage() const { return m_statusMessage; }
int OTADaemon::GetProgress() const { return m_progress; }
QString OTADaemon::GetCurrentStep() const { return m_currentStep; }
int OTADaemon::GetBatteryLevel() const { return m_batteryLevel; }
bool OTADaemon::IsCharging() const { return m_isCharging; }
bool OTADaemon::IsNetworkAvailable() const { return m_networkAvailable; }
QString OTADaemon::GetNetworkType() const { return m_networkType; }

void OTADaemon::querySystemStats()
{
    m_batteryLevel = 100;
    m_isCharging = true;

    QDir powerDir(QStringLiteral("/sys/class/power_supply"));
    QStringList supplies = powerDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &supply : supplies) {
        QString typePath = powerDir.absoluteFilePath(supply + QStringLiteral("/type"));
        QFile typeFile(typePath);
        if (typeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString type = QString::fromUtf8(typeFile.readAll()).trimmed();
            if (type.compare(QStringLiteral("Battery"), Qt::CaseInsensitive) == 0) {
                QFile capFile(powerDir.absoluteFilePath(supply + QStringLiteral("/capacity")));
                if (capFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    m_batteryLevel = QString::fromUtf8(capFile.readAll()).trimmed().toInt();
                }
                QFile statusFile(powerDir.absoluteFilePath(supply + QStringLiteral("/status")));
                if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QString status = QString::fromUtf8(statusFile.readAll()).trimmed();
                    m_isCharging = (status.compare(QStringLiteral("Charging"), Qt::CaseInsensitive) == 0 ||
                                    status.compare(QStringLiteral("Full"), Qt::CaseInsensitive) == 0);
                }
                break;
            }
        }
    }

    m_networkAvailable = false;
    m_networkType = QStringLiteral("None");

    const struct { const char *dev; const char *name; } ifaces[] = {
        { "wlan0", "Wi-Fi" },
        { "bnep0", "Bluetooth PAN" },
        { "rndis0", "USB" },
        { "usb0", "USB" },
        { "eth0", "Ethernet" }
    };

    for (const auto &iface : ifaces) {
        QString operPath = QStringLiteral("/sys/class/net/%1/operstate").arg(QString::fromLatin1(iface.dev));
        QFile operFile(operPath);
        if (operFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString state = QString::fromUtf8(operFile.readAll()).trimmed();
            if (state == QStringLiteral("up") || state == QStringLiteral("unknown")) {
                m_networkAvailable = true;
                m_networkType = QString::fromLatin1(iface.name);
                break;
            }
        }
    }

    QFile routeFile(QStringLiteral("/proc/net/route"));
    if (routeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&routeFile);
        QString line;
        while (in.readLineInto(&line)) {
            QStringList parts = line.split(QLatin1Char('\t'), Qt::SkipEmptyParts);
            if (parts.size() >= 2 && parts[1] == QStringLiteral("00000000")) {
                m_networkAvailable = true;
                break;
            }
        }
    }
}

bool OTADaemon::checkPreflight(bool isRemote)
{
    querySystemStats();

    if (isRemote && !m_networkAvailable) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("No internet connection. Connect to Wi-Fi or turn on Bluetooth Internet Sharing."));
        Q_EMIT updateFinished(false, m_statusMessage);
        return false;
    }

    if (isRemote && QDateTime::currentDateTime().date().year() < 2024) {
        QProcess::startDetached(QStringLiteral("systemctl"), QStringList() << QStringLiteral("restart") << QStringLiteral("systemd-timesyncd"));
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Clock out of sync. Please verify Date & Time in Settings to validate SSL certificates."));
        Q_EMIT updateFinished(false, m_statusMessage);
        return false;
    }

    if (m_batteryLevel < 20 && !m_isCharging) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Battery too low (%1%). Please connect watch to charger before upgrading.").arg(m_batteryLevel));
        Q_EMIT updateFinished(false, m_statusMessage);
        return false;
    }

    struct statvfs s;
    if (statvfs("/", &s) == 0) {
        unsigned long long freeMb = ((unsigned long long)s.f_bavail * s.f_frsize) / (1024 * 1024);
        if (freeMb < 80) {
            setState(QStringLiteral("error"));
            setStatusMessage(QStringLiteral("Insufficient disk space (%1 MB free). At least 80 MB required.").arg(freeMb));
            Q_EMIT updateFinished(false, m_statusMessage);
            return false;
        }
    }

    return true;
}

void OTADaemon::StartImageUpdate(const QString &source)
{
    if (m_state == QStringLiteral("downloading") || m_state == QStringLiteral("syncing")) {
        return;
    }

    QString targetSource = source.trimmed();
    if (targetSource.isEmpty()) {
        targetSource = m_imageSource.trimmed();
    }
    if (targetSource.isEmpty()) {
        targetSource = GetDefaultImageSource();
    }
    m_imageSource = targetSource;

    bool isRemote = targetSource.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive) ||
                    targetSource.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive);

    if (!checkPreflight(isRemote)) {
        return;
    }

    if (isRemote) {
        startDownload(QUrl(targetSource));
    } else {
        // Local image path
        QFileInfo fi(targetSource);
        if (!fi.exists() || !fi.isFile()) {
            setState(QStringLiteral("error"));
            setStatusMessage(QStringLiteral("Image file not found: %1").arg(targetSource));
            Q_EMIT updateFinished(false, m_statusMessage);
            return;
        }
        m_imageFilePath = targetSource;
        m_isTempFile = false;
        startMountAndSync(m_imageFilePath);
    }
}

void OTADaemon::startDownload(const QUrl &url)
{
    setState(QStringLiteral("downloading"));
    setStatusMessage(QStringLiteral("Downloading OS image..."));
    setProgress(2, QStringLiteral("Connecting to server..."));

    QString downloadDir = QStringLiteral("/tmp");
    m_imageFilePath = QStringLiteral("%1/asteroid-ota-image.ext4").arg(downloadDir);
    m_isTempFile = true;

    if (m_tempFile) {
        if (m_tempFile->isOpen()) m_tempFile->close();
        delete m_tempFile;
    }
    m_tempFile = new QFile(m_imageFilePath, this);
    if (!m_tempFile->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Cannot create temporary image file in /tmp"));
        Q_EMIT updateFinished(false, m_statusMessage);
        return;
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    if (m_downloadReply) {
        m_downloadReply->deleteLater();
    }
    m_downloadReply = m_netManager->get(request);

    connect(m_downloadReply, &QNetworkReply::readyRead, this, [this]() {
        if (m_tempFile && m_downloadReply) {
            m_tempFile->write(m_downloadReply->readAll());
        }
    });

    connect(m_downloadReply, &QNetworkReply::downloadProgress,
            this, &OTADaemon::handleDownloadProgress);
    connect(m_downloadReply, &QNetworkReply::finished,
            this, &OTADaemon::handleDownloadFinished);
}

void OTADaemon::handleDownloadProgress(qint64 received, qint64 total)
{
    if (total > 0) {
        int percent = qBound(2, static_cast<int>((received * 50) / total), 50);
        double mbRecv = received / (1024.0 * 1024.0);
        double mbTotal = total / (1024.0 * 1024.0);
        setProgress(percent, QStringLiteral("Downloading: %1 / %2 MB (%3%)")
                    .arg(mbRecv, 0, 'f', 1)
                    .arg(mbTotal, 0, 'f', 1)
                    .arg(percent * 2));
    } else {
        double mbRecv = received / (1024.0 * 1024.0);
        setProgress(25, QStringLiteral("Downloaded %1 MB").arg(mbRecv, 0, 'f', 1));
    }
}

void OTADaemon::handleDownloadFinished()
{
    if (!m_downloadReply) return;

    if (m_tempFile) {
        m_tempFile->flush();
        m_tempFile->close();
    }

    if (m_downloadReply->error() != QNetworkReply::NoError) {
        QString err = m_downloadReply->errorString();
        m_downloadReply->deleteLater();
        m_downloadReply = nullptr;
        if (m_isTempFile) {
            QFile::remove(m_imageFilePath);
        }
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Download failed: %1").arg(err));
        Q_EMIT updateFinished(false, m_statusMessage);
        return;
    }

    m_downloadReply->deleteLater();
    m_downloadReply = nullptr;

    setProgress(50, QStringLiteral("Download complete. Preparing mount..."));
    startMountAndSync(m_imageFilePath);
}

void OTADaemon::startMountAndSync(const QString &imagePath)
{
    setState(QStringLiteral("syncing"));
    setStatusMessage(QStringLiteral("Mounting OS image..."));
    setProgress(55, QStringLiteral("Loop-mounting image..."));

    QDir().mkpath(m_mountPoint);

    // Unmount if previously mounted
    QProcess::execute(QStringLiteral("umount"), QStringList() << QStringLiteral("-f") << m_mountPoint);

    // Loop-mount read-only
    int mountCode = QProcess::execute(QStringLiteral("mount"),
        QStringList() << QStringLiteral("-o") << QStringLiteral("loop,ro") << imagePath << m_mountPoint);

    if (mountCode != 0) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Failed to mount image (code %1)").arg(mountCode));
        cleanupMount();
        Q_EMIT updateFinished(false, m_statusMessage);
        return;
    }

    // Check that mount has valid rootfs files
    if (!QFile::exists(m_mountPoint + QStringLiteral("/etc/os-release")) &&
        !QFile::exists(m_mountPoint + QStringLiteral("/usr/bin/asteroid-launcher"))) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Invalid image: missing rootfs files"));
        cleanupMount();
        Q_EMIT updateFinished(false, m_statusMessage);
        return;
    }

    setStatusMessage(QStringLiteral("Applying new OS image..."));
    setProgress(60, QStringLiteral("Syncing system files (preserving /home)..."));

    if (m_syncProcess) {
        m_syncProcess->deleteLater();
    }
    m_syncProcess = new QProcess(this);
    m_syncProcess->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_syncProcess, &QProcess::readyReadStandardOutput,
            this, &OTADaemon::handleSyncOutput);
    connect(m_syncProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &OTADaemon::handleSyncFinished);

    // Synchronize system files from loop-mounted image into live filesystem:
    // Exclude /home (preserves /home/ceres completely)
    // Exclude /var/lib/connman (saved Wi-Fi connections)
    // Exclude /var/lib/bluetooth (paired device keys)
    // Exclude /etc/machine-id and /etc/hostname (local identity)
    // Exclude volatile virtual mountpoints
    QStringList rsyncArgs;
    rsyncArgs << QStringLiteral("-aHAX")
              << QStringLiteral("--delete")
              << QStringLiteral("--exclude=/home")
              << QStringLiteral("--exclude=/var/lib/connman")
              << QStringLiteral("--exclude=/var/lib/bluetooth")
              << QStringLiteral("--exclude=/etc/machine-id")
              << QStringLiteral("--exclude=/etc/hostname")
              << QStringLiteral("--exclude=/dev")
              << QStringLiteral("--exclude=/proc")
              << QStringLiteral("--exclude=/sys")
              << QStringLiteral("--exclude=/tmp")
              << QStringLiteral("--exclude=/run")
              << QStringLiteral("--exclude=/mnt")
              << QStringLiteral("--exclude=/media")
              << QStringLiteral("--exclude=/lost+found")
              << (m_mountPoint + QStringLiteral("/"))
              << QStringLiteral("/");

    m_syncProcess->start(QStringLiteral("rsync"), rsyncArgs);
}

void OTADaemon::handleSyncOutput()
{
    if (m_progress < 95) {
        setProgress(qMin(m_progress + 2, 95), QStringLiteral("Updating system packages..."));
    }
}

void OTADaemon::handleSyncFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);
    cleanupMount();

    if (exitCode == 0 || exitCode == 24) { // 24 = vanished files during copy, standard for live sync
        sync();
        setProgress(100, QStringLiteral("Complete"));
        setState(QStringLiteral("reboot_required"));
        setStatusMessage(QStringLiteral("New OS image applied! Reboot to boot into the new system."));
        Q_EMIT updateFinished(true, QString());
    } else {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("System sync failed (exit code %1)").arg(exitCode));
        Q_EMIT updateFinished(false, m_statusMessage);
    }
}

void OTADaemon::cleanupMount()
{
    if (QFile::exists(m_mountPoint)) {
        QProcess::execute(QStringLiteral("umount"), QStringList() << QStringLiteral("-f") << m_mountPoint);
    }
    if (m_isTempFile && !m_imageFilePath.isEmpty()) {
        QFile::remove(m_imageFilePath);
        m_imageFilePath.clear();
    }
}

void OTADaemon::CancelUpdate()
{
    if (m_downloadReply && m_downloadReply->isRunning()) {
        m_downloadReply->abort();
    }
    if (m_syncProcess && m_syncProcess->state() != QProcess::NotRunning) {
        m_syncProcess->kill();
    }
    cleanupMount();
    setState(QStringLiteral("idle"));
    setStatusMessage(QStringLiteral("Update cancelled"));
    setProgress(0, QString());
}

void OTADaemon::Reboot()
{
    qInfo() << "OTADaemon: Requesting clean reboot via systemd login1...";
    QDBusInterface login1(QStringLiteral("org.freedesktop.login1"),
                          QStringLiteral("/org/freedesktop/login1"),
                          QStringLiteral("org.freedesktop.login1.Manager"),
                          QDBusConnection::systemBus());
    if (login1.isValid()) {
        login1.call(QStringLiteral("Reboot"), false);
    } else {
        QProcess::startDetached(QStringLiteral("systemctl"), QStringList() << QStringLiteral("reboot"));
    }
}
