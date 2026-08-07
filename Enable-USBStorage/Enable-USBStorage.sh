#!/bin/bash
# Enable USB Storage

CONF_FILE="/etc/modprobe.d/disable-usb-storage.conf"

# Detection
if [ ! -f "$CONF_FILE" ]; then
    echo "USB storage is already enabled (configuration file not found)."
    exit 0
fi

echo "Enabling USB storage..."

# Remove the configuration file that blacklists the modules
rm -f "$CONF_FILE"

# Attempt to load the modules so it works immediately without a reboot
modprobe usb-storage 2>/dev/null
modprobe uas 2>/dev/null

echo "USB storage enabled successfully."


