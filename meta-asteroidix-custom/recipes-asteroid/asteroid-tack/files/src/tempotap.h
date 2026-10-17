/*
 * This file is part of Asteroid Tack (ported from Tack Android).
 * Upstream: https://github.com/patzly/tack-android
 *
 * Copyright (c) 2020-2026 by Patrick Zedler
 * Qt/AsteroidOS port Copyright (c) 2026 AsteroidOS & Asteroidix Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef TEMPOTAP_H
#define TEMPOTAP_H

#include <QObject>
#include <QQueue>
#include <QDateTime>

class TempoTap : public QObject
{
    Q_OBJECT
public:
    explicit TempoTap(QObject *parent = nullptr);

    Q_INVOKABLE int tap();
    Q_INVOKABLE void reset();

    int tempo() const;

private:
    qint64 averageInterval() const;
    bool shouldReset(qint64 interval) const;
    int intervalToTempo(qint64 interval) const;

    QQueue<qint64> m_intervals;
    qint64 m_previousTime = 0;

    static constexpr int MAX_TAPS = 20;
    static constexpr double TEMPO_FACTOR = 0.5;
    static constexpr int INTERVAL_FACTOR = 3;
};

#endif // TEMPOTAP_H
