# Jetson Orin Nano: Override meta-tegra's X11 requirement
# meta-tegra forces x11 and removes wayland, but we need pure Wayland

# Remove x11 requirement added by meta-tegra
REQUIRED_DISTRO_FEATURES:remove:tegra = "x11"

# Force wayland support (override meta-tegra's removal)
PACKAGECONFIG:tegra = "wayland"

# Use tegra's vulkan driver
RDEPENDS:${PN}:tegra = "tegra-libraries-vulkan"
