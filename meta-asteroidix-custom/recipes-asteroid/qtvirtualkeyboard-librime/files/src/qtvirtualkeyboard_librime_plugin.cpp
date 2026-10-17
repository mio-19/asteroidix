#include "qtvirtualkeyboard_librime_plugin.h"
#include "rimeinputmethod.h"
#include <qqml.h>

RimeVirtualKeyboardPlugin::RimeVirtualKeyboardPlugin(QObject *parent)
    : QVirtualKeyboardExtensionPlugin(parent)
{
}

void RimeVirtualKeyboardPlugin::registerTypes(const char *uri) const
{
    qmlRegisterType<RimeInputMethod>(uri, 1, 0, "RimeInputMethod");
}
