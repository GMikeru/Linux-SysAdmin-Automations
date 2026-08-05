#!/bin/bash
# =============================================================================
# Setup Script: OpenVPN Permissions (Least Privilege)
# =============================================================================
# Unified script for Intune / Canonical Landscape deployment.
# Ensures OpenVPN is installed and allows developers (without sudo group) to 
# use the VPN via GUI and CLI without requiring a root password.
#
# No users are added to the sudo group.
# =============================================================================

TOTAL_APPLIED=0
TOTAL_ALREADY_OK=0

# ==============================================================================
# PART 1: OPENVPN PACKAGE INSTALLATION
# ==============================================================================
echo "[1/3] Checking openvpn package..."

if dpkg-query -W -f='${Status}' openvpn 2>/dev/null | grep -q "install ok installed"; then
    echo "  ✔ openvpn package is already installed."
    TOTAL_ALREADY_OK=$((TOTAL_ALREADY_OK + 1))
else
    echo "  ✘ openvpn package not found. Installing..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq openvpn

    if dpkg-query -W -f='${Status}' openvpn 2>/dev/null | grep -q "install ok installed"; then
        echo "  ✔ openvpn package installed successfully."
        TOTAL_APPLIED=$((TOTAL_APPLIED + 1))
    else
        echo "  ✘ ERROR: Failed to install openvpn package."
        exit 1
    fi
fi

# ==============================================================================
# PART 2: GUI PERMISSION — POLKIT (NetworkManager)
# ==============================================================================
echo ""
echo "[2/3] Checking GUI permissions (Polkit for NetworkManager)..."

POLKIT_RULE_FILE="/etc/polkit-1/rules.d/90-networkmanager-nonroot.rules"

if [ -f "$POLKIT_RULE_FILE" ]; then
    echo "  ✔ Polkit rule already exists at $POLKIT_RULE_FILE."
    TOTAL_ALREADY_OK=$((TOTAL_ALREADY_OK + 1))
else
    echo "  ✘ Polkit rule not found. Creating..."

    cat << 'EOF' > "$POLKIT_RULE_FILE"
// Allows local users to manage networks and connect/disconnect VPNs without root password
// Scope: NetworkManager actions (GUI and nmcli) ONLY.
polkit.addRule(function(action, subject) {
    if (
        action.id.indexOf("org.freedesktop.NetworkManager.") === 0 && 
        subject.local && 
        subject.active
    ) {
        return polkit.Result.YES;
    }
});
EOF

    chown root:root "$POLKIT_RULE_FILE"
    chmod 0644 "$POLKIT_RULE_FILE"
    systemctl restart polkit.service

    if [ -f "$POLKIT_RULE_FILE" ]; then
        echo "  ✔ Polkit rule created and service restarted."
        TOTAL_APPLIED=$((TOTAL_APPLIED + 1))
    else
        echo "  ✘ ERROR: Failed to create Polkit rule."
        exit 1
    fi
fi

# ==============================================================================
# PART 3: CLI PERMISSION — SUDOERS (openvpn --config)
# ==============================================================================
echo ""
echo "[3/3] Checking CLI permissions (sudoers for openvpn --config)..."

SUDOERS_FILE="/etc/sudoers.d/openvpn-devs"

if [ -f "$SUDOERS_FILE" ]; then
    echo "  ✔ Sudoers rule already exists at $SUDOERS_FILE."
    TOTAL_ALREADY_OK=$((TOTAL_ALREADY_OK + 1))
else
    echo "  ✘ Sudoers rule not found. Creating..."

    cat << 'EOF' > "$SUDOERS_FILE"
# Allows any user to run OpenVPN in client mode without root password.
# Scope: ONLY the 'openvpn --config <file>' command. Users are NOT added to the sudo group.
ALL ALL=(ALL) NOPASSWD: /usr/sbin/openvpn --config *
EOF

    chmod 0440 "$SUDOERS_FILE"

    if visudo -cf "$SUDOERS_FILE"; then
        echo "  ✔ Sudoers rule created and validated."
        TOTAL_APPLIED=$((TOTAL_APPLIED + 1))
    else
        echo "  ✘ ERROR: Invalid sudoers syntax. Removing for safety..."
        rm -f "$SUDOERS_FILE"
        exit 1
    fi
fi

echo ""
echo "=================================================================="
if [ "$TOTAL_APPLIED" -eq 0 ] && [ "$TOTAL_ALREADY_OK" -eq 3 ]; then
    echo "RESULT: Everything was already configured. No changes made."
elif [ "$TOTAL_APPLIED" -gt 0 ]; then
    echo "RESULT: $TOTAL_APPLIED of 3 components applied, $TOTAL_ALREADY_OK were already OK."
fi
echo "=================================================================="
exit 0
