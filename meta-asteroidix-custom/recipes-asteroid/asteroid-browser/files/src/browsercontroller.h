#pragma once

#include <QObject>
#include <QString>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringList>

class BrowserController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentUrl READ currentUrl NOTIFY currentUrlChanged)
    Q_PROPERTY(QString pageTitle READ pageTitle NOTIFY pageTitleChanged)
    Q_PROPERTY(QString pageContent READ pageContent NOTIFY pageContentChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY historyChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY historyChanged)

public:
    explicit BrowserController(QObject *parent = nullptr);
    ~BrowserController() override = default;

    QString currentUrl() const { return m_currentUrl; }
    QString pageTitle() const { return m_pageTitle; }
    QString pageContent() const { return m_pageContent; }
    bool loading() const { return m_loading; }
    QString statusMessage() const { return m_statusMessage; }
    bool canGoBack() const { return m_historyIndex > 0; }
    bool canGoForward() const { return m_historyIndex + 1 < m_history.size(); }

public slots:
    void load(const QString &input);
    void reload();
    void goBack();
    void goForward();
    void stop();

signals:
    void currentUrlChanged();
    void pageTitleChanged();
    void pageContentChanged();
    void loadingChanged();
    void statusMessageChanged();
    void historyChanged();

private slots:
    void onReplyFinished();

private:
    void fetchUrl(const QUrl &url, bool addToHistory = true);
    QString cleanAndFormatHtml(const QString &rawHtml, const QUrl &baseUrl);

    QNetworkAccessManager m_netManager;
    QNetworkReply *m_activeReply = nullptr;

    QString m_currentUrl;
    QString m_pageTitle;
    QString m_pageContent;
    bool m_loading = false;
    QString m_statusMessage;

    QStringList m_history;
    int m_historyIndex = -1;
};
