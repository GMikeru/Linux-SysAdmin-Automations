#!/bin/bash
# Install Chrome Remote Desktop

# Detection
if dpkg -l | grep -q "chrome-remote-desktop"; then
    echo "Chrome Remote Desktop is already installed."
    exit 0
fi

echo "Installing Chrome Remote Desktop..."
wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -O /tmp/chrome-remote-desktop_current_amd64.deb
apt-get install -y /tmp/chrome-remote-desktop_current_amd64.deb

echo "Installation completed successfully."


