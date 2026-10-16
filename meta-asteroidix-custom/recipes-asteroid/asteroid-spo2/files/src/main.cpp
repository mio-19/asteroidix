#include "spo2controller.h"

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

    SPO2Controller controller;
    view->rootContext()->setContextProperty(QStringLiteral("spo2Controller"), &controller);

    QUrl source(QStringLiteral("qrc:/Spo2/main.qml"));
    if (!QFile::exists(source.toLocalFile()) && !QFile::exists(QStringLiteral(":/Spo2/main.qml"))) {
        if (QFile::exists(QStringLiteral(":/asteroid-spo2/main.qml")))
            source = QUrl(QStringLiteral("qrc:/asteroid-spo2/main.qml"));
        else if (QFile::exists(QStringLiteral(":/spo2/main.qml")))
            source = QUrl(QStringLiteral("qrc:/spo2/main.qml"));
    }
    view->setSource(source);
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
