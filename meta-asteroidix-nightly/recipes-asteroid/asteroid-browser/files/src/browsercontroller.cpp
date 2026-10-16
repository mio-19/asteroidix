#include "browsercontroller.h"

#include <QRegularExpression>
#include <QNetworkRequest>
#include <QUrlQuery>

BrowserController::BrowserController(QObject *parent)
    : QObject(parent)
{
    m_pageTitle = QStringLiteral("AsteroidOS Browser");
    m_pageContent = QStringLiteral(
        "<h2 style='text-align:center;'>AsteroidOS Web</h2>"
        "<p style='text-align:center; color:#88aacc;'>Lightweight web browser designed for smartwatches.</p>"
        "<hr/>"
        "<p><b>Quick Links:</b></p>"
        "<ul>"
        "<li><a href='https://asteroidos.org'>AsteroidOS Project</a></li>"
        "<li><a href='https://en.m.wikipedia.org'>Wikipedia Mobile</a></li>"
        "<li><a href='https://news.ycombinator.com'>Hacker News</a></li>"
        "<li><a href='https://wttr.in/?format=3'>Weather</a></li>"
        "</ul>"
    );
}

void BrowserController::load(const QString &input)
{
    QString trimmed = input.trimmed();
    if (trimmed.isEmpty())
        return;

    QUrl url;
    if (trimmed.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive) ||
        trimmed.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive) ||
        trimmed.startsWith(QStringLiteral("file://"), Qt::CaseInsensitive)) {
        url = QUrl(trimmed);
    } else if (trimmed.contains(QLatin1Char('.')) && !trimmed.contains(QLatin1Char(' '))) {
        url = QUrl(QStringLiteral("https://") + trimmed);
    } else {
        // Fallback to DuckDuckGo HTML Lite search
        url = QUrl(QStringLiteral("https://html.duckduckgo.com/html/"));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("q"), trimmed);
        url.setQuery(query);
    }

    fetchUrl(url, true);
}

void BrowserController::reload()
{
    if (!m_currentUrl.isEmpty()) {
        fetchUrl(QUrl(m_currentUrl), false);
    }
}

void BrowserController::goBack()
{
    if (canGoBack()) {
        m_historyIndex--;
        emit historyChanged();
        fetchUrl(QUrl(m_history.at(m_historyIndex)), false);
    }
}

void BrowserController::goForward()
{
    if (canGoForward()) {
        m_historyIndex++;
        emit historyChanged();
        fetchUrl(QUrl(m_history.at(m_historyIndex)), false);
    }
}

void BrowserController::stop()
{
    if (m_activeReply) {
        m_activeReply->abort();
        m_activeReply->deleteLater();
        m_activeReply = nullptr;
    }
    m_loading = false;
    emit loadingChanged();
}

void BrowserController::fetchUrl(const QUrl &url, bool addToHistory)
{
    stop();

    m_currentUrl = url.toString();
    emit currentUrlChanged();

    if (addToHistory) {
        while (m_history.size() > m_historyIndex + 1) {
            m_history.removeLast();
        }
        m_history.append(m_currentUrl);
        m_historyIndex = m_history.size() - 1;
        emit historyChanged();
    }

    m_loading = true;
    m_statusMessage = QStringLiteral("Loading...");
    emit loadingChanged();
    emit statusMessageChanged();

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader,
        QStringLiteral("Mozilla/5.0 (Smartwatch; AsteroidOS; Linux) AsteroidBrowser/1.0"));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    m_activeReply = m_netManager.get(request);
    connect(m_activeReply, &QNetworkReply::finished, this, &BrowserController::onReplyFinished);
}

void BrowserController::onReplyFinished()
{
    if (!m_activeReply)
        return;

    m_loading = false;
    emit loadingChanged();

    if (m_activeReply->error() != QNetworkReply::NoError) {
        m_statusMessage = QStringLiteral("Error: ") + m_activeReply->errorString();
        m_pageContent = QStringLiteral("<h3 style='color:#ff6666;'>Failed to load page</h3><p>") +
                        m_activeReply->errorString() + QStringLiteral("</p>");
        emit statusMessageChanged();
        emit pageContentChanged();
        m_activeReply->deleteLater();
        m_activeReply = nullptr;
        return;
    }

    // Check for redirects
    QVariant redirectTarget = m_activeReply->attribute(QNetworkRequest::RedirectionTargetAttribute);
    if (!redirectTarget.isNull()) {
        QUrl redirectedUrl = m_activeReply->url().resolved(redirectTarget.toUrl());
        m_activeReply->deleteLater();
        m_activeReply = nullptr;
        fetchUrl(redirectedUrl, false);
        return;
    }

    QByteArray rawData = m_activeReply->readAll();
    QString html = QString::fromUtf8(rawData);
    QUrl baseUrl = m_activeReply->url();

    m_activeReply->deleteLater();
    m_activeReply = nullptr;

    // Extract title
    static const QRegularExpression titleRegex(QStringLiteral("<title[^>]*>(.*?)</title>"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    auto titleMatch = titleRegex.match(html);
    if (titleMatch.hasMatch()) {
        m_pageTitle = titleMatch.captured(1).trimmed();
    } else {
        m_pageTitle = baseUrl.host();
    }
    emit pageTitleChanged();

    m_pageContent = cleanAndFormatHtml(html, baseUrl);
    m_statusMessage = QStringLiteral("Done");
    emit statusMessageChanged();
    emit pageContentChanged();
}

QString BrowserController::cleanAndFormatHtml(const QString &rawHtml, const QUrl &baseUrl)
{
    QString doc = rawHtml;

    // Remove <script> and <style> tags and content
    static const QRegularExpression scriptRegex(QStringLiteral("<script[^>]*>.*?</script>"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression styleRegex(QStringLiteral("<style[^>]*>.*?</style>"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression svgRegex(QStringLiteral("<svg[^>]*>.*?</svg>"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    doc.remove(scriptRegex);
    doc.remove(styleRegex);
    doc.remove(svgRegex);

    // Resolve relative links: href="/path" -> href="https://example.com/path"
    static const QRegularExpression hrefRegex(QStringLiteral("href=([\"'])(.*?)([\"'])"), QRegularExpression::CaseInsensitiveOption);
    QString result;
    int lastPos = 0;
    auto it = hrefRegex.globalMatch(doc);
    while (it.hasNext()) {
        auto match = it.next();
        result.append(doc.sliced(lastPos, match.capturedStart() - lastPos));
        QString link = match.captured(2);
        if (link.startsWith(QLatin1String("//"))) {
            link = baseUrl.scheme() + QLatin1String(":") + link;
        } else if (link.startsWith(QLatin1Char('/')) || (!link.contains(QLatin1String("://")) && !link.startsWith(QLatin1String("mailto:")))) {
            link = baseUrl.resolved(QUrl(link)).toString();
        }
        result.append(QStringLiteral("href=\"") + link + QStringLiteral("\""));
        lastPos = match.capturedEnd();
    }
    result.append(doc.sliced(lastPos));
    return result;
}
