SUMMARY = "Head Unit Main Application - Wayland Compositor"
DESCRIPTION = "Qt5-based Wayland compositor for Head Unit automotive infotainment system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2 qtwayland"

# Use external source directory for local development
SRC_URI = "file://hu-mainapp-compositor.service \
           file://start-compositor.sh \
           file://eglfs-kms-hdmi.json"
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/HU_MainApp"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build"

inherit cmake_qt5 systemd externalsrc

# Qt5 specific settings
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "hu-mainapp-compositor.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/HU_MainApp_Compositor ${D}${bindir}/HU_MainApp_Compositor
    install -m 0755 ${WORKDIR}/start-compositor.sh ${D}${bindir}/start-compositor.sh

    # Install EGLFS KMS configuration for HDMI
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/eglfs-kms-hdmi.json ${D}${sysconfdir}/eglfs-kms-hdmi.json

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hu-mainapp-compositor.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = "${bindir}/HU_MainApp_Compositor ${bindir}/start-compositor.sh ${sysconfdir}/eglfs-kms-hdmi.json ${systemd_system_unitdir}/hu-mainapp-compositor.service"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2 qtwayland qtwayland-plugins systemd"

# Prevent stripping of Qt resource data
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
