#!/bin/bash
# Install Microsoft Edge and Google Endpoint Verification with policies

# Detection
if dpkg -l | grep -q "microsoft-edge-stable" && \
   dpkg -l | grep -q "endpoint-verification" && \
   [ -f "/etc/opt/edge/policies/managed/endpoint_policy.json" ]; then
    echo "Microsoft Edge, Endpoint Verification and policies are already installed."
    exit 0
fi

echo "Installing Microsoft Edge and Endpoint Verification..."

# Add Microsoft Edge repository
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg
chmod 644 /usr/share/keyrings/microsoft.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main' > /etc/apt/sources.list.d/microsoft-edge.list

# Add Google Endpoint Verification repository
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/endpoint-verification.gpg
chmod 644 /etc/apt/keyrings/endpoint-verification.gpg
echo 'deb [signed-by=/etc/apt/keyrings/endpoint-verification.gpg] https://packages.cloud.google.com/apt endpoint-verification main' > /etc/apt/sources.list.d/endpoint-verification.list

# Update and install
apt-get update
apt-get install -y microsoft-edge-stable endpoint-verification

# Configure Edge Policies
mkdir -p /etc/opt/edge/policies/managed

cat << 'EOF' > /etc/opt/edge/policies/managed/endpoint_policy.json
{
  "ExtensionInstallForcelist": [
    "callobklhcbilhphinckomhgkigmfocg;https://clients2.google.com/service/update2/crx"
  ],
  "HomepageLocation": "https://app.yourcompany.com",
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": [
    "https://app.yourcompany.com"
  ],
  "URLBlocklist": [
    "discord.com",
    "discordstatus.com",
    "updates.discord.com"
  ],
  "AllowedDomainsForApps": "Corporate.com.br,linker.com.br,conpass.io,devitecnologia.com.br,ergoncredit.com.br,gclick.com.br,mintegra.com.br,oneflow.com.br",
  "RestrictSigninToPattern": ".*@Corporate\\.com\\.br"
}
EOF
chmod 644 /etc/opt/edge/policies/managed/endpoint_policy.json

echo "Installation and configuration completed successfully."


