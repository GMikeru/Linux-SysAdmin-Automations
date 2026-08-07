#!/bin/bash
# Install RMM Agent

# Detection
MARKER_FILE="/var/log/rmm_agent_installed.log"
if [ -f "$MARKER_FILE" ]; then
    echo "RMM Agent was already installed."
    exit 0
fi

echo "Downloading and installing RMM Agent..."
wget -q https://scconfigmgrappdataCorporate.blob.core.windows.net/customization/install_agent.sh -O /tmp/install_agent.sh
chmod +x /tmp/install_agent.sh
bash /tmp/install_agent.sh

# Create marker file if installation succeeded
if [ $? -eq 0 ]; then
    echo "Installation completed on $(date)" > "$MARKER_FILE"
    echo "RMM Agent installed successfully."
else
    echo "RMM Agent installation failed."
    exit 1
fi


