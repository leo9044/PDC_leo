SUMMARY = "Waveshare 7.9inch DSI LCD Driver"
DESCRIPTION = "Device tree overlays and kernel modules for Waveshare 7.9 inch DSI LCD Model 22293"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
    file://WS_xinchDSI_Screen.dtbo \
    file://WS_xinchDSI_Touch.dtbo \
    file://WS_xinchDSI_Screen.ko \
    file://WS_xinchDSI_Screen_Interface.ko \
    file://WS_xinchDSI_Touch.ko \
    file://WS_xinchDSI_Touch_Interface.ko \
"

S = "${WORKDIR}"

# Kernel modules are architecture-specific, do NOT inherit allarch
PACKAGE_ARCH = "${MACHINE_ARCH}"

KERNEL_MODULE_AUTOLOAD += "WS_xinchDSI_Screen WS_xinchDSI_Screen_Interface WS_xinchDSI_Touch WS_xinchDSI_Touch_Interface"

# Add dependency on kernel to get correct version
DEPENDS = "virtual/kernel"
RDEPENDS:${PN} += "kernel-module-i2c-dev"

# Inherit module class to get proper kernel variables and deploy class for overlay deployment
inherit module-base deploy

do_install() {
    # Use KERNEL_VERSION from module-base class (includes -v8 suffix)
    install -d ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Screen.ko ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Screen_Interface.ko ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Touch.ko ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Touch_Interface.ko ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
}

do_deploy() {
    # Deploy device tree overlays to boot partition
    install -d ${DEPLOYDIR}/overlays
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Screen.dtbo ${DEPLOYDIR}/overlays/
    install -m 0644 ${WORKDIR}/WS_xinchDSI_Touch.dtbo ${DEPLOYDIR}/overlays/
}

addtask deploy after do_install before do_build

FILES:${PN} += " \
    ${nonarch_base_libdir}/modules/*/extra/*.ko \
"

# Prevent QA warnings
INSANE_SKIP:${PN} += "already-stripped"
