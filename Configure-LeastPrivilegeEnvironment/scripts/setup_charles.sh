#!/bin/bash
# =============================================================================
# Setup Script: Charles Proxy Permissions (Least Privilege)
# =============================================================================
# Allows developers to run Charles Proxy as root (via sudo charles) so the app 
# can install its own certificates and function without blocks, while adhering 
# to the Principle of Least Privilege.
#
# Scope: Only the '/usr/bin/charles' binary — NO users are added to the sudo group.
# =============================================================================

# 1. DETECTION
if [ -f /etc/sudoers.d/charles-proxy-devs ]; then
    echo "Sudo permissions for Charles Proxy are already configured."
    exit 0
fi

echo "Starting Charles Proxy permission configuration for developers..."

# 2. SUDOERS RULE (Granular Permission)
echo "Creating sudoers rule in /etc/sudoers.d/charles-proxy-devs..."

cat << 'EOF' > /etc/sudoers.d/charles-proxy-devs
# Allows any user to run Charles Proxy as root without a password.
# Scope: ONLY the Charles application. Users are NOT added to the sudo group.
ALL ALL=(ALL) NOPASSWD: /usr/bin/charles
EOF

chmod 0440 /etc/sudoers.d/charles-proxy-devs

# 3. VALIDATION
echo "Validating sudoers file syntax..."
if visudo -cf /etc/sudoers.d/charles-proxy-devs; then
    echo ""
    echo "=================================================================="
    echo "SUCCESS: Charles Proxy permissions applied!"
    echo "Developers can now start the app with privileges by running: sudo charles"
    echo "No additional root access was granted."
    echo "=================================================================="
    exit 0
else
    echo "ERROR: The sudoers file has a syntax error. Removing for safety..."
    rm -f /etc/sudoers.d/charles-proxy-devs
    exit 1
fi
