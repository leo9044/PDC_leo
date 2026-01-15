# Enable Kiosk Shell for automotive dual-display setup
# Kiosk Shell provides per-output app-id routing needed for HU and IC displays

# Add kiosk-shell to PACKAGECONFIG
# The base recipe doesn't include shell-kiosk, so we need to add it
PACKAGECONFIG:append = " shell-kiosk"

# Define the kiosk-shell PACKAGECONFIG option
# This enables the meson build option -Dshell-kiosk=true
PACKAGECONFIG[shell-kiosk] = "-Dshell-kiosk=true,-Dshell-kiosk=false"
