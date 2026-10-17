#pragma once

#include <QVirtualKeyboardExtensionPlugin>

class RimeVirtualKeyboardPlugin : public QVirtualKeyboardExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.qt.virtualkeyboard.plugin/6.0" FILE "plugin.json")
    Q_INTERFACES(QVirtualKeyboardExtensionPlugin)

public:
    explicit RimeVirtualKeyboardPlugin(QObject *parent = nullptr);
    void registerTypes(const char *uri) const override;
};
