/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
 *               2020 - MagneFire
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

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

    QUrl source(QStringLiteral("qrc:/asteroid-2048/main.qml"));
    if (!QFile::exists(source.toLocalFile()) && !QFile::exists(QStringLiteral(":/asteroid-2048/main.qml"))) {
        if (QFile::exists(QStringLiteral(":/2048/main.qml")))
            source = QUrl(QStringLiteral("qrc:/2048/main.qml"));
        else if (QFile::exists(QStringLiteral(":/main.qml")))
            source = QUrl(QStringLiteral("qrc:/main.qml"));
    }
    view->setSource(source);
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
