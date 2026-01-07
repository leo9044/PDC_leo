SUMMARY = "Home Screen Application"
DESCRIPTION = "Qt5-based home screen launcher application with CommonAPI SOME/IP communication"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia commonapi-core commonapi-someip-runtime vsomeip"

# Use external source directory for local development
SRC_URI = "file://homescreenapp.service"
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/HomeScreenApp"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build"

inherit cmake_qt5 systemd externalsrc

# CommonAPI generated code path
EXTRA_OECMAKE += "-DCOMMONAPI_GEN_DIR=/home/seame/ChangGit2/DES_Head-Unit/commonapi/generated"
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "homescreenapp.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/HomeScreenApp ${D}${bindir}/HomeScreenApp

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/homescreenapp.service ${D}${systemd_system_unitdir}/

    # Install CommonAPI configuration
    install -d ${D}${sysconfdir}
    install -m 0644 ${EXTERNALSRC}/commonapi_homescreen.ini ${D}${sysconfdir}/commonapi-homescreen.ini
}

FILES:${PN} = "${bindir}/HomeScreenApp ${systemd_system_unitdir}/homescreenapp.service ${sysconfdir}/commonapi-homescreen.ini"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2 qtmultimedia qtwayland commonapi-core commonapi-someip-runtime vsomeip systemd"
