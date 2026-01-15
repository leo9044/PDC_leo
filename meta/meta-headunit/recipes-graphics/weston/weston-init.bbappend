FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Kiosk Shell configuration with socket activation
SRC_URI += "file://weston.ini \
            file://weston.service \
            file://weston.socket"

# Use both weston.service and weston.socket
SYSTEMD_SERVICE:${PN} = "weston.service weston.socket"

do_install:append() {
    install -d ${D}${sysconfdir}/xdg/weston
    install -m 0644 ${WORKDIR}/weston.ini ${D}${sysconfdir}/xdg/weston/weston.ini

    # Install custom weston.service and weston.socket
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/weston.service ${D}${systemd_system_unitdir}/weston.service
    install -m 0644 ${WORKDIR}/weston.socket ${D}${systemd_system_unitdir}/weston.socket
}

FILES:${PN} += "${sysconfdir}/xdg/weston/weston.ini \
                ${systemd_system_unitdir}/weston.service \
                ${systemd_system_unitdir}/weston.socket"
