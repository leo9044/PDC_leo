FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://pulseaudio.service \
    file://default.pa \
"

do_install:append() {
    # Install custom systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/pulseaudio.service ${D}${systemd_system_unitdir}/

    # Install custom PulseAudio configuration
    install -d ${D}${sysconfdir}/pulse
    install -m 0644 ${WORKDIR}/default.pa ${D}${sysconfdir}/pulse/system.pa

    # Create pulse user and group if not exists
    install -d ${D}${sysconfdir}/default
    echo 'PULSEAUDIO_SYSTEM_START=1' > ${D}${sysconfdir}/default/pulseaudio
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/pulseaudio.service \
    ${sysconfdir}/pulse/system.pa \
    ${sysconfdir}/default/pulseaudio \
"

SYSTEMD_SERVICE:${PN} = "pulseaudio.service"
