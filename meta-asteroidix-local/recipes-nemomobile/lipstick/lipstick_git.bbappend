# Pin before Qt6 (timed-qt6) and MDConfItem (mlite5 still ships MGConfItem).
SRCREV = "931657014a22dd27a6cccecac9b378784d762a74"

# These patches are already present in current AsteroidOS/lipstick master;
# applying them fails with "reversed or previously applied".
SRC_URI:remove = " \
    file://0001-Disables-tests-and-doc.patch \
    file://0002-notificationcategories-use-ion-icons.patch \
    file://0003-Disable-USB-mode-notifications-on-connect.patch \
    file://0004-ScreenshotService-Use-system-bus-to-workaround-the-s.patch \
    file://0005-BluetoothAgent-Advertise-less-hardware-capabilities-.patch \
"
