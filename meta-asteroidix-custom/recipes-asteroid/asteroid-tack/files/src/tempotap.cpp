/*
 * This file is part of Asteroid Tack (ported from Tack Android).
 * Upstream: https://github.com/patzly/tack-android
 *
 * Copyright (c) 2020-2026 by Patrick Zedler
 * Qt/AsteroidOS port Copyright (c) 2026 AsteroidOS & Asteroidix Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "tempotap.h"
#include <algorithm>

TempoTap::TempoTap(QObject *parent)
    : QObject(parent)
{
}

int TempoTap::tap()
{
    const qint64 current = QDateTime::currentMSecsSinceEpoch();
    if (m_previousTime > 0) {
        const qint64 interval = current - m_previousTime;
        if (!m_intervals.isEmpty() && shouldReset(interval)) {
            m_intervals.clear();
        } else if (m_intervals.size() >= MAX_TAPS) {
            m_intervals.dequeue();
        }
        m_intervals.enqueue(interval);
    }
    m_previousTime = current;
    return tempo();
}

void TempoTap::reset()
{
    m_intervals.clear();
    m_previousTime = 0;
}

int TempoTap::tempo() const
{
    return intervalToTempo(averageInterval());
}

qint64 TempoTap::averageInterval() const
{
    if (m_intervals.isEmpty()) {
        return 0;
    }
    qint64 sum = 0;
    for (qint64 val : m_intervals) {
        sum += val;
    }
    return sum / m_intervals.size();
}

int TempoTap::intervalToTempo(qint64 interval) const
{
    if (interval <= 0) {
        return 0;
    }
    return static_cast<int>(60000 / interval);
}

bool TempoTap::shouldReset(qint64 interval) const
{
    const int currentTempo = tempo();
    if (currentTempo <= 0) return false;

    const int newTempo = intervalToTempo(interval);
    const qint64 avg = averageInterval();

    return (newTempo >= currentTempo * (1.0 + TEMPO_FACTOR))
        || (newTempo <= currentTempo * (1.0 - TEMPO_FACTOR))
        || (avg > 0 && interval > avg * INTERVAL_FACTOR);
}
