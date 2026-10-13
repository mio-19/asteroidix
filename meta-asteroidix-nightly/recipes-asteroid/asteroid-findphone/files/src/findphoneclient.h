#ifndef FINDPHONECLIENT_H
#define FINDPHONECLIENT_H

#include <QObject>
#include <QString>
#include <QTimer>

class FindPhoneClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ringing READ ringing NOTIFY ringingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit FindPhoneClient(QObject *parent = nullptr);

    bool ringing() const { return m_ringing; }
    QString status() const { return m_status; }

    Q_INVOKABLE void ring();
    Q_INVOKABLE void stop();

signals:
    void ringingChanged();
    void statusChanged();

private:
    bool call(const char *method);
    void setRinging(bool ringing);
    void setStatus(const QString &status);

    bool m_ringing;
    QString m_status;
    QTimer m_stopTimer;
};

#endif
