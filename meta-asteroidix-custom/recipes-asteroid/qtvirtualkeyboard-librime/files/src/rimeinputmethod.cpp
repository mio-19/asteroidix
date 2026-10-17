#include "rimeinputmethod.h"
#include <QDir>
#include <QDebug>

RimeInputMethod::RimeInputMethod(QObject *parent)
    : QVirtualKeyboardAbstractInputMethod(parent)
    , m_rimeApi(nullptr)
    , m_sessionId(0)
    , m_rimeInitialized(false)
    , m_inputMode(QVirtualKeyboardInputEngine::InputMode::Latin)
    , m_textCase(QVirtualKeyboardInputEngine::TextCase::Lower)
    , m_highlightedCandidate(0)
{
    initRime();
}

RimeInputMethod::~RimeInputMethod()
{
    if (m_rimeInitialized && m_sessionId != 0 && m_rimeApi) {
        m_rimeApi->destroy_session(m_sessionId);
        m_sessionId = 0;
    }
}

void RimeInputMethod::initRime()
{
    if (m_rimeInitialized) {
        return;
    }

    m_rimeApi = rime_get_api();
    if (!m_rimeApi) {
        qWarning() << "RimeInputMethod: rime_get_api() returned null";
        return;
    }

    RIME_STRUCT(RimeTraits, traits);
    traits.shared_data_dir = "/usr/share/rime-data";
    QString userDir = QDir::homePath() + "/.config/asteroid-virtualkeyboard/rime";
    QDir().mkpath(userDir);
    QByteArray userDirBytes = userDir.toUtf8();
    traits.user_data_dir = userDirBytes.constData();
    traits.distribution_name = "AsteroidOS";
    traits.distribution_code_name = "asteroidix";
    traits.distribution_version = "1.0";
    traits.app_name = "rime.asteroid";

    m_rimeApi->setup(&traits);
    m_rimeApi->initialize(nullptr);

    // Run deployment/maintenance on initial startup to compile dictionaries
    if (m_rimeApi->start_maintenance(1)) {
        m_rimeApi->join_maintenance_thread();
    }

    m_sessionId = m_rimeApi->create_session();
    m_rimeInitialized = (m_sessionId != 0);

    if (m_rimeInitialized) {
        setSchema("pinyin_simp");
    }
}

QList<QVirtualKeyboardInputEngine::InputMode> RimeInputMethod::inputModes(const QString &locale)
{
    Q_UNUSED(locale);
    return {
        QVirtualKeyboardInputEngine::InputMode::Pinyin,
        QVirtualKeyboardInputEngine::InputMode::Stroke,
        QVirtualKeyboardInputEngine::InputMode::Cangjie,
        QVirtualKeyboardInputEngine::InputMode::Latin
    };
}

bool RimeInputMethod::setInputMode(const QString &locale, QVirtualKeyboardInputEngine::InputMode inputMode)
{
    m_locale = locale;
    m_inputMode = inputMode;

    if (!m_rimeInitialized) {
        initRime();
    }

    switch (inputMode) {
    case QVirtualKeyboardInputEngine::InputMode::Pinyin:
        setSchema("pinyin_simp");
        break;
    case QVirtualKeyboardInputEngine::InputMode::Stroke:
        setSchema("stroke");
        break;
    case QVirtualKeyboardInputEngine::InputMode::Cangjie:
        setSchema("wubi86");
        break;
    default:
        break;
    }

    emit inputModeChanged();
    return true;
}

bool RimeInputMethod::setTextCase(QVirtualKeyboardInputEngine::TextCase textCase)
{
    m_textCase = textCase;
    return true;
}

bool RimeInputMethod::keyEvent(Qt::Key key, const QString &text, Qt::KeyboardModifiers modifiers)
{
    Q_UNUSED(modifiers);

    if (m_inputMode == QVirtualKeyboardInputEngine::InputMode::Latin || !m_rimeInitialized || !m_rimeApi) {
        return false;
    }

    QVirtualKeyboardInputContext *ctx = inputContext();
    if (!ctx) {
        return false;
    }

    int rimeKey = 0;
    if (key == Qt::Key_Backspace) {
        rimeKey = 0xff08; // XK_BackSpace
    } else if (key == Qt::Key_Return || key == Qt::Key_Enter) {
        rimeKey = 0xff0d; // XK_Return
    } else if (key == Qt::Key_Space) {
        rimeKey = 0x0020; // XK_space
    } else if (!text.isEmpty()) {
        rimeKey = text.at(0).toLatin1();
        if (rimeKey == 0) {
            rimeKey = text.at(0).unicode();
        }
    }

    if (rimeKey == 0) {
        return false;
    }

    bool handled = m_rimeApi->process_key(m_sessionId, rimeKey, 0);

    // Commit any text produced
    RIME_STRUCT(RimeCommit, commit);
    if (m_rimeApi->get_commit(m_sessionId, &commit)) {
        if (commit.text) {
            ctx->commit(QString::fromUtf8(commit.text));
        }
        m_rimeApi->free_commit(&commit);
    }

    updateCandidates();
    return handled;
}

void RimeInputMethod::updateCandidates()
{
    QVirtualKeyboardInputContext *ctx = inputContext();
    if (!ctx || !m_rimeInitialized || !m_rimeApi) {
        return;
    }

    RIME_STRUCT(RimeContext, rimeCtx);
    if (m_rimeApi->get_context(m_sessionId, &rimeCtx)) {
        if (rimeCtx.composition.preedit) {
            ctx->setPreeditText(QString::fromUtf8(rimeCtx.composition.preedit));
        } else {
            ctx->setPreeditText(QString());
        }

        m_candidates.clear();
        for (int i = 0; i < rimeCtx.menu.num_candidates; ++i) {
            if (rimeCtx.menu.candidates[i].text) {
                m_candidates.append(QString::fromUtf8(rimeCtx.menu.candidates[i].text));
            }
        }
        m_highlightedCandidate = rimeCtx.menu.highlighted_candidate_index;

        emit selectionListChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidate);
        emit selectionListActiveItemChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidate, m_highlightedCandidate);

        m_rimeApi->free_context(&rimeCtx);
    } else {
        m_candidates.clear();
        ctx->setPreeditText(QString());
        emit selectionListChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidate);
    }
}

QList<QVirtualKeyboardSelectionListModel::Type> RimeInputMethod::selectionLists()
{
    return { QVirtualKeyboardSelectionListModel::Type::WordCandidate };
}

int RimeInputMethod::selectionListItemCount(QVirtualKeyboardSelectionListModel::Type type)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidate) {
        return m_candidates.size();
    }
    return 0;
}

QVariant RimeInputMethod::selectionListData(QVirtualKeyboardSelectionListModel::Type type, int index, QVirtualKeyboardSelectionListModel::Role role)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidate && index >= 0 && index < m_candidates.size()) {
        if (role == QVirtualKeyboardSelectionListModel::Role::Display) {
            return m_candidates.at(index);
        }
    }
    return QVariant();
}

void RimeInputMethod::selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type type, int index)
{
    if (type == QVirtualKeyboardSelectionListModel::Type::WordCandidate && m_rimeInitialized && m_rimeApi) {
        if (m_rimeApi->select_candidate(m_sessionId, index)) {
            QVirtualKeyboardInputContext *ctx = inputContext();
            RIME_STRUCT(RimeCommit, commit);
            if (m_rimeApi->get_commit(m_sessionId, &commit)) {
                if (commit.text && ctx) {
                    ctx->commit(QString::fromUtf8(commit.text));
                }
                m_rimeApi->free_commit(&commit);
            }
            updateCandidates();
        }
    }
}

bool RimeInputMethod::reselect(int cursorPosition, const QVirtualKeyboardInputEngine::ReselectFlags &reselectFlags)
{
    Q_UNUSED(cursorPosition);
    Q_UNUSED(reselectFlags);
    return false;
}

void RimeInputMethod::reset()
{
    if (m_rimeInitialized && m_sessionId != 0 && m_rimeApi) {
        m_rimeApi->clear_composition(m_sessionId);
        m_candidates.clear();
        emit selectionListChanged(QVirtualKeyboardSelectionListModel::Type::WordCandidate);
    }
}

void RimeInputMethod::update()
{
    updateCandidates();
}

QString RimeInputMethod::currentSchema() const
{
    return m_currentSchema;
}

void RimeInputMethod::setSchema(const QString &schemaId)
{
    if (m_currentSchema != schemaId && m_rimeInitialized && m_rimeApi) {
        m_currentSchema = schemaId;
        QByteArray schemaBytes = schemaId.toUtf8();
        m_rimeApi->select_schema(m_sessionId, schemaBytes.constData());
        emit schemaChanged();
    }
}

QStringList RimeInputMethod::availableSchemas() const
{
    return {
        "pinyin_simp",
        "luna_pinyin",
        "double_pinyin",
        "wubi86",
        "stroke"
    };
}
