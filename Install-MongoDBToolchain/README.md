# Install MongoDB Toolchain

This package automates the deployment of a complete local MongoDB development environment for Linux endpoints, while adhering to the **Principle of Least Privilege**.

## What is installed?
1. **MongoDB Server (`mongod`)**: The core database service. Installed securely via the official MongoDB APT Repository (`pgp.mongodb.com`).
2. **MongoDB Shell (`mongosh`)**: The modern command-line interface for interacting with the database.
3. **MongoDB Compass**: The official Graphical User Interface (GUI), downloaded and installed dynamically via its `.deb` package to ensure dependency resolution.

## Sudoers Integration (Least Privilege)
Ordinarily, a developer would need full `sudo` root access to stop, start, or check the logs of the MongoDB system service (`systemctl`).

This script prevents the need for root access by injecting a highly specific `/etc/sudoers.d/mongodb-manage` file using `Cmnd_Alias`.

**It grants developers passwordless sudo access strictly to:**
- `systemctl start/stop/restart/status mongod`
- Editing `/etc/mongod.conf` (via nano, vim, or vi)
- Reading `/var/log/mongodb/mongod.log` (via tail, cat, or less)

They cannot use `systemctl` to stop any other service, nor can they edit any other configuration file on the system.

## Deployment
This script is idempotent. It can be deployed safely as root via:
- Canonical Landscape
- Microsoft Intune (Custom Linux Scripts)
- Ansible / Puppet
