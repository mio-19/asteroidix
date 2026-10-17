#include "otaclient.h"

#include <QDBusConnection>
#include <QDBusReply>
#include <QDebug>

OTAClient::OTAClient(QObject *parent)
    : QObject(parent)
    , m_state(QStringLiteral("idle"))
    , m_statusMessage(QStringLiteral("Checking for updates..."))
    , m_progress(0)
    , m_currentStep(QString())
    , m_upgradableCount(0)
    , m_batteryLevel(100)
    , m_isCharging(true)
    , m_networkAvailable(false)
    , m_networkType(QStringLiteral("None"))
    , m_iface(nullptr)
{
    m_iface = new QDBusInterface(
        QStringLiteral("org.asteroidos.OTA1"),
        QStringLiteral("/org/asteroidos/OTA1"),
        QStringLiteral("org.asteroidos.OTA1"),
        QDBusConnection::systemBus(),
        this
    );

    if (m_iface->isValid()) {
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("stateChanged"),
            this, SLOT(onStateChanged(QString))
        );
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("statusMessageChanged"),
            this, SLOT(onStatusMessageChanged(QString))
        );
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("progressChanged"),
            this, SLOT(onProgressChanged(int,QString))
        );
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("checkFinished"),
            this, SLOT(onCheckFinished(int,QStringList,QString))
        );
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("upgradeFinished"),
            this, SLOT(onUpgradeFinished(bool,QString))
        );
    } else {
        qWarning() << "OTAClient: Cannot connect to org.asteroidos.OTA1 D-Bus service:" << m_iface->lastError().message();
    }

    refresh();
}

void OTAClient::refresh()
{
    fetchDaemonState();
}

void OTAClient::fetchDaemonState()
{
    if (!m_iface || !m_iface->isValid()) {
        m_state = QStringLiteral("error");
        m_statusMessage = QStringLiteral("OTA update service not running.");
        Q_EMIT stateChanged();
        Q_EMIT statusMessageChanged();
        return;
    }

    QDBusReply<QString> stateReply = m_iface->call(QStringLiteral("GetState"));
    if (stateReply.isValid()) {
        m_state = stateReply.value();
        Q_EMIT stateChanged();
    }

    QDBusReply<QString> msgReply = m_iface->call(QStringLiteral("GetStatusMessage"));
    if (msgReply.isValid()) {
        m_statusMessage = msgReply.value();
        Q_EMIT statusMessageChanged();
    }

    QDBusReply<int> progReply = m_iface->call(QStringLiteral("GetProgress"));
    if (progReply.isValid()) {
        m_progress = progReply.value();
        Q_EMIT progressChanged();
    }

    QDBusReply<QString> stepReply = m_iface->call(QStringLiteral("GetCurrentStep"));
    if (stepReply.isValid()) {
        m_currentStep = stepReply.value();
        Q_EMIT currentStepChanged();
    }

    QDBusReply<int> countReply = m_iface->call(QStringLiteral("GetUpgradableCount"));
    if (countReply.isValid()) {
        m_upgradableCount = countReply.value();
        Q_EMIT upgradableCountChanged();
    }

    QDBusReply<QStringList> pkgsReply = m_iface->call(QStringLiteral("GetUpgradablePackages"));
    if (pkgsReply.isValid()) {
        m_upgradablePackages = pkgsReply.value();
        Q_EMIT upgradablePackagesChanged();
    }

    QDBusReply<int> batReply = m_iface->call(QStringLiteral("GetBatteryLevel"));
    if (batReply.isValid()) {
        m_batteryLevel = batReply.value();
    }

    QDBusReply<bool> chargeReply = m_iface->call(QStringLiteral("IsCharging"));
    if (chargeReply.isValid()) {
        m_isCharging = chargeReply.value();
    }

    QDBusReply<bool> netReply = m_iface->call(QStringLiteral("IsNetworkAvailable"));
    if (netReply.isValid()) {
        m_networkAvailable = netReply.value();
    }

    QDBusReply<QString> netTypeReply = m_iface->call(QStringLiteral("GetNetworkType"));
    if (netTypeReply.isValid()) {
        m_networkType = netTypeReply.value();
    }

    Q_EMIT statsChanged();
}

void OTAClient::checkForUpdates()
{
    if (m_iface && m_iface->isValid()) {
        m_state = QStringLiteral("checking");
        m_statusMessage = QStringLiteral("Checking for updates...");
        Q_EMIT stateChanged();
        Q_EMIT statusMessageChanged();
        m_iface->call(QStringLiteral("CheckForUpdates"));
    } else {
        refresh();
    }
}

void OTAClient::startUpgrade()
{
    if (m_iface && m_iface->isValid()) {
        m_state = QStringLiteral("upgrading");
        m_statusMessage = QStringLiteral("Starting upgrade...");
        m_progress = 5;
        Q_EMIT stateChanged();
        Q_EMIT statusMessageChanged();
        Q_EMIT progressChanged();
        m_iface->call(QStringLiteral("StartUpgrade"));
    }
}

void OTAClient::rebootWatch()
{
    if (m_iface && m_iface->isValid()) {
        m_iface->call(QStringLiteral("Reboot"));
    }
}

void OTAClient::onStateChanged(const QString &newState)
{
    if (m_state != newState) {
        m_state = newState;
        Q_EMIT stateChanged();
    }
}

void OTAClient::onStatusMessageChanged(const QString &msg)
{
    if (m_statusMessage != msg) {
        m_statusMessage = msg;
        Q_EMIT statusMessageChanged();
    }
}

void OTAClient::onProgressChanged(int percent, const QString &step)
{
    m_progress = percent;
    m_currentStep = step;
    Q_EMIT progressChanged();
    Q_EMIT currentStepChanged();
}

void OTAClient::onCheckFinished(int count, const QStringList &packages, const QString &error)
{
    m_upgradableCount = count;
    m_upgradablePackages = packages;
    Q_EMIT upgradableCountChanged();
    Q_EMIT upgradablePackagesChanged();

    if (!error.isEmpty()) {
        m_state = QStringLiteral("error");
        m_statusMessage = error;
    } else if (count == 0) {
        m_state = QStringLiteral("up_to_date");
        m_statusMessage = QStringLiteral("AsteroidOS is up to date");
    } else {
        m_state = QStringLiteral("available");
        m_statusMessage = QStringLiteral("%1 update(s) available").arg(count);
    }

    Q_EMIT stateChanged();
    Q_EMIT statusMessageChanged();
}

void OTAClient::onUpgradeFinished(bool success, const QString &error)
{
    if (success) {
        m_state = QStringLiteral("reboot_required");
        m_statusMessage = QStringLiteral("Upgrade complete! Reboot to apply.");
    } else {
        m_state = QStringLiteral("error");
        m_statusMessage = error.isEmpty() ? QStringLiteral("Upgrade failed.") : error;
    }

    Q_EMIT stateChanged();
    Q_EMIT statusMessageChanged();
}
