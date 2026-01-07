SUMMARY = "vsomeip - An implementation of Scalable service-Oriented MiddlewarE over IP"
DESCRIPTION = "vsomeip is an implementation of the SOME/IP protocol"
HOMEPAGE = "https://github.com/COVESA/vsomeip"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"

DEPENDS = "boost"

SRC_URI = "git://github.com/COVESA/vsomeip.git;protocol=https;branch=master"
SRCREV = "3.5.8"

S = "${WORKDIR}/git"

inherit cmake

EXTRA_OECMAKE = " \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DENABLE_SIGNAL_HANDLING=1 \
"

FILES:${PN} += " \
    ${libdir}/libvsomeip3*.so.* \
    ${sysconfdir}/vsomeip \
"

FILES:${PN}-dev += " \
    ${includedir}/vsomeip \
    ${libdir}/cmake/vsomeip3 \
"

BBCLASSEXTEND = "native nativesdk"
