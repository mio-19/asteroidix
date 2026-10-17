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
#include <QFile>
#include <QSettings>
#include <QDebug>
#include <algorithm>

TackEngine::TackEngine(QObject *parent)
    : QObject(parent)
{
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer, &QTimer::timeout, this, &TackEngine::onTick);

    // Default 4/4 signature with strong downbeat and 3 normal beats
    m_beatAccents = { TICK_STRONG, TICK_NORMAL, TICK_NORMAL, TICK_NORMAL };

    loadSettings();
}

TackEngine::~TackEngine()
{
    stop();
    saveSettings();
}

void TackEngine::setPlaying(bool playing)
{
    if (m_playing == playing) return;
    if (playing) {
        start();
    } else {
        stop();
    }
}

void TackEngine::start()
{
    if (m_playing) return;

    m_playing = true;
    m_currentBeat = 0;
    m_currentSubdivision = m_subdivisionsCount; // Will roll over to 1 on first tick
    emit playingChanged();

    // Trigger immediate first beat
    onTick();

    // Schedule subsequent ticks
    restartTimer();
}

void TackEngine::stop()
{
    if (!m_playing) return;

    m_playing = false;
    m_timer.stop();
    emit playingChanged();
}

void TackEngine::togglePlaying()
{
    if (m_playing) {
        stop();
    } else {
        start();
    }
}

void TackEngine::setTempo(int tempo)
{
    int bounded = std::clamp(tempo, TEMPO_MIN, TEMPO_MAX);
    if (m_tempo == bounded) return;

    m_tempo = bounded;
    emit tempoChanged();

    if (m_playing) {
        restartTimer();
    }
    saveSettings();
}

void TackEngine::changeTempo(int delta)
{
    setTempo(m_tempo + delta);
}

int TackEngine::tapTempo()
{
    int tapped = m_tempoTap.tap();
    if (tapped >= TEMPO_MIN && tapped <= TEMPO_MAX) {
        setTempo(tapped);
        return tapped;
    }
    return m_tempo;
}

void TackEngine::setBeatsCount(int count)
{
    int bounded = std::clamp(count, 1, BEATS_MAX);
    if (m_beatsCount == bounded) return;

    m_beatsCount = bounded;

    // Adjust accents array
    while (m_beatAccents.size() < m_beatsCount) {
        m_beatAccents.append(TICK_NORMAL);
    }
    while (m_beatAccents.size() > m_beatsCount) {
        m_beatAccents.removeLast();
    }

    emit beatsCountChanged();
    emit beatAccentsChanged();

    if (m_currentBeat > m_beatsCount) {
        m_currentBeat = 1;
        emit currentBeatChanged();
    }
    saveSettings();
}

void TackEngine::setSubdivisionsCount(int count)
{
    int bounded = std::clamp(count, 1, 4);
    if (m_subdivisionsCount == bounded) return;

    m_subdivisionsCount = bounded;
    emit subdivisionsCountChanged();

    if (m_playing) {
        restartTimer();
    }
    saveSettings();
}

void TackEngine::cycleBeatAccent(int index)
{
    if (index < 0 || index >= m_beatAccents.size()) return;

    int current = m_beatAccents.at(index);
    int next = TICK_NORMAL;
    switch (current) {
    case TICK_STRONG: next = TICK_NORMAL; break;
    case TICK_NORMAL: next = TICK_SUB; break;
    case TICK_SUB:    next = TICK_MUTED; break;
    case TICK_MUTED:  next = TICK_STRONG; break;
    default:          next = TICK_NORMAL; break;
    }
    m_beatAccents[index] = next;
    emit beatAccentsChanged();
    saveSettings();
}

void TackEngine::setBeatAccent(int index, int type)
{
    if (index < 0 || index >= m_beatAccents.size()) return;
    m_beatAccents[index] = type;
    emit beatAccentsChanged();
    saveSettings();
}

void TackEngine::setBeatMode(const QString &mode)
{
    if (m_beatMode == mode) return;
    m_beatMode = mode;
    emit beatModeChanged();
    saveSettings();
}

void TackEngine::setVibrationIntensity(const QString &intensity)
{
    if (m_vibrationIntensity == intensity) return;
    m_vibrationIntensity = intensity;
    emit vibrationIntensityChanged();
    saveSettings();
}

void TackEngine::setSoundPack(const QString &sound)
{
    if (m_soundPack == sound) return;
    m_soundPack = sound;
    emit soundPackChanged();
    saveSettings();
}

void TackEngine::setFlashScreen(bool flash)
{
    if (m_flashScreen == flash) return;
    m_flashScreen = flash;
    emit flashScreenChanged();
    saveSettings();
}

void TackEngine::setKeepAwake(bool keep)
{
    if (m_keepAwake == keep) return;
    m_keepAwake = keep;
    emit keepAwakeChanged();
    saveSettings();
}

void TackEngine::setGain(int gain)
{
    int bounded = std::clamp(gain, 0, 100);
    if (m_gain == bounded) return;
    m_gain = bounded;
    emit gainChanged();
    saveSettings();
}

void TackEngine::addBookmark()
{
    if (m_bookmarks.size() >= 10) return;

    // Check if duplicate exists
    for (const QVariant &bmVar : m_bookmarks) {
        QVariantMap bm = bmVar.toMap();
        if (bm.value(QStringLiteral("tempo")).toInt() == m_tempo &&
            bm.value(QStringLiteral("beats")).toInt() == m_beatsCount &&
            bm.value(QStringLiteral("subs")).toInt() == m_subdivisionsCount) {
            return;
        }
    }

    QVariantMap item;
    item.insert(QStringLiteral("tempo"), m_tempo);
    item.insert(QStringLiteral("beats"), m_beatsCount);
    item.insert(QStringLiteral("subs"), m_subdivisionsCount);

    QList<QVariant> accentsList;
    for (int acc : m_beatAccents) {
        accentsList.append(acc);
    }
    item.insert(QStringLiteral("accents"), accentsList);

    m_bookmarks.append(item);
    emit bookmarksChanged();
    saveSettings();
}

void TackEngine::deleteBookmark(int index)
{
    if (index >= 0 && index < m_bookmarks.size()) {
        m_bookmarks.removeAt(index);
        emit bookmarksChanged();
        saveSettings();
    }
}

void TackEngine::applyBookmark(int index)
{
    if (index < 0 || index >= m_bookmarks.size()) return;

    QVariantMap bm = m_bookmarks.at(index).toMap();
    setTempo(bm.value(QStringLiteral("tempo"), 120).toInt());
    setBeatsCount(bm.value(QStringLiteral("beats"), 4).toInt());
    setSubdivisionsCount(bm.value(QStringLiteral("subs"), 1).toInt());

    QVariantList accs = bm.value(QStringLiteral("accents")).toList();
    if (accs.size() == m_beatsCount) {
        m_beatAccents.clear();
        for (const QVariant &v : accs) {
            m_beatAccents.append(v.toInt());
        }
        emit beatAccentsChanged();
    }
}

void TackEngine::circulateBookmarks()
{
    if (m_bookmarks.isEmpty()) return;

    int currentIndex = -1;
    for (int i = 0; i < m_bookmarks.size(); ++i) {
        QVariantMap bm = m_bookmarks.at(i).toMap();
        if (bm.value(QStringLiteral("tempo")).toInt() == m_tempo &&
            bm.value(QStringLiteral("beats")).toInt() == m_beatsCount) {
            currentIndex = i;
            break;
        }
    }

    int nextIndex = (currentIndex + 1) % m_bookmarks.size();
    applyBookmark(nextIndex);
}

void TackEngine::restartTimer()
{
    if (!m_playing) return;
    int intervalMs = (60000 / m_tempo) / m_subdivisionsCount;
    if (intervalMs < 10) intervalMs = 10;
    m_timer.start(intervalMs);
}

void TackEngine::onTick()
{
    if (!m_playing) return;

    if (m_currentSubdivision >= m_subdivisionsCount) {
        m_currentSubdivision = 1;
        m_currentBeat = (m_currentBeat % m_beatsCount) + 1;
        emit currentBeatChanged();
    } else {
        m_currentSubdivision++;
    }
    emit currentSubdivisionChanged();

    int tickType = TICK_NORMAL;
    if (m_currentSubdivision == 1) {
        tickType = m_beatAccents.value(m_currentBeat - 1, TICK_NORMAL);
    } else {
        tickType = TICK_SUB;
    }

    m_isStrongBeat = (tickType == TICK_STRONG);

    // Emit tick and pulse signals
    emit tick(m_currentBeat, m_currentSubdivision, tickType);
    emit beatPulse(m_isStrongBeat);

    // Hardware vibration on watch
    if (tickType != TICK_MUTED && (m_beatMode == QLatin1String("both") || m_beatMode == QLatin1String("vibrate"))) {
        triggerHardwareVibration(tickType);
    }
}

void TackEngine::triggerHardwareVibration(int tickType)
{
    int durationMs = 25;
    if (tickType == TICK_STRONG) {
        durationMs = (m_vibrationIntensity == QLatin1String("strong")) ? 80 : 45;
    } else if (tickType == TICK_SUB) {
        durationMs = (m_vibrationIntensity == QLatin1String("soft")) ? 10 : 15;
    } else {
        durationMs = (m_vibrationIntensity == QLatin1String("strong")) ? 45 : 25;
    }

    vibrate(durationMs);
}

void TackEngine::vibrate(int durationMs)
{
    // Try Fossil Gen 6 (hoki) / Qualcomm sysfs timed_output paths
    static const QStringList paths = {
        QStringLiteral("/sys/class/timed_output/vibrator/enable"),
        QStringLiteral("/sys/devices/virtual/timed_output/vibrator/enable"),
        QStringLiteral("/sys/class/leds/vibrator/duration")
    };

    for (const QString &path : paths) {
        QFile file(path);
        if (file.open(QIODevice::WriteOnly | QIODevice::Unbuffered)) {
            file.write(QByteArray::number(durationMs));
            file.close();
            return;
        }
    }
}

void TackEngine::loadSettings()
{
    QSettings settings(QStringLiteral("AsteroidOS"), QStringLiteral("asteroid-tack"));
    m_tempo = settings.value(QStringLiteral("tempo"), 120).toInt();
    m_beatsCount = settings.value(QStringLiteral("beatsCount"), 4).toInt();
    m_subdivisionsCount = settings.value(QStringLiteral("subdivisionsCount"), 1).toInt();
    m_beatMode = settings.value(QStringLiteral("beatMode"), QStringLiteral("both")).toString();
    m_vibrationIntensity = settings.value(QStringLiteral("vibrationIntensity"), QStringLiteral("auto")).toString();
    m_soundPack = settings.value(QStringLiteral("soundPack"), QStringLiteral("wood")).toString();
    m_flashScreen = settings.value(QStringLiteral("flashScreen"), true).toBool();
    m_keepAwake = settings.value(QStringLiteral("keepAwake"), true).toBool();
    m_gain = settings.value(QStringLiteral("gain"), 100).toInt();

    QString accentsStr = settings.value(QStringLiteral("accents"), QStringLiteral("1,2,2,2")).toString();
    QStringList parts = accentsStr.split(QLatin1Char(','));
    m_beatAccents.clear();
    for (const QString &p : parts) {
        m_beatAccents.append(p.toInt());
    }
    while (m_beatAccents.size() < m_beatsCount) {
        m_beatAccents.append(TICK_NORMAL);
    }

    int bmCount = settings.beginReadArray(QStringLiteral("bookmarks"));
    m_bookmarks.clear();
    for (int i = 0; i < bmCount; ++i) {
        settings.setArrayIndex(i);
        QVariantMap bm;
        bm.insert(QStringLiteral("tempo"), settings.value(QStringLiteral("tempo")).toInt());
        bm.insert(QStringLiteral("beats"), settings.value(QStringLiteral("beats")).toInt());
        bm.insert(QStringLiteral("subs"), settings.value(QStringLiteral("subs")).toInt());
        m_bookmarks.append(bm);
    }
    settings.endArray();

    if (m_bookmarks.isEmpty()) {
        // Prepopulate with a few classic presets
        QVariantMap b1; b1[QStringLiteral("tempo")] = 120; b1[QStringLiteral("beats")] = 4; b1[QStringLiteral("subs")] = 1;
        QVariantMap b2; b2[QStringLiteral("tempo")] = 80;  b2[QStringLiteral("beats")] = 4; b2[QStringLiteral("subs")] = 1;
        QVariantMap b3; b3[QStringLiteral("tempo")] = 140; b3[QStringLiteral("beats")] = 3; b3[QStringLiteral("subs")] = 1;
        m_bookmarks.append(b1);
        m_bookmarks.append(b2);
        m_bookmarks.append(b3);
    }
}

void TackEngine::saveSettings()
{
    QSettings settings(QStringLiteral("AsteroidOS"), QStringLiteral("asteroid-tack"));
    settings.setValue(QStringLiteral("tempo"), m_tempo);
    settings.setValue(QStringLiteral("beatsCount"), m_beatsCount);
    settings.setValue(QStringLiteral("subdivisionsCount"), m_subdivisionsCount);
    settings.setValue(QStringLiteral("beatMode"), m_beatMode);
    settings.setValue(QStringLiteral("vibrationIntensity"), m_vibrationIntensity);
    settings.setValue(QStringLiteral("soundPack"), m_soundPack);
    settings.setValue(QStringLiteral("flashScreen"), m_flashScreen);
    settings.setValue(QStringLiteral("keepAwake"), m_keepAwake);
    settings.setValue(QStringLiteral("gain"), m_gain);

    QStringList accs;
    for (int a : m_beatAccents) {
        accs.append(QString::number(a));
    }
    settings.setValue(QStringLiteral("accents"), accs.join(QLatin1Char(',')));

    settings.beginWriteArray(QStringLiteral("bookmarks"), m_bookmarks.size());
    for (int i = 0; i < m_bookmarks.size(); ++i) {
        settings.setArrayIndex(i);
        QVariantMap bm = m_bookmarks.at(i).toMap();
        settings.setValue(QStringLiteral("tempo"), bm.value(QStringLiteral("tempo")));
        settings.setValue(QStringLiteral("beats"), bm.value(QStringLiteral("beats")));
        settings.setValue(QStringLiteral("subs"), bm.value(QStringLiteral("subs")));
    }
    settings.endArray();
}
