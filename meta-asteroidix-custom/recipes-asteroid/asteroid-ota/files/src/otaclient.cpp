#include "otaclient.h"

#include <QDBusConnection>
#include <QDBusReply>
#include <QDebug>

OTAClient::OTAClient(QObject *parent)
    : QObject(parent)
    , m_state(QStringLiteral("idle"))
    , m_statusMessage(QStringLiteral("Ready to update"))
    , m_progress(0)
    , m_currentStep(QString())
    , m_imageSource(QString())
    , m_machineName(QStringLiteral("hoki"))
    , m_defaultSource(QString())
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
            QStringLiteral("imageSourceChanged"),
            this, SLOT(onImageSourceChanged(QString))
        );
        QDBusConnection::systemBus().connect(
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("/org/asteroidos/OTA1"),
            QStringLiteral("org.asteroidos.OTA1"),
            QStringLiteral("updateFinished"),
            this, SLOT(onUpdateFinished(bool,QString))
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

    QDBusReply<QString> machReply = m_iface->call(QStringLiteral("GetMachineName"));
    if (machReply.isValid()) {
        m_machineName = machReply.value();
        Q_EMIT machineNameChanged();
    }

    QDBusReply<QString> defReply = m_iface->call(QStringLiteral("GetDefaultImageSource"));
    if (defReply.isValid()) {
        m_defaultSource = defReply.value();
    }

    QDBusReply<QString> srcReply = m_iface->call(QStringLiteral("GetImageSource"));
    if (srcReply.isValid()) {
        m_imageSource = srcReply.value();
        Q_EMIT imageSourceChanged();
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

void OTAClient::setImageSource(const QString &source)
{
    if (m_iface && m_iface->isValid()) {
        m_iface->call(QStringLiteral("SetImageSource"), source);
        m_imageSource = source;
        Q_EMIT imageSourceChanged();
    }
}

void OTAClient::startImageUpdate(const QString &source)
{
    if (m_iface && m_iface->isValid()) {
        QString s = source.isEmpty() ? m_imageSource : source;
        m_state = QStringLiteral("downloading");
        m_statusMessage = QStringLiteral("Starting update...");
        m_progress = 1;
        Q_EMIT stateChanged();
        Q_EMIT statusMessageChanged();
        Q_EMIT progressChanged();
        m_iface->call(QStringLiteral("StartImageUpdate"), s);
    }
}

void OTAClient::cancelUpdate()
{
    if (m_iface && m_iface->isValid()) {
        m_iface->call(QStringLiteral("CancelUpdate"));
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

void OTAClient::onImageSourceChanged(const QString &newSource)
{
    if (m_imageSource != newSource) {
        m_imageSource = newSource;
        Q_EMIT imageSourceChanged();
    }
}

void OTAClient::onUpdateFinished(bool success, const QString &error)
{
    if (success) {
        m_state = QStringLiteral("reboot_required");
        m_statusMessage = QStringLiteral("New OS image applied! Reboot to complete.");
    } else {
        m_state = QStringLiteral("error");
        m_statusMessage = error.isEmpty() ? QStringLiteral("Update failed.") : error;
    }

    Q_EMIT stateChanged();
    Q_EMIT statusMessageChanged();
}
