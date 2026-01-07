SUMMARY = "Instrument Cluster Application"
DESCRIPTION = "Qt5-based instrument cluster application with CommonAPI SOME/IP communication"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia commonapi-core commonapi-someip-runtime vsomeip"

# Use external source directory for local development
SRC_URI = "file://ic-app.service \
           file://eglfs-kms-dsi.json"
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/IC_app"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build"

inherit cmake_qt5 systemd externalsrc

# CommonAPI generated code path
EXTRA_OECMAKE += "-DCOMMONAPI_GEN_DIR=/home/seame/ChangGit2/DES_Head-Unit/commonapi/generated"
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "ic-app.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/IC_app ${D}${bindir}/IC_app

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ic-app.service ${D}${systemd_system_unitdir}/

    # Install EGLFS KMS configuration for DSI display
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/eglfs-kms-dsi.json ${D}${sysconfdir}/eglfs-kms-dsi.json
}

FILES:${PN} = "${bindir}/IC_app ${systemd_system_unitdir}/ic-app.service ${sysconfdir}/eglfs-kms-dsi.json"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia qtwayland commonapi-core commonapi-someip-runtime vsomeip systemd"
