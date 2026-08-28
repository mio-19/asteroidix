FILESEXTRAPATHS:prepend := "${THISDIR}/systemd:"

# Same errno alias issue affects target systemd build on newer host headers.
SRC_URI:append = " file://0003-errno-list-filter-out-EFSBADCRC-and-EFSCORRUPTED.patch"
