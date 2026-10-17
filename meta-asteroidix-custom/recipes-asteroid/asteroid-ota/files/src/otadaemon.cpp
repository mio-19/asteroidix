#include "otadaemon.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusInterface>
#include <QDateTime>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QTextStream>
#include <QDebug>
#include <sys/statvfs.h>
#include <unistd.h>

OTADaemon::OTADaemon(QObject *parent)
    : QObject(parent)
    , m_state(QStringLiteral("idle"))
    , m_statusMessage(QStringLiteral("System update is ready"))
    , m_progress(0)
    , m_currentStep(QString())
    , m_upgradableCount(0)
    , m_batteryLevel(100)
    , m_isCharging(true)
    , m_networkAvailable(false)
    , m_networkType(QStringLiteral("None"))
    , m_process(nullptr)
{
    querySystemStats();
}

OTADaemon::~OTADaemon()
{
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(1000);
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

QString OTADaemon::GetState() const
{
    return m_state;
}

QString OTADaemon::GetStatusMessage() const
{
    return m_statusMessage;
}

int OTADaemon::GetProgress() const
{
    return m_progress;
}

QString OTADaemon::GetCurrentStep() const
{
    return m_currentStep;
}

int OTADaemon::GetUpgradableCount() const
{
    return m_upgradableCount;
}

QStringList OTADaemon::GetUpgradablePackages() const
{
    return m_upgradablePackages;
}

int OTADaemon::GetBatteryLevel() const
{
    return m_batteryLevel;
}

bool OTADaemon::IsCharging() const
{
    return m_isCharging;
}

bool OTADaemon::IsNetworkAvailable() const
{
    return m_networkAvailable;
}

QString OTADaemon::GetNetworkType() const
{
    return m_networkType;
}

void OTADaemon::querySystemStats()
{
    // 1. Query battery status from sysfs
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

    // 2. Query network status
    m_networkAvailable = false;
    m_networkType = QStringLiteral("None");

    // Check specific watch network interfaces
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

    // Also inspect /proc/net/route for default route
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

bool OTADaemon::checkPreflightForUpdate()
{
    querySystemStats();

    // Check network
    if (!m_networkAvailable) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("No internet connection. Connect to Wi-Fi or turn on Bluetooth Internet Sharing."));
        Q_EMIT checkFinished(0, QStringList(), m_statusMessage);
        return false;
    }

    // Check system clock: AsteroidOS wiki specifically warns about SSL cert error if time is invalid
    if (QDateTime::currentDateTime().date().year() < 2024) {
        qWarning() << "System clock invalid, year:" << QDateTime::currentDateTime().date().year();
        // Try to trigger timesyncd
        QProcess::startDetached(QStringLiteral("systemctl"), QStringList() << QStringLiteral("restart") << QStringLiteral("systemd-timesyncd"));
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Clock out of sync. Please verify Date & Time in Settings to validate SSL certificates."));
        Q_EMIT checkFinished(0, QStringList(), m_statusMessage);
        return false;
    }

    return true;
}

bool OTADaemon::checkPreflightForUpgrade()
{
    querySystemStats();

    // Check network
    if (!m_networkAvailable) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("No internet connection. Ensure Wi-Fi or Bluetooth PAN is active."));
        Q_EMIT upgradeFinished(false, m_statusMessage);
        return false;
    }

    // Check battery level: require >= 20% or charging
    if (m_batteryLevel < 20 && !m_isCharging) {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Battery too low (%1%). Please connect watch to charger before upgrading.").arg(m_batteryLevel));
        Q_EMIT upgradeFinished(false, m_statusMessage);
        return false;
    }

    // Check storage space on root filesystem (at least 80MB free required)
    struct statvfs s;
    if (statvfs("/", &s) == 0) {
        unsigned long long freeBytes = (unsigned long long)s.f_bavail * s.f_frsize;
        unsigned long long freeMb = freeBytes / (1024 * 1024);
        if (freeMb < 80) {
            setState(QStringLiteral("error"));
            setStatusMessage(QStringLiteral("Insufficient disk space (%1 MB free). At least 80 MB required.").arg(freeMb));
            Q_EMIT upgradeFinished(false, m_statusMessage);
            return false;
        }
    }

    return true;
}

void OTADaemon::CheckForUpdates()
{
    if (m_state == QStringLiteral("checking") || m_state == QStringLiteral("upgrading")) {
        return;
    }

    if (!checkPreflightForUpdate()) {
        return;
    }

    setState(QStringLiteral("checking"));
    setStatusMessage(QStringLiteral("Connecting to package feeds..."));
    setProgress(10, QStringLiteral("Checking repository..."));

    m_collectedOutput.clear();

    if (m_process) {
        m_process->deleteLater();
    }
    m_process = new QProcess(this);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &OTADaemon::handleUpdateFinished);

    m_process->start(QStringLiteral("opkg"), QStringList() << QStringLiteral("update"));
}

void OTADaemon::handleUpdateFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);
    QString out = QString::fromUtf8(m_process->readAllStandardOutput());
    QString err = QString::fromUtf8(m_process->readAllStandardError());

    if (exitCode != 0) {
        QString errorDetail = err.trimmed();
        if (errorDetail.contains(QStringLiteral("SSL"), Qt::CaseInsensitive) ||
            out.contains(QStringLiteral("SSL"), Qt::CaseInsensitive) ||
            errorDetail.contains(QStringLiteral("certificate"), Qt::CaseInsensitive)) {
            setStatusMessage(QStringLiteral("SSL certificate error. Please check your watch Date & Time settings."));
        } else if (errorDetail.contains(QStringLiteral("Failed to download"), Qt::CaseInsensitive) ||
                   out.contains(QStringLiteral("Failed to download"), Qt::CaseInsensitive)) {
            setStatusMessage(QStringLiteral("Could not reach AsteroidOS update server. Check your internet connection."));
        } else {
            setStatusMessage(QStringLiteral("Package check failed (exit code %1).").arg(exitCode));
        }
        setState(QStringLiteral("error"));
        Q_EMIT checkFinished(0, QStringList(), m_statusMessage);
        return;
    }

    // Now query upgradable packages
    setStatusMessage(QStringLiteral("Querying upgradable packages..."));
    setProgress(50, QStringLiteral("Analyzing updates..."));

    if (m_process) {
        m_process->deleteLater();
    }
    m_process = new QProcess(this);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &OTADaemon::handleListFinished);

    m_process->start(QStringLiteral("opkg"), QStringList() << QStringLiteral("list-upgradable"));
}

void OTADaemon::handleListFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);
    QString out = QString::fromUtf8(m_process->readAllStandardOutput());

    m_upgradablePackages.clear();
    const QStringList lines = out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        QString trimmed = line.trimmed();
        if (trimmed.isEmpty() || trimmed.startsWith(QLatin1Char('*'))) {
            continue;
        }
        QString pkg = trimmed.section(QLatin1Char(' '), 0, 0);
        if (!pkg.isEmpty()) {
            m_upgradablePackages.append(pkg);
        }
    }

    m_upgradableCount = m_upgradablePackages.size();
    setProgress(100, QString());

    if (m_upgradableCount == 0) {
        setState(QStringLiteral("up_to_date"));
        setStatusMessage(QStringLiteral("Your AsteroidOS system is up to date"));
    } else {
        setState(QStringLiteral("available"));
        setStatusMessage(QStringLiteral("%1 package(s) available to update").arg(m_upgradableCount));
    }

    Q_EMIT checkFinished(m_upgradableCount, m_upgradablePackages, QString());
}

void OTADaemon::StartUpgrade()
{
    if (m_state == QStringLiteral("upgrading")) {
        return;
    }

    if (!checkPreflightForUpgrade()) {
        return;
    }

    setState(QStringLiteral("upgrading"));
    setStatusMessage(QStringLiteral("Starting system upgrade..."));
    setProgress(5, QStringLiteral("Preparing package manager..."));

    if (m_process) {
        m_process->deleteLater();
    }
    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &OTADaemon::handleUpgradeOutput);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &OTADaemon::handleUpgradeFinished);

    // Run opkg upgrade with force-maintainer to automatically preserve configs cleanly
    m_process->start(QStringLiteral("opkg"), QStringList() << QStringLiteral("--force-maintainer") << QStringLiteral("upgrade"));
}

void OTADaemon::handleUpgradeOutput()
{
    while (m_process && m_process->canReadLine()) {
        QString line = QString::fromUtf8(m_process->readLine()).trimmed();
        if (line.isEmpty()) continue;

        if (line.startsWith(QStringLiteral("Downloading "))) {
            QString url = line.mid(12);
            QString pkgName = QFileInfo(url).fileName();
            setProgress(qMin(m_progress + 2, 50), QStringLiteral("Downloading %1").arg(pkgName));
        } else if (line.startsWith(QStringLiteral("Upgrading ")) || line.startsWith(QStringLiteral("Installing "))) {
            QString pkg = line.section(QLatin1Char(' '), 1, 1);
            setProgress(qMin(m_progress + 3, 85), QStringLiteral("Upgrading %1").arg(pkg));
        } else if (line.startsWith(QStringLiteral("Configuring "))) {
            QString pkg = line.section(QLatin1Char(' '), 1, 1);
            setProgress(qMin(m_progress + 2, 98), QStringLiteral("Configuring %1").arg(pkg));
        }
    }
}

void OTADaemon::handleUpgradeFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);
    if (exitCode == 0) {
        setProgress(100, QStringLiteral("Complete"));
        setState(QStringLiteral("reboot_required"));
        setStatusMessage(QStringLiteral("AsteroidOS updated successfully! Reboot to apply changes."));
        Q_EMIT upgradeFinished(true, QString());
    } else {
        setState(QStringLiteral("error"));
        setStatusMessage(QStringLiteral("Upgrade encountered an error (exit code %1).").arg(exitCode));
        Q_EMIT upgradeFinished(false, m_statusMessage);
    }
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
        // Fallback
        QProcess::startDetached(QStringLiteral("systemctl"), QStringList() << QStringLiteral("reboot"));
    }
}
