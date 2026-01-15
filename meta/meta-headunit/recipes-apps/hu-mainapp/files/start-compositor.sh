#!/bin/sh
# Compositor startup script

# Wait for DRM to be ready
sleep 2

# Ensure runtime directory exists with correct permissions
mkdir -p /run/user/0
chmod 700 /run/user/0

# Export all environment variables
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
export QT_QPA_EGLFS_KMS_ATOMIC=1
export QT_QPA_EGLFS_FORCE888=1
export QT_QPA_EGLFS_PHYSICAL_WIDTH=1024
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=600
export QT_QPA_EGLFS_KMS_CONFIG=/dev/dri/card0
export QT_PLUGIN_PATH=/usr/lib/plugins
export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib

# Run compositor
exec /usr/bin/HU_MainApp_Compositor
