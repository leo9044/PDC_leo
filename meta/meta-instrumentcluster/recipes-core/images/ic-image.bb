SUMMARY = "Instrument Cluster Test Image"
DESCRIPTION = "Minimal Linux image for testing IC_app standalone (OPTIONAL - for testing only)"

# Inherit from headunit-image class for base configuration
# This provides Qt5, middleware, system utilities, etc.
inherit headunit-image

# Instrument Cluster only (for standalone testing)
IMAGE_INSTALL:append = " \
    ic-app \
    vsomeip-config \
"

# NOTE: This image is OPTIONAL and only for IC standalone testing.
# For production dual-display ECU2, use headunit-image which includes both:
# - HDMI-1: Head Unit apps (HU_MainApp + clients)
# - HDMI-2: IC_app
