FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_deploy:append() {
    # Waveshare 7" HDMI LCD 1024x600 Configuration
    # Need to update BOTH bootfiles directories used by meta-raspberrypi

    for bootdir in bcm2835-bootfiles bootfiles; do
        # Ensure directory exists
        mkdir -p ${DEPLOYDIR}/${bootdir}

        # Ensure config.txt exists
        if [ ! -f ${DEPLOYDIR}/${bootdir}/config.txt ]; then
            touch ${DEPLOYDIR}/${bootdir}/config.txt
        fi

        # Add Waveshare HDMI display configuration
        if ! grep -q "^hdmi_group=2" ${DEPLOYDIR}/${bootdir}/config.txt; then
            echo "" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "# Waveshare 7\" HDMI LCD 1024x600 Configuration (Head Unit)" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "hdmi_group=2" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "hdmi_mode=87" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "hdmi_cvt=1024 600 60 6 0 0 0" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "hdmi_drive=1" >> ${DEPLOYDIR}/${bootdir}/config.txt
        fi

        # Add Waveshare 7.9\" DSI LCD Configuration (Instrument Cluster)
        # Model: 22293 - 1280x400 DSI display with ST7701S controller
        # Using kernel 6.1+ built-in driver (no custom modules needed)
        # Reference: Head-Unit-Team1 implementation
        if ! grep -q "dtoverlay=vc4-kms-dsi-waveshare-panel" ${DEPLOYDIR}/${bootdir}/config.txt; then
            echo "" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "# Waveshare 7.9\" DSI LCD 1280x400 Configuration (Instrument Cluster)" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "dtparam=i2c_arm=on" >> ${DEPLOYDIR}/${bootdir}/config.txt
            echo "dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch" >> ${DEPLOYDIR}/${bootdir}/config.txt
        fi
    done
}
