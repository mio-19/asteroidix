#include "findphoneclient.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>

FindPhoneClient::FindPhoneClient(QObject *parent)
    : QObject(parent), m_ringing(false), m_status(QStringLiteral("Find phone"))
{
    m_stopTimer.setSingleShot(true);
    m_stopTimer.setInterval(30000);
    connect(&m_stopTimer, &QTimer::timeout, this, [this] {
        setRinging(false);
        setStatus(QStringLiteral("Find phone"));
    });
}

void FindPhoneClient::ring()
{
    if (!call("Ring"))
        return;
    setRinging(true);
    m_stopTimer.start();
}

void FindPhoneClient::stop()
{
    m_stopTimer.stop();
    if (call("Stop"))
        setRinging(false);
}

bool FindPhoneClient::call(const char *method)
{
    QDBusInterface iface(QStringLiteral("org.asteroidos.findphone"),
                         QStringLiteral("/org/asteroidos/findphone"),
                         QStringLiteral("org.asteroidos.findphone"),
                         QDBusConnection::sessionBus());
    if (!iface.isValid()) {
        setStatus(QStringLiteral("Sync daemon unavailable"));
        return false;
    }

    QDBusReply<void> reply = iface.call(QString::fromLatin1(method));
    if (!reply.isValid()) {
        setStatus(reply.error().message());
        return false;
    }

    setStatus(QLatin1String(method) == QLatin1String("Ring") ? QStringLiteral("Ringing")
                                                             : QStringLiteral("Find phone"));
    return true;
}

void FindPhoneClient::setRinging(bool ringing)
{
    if (m_ringing == ringing)
        return;
    m_ringing = ringing;
    emit ringingChanged();
}

void FindPhoneClient::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}
