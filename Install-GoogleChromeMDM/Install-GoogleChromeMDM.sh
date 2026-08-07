#!/bin/bash
# Install Google Chrome and Google Endpoint Verification with policies

# Detection
if dpkg -l | grep -q "google-chrome-stable" && \
   dpkg -l | grep -q "endpoint-verification" && \
   [ -f "/etc/opt/chrome/policies/forced/Corporate_policy.json" ] && \
   [ -f "/etc/opt/chrome/policies/managed/my_policy.json" ]; then
    echo "Google Chrome, Endpoint Verification and policies are already installed."
    exit 0
fi

echo "Installing Google Chrome and Endpoint Verification..."

# Add Google Chrome repository
mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
chmod 644 /etc/apt/keyrings/google-chrome.gpg
echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list

# Add Google Endpoint Verification repository
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/endpoint-verification.gpg
chmod 644 /etc/apt/keyrings/endpoint-verification.gpg
echo 'deb [signed-by=/etc/apt/keyrings/endpoint-verification.gpg] https://packages.cloud.google.com/apt endpoint-verification main' > /etc/apt/sources.list.d/endpoint-verification.list

# Update and install
apt-get update
apt-get install -y google-chrome-stable endpoint-verification

# Configure Chrome Policies
mkdir -p /etc/opt/chrome/policies/forced
mkdir -p /etc/opt/chrome/policies/managed

# Forced policies
cat << 'EOF' > /etc/opt/chrome/policies/forced/Corporate_policy.json
{
  "ExtensionInstallForcelist": [
    "mclkkofklkfljcocdinagocijianpkik;https://clients2.google.com/service/update2/crx",
    "inomeicfmomofachclnbeeidmbiinean;https://clients2.google.com/service/update2/crx"
  ]
}
EOF
chmod 644 /etc/opt/chrome/policies/forced/Corporate_policy.json

# Managed policies
cat << 'EOF' > /etc/opt/chrome/policies/managed/my_policy.json
{
  "ExtensionInstallForcelist": [
    "callobklhcbilhphinckomhgkigmfocg"
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
chmod 644 /etc/opt/chrome/policies/managed/my_policy.json

echo "Installation and configuration completed successfully."


