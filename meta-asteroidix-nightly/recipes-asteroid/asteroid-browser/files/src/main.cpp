#include "browsercontroller.h"

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

    BrowserController controller;
    view->rootContext()->setContextProperty(QStringLiteral("browserController"), &controller);

    QUrl source(QStringLiteral("qrc:/Browser/main.qml"));
    if (!QFile::exists(source.toLocalFile()) && !QFile::exists(QStringLiteral(":/Browser/main.qml"))) {
        if (QFile::exists(QStringLiteral(":/asteroid-browser/main.qml")))
            source = QUrl(QStringLiteral("qrc:/asteroid-browser/main.qml"));
        else if (QFile::exists(QStringLiteral(":/browser/main.qml")))
            source = QUrl(QStringLiteral("qrc:/browser/main.qml"));
    }
    view->setSource(source);
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
