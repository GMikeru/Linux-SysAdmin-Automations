# Configure Gemini CLI

> **Platform:** Ubuntu 22.04 / 24.04 LTS (Tested on 26.04 pre-release)
> **Deployment:** Microsoft Intune for Linux / Canonical Landscape

## Overview

This remediation package solves a specific corporate licensing issue with the **Gemini CLI** (Google Gemini Code Assist) on managed Linux endpoints.

### The Problem
When a developer runs `gemini` for the first time, if the OAuth flow redirects to a personal Google account instead of the corporate account linked to GCP, the CLI falls back to personal mode. It records `"selectedType": "oauth-personal"` in the user's `~/.gemini/settings.json`.

Once in personal mode, the CLI **ignores** the corporate Google Cloud license, even if the correct `GOOGLE_CLOUD_PROJECT` environment variable is set later. This prevents the use of enterprise features.

**Root causes:**
1. **First run without `GOOGLE_CLOUD_PROJECT`:** If the environment variable wasn't set when the user ran `gemini` the first time, it defaults to the personal flow.
2. **Missing Machine Scope:** Without `/etc/gemini-cli/settings.json` configured, there is no system override to force the correct authentication type.

## What it does

This package contains two scripts designed to be deployed sequentially via an MDM (like Intune) or run manually.

### `Detect.sh`
Collects the full state of the Gemini CLI across all users on the machine (local, LDAP, SSSD, and Entra ID users) and reports any misconfigurations.

**Checks performed:**
- Validates the Gemini CLI binary and Node.js installation.
- Checks if the Machine Scope config (`/etc/gemini-cli/settings.json`) exists and is correct.
- Verifies system-wide environment variables (`/etc/environment`, `/etc/profile.d/`).
- Scans every user's home directory to check their `~/.gemini/settings.json` for the problematic `"oauth-personal"` auth type.
- **Returns Exit 1** if any user is configured incorrectly, triggering the remediation.

### `Remediate.sh`
Applies all necessary fixes to ensure the `gemini` command runs with the corporate license.

**Actions performed:**
1. **Machine Scope:** Creates `/etc/gemini-cli/settings.json` forcing the `gcp` selectedType for all users.
2. **System Variables:** Injects `GOOGLE_CLOUD_PROJECT` into `/etc/environment` and `/etc/profile.d/gemini-cli.sh`.
3. **Per-User Fixes:** Iterates through all users and:
   - Modifies their personal `settings.json` to the corporate auth type.
   - Deletes `oauth_creds.json` if they were logged in with a personal account (forcing a new login).
   - Injects the GCP project into their `.bashrc`, `.profile`, and `.zshrc`.
   - **Fixes permissions:** Ensures the `~/.gemini/` folder is owned by the user (fixing scenarios where `sudo gemini` was run by mistake).
4. **Safety:** Automatically creates backups of all modified files in `/var/backups/gemini-cli-remediation/`.

### `Fix-NodeTLS.sh` (Optional/Standalone)
A standalone script to fix `"Premature close"` or `"Failed to sign in"` errors caused by corporate network SSL inspection. It forcefully injects `NODE_TLS_REJECT_UNAUTHORIZED=0` globally across all shell profiles.

## Deployment Instructions

Before deploying, you **must** configure the variables at the top of the scripts to match your environment.

### 1. Configuration (`Remediate.sh` and `Detect.sh`)
Edit the `Remediate.sh` script and set your organization's GCP Project ID:

```bash
# Organization GCP Project
GOOGLE_CLOUD_PROJECT="YOUR_GCP_PROJECT_ID"
```

### 2. Microsoft Intune for Linux
1. Go to the Intune portal: **Devices > Scripts and remediations > Create**
2. Configure the deployment:
   - **Detection script:** `Detect.sh`
   - **Remediation script:** `Remediate.sh`
   - **Run as:** `Root`
   - **Run frequency:** Daily (or weekly after stabilization)
3. Assign to your Ubuntu device groups.

### 3. User Experience Post-Remediation
After the remediation runs, ask the affected developer to:
1. Close all active terminals (including VS Code integrated terminals).
2. Open a new terminal.
3. Run `gemini` again.
4. The login flow will now automatically present the corporate GCP authentication flow.
