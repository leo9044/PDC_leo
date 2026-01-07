#!/bin/sh
# USB Auto-mount script
# This script tries to mount USB partitions intelligently

DEVICE=$1
MOUNT_POINT="/media/usb"

if [ -z "$DEVICE" ]; then
    echo "Usage: $0 <device>"
    exit 1
fi

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Check if something is already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "$MOUNT_POINT is already mounted"
    exit 0
fi

# Try to mount the device
if mount "/dev/$DEVICE" "$MOUNT_POINT" 2>/dev/null; then
    echo "Successfully mounted /dev/$DEVICE to $MOUNT_POINT"

    # Check if there are any media files on this partition
    file_count=$(find "$MOUNT_POINT" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.m4a" \) 2>/dev/null | wc -l)

    if [ "$file_count" -gt 0 ]; then
        echo "Found $file_count media files on /dev/$DEVICE"
    else
        echo "No media files found on /dev/$DEVICE, but keeping it mounted"
    fi

    exit 0
else
    echo "Failed to mount /dev/$DEVICE"
    exit 1
fi
