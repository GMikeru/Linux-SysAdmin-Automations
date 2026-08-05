#!/bin/bash
# =============================================================================
# Setup Script: /etc/hosts Permissions (Least Privilege)
# =============================================================================
# Installs a secure utility script to allow developers to modify domain IPs 
# in the /etc/hosts file without requiring full sudo permissions.
# =============================================================================

echo "Creating the secure utility at /usr/local/bin/update-hosts..."

# 1. Create the utility script
cat << 'EOF' > /usr/local/bin/update-hosts
#!/bin/bash
# Secure script to update /etc/hosts

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$#" -lt 2 ]; then
    echo "Usage: sudo update-hosts <IP> <DOMAIN>"
    echo "Remove all domain entries: sudo update-hosts rm <DOMAIN>"
    echo "Remove specific IP entry:  sudo update-hosts rm <IP> <DOMAIN>"
    exit 1
fi

if [ "$1" == "rm" ] || [ "$1" == "remove" ]; then
    if [ "$#" -eq 2 ]; then
        DOMAIN=$2
        if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            echo "ERROR: Invalid domain characters."
            exit 1
        fi
        sed -i.bak "/[[:space:]]${DOMAIN}\b/d" /etc/hosts
        echo "SUCCESS: All entries for '$DOMAIN' removed from /etc/hosts."
        exit 0
    elif [ "$#" -eq 3 ]; then
        IP=$2
        DOMAIN=$3
        if ! [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
            echo "ERROR: Invalid IP format."
            exit 1
        fi
        if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            echo "ERROR: Invalid domain characters."
            exit 1
        fi
        ESCAPED_IP=$(echo "$IP" | sed 's/\./\\./g')
        sed -i.bak "/^${ESCAPED_IP}[[:space:]]\+${DOMAIN}\b/d" /etc/hosts
        echo "SUCCESS: Specific entry '$IP $DOMAIN' removed from /etc/hosts."
        exit 0
    fi
fi

IP=$1
DOMAIN=$2

if ! [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    echo "ERROR: Invalid IP format."
    exit 1
fi
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "ERROR: Invalid domain characters."
    exit 1
fi

sed -i.bak "/[[:space:]]${DOMAIN}\b/d" /etc/hosts
echo "$IP $DOMAIN" >> /etc/hosts

echo "SUCCESS: /etc/hosts updated with '$IP $DOMAIN'."
EOF

chmod +x /usr/local/bin/update-hosts

# 2. Grant sudoers permission for the utility only
echo "Configuring permissions in /etc/sudoers.d/..."

cat << 'EOF' > /etc/sudoers.d/update-hosts-devs
# Allows any user to run the update-hosts utility as root without a password
ALL ALL=(ALL) NOPASSWD: /usr/local/bin/update-hosts
EOF

chmod 0440 /etc/sudoers.d/update-hosts-devs

echo "Configuration completed successfully!"
