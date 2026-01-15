SUMMARY = "Static IP configuration for Raspberry Pi"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://20-wired-static.network"

S = "${WORKDIR}"

inherit allarch systemd

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/20-wired-static.network ${D}${sysconfdir}/systemd/network/
}

FILES:${PN} = "${sysconfdir}/systemd/network/20-wired-static.network"

# Ensure systemd-networkd is enabled
RDEPENDS:${PN} = "systemd"

pkg_postinst_ontarget:${PN}() {
    # Enable and restart systemd-networkd to apply static IP
    systemctl enable systemd-networkd
    systemctl restart systemd-networkd
}
