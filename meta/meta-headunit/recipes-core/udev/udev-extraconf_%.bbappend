FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://99-usb-automount.rules \
    file://usb-mount@.service \
    file://usb-unmount@.service \
    file://usb-mount.sh \
"

do_install:append() {
    # Install udev rules
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-usb-automount.rules ${D}${sysconfdir}/udev/rules.d/

    # Install systemd service files
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/usb-mount@.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/usb-unmount@.service ${D}${systemd_system_unitdir}/

    # Install mount script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/usb-mount.sh ${D}${bindir}/
}

FILES:${PN} += " \
    ${sysconfdir}/udev/rules.d/99-usb-automount.rules \
    ${systemd_system_unitdir}/usb-mount@.service \
    ${systemd_system_unitdir}/usb-unmount@.service \
    ${bindir}/usb-mount.sh \
"
