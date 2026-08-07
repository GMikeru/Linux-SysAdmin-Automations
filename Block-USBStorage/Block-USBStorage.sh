#!/bin/bash
# Disable USB Storage

# Detection
if grep -q 'blacklist usb-storage' /etc/modprobe.d/disable-usb-storage.conf 2>/dev/null && \
   grep -q 'blacklist uas' /etc/modprobe.d/disable-usb-storage.conf 2>/dev/null; then
    echo "USB storage is already disabled."
    exit 0
fi

echo "Disabling USB storage..."
echo 'blacklist usb-storage' > /etc/modprobe.d/disable-usb-storage.conf
echo 'blacklist uas' >> /etc/modprobe.d/disable-usb-storage.conf
chmod 644 /etc/modprobe.d/disable-usb-storage.conf

echo "USB storage disabled successfully."


