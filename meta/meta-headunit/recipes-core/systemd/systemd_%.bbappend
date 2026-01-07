FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://20-wired-static.network \
    file://20-eth0.network \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/20-wired-static.network ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${WORKDIR}/20-eth0.network ${D}${sysconfdir}/systemd/network/
}

FILES:${PN} += "${sysconfdir}/systemd/network/"
