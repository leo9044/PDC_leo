# Headunit Image Configuration Guide

This document explains the configuration options available in the headunit image build.

## User Management

### fossball User
The image automatically creates a user called `fossball` with the following settings:

- **Username**: fossball
- **Home Directory**: /home/fossball
- **Shell**: /bin/bash
- **Groups**: sudo, wheel
- **Sudo**: NOPASSWD (passwordless sudo - requires entering user password for initial login)

This user is created during the Yocto build and is configured in `classes/headunit-image.bbclass`.

## WiFi Configuration

### Automatic WiFi Setup
The image includes automatic WiFi configuration through `wpa_supplicant` and `systemd-networkd`.

### How to Configure WiFi

#### Method 1: Build-Time Configuration (Recommended)
Configure WiFi SSID and password in the build configuration:

1. Edit `poky-kirkstone/build-headunit/conf/local.conf`:

```bash
WIFI_SSID = "YourWiFiSSID"
WIFI_PASSWORD = "YourWiFiPassword"
```

2. Rebuild the image:

```bash
cd poky-kirkstone/build-headunit
source ../oe-init-build-env build-headunit
bitbake headunit-image
```

The WiFi configuration will be automatically baked into the image.

#### Method 2: Runtime Configuration (After Boot)
If you need to change WiFi after the image is flashed:

On the Raspberry Pi:

```bash
# Edit the WiFi configuration
sudo vi /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
```

Update the SSID and password, then restart:

```bash
sudo systemctl restart wpa_supplicant@wlan0.service
sudo systemctl restart systemd-networkd

# Check connection
ip addr show wlan0
```

### WiFi Services

The image automatically enables:
- `wpa_supplicant@wlan0.service` - Manages WiFi authentication
- `systemd-networkd.service` - Manages network interfaces and IP assignment

These services start automatically on boot.

### Network Interface Configuration

WiFi configuration files created:
- `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf` - WiFi credentials and settings
- `/etc/systemd/network/25-wireless.network` - Network interface configuration (DHCP enabled)

## SSH Access

### SSH Configuration
- SSH server is enabled and runs by default
- Port: 22 (default)
- Service: `openssh`

### Connecting via SSH

From your laptop/computer:

```bash
# Find Raspberry Pi's IP
ping 192.168.1.1  # Check your network

# SSH into the Pi
ssh fossball@<PI_IP>
```

Example:
```bash
ssh fossball@192.168.1.50
```

When prompted for password, enter the fossball user's password (if set via `sudo passwd fossball`).

## Systemd Services

The image includes various systemd services for:
- SSH server (openssh)
- WiFi management (wpa_supplicant@wlan0)
- Network management (systemd-networkd)
- Display server (HU_MainApp Wayland compositor)
- Audio (pulseaudio)
- System utilities (dbus, systemd-logind, etc.)

## Building the Image

### Standard Build

```bash
cd /home/seame/HU/chang_new/poky-kirkstone/build-headunit
source ../oe-init-build-env build-headunit
bitbake headunit-image
```

### With WiFi Configuration

1. Update `local.conf` with your WiFi details
2. Run the build command above
3. Flash the image to SD card
4. The Pi will automatically connect to WiFi on boot

## Troubleshooting

### WiFi Not Connecting

On the Raspberry Pi:

```bash
# Check wpa_supplicant status
systemctl status wpa_supplicant@wlan0.service

# Check network configuration
cat /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# View WiFi connection status
wpa_cli -i wlan0 status

# Bring up wlan0 if needed
sudo ip link set wlan0 up
```

### SSH Connection Refused

1. Check SSH is running: `systemctl status ssh`
2. Check SSH is listening: `ss -tlnp | grep :22`
3. Verify fossball user exists: `id fossball`
4. Try connecting as root first to diagnose

### No IP Address

```bash
# Restart networking
sudo systemctl restart systemd-networkd

# Check IP after a few seconds
ip addr show wlan0
```

## File Locations

| File | Purpose |
|------|---------|
| `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf` | WiFi credentials |
| `/etc/systemd/network/25-wireless.network` | Network interface config |
| `/etc/sudoers.d/fossball` | Sudoers configuration |
| `/etc/ssh/sshd_config` | SSH server configuration |

## Notes

- WiFi password is stored in plaintext in `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`
- File permissions are set to 600 for security
- DHCP is enabled by default for automatic IP assignment
- For production systems, consider using SSH keys instead of passwords

