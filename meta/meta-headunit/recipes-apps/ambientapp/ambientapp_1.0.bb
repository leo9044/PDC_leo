SUMMARY = "Ambient Lighting Application"
DESCRIPTION = "Qt5-based ambient lighting control application with CommonAPI SOME/IP communication"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia qtgraphicaleffects commonapi-core commonapi-someip-runtime vsomeip"

# Use external source directory for local development
SRC_URI = "file://ambientapp.service"
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/AmbientApp"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build"

inherit cmake_qt5 systemd externalsrc

# CommonAPI generated code path
EXTRA_OECMAKE += "-DCOMMONAPI_GEN_DIR=/home/seame/ChangGit2/DES_Head-Unit/commonapi/generated"
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "ambientapp.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/AmbientApp ${D}${bindir}/AmbientApp

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ambientapp.service ${D}${systemd_system_unitdir}/

    # Install CommonAPI configuration
    install -d ${D}${sysconfdir}
    install -m 0644 ${EXTERNALSRC}/commonapi_ambient.ini ${D}${sysconfdir}/commonapi-someip.ini
}

FILES:${PN} = "${bindir}/AmbientApp ${systemd_system_unitdir}/ambientapp.service ${sysconfdir}/commonapi-someip.ini"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia qtgraphicaleffects qtgraphicaleffects-qmlplugins qtsvg qtsvg-plugins qtwayland commonapi-core commonapi-someip-runtime vsomeip systemd"
