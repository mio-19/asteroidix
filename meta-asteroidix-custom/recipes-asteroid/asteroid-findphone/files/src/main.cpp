#include "findphoneclient.h"

#include <asteroidapp.h>

#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QScreen>

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(AsteroidApp::application(argc, argv));
    QScopedPointer<QQuickView> view(AsteroidApp::createView());

    FindPhoneClient client;
    view->rootContext()->setContextProperty(QStringLiteral("findPhone"), &client);
    view->setSource(QUrl(QStringLiteral("qrc:/Findphone/main.qml")));
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
