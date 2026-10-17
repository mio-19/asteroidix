/*
 * This file is part of Asteroid Tack (ported from Tack Android).
 * Upstream: https://github.com/patzly/tack-android
 *
 * Copyright (c) 2020-2026 by Patrick Zedler
 * Qt/AsteroidOS port Copyright (c) 2026 AsteroidOS & Asteroidix Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "tackengine.h"

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

    TackEngine engine;
    view->rootContext()->setContextProperty(QStringLiteral("tackEngine"), &engine);

    QUrl source(QStringLiteral("qrc:/Tack/main.qml"));
    if (!QFile::exists(source.toLocalFile()) && !QFile::exists(QStringLiteral(":/Tack/main.qml"))) {
        if (QFile::exists(QStringLiteral(":/asteroid-tack/main.qml")))
            source = QUrl(QStringLiteral("qrc:/asteroid-tack/main.qml"));
        else if (QFile::exists(QStringLiteral(":/tack/main.qml")))
            source = QUrl(QStringLiteral("qrc:/tack/main.qml"));
    }
    view->setSource(source);
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
