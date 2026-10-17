#pragma once

#include <QVirtualKeyboardAbstractInputMethod>
#include <QVirtualKeyboardInputContext>
#include <QVirtualKeyboardInputEngine>
#include <QVirtualKeyboardSelectionListModel>
#include <QStringList>
#include <rime_api.h>

class RimeInputMethod : public QVirtualKeyboardAbstractInputMethod
{
    Q_OBJECT
    Q_PROPERTY(QString currentSchema READ currentSchema WRITE setSchema NOTIFY schemaChanged)
    Q_PROPERTY(QStringList availableSchemas READ availableSchemas NOTIFY availableSchemasChanged)

public:
    explicit RimeInputMethod(QObject *parent = nullptr);
    ~RimeInputMethod() override;

    QList<QVirtualKeyboardInputEngine::InputMode> inputModes(const QString &locale) override;
    bool setInputMode(const QString &locale, QVirtualKeyboardInputEngine::InputMode inputMode) override;
    bool setTextCase(QVirtualKeyboardInputEngine::TextCase textCase) override;
    bool keyEvent(Qt::Key key, const QString &text, Qt::KeyboardModifiers modifiers) override;

    QList<QVirtualKeyboardSelectionListModel::Type> selectionLists() override;
    int selectionListItemCount(QVirtualKeyboardSelectionListModel::Type type) override;
    QVariant selectionListData(QVirtualKeyboardSelectionListModel::Type type, int index, QVirtualKeyboardSelectionListModel::Role role) override;
    void selectionListItemSelected(QVirtualKeyboardSelectionListModel::Type type, int index) override;
    bool reselect(int cursorPosition, const QVirtualKeyboardInputEngine::ReselectFlags &reselectFlags) override;
    void reset() override;
    void update() override;

    QString currentSchema() const;
    void setSchema(const QString &schemaId);
    QStringList availableSchemas() const;

signals:
    void schemaChanged();
    void availableSchemasChanged();

private:
    void initRime();
    void updateCandidates();

    RimeApi *m_rimeApi;
    RimeSessionId m_sessionId;
    bool m_rimeInitialized;
    QString m_locale;
    QVirtualKeyboardInputEngine::InputMode m_inputMode;
    QVirtualKeyboardInputEngine::TextCase m_textCase;
    QStringList m_candidates;
    int m_highlightedCandidate;
    QString m_currentSchema;
};
