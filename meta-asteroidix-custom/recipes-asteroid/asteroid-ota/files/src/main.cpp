#include "otaclient.h"

#include <asteroidapp.h>

#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QScreen>
#include <QFile>
#include <QUrl>

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(AsteroidApp::application(argc, argv));
    QScopedPointer<QQuickView> view(AsteroidApp::createView());

    OTAClient client;
    view->rootContext()->setContextProperty(QStringLiteral("otaClient"), &client);

    QUrl source(QStringLiteral("qrc:/Ota/main.qml"));
    if (!QFile::exists(source.toLocalFile()) && !QFile::exists(QStringLiteral(":/Ota/main.qml"))) {
        if (QFile::exists(QStringLiteral(":/asteroid-ota/main.qml")))
            source = QUrl(QStringLiteral("qrc:/asteroid-ota/main.qml"));
        else if (QFile::exists(QStringLiteral(":/ota/main.qml")))
            source = QUrl(QStringLiteral("qrc:/ota/main.qml"));
    }

    view->setSource(source);
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
