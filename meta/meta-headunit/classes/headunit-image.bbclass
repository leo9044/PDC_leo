# Headunit Image Class - Common configuration for all headunit images
# This class centralizes image configuration, reducing duplication across recipes

inherit core-image

# =====================================================================
# IMAGE FILE SYSTEM TYPES
# =====================================================================
IMAGE_FSTYPES = " \
    tar.bz2 \
    ext4 \
    rpi-sdimg \
"

# =====================================================================
# IMAGE SIZING
# =====================================================================
# Root filesystem size (in KB) - 1GB
IMAGE_ROOTFS_SIZE ?= "1048576"

# Extra space after root filesystem (in KB) - 100MB
IMAGE_ROOTFS_EXTRA_SPACE ?= "102400"

# Alignment in KB for proper SD card write
IMAGE_ROOTFS_ALIGNMENT ?= "10240"

# Overhead factor for image size calculation
IMAGE_OVERHEAD_FACTOR ?= "1.3"

# =====================================================================
# BASE PACKAGES FOR CORE FUNCTIONALITY
# =====================================================================
HEADUNIT_BASE_INSTALL = " \
    packagegroup-core-boot \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

# =====================================================================
# QT5 FRAMEWORK AND DEPENDENCIES
# =====================================================================
HEADUNIT_QT5_INSTALL = " \
    qtbase \
    qtbase-plugins \
    qtdeclarative \
    qtquickcontrols2 \
    qtmultimedia \
    qtwayland \
    qtwayland-plugins \
"

# =====================================================================
# COMMUNICATION MIDDLEWARE (SOME/IP + CommonAPI)
# =====================================================================
HEADUNIT_COMM_INSTALL = " \
    commonapi-core \
    commonapi-someip-runtime \
    vsomeip \
    boost \
"

# =====================================================================
# SYSTEM UTILITIES AND SERVICES
# =====================================================================
HEADUNIT_SYSTEM_INSTALL = " \
    systemd \
    bash \
    coreutils \
    binutils \
    curl \
    sudo \
    udev-extraconf \
"

# =====================================================================
# NETWORK AND CONNECTIVITY
# =====================================================================
HEADUNIT_NETWORK_INSTALL = " \
    openssh \
    openssh-sftp-server \
    wpa-supplicant \
    iw \
    linux-firmware-rpidistro-bcm43455 \
"

# =====================================================================
# AUDIO AND MULTIMEDIA SUPPORT
# =====================================================================
HEADUNIT_MULTIMEDIA_INSTALL = " \
    usbutils \
    alsa-utils \
    alsa-plugins \
    alsa-lib \
    pulseaudio \
    pulseaudio-server \
    pulseaudio-module-alsa-sink \
    pulseaudio-module-alsa-source \
    pulseaudio-module-native-protocol-unix \
    kernel-modules \
    kernel-module-snd-bcm2835 \
"

# =====================================================================
# DISPLAY SERVER (WESTON WAYLAND COMPOSITOR)
# =====================================================================
# Weston compositor for dual display management
# HU_MainApp runs as nested compositor on wayland-1
HEADUNIT_DISPLAY_INSTALL = " \
    weston \
    weston-init \
    weston-examples \
    wayland \
    wayland-protocols \
    libxkbcommon \
"

# =====================================================================
# CONSOLIDATED IMAGE INSTALL
# =====================================================================
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    ${HEADUNIT_QT5_INSTALL} \
    ${HEADUNIT_COMM_INSTALL} \
    ${HEADUNIT_SYSTEM_INSTALL} \
    ${HEADUNIT_NETWORK_INSTALL} \
    ${HEADUNIT_MULTIMEDIA_INSTALL} \
    ${HEADUNIT_DISPLAY_INSTALL} \
"

# =====================================================================
# IMAGE FEATURES
# =====================================================================
IMAGE_FEATURES += " \
    debug-tweaks \
    ssh-server-openssh \
"

# =====================================================================
# DISTRO FEATURES
# =====================================================================
DISTRO_FEATURES:append = " systemd wayland pam opengl"

# Set systemd as the init manager
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# =====================================================================
# LOCALIZATION SUPPORT
# =====================================================================
LINGUAS_KO_KR = "ko-kr"
LINGUAS_EN_US = "en-us"
IMAGE_LINGUAS = "${LINGUAS_KO_KR} ${LINGUAS_EN_US}"

# =====================================================================
# USER MANAGEMENT
# =====================================================================
inherit extrausers

# Create user with password 'fossball'
# Password is hashed using: openssl passwd -6 fossball
EXTRA_USERS_PARAMS = " \
    useradd -m -s /bin/bash -p '\$6\$fA7LvQuxAj1SVJvh\$VH8RvSyPug8LwhF7QfvIGH62u5JcN9KwubxzaLVEJxc4XYEvS1hoikejsEjhpJpzowj7uHDyCsbqALyBwsUnM.' fossball; \
    usermod -aG sudo,wheel fossball; \
"

# Set password for fossball user
set_fossball_password() {
    # Create directory if it doesn't exist
    mkdir -p ${IMAGE_ROOTFS}/usr/local/bin

    # Create a simple script to set password that will run on first boot
    cat > ${IMAGE_ROOTFS}/usr/local/bin/set-fossball-password.sh << 'EOF'
#!/bin/sh
# Set fossball password to 'fossball'
echo "fossball:fossball" | chpasswd
# Remove this script after running
rm -f /usr/local/bin/set-fossball-password.sh
rm -f /etc/systemd/system/set-fossball-password.service
systemctl daemon-reload
EOF
    chmod +x ${IMAGE_ROOTFS}/usr/local/bin/set-fossball-password.sh

    # Create systemd service to run on first boot
    cat > ${IMAGE_ROOTFS}/etc/systemd/system/set-fossball-password.service << 'EOF'
[Unit]
Description=Set fossball user password
Before=sshd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-fossball-password.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable the service
    ln -sf /etc/systemd/system/set-fossball-password.service \
        ${IMAGE_ROOTFS}/etc/systemd/system/multi-user.target.wants/set-fossball-password.service
}

# Configure sudoers for proper sudo group and user permissions
update_sudoers() {
    mkdir -p ${IMAGE_ROOTFS}/etc/sudoers.d

    # Allow sudo group to run all commands without password
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' > ${IMAGE_ROOTFS}/etc/sudoers.d/sudo-group
    chmod 0440 ${IMAGE_ROOTFS}/etc/sudoers.d/sudo-group

    # Allow wheel group to run all commands without password
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > ${IMAGE_ROOTFS}/etc/sudoers.d/wheel-group
    chmod 0440 ${IMAGE_ROOTFS}/etc/sudoers.d/wheel-group

    # Specific rule for fossball user (redundant but explicit)
    echo 'fossball ALL=(ALL:ALL) NOPASSWD: ALL' > ${IMAGE_ROOTFS}/etc/sudoers.d/fossball
    chmod 0440 ${IMAGE_ROOTFS}/etc/sudoers.d/fossball
}

ROOTFS_POSTPROCESS_COMMAND += "update_sudoers;"

# =====================================================================
# NETWORK CONFIGURATION - WiFi Setup
# =====================================================================
# WiFi Configuration for wpa_supplicant
# IMPORTANT: Update these with your actual WiFi SSID and password!
WIFI_SSID ?= "YourWiFiSSID"
WIFI_PASSWORD ?= "YourWiFiPassword"

configure_wifi() {
    # Create wpa_supplicant directory
    mkdir -p ${IMAGE_ROOTFS}/etc/wpa_supplicant

    # Create wpa_supplicant configuration for wlan0
    echo "ctrl_interface=/var/run/wpa_supplicant" > ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "update_config=1" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "network={" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "    ssid=\"${WIFI_SSID}\"" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "    psk=\"${WIFI_PASSWORD}\"" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "    key_mgmt=WPA-PSK" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "}" >> ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf

    # Set proper permissions
    chmod 600 ${IMAGE_ROOTFS}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
}

# Create systemd-networkd configuration for WiFi
configure_networkd() {
    mkdir -p ${IMAGE_ROOTFS}/etc/systemd/network

    echo "[Match]" > ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "Name=wlan0" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "[Network]" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "DHCP=yes" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "[Link]" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
    echo "RequiredForOnline=no" >> ${IMAGE_ROOTFS}/etc/systemd/network/25-wireless.network
}

# Enable WiFi services
enable_wifi_services() {
    if [ -d ${IMAGE_ROOTFS}${systemd_system_unitdir} ]; then
        # Enable wpa_supplicant for wlan0
        mkdir -p ${IMAGE_ROOTFS}${systemd_system_unitdir}/multi-user.target.wants
        ln -sf ../wpa_supplicant@.service ${IMAGE_ROOTFS}${systemd_system_unitdir}/multi-user.target.wants/wpa_supplicant@wlan0.service

        # Enable systemd-networkd
        mkdir -p ${IMAGE_ROOTFS}${systemd_system_unitdir}/multi-user.target.wants
        ln -sf ../systemd-networkd.service ${IMAGE_ROOTFS}${systemd_system_unitdir}/multi-user.target.wants/systemd-networkd.service
        ln -sf ../systemd-networkd.socket ${IMAGE_ROOTFS}${systemd_system_unitdir}/sockets.target.wants/systemd-networkd.socket
    fi
}

# Disable systemd-networkd-wait-online to speed up boot
disable_network_wait() {
    if [ -d ${IMAGE_ROOTFS}${systemd_system_unitdir} ]; then
        rm -f ${IMAGE_ROOTFS}${systemd_system_unitdir}/network-online.target.wants/systemd-networkd-wait-online.service
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "configure_wifi; configure_networkd; enable_wifi_services; disable_network_wait;"

# =====================================================================
# AUTO-LOGIN CONFIGURATION
# =====================================================================
# Enable auto-login for getty (serial and graphical)
KIRKSTONE_LOCAL_GETTY ?= " \
    ${IMAGE_ROOTFS}${systemd_system_unitdir}/serial-getty@.service \
    ${IMAGE_ROOTFS}${systemd_system_unitdir}/getty@.service \
"


# =====================================================================
# QT ENVIRONMENT VARIABLES
# =====================================================================
# Configure Qt platform for Wayland (Weston compositor)
export QT_QPA_PLATFORM = "wayland"

# =====================================================================
# PACKAGING CONFIGURATION
# =====================================================================
# Enable stripping of debug symbols to reduce image size
INHERIT += "insane"
INSANE_SKIP:${PN} += "ldflags"
