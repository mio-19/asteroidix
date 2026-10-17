/*
 * This file is part of Asteroid Tack (ported from Tack Android).
 * Upstream: https://github.com/patzly/tack-android
 *
 * Copyright (c) 2020-2026 by Patrick Zedler
 * Qt/AsteroidOS port Copyright (c) 2026 AsteroidOS & Asteroidix Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef TACKENGINE_H
#define TACKENGINE_H

#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
#include <QStringList>
#include <QVariantList>
#include "tempotap.h"

class TackEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool playing READ isPlaying WRITE setPlaying NOTIFY playingChanged)
    Q_PROPERTY(int tempo READ tempo WRITE setTempo NOTIFY tempoChanged)
    Q_PROPERTY(int beatsCount READ beatsCount WRITE setBeatsCount NOTIFY beatsCountChanged)
    Q_PROPERTY(int subdivisionsCount READ subdivisionsCount WRITE setSubdivisionsCount NOTIFY subdivisionsCountChanged)
    Q_PROPERTY(int currentBeat READ currentBeat NOTIFY currentBeatChanged)
    Q_PROPERTY(int currentSubdivision READ currentSubdivision NOTIFY currentSubdivisionChanged)
    Q_PROPERTY(bool isStrongBeat READ isStrongBeat NOTIFY beatPulse)
    Q_PROPERTY(QList<int> beatAccents READ beatAccents NOTIFY beatAccentsChanged)
    Q_PROPERTY(QString beatMode READ beatMode WRITE setBeatMode NOTIFY beatModeChanged)
    Q_PROPERTY(QString vibrationIntensity READ vibrationIntensity WRITE setVibrationIntensity NOTIFY vibrationIntensityChanged)
    Q_PROPERTY(QString soundPack READ soundPack WRITE setSoundPack NOTIFY soundPackChanged)
    Q_PROPERTY(bool flashScreen READ flashScreen WRITE setFlashScreen NOTIFY flashScreenChanged)
    Q_PROPERTY(bool keepAwake READ keepAwake WRITE setKeepAwake NOTIFY keepAwakeChanged)
    Q_PROPERTY(int gain READ gain WRITE setGain NOTIFY gainChanged)
    Q_PROPERTY(QVariantList bookmarks READ bookmarks NOTIFY bookmarksChanged)

public:
    enum TickType {
        TICK_STRONG = 1,
        TICK_NORMAL = 2,
        TICK_SUB    = 3,
        TICK_MUTED  = 4
    };
    Q_ENUM(TickType)

    explicit TackEngine(QObject *parent = nullptr);
    ~TackEngine() override;

    bool isPlaying() const { return m_playing; }
    void setPlaying(bool playing);

    int tempo() const { return m_tempo; }
    void setTempo(int tempo);

    int beatsCount() const { return m_beatsCount; }
    void setBeatsCount(int count);

    int subdivisionsCount() const { return m_subdivisionsCount; }
    void setSubdivisionsCount(int count);

    int currentBeat() const { return m_currentBeat; }
    int currentSubdivision() const { return m_currentSubdivision; }
    bool isStrongBeat() const { return m_isStrongBeat; }

    QList<int> beatAccents() const { return m_beatAccents; }

    QString beatMode() const { return m_beatMode; }
    void setBeatMode(const QString &mode);

    QString vibrationIntensity() const { return m_vibrationIntensity; }
    void setVibrationIntensity(const QString &intensity);

    QString soundPack() const { return m_soundPack; }
    void setSoundPack(const QString &sound);

    bool flashScreen() const { return m_flashScreen; }
    void setFlashScreen(bool flash);

    bool keepAwake() const { return m_keepAwake; }
    void setKeepAwake(bool keep);

    int gain() const { return m_gain; }
    void setGain(int gain);

    QVariantList bookmarks() const { return m_bookmarks; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void togglePlaying();
    Q_INVOKABLE void changeTempo(int delta);
    Q_INVOKABLE int tapTempo();
    Q_INVOKABLE void cycleBeatAccent(int index);
    Q_INVOKABLE void setBeatAccent(int index, int type);
    Q_INVOKABLE void addBookmark();
    Q_INVOKABLE void deleteBookmark(int index);
    Q_INVOKABLE void applyBookmark(int index);
    Q_INVOKABLE void circulateBookmarks();
    Q_INVOKABLE void vibrate(int durationMs);

signals:
    void playingChanged();
    void tempoChanged();
    void beatsCountChanged();
    void subdivisionsCountChanged();
    void currentBeatChanged();
    void currentSubdivisionChanged();
    void beatAccentsChanged();
    void beatModeChanged();
    void vibrationIntensityChanged();
    void soundPackChanged();
    void flashScreenChanged();
    void keepAwakeChanged();
    void gainChanged();
    void bookmarksChanged();

    void tick(int beat, int subdivision, int tickType);
    void beatPulse(bool strong);

private slots:
    void onTick();

private:
    void restartTimer();
    void scheduleNextTick();
    void triggerHardwareVibration(int tickType);
    void loadSettings();
    void saveSettings();

    QTimer m_timer;
    TempoTap m_tempoTap;

    bool m_playing = false;
    int m_tempo = 120;
    int m_beatsCount = 4;
    int m_subdivisionsCount = 1;
    int m_currentBeat = 1;
    int m_currentSubdivision = 1;
    bool m_isStrongBeat = false;

    QList<int> m_beatAccents;

    QString m_beatMode = QStringLiteral("both"); // "both", "sound", "vibrate"
    QString m_vibrationIntensity = QStringLiteral("auto"); // "auto", "soft", "strong"
    QString m_soundPack = QStringLiteral("wood"); // "wood", "sine", "mechanical", "hands"
    bool m_flashScreen = true;
    bool m_keepAwake = true;
    int m_gain = 100;
    QVariantList m_bookmarks;

    static constexpr int TEMPO_MIN = 1;
    static constexpr int TEMPO_MAX = 600;
    static constexpr int BEATS_MAX = 20;
};

#endif // TACKENGINE_H
