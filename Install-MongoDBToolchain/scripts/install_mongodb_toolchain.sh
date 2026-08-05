#!/bin/bash
# =============================================================================
# Setup Script: Install MongoDB Toolchain (Server, Shell, Compass)
# =============================================================================
# Deploys the complete MongoDB local development stack on Ubuntu/Debian.
# 
# Components:
# 1. MongoDB Server (mongod) & Shell (mongosh) - via Official APT Repository
# 2. MongoDB Compass (GUI) - via direct .deb download
# 3. Developer Permissions - via /etc/sudoers.d/ granular rules
# =============================================================================

COMPASS_VERSION="1.43.0"
COMPASS_URL="https://downloads.mongodb.com/compass/mongodb-compass_${COMPASS_VERSION}_amd64.deb"

# ------------------------------------------------------------------------------
# 1. DETECTION (Idempotency)
# ------------------------------------------------------------------------------
if dpkg-query -W -f='${Status}' mongodb-compass 2>/dev/null | grep -q "install ok installed" && \
   dpkg-query -W -f='${Status}' mongodb-mongosh 2>/dev/null | grep -q "install ok installed" && \
   dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -q "install ok installed" && \
   [ -f /etc/sudoers.d/mongodb-manage ]; then
    echo "MongoDB (Compass, Shell, Server) and developer permissions are already configured."
    exit 0
fi

echo "Starting the MongoDB toolchain installation..."
export DEBIAN_FRONTEND=noninteractive

# Clean up any broken configurations from previous failed attempts
rm -f /etc/apt/sources.list.d/mongodb-org-7.0.list
rm -f /usr/share/keyrings/mongodb-server-7.0.gpg

apt-get update -qq
apt-get install -y -qq curl wget gpg apt-transport-https

# ------------------------------------------------------------------------------
# 2. MONGODB SERVER & SHELL (Official APT Repository)
# ------------------------------------------------------------------------------
echo "Configuring the MongoDB GPG security key..."
curl -fsSL --connect-timeout 10 https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-7.0.gpg

echo "Registering the official version 7.0 repository..."
echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list

echo "Installing MongoDB Server (mongod) and MongoDB Shell (mongosh)..."
apt-get update -qq
apt-get install -y -qq mongodb-org mongodb-mongosh

echo "Enabling and starting the local MongoDB service..."
systemctl daemon-reload
systemctl enable --now mongod

# ------------------------------------------------------------------------------
# 3. MONGODB COMPASS (Debian Package)
# ------------------------------------------------------------------------------
COMPASS_TMP="/tmp/mongodb-compass.deb"

echo "Downloading official MongoDB Compass (Version ${COMPASS_VERSION})..."
if ! curl -fsSL --connect-timeout 10 -o "$COMPASS_TMP" "$COMPASS_URL"; then
    echo "ERROR: Failed to download MongoDB Compass. Check the URL or network connection."
    exit 1
fi

echo "Installing MongoDB Compass..."
# Using apt-get install instead of dpkg -i ensures dependencies (like libgconf) are resolved
apt-get install -y -qq "$COMPASS_TMP"
rm -f "$COMPASS_TMP"

# ------------------------------------------------------------------------------
# 4. DEVELOPER PERMISSIONS (Least Privilege)
# ------------------------------------------------------------------------------
echo "Configuring advanced developer permissions for MongoDB..."

cat << 'EOF' > /etc/sudoers.d/mongodb-manage
# 1. Commands to manage the MongoDB service
Cmnd_Alias MONGODB_SYSCTL = /usr/bin/systemctl start mongod, /usr/bin/systemctl stop mongod, /usr/bin/systemctl restart mongod, /usr/bin/systemctl status mongod

# 2. Commands to edit the configuration file
Cmnd_Alias MONGODB_EDIT = /usr/bin/nano /etc/mongod.conf, /usr/bin/vim /etc/mongod.conf, /usr/bin/vi /etc/mongod.conf

# 3. Commands to read MongoDB logs
Cmnd_Alias MONGODB_LOGS = /usr/bin/tail /var/log/mongodb/mongod.log, /usr/bin/tail -f /var/log/mongodb/mongod.log, /usr/bin/cat /var/log/mongodb/mongod.log, /usr/bin/less /var/log/mongodb/mongod.log

# Apply passwordless permission for all users targeting the aliases above
ALL ALL=(ALL) NOPASSWD: MONGODB_SYSCTL, MONGODB_EDIT, MONGODB_LOGS
EOF

chmod 0440 /etc/sudoers.d/mongodb-manage

# ------------------------------------------------------------------------------
# 5. FINAL VALIDATION
# ------------------------------------------------------------------------------
if dpkg-query -W -f='${Status}' mongodb-compass 2>/dev/null | grep -q "install ok installed" && \
   dpkg-query -W -f='${Status}' mongodb-mongosh 2>/dev/null | grep -q "install ok installed" && \
   dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -q "install ok installed"; then
    echo "SUCCESS: MongoDB Compass, Shell, and Server installation completed perfectly!"
    exit 0
else
    echo "ERROR: One or more tools failed during installation."
    exit 1
fi
