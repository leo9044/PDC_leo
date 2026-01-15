SUMMARY = "Head Unit Linux Image"
DESCRIPTION = "Custom Linux image for Raspberry Pi with dual-display support (HDMI-1: Head Unit, HDMI-2: Instrument Cluster)"

# Inherit all common headunit image configuration from custom class
inherit headunit-image

# ECU2 Applications for dual-display setup
IMAGE_INSTALL:append = " \
    hu-mainapp \
    ambientapp \
    gearapp \
    mediaapp \
    homescreenapp \
    ic-app \
    vsomeip-config \
    vsomeip-routingmanager \
    systemd-network-config \
    udev-touchscreen-calibration \
    \
    fontconfig \
    fontconfig-utils \
    ttf-dejavu-sans \
    ttf-dejavu-sans-mono \
    ttf-dejavu-serif \
    liberation-fonts \
    qtsvg \
    qtsvg-plugins \
    qtimageformats-plugins \
"
