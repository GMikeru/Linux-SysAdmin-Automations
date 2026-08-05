# Configure Least Privilege Environment

This package contains deployment scripts designed to transform a locked-down corporate Linux endpoint into a fully functional developer environment **without granting users full root access.**

## The Problem
Developers frequently need administrative permissions on Linux machines to:
- Connect to VPNs (`openvpn`)
- Map internal IPs to domains for local testing (`/etc/hosts`)
- Capture secure network traffic (`charles-proxy`)

The amateur solution is to add the developer to the `sudo` group, granting them unrestricted root access. This violates enterprise security policies and the **Principle of Least Privilege (PoLP)**.

## The Solution
These scripts leverage `/etc/sudoers.d/` drop-in files and PolicyKit (`Polkit`) JavaScript rules to grant granular, passwordless execution rights to specific binaries.

### Included Scripts

#### 1. `setup_openvpn.sh`
- **What it does:** Installs the OpenVPN package.
- **Sudoers Rule:** Allows the developer to run exactly `sudo /usr/sbin/openvpn --config *`. This prevents them from using the OpenVPN binary for unintended purposes.
- **Polkit Rule:** Injects a JS rule into `/etc/polkit-1/rules.d/` that authorizes the `org.freedesktop.NetworkManager.*` namespace for active local users. This allows developers to use the Ubuntu GUI (or `nmcli`) to connect/disconnect VPNs without being prompted for the root password.

#### 2. `setup_hosts.sh`
- **What it does:** Modifying `/etc/hosts` directly is dangerous. This script compiles a secure, validation-checked bash utility at `/usr/local/bin/update-hosts`.
- **Sudoers Rule:** Allows developers to run `sudo update-hosts <IP> <DOMAIN>`. The utility sanitizes the inputs (preventing bash injection) and securely appends or removes domains from the hosts file.

#### 3. `setup_charles.sh`
- **What it does:** Charles Proxy requires root access to install its local root certificate into the OS trust store to decrypt HTTPS traffic.
- **Sudoers Rule:** Grants passwordless execution rights strictly to `/usr/bin/charles`. 

## Deployment
These scripts are idempotent. They can be deployed safely as root via:
- Canonical Landscape
- Microsoft Intune (Custom Linux Scripts)
- Ansible / Puppet
