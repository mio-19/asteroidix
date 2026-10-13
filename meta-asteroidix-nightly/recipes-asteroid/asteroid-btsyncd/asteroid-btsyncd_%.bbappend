FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# hoki is the watch mio uses. Other machines keep upstream asteroid-btsyncd.
SRC_URI:append:hoki = " file://0001-add-find-phone-service.patch"
