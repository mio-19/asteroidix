#include "otadaemon.h"

#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("asteroid-otad"));
    app.setOrganizationName(QStringLiteral("AsteroidOS"));

    OTADaemon daemon;
    if (!daemon.initDBus()) {
        qCritical() << "Failed to initialize D-Bus interface. Exiting.";
        return 1;
    }

    qInfo() << "AsteroidOS OTA Update Daemon (asteroid-otad) running...";
    return app.exec();
}
