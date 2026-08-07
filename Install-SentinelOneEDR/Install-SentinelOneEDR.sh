#!/bin/bash
# Install and Configure SentinelOne Agent

# Detection
if [ -d "/opt/sentinelone" ] && dpkg -l | grep -q -i "sentinelagent"; then
    echo "SentinelOne Agent is already installed."
    exit 0
fi

echo "Installing SentinelOne Agent..."
wget -q https://scconfigmgrappdataCorporate.blob.core.windows.net/customization/SentinelAgent_linux_x86_64_v23_2_2_358.deb -O /tmp/SentinelAgent.deb
dpkg --force-all -i /tmp/SentinelAgent.deb
apt-get install -f -y

echo "Applying Management Token and Starting Service..."
/opt/sentinelone/bin/sentinelctl management token set <YOUR_CORP_TOKEN>
/opt/sentinelone/bin/sentinelctl control start

echo "SentinelOne installation and configuration completed."


