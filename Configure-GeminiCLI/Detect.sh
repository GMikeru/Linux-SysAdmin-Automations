#!/usr/bin/env bash
# =============================================================================
# Detect.sh — Gemini CLI Diagnostic Script (Ubuntu)
# Compatible with: Microsoft Intune for Linux / Canonical Landscape
#
# Usage: sudo bash Detect.sh
#
# Exit codes:
#   0 = All users with Gemini CLI are configured correctly
#   1 = Problems found (details in stdout)
# =============================================================================

set -euo pipefail

# ============================ CONFIGURATION ====================================
# Expected GCP project for corporate license
EXPECTED_PROJECT="YOUR_GCP_PROJECT_ID"

# Auth types considered "correct" (corporate)
# After running this script on a working machine, update this list if needed
VALID_AUTH_TYPES=("gcp" "oauth-google-cloud" "google-cloud")

# Auth type considered "problematic" (personal flow)
BAD_AUTH_TYPE="oauth-personal"

# Minimum UID to consider as a human user (Ubuntu default = 1000)
MIN_UID=1000

# System users to ignore even if UID >= 1000
IGNORE_USERS=("nobody" "nfsnobody" "splunk")
# ==============================================================================

# Colors for readable output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Reset

# Problem counters
PROBLEMS_FOUND=0
USERS_CHECKED=0
USERS_WITH_GEMINI=0

# Timestamp for the log
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
HOSTNAME_INFO=$(hostname -f 2>/dev/null || hostname)

# ==============================================================================
# Helper Functions
# ==============================================================================

log_header() {
    echo ""
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

log_section() {
    echo ""
    echo -e "${BOLD}── $1 ──${NC}"
}

log_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "  ${YELLOW}[WARNING]${NC} $1"
    ((PROBLEMS_FOUND++)) || true
}

log_fail() {
    echo -e "  ${RED}[FAILED]${NC} $1"
    ((PROBLEMS_FOUND++)) || true
}

log_info() {
    echo -e "  ${CYAN}[INFO]${NC} $1"
}

# Checks if a user is in the ignored list
is_ignored_user() {
    local user="$1"
    for ignored in "${IGNORE_USERS[@]}"; do
        if [[ "$user" == "$ignored" ]]; then
            return 0
        fi
    done
    return 1
}

# Extracts selectedType from settings.json (handles nested JSON)
get_selected_type() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep -oP '"selectedType"\s*:\s*"\K[^"]+' "$file" 2>/dev/null | head -1
    fi
}

# ==============================================================================
# Prerequisites Check
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: This script must be run as root (sudo).${NC}"
    exit 1
fi

# ==============================================================================
# DIAGNOSTICS START
# ==============================================================================

log_header "GEMINI CLI DIAGNOSTICS — $TIMESTAMP"
echo -e "  Hostname: ${BOLD}${HOSTNAME_INFO}${NC}"
echo -e "  OS:       $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo -e "  Kernel:   $(uname -r)"
echo -e "  Uptime:   $(uptime -p 2>/dev/null || uptime)"

# ==============================================================================
# 1. GEMINI BINARY INFO
# ==============================================================================

log_header "1. GEMINI CLI BINARY"

GEMINI_PATH=$(which gemini 2>/dev/null || true)
if [[ -n "$GEMINI_PATH" ]]; then
    log_ok "Gemini CLI found at: ${BOLD}${GEMINI_PATH}${NC}"

    # Check if symlink
    if [[ -L "$GEMINI_PATH" ]]; then
        REAL_PATH=$(readlink -f "$GEMINI_PATH")
        log_info "Symlink points to: $REAL_PATH"
    fi

    # Check binary permissions
    GEMINI_PERMS=$(stat -c '%a %U:%G' "$GEMINI_PATH" 2>/dev/null || true)
    log_info "Binary permissions: $GEMINI_PERMS"

    # CLI Version
    GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "Unable to get version")
    log_info "Version: $GEMINI_VERSION"
else
    log_fail "Gemini CLI NOT found in the system PATH"
fi

# Node.js
log_section "Node.js"
NODE_PATH=$(which node 2>/dev/null || true)
if [[ -n "$NODE_PATH" ]]; then
    NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
    log_ok "Node.js found: $NODE_PATH (version: $NODE_VERSION)"
else
    log_warn "Node.js NOT found in the system PATH"
fi

NPM_PATH=$(which npm 2>/dev/null || true)
if [[ -n "$NPM_PATH" ]]; then
    NPM_VERSION=$(npm --version 2>/dev/null || echo "unknown")
    log_info "npm: $NPM_PATH (version: $NPM_VERSION)"
fi

# ==============================================================================
# 2. MACHINE SCOPE CONFIGURATION (/etc/gemini-cli/)
# ==============================================================================

log_header "2. MACHINE SCOPE (/etc/gemini-cli/)"

# /etc/gemini-cli/settings.json (Override)
if [[ -f /etc/gemini-cli/settings.json ]]; then
    log_ok "/etc/gemini-cli/settings.json EXISTS"
    log_info "Content:"
    sed 's/^/    /' /etc/gemini-cli/settings.json
    echo ""

    MACHINE_AUTH_TYPE=$(get_selected_type /etc/gemini-cli/settings.json)
    if [[ -n "$MACHINE_AUTH_TYPE" ]]; then
        log_info "selectedType (machine): ${BOLD}${MACHINE_AUTH_TYPE}${NC}"
    fi
else
    log_warn "/etc/gemini-cli/settings.json DOES NOT EXIST (no system override)"
fi

# /etc/gemini-cli/system-defaults.json
if [[ -f /etc/gemini-cli/system-defaults.json ]]; then
    log_ok "/etc/gemini-cli/system-defaults.json EXISTS"
    log_info "Content:"
    sed 's/^/    /' /etc/gemini-cli/system-defaults.json
    echo ""
else
    log_info "/etc/gemini-cli/system-defaults.json does not exist (normal if never configured)"
fi

# List directory contents if it exists
if [[ -d /etc/gemini-cli ]]; then
    log_section "Full content of /etc/gemini-cli/"
    ls -la /etc/gemini-cli/ 2>/dev/null | sed 's/^/    /'
fi

# ==============================================================================
# 3. SYSTEM ENVIRONMENT VARIABLES
# ==============================================================================

log_header "3. SYSTEM ENVIRONMENT VARIABLES"

# /etc/environment
log_section "/etc/environment"
if [[ -f /etc/environment ]]; then
    GCLOUD_IN_ENV=$(grep -i "GOOGLE_CLOUD_PROJECT" /etc/environment 2>/dev/null || true)
    if [[ -n "$GCLOUD_IN_ENV" ]]; then
        log_ok "GOOGLE_CLOUD_PROJECT defined in /etc/environment: ${BOLD}${GCLOUD_IN_ENV}${NC}"
    else
        log_warn "GOOGLE_CLOUD_PROJECT NOT defined in /etc/environment"
    fi

    NODE_CA_IN_ENV=$(grep -i "NODE_USE_SYSTEM_CA\|NODE_EXTRA_CA_CERTS" /etc/environment 2>/dev/null || true)
    if [[ -n "$NODE_CA_IN_ENV" ]]; then
        log_info "Node CA variables in /etc/environment: $NODE_CA_IN_ENV"
    else
        log_info "NODE_USE_SYSTEM_CA / NODE_EXTRA_CA_CERTS not defined in /etc/environment (OK without SSL proxy)"
    fi
else
    log_warn "/etc/environment not found"
fi

# /etc/profile.d/ (global scripts)
log_section "/etc/profile.d/ (scripts with gemini/google)"
PROFILE_D_HITS=$(grep -rl -i "GOOGLE_CLOUD_PROJECT\|gemini" /etc/profile.d/ 2>/dev/null || true)
if [[ -n "$PROFILE_D_HITS" ]]; then
    log_ok "Relevant scripts found in /etc/profile.d/:"
    echo "$PROFILE_D_HITS" | while read -r f; do
        log_info "  File: $f"
        grep -i "GOOGLE_CLOUD_PROJECT\|gemini" "$f" 2>/dev/null | sed 's/^/      /'
    done
else
    log_info "No gemini/google scripts in /etc/profile.d/"
fi

# ==============================================================================
# 4. IDENTITY PROVIDER (SSSD / Entra ID)
# ==============================================================================

log_header "4. IDENTITY PROVIDER"

# Check SSSD (used by Intune for Entra ID)
if systemctl is-active --quiet sssd 2>/dev/null; then
    log_ok "SSSD is ACTIVE (Entra ID/LDAP users will be detected)"
    SSSD_DOMAINS=$(grep -oP 'domains\s*=\s*\K.*' /etc/sssd/sssd.conf 2>/dev/null || echo "not found")
    log_info "SSSD Domains: $SSSD_DOMAINS"
elif systemctl list-unit-files | grep -q sssd 2>/dev/null; then
    log_warn "SSSD is installed but INACTIVE — Entra ID users may not appear"
else
    log_info "SSSD not installed (using only local authentication)"
fi

# Check Intune agent
if command -v intune-portal &>/dev/null || [[ -d /opt/microsoft/intune ]]; then
    log_ok "Microsoft Intune agent detected"
fi

# ==============================================================================
# 5. PER-USER DIAGNOSTICS
# ==============================================================================

log_header "5. PER-USER DIAGNOSTICS"

# Phase 1: Collect users from ALL sources (local + SSSD/LDAP/Entra ID)
# getent passwd queries all configured NSS backends
USERS_SEEN=()

log_info "Source: getent passwd (local + SSSD/LDAP/Entra ID)"
while IFS=: read -r username _ uid _ _ homedir shell; do
    # Skip if UID < minimum
    [[ "$uid" -lt "$MIN_UID" ]] && continue

    # Skip ignored users
    is_ignored_user "$username" && continue

    # Skip if shell is nologin or false
    [[ "$shell" == */nologin ]] && continue
    [[ "$shell" == */false ]] && continue

    # Skip if homedir doesn't exist
    [[ ! -d "$homedir" ]] && continue

    ((USERS_CHECKED++)) || true
    USERS_SEEN+=("$username")

    log_section "User: ${BOLD}${username}${NC} (UID: $uid, Home: $homedir)"
    echo -e "  Shell: $shell"

    # ---- .gemini Directory ----
    GEMINI_DIR="$homedir/.gemini"

    if [[ ! -d "$GEMINI_DIR" ]]; then
        log_info "Directory $GEMINI_DIR DOES NOT EXIST (user never ran Gemini CLI)"
        continue
    fi

    ((USERS_WITH_GEMINI++)) || true

    # Directory ownership
    GEMINI_OWNER=$(stat -c '%U:%G' "$GEMINI_DIR" 2>/dev/null || echo "unknown")
    if [[ "$GEMINI_OWNER" == "${username}:"* ]]; then
        log_ok "Ownership of .gemini/: $GEMINI_OWNER"
    else
        log_fail "INCORRECT ownership of .gemini/: $GEMINI_OWNER (expected: ${username}:${username})"
    fi

    # List contents
    log_info "Contents of $GEMINI_DIR/:"
    ls -la "$GEMINI_DIR/" 2>/dev/null | sed 's/^/      /'
    echo ""

    # ---- settings.json (User Scope) ----
    SETTINGS_FILE="$GEMINI_DIR/settings.json"
    if [[ -f "$SETTINGS_FILE" ]]; then
        log_ok "settings.json exists"
        log_info "Content:"
        sed 's/^/      /' "$SETTINGS_FILE"
        echo ""

        # Extract selectedType
        USER_AUTH_TYPE=$(get_selected_type "$SETTINGS_FILE")
        if [[ -n "$USER_AUTH_TYPE" ]]; then
            if [[ "$USER_AUTH_TYPE" == "$BAD_AUTH_TYPE" ]]; then
                log_fail "selectedType = \"${BOLD}${USER_AUTH_TYPE}${NC}\" ← PROBLEM: personal authentication (not corporate)"
            else
                log_ok "selectedType = \"${BOLD}${USER_AUTH_TYPE}${NC}\""
            fi
        else
            log_warn "selectedType not found in settings.json"
        fi
    else
        log_info "settings.json DOES NOT EXIST (no user configuration)"
    fi

    # ---- oauth_creds.json ----
    OAUTH_FILE="$GEMINI_DIR/oauth_creds.json"
    if [[ -f "$OAUTH_FILE" ]]; then
        OAUTH_PERMS=$(stat -c '%a %U:%G %s bytes' "$OAUTH_FILE" 2>/dev/null || echo "unknown")
        OAUTH_MODIFIED=$(stat -c '%y' "$OAUTH_FILE" 2>/dev/null || echo "unknown")
        log_ok "oauth_creds.json exists (${OAUTH_PERMS}, modified: ${OAUTH_MODIFIED})"

        # Check ownership
        OAUTH_OWNER=$(stat -c '%U' "$OAUTH_FILE" 2>/dev/null || echo "unknown")
        if [[ "$OAUTH_OWNER" != "$username" ]]; then
            log_fail "oauth_creds.json belongs to '${OAUTH_OWNER}', should be '${username}'"
        fi

        # DO NOT display contents (contains sensitive tokens)
        # Just check if it has content
        OAUTH_SIZE=$(stat -c '%s' "$OAUTH_FILE" 2>/dev/null || echo "0")
        if [[ "$OAUTH_SIZE" -lt 10 ]]; then
            log_warn "oauth_creds.json appears empty or corrupted (size: ${OAUTH_SIZE} bytes)"
        fi
    else
        log_info "oauth_creds.json DOES NOT EXIST (user not logged in or credentials cleared)"
    fi

    # ---- google_accounts.json ----
    GACCOUNTS_FILE="$GEMINI_DIR/google_accounts.json"
    if [[ -f "$GACCOUNTS_FILE" ]]; then
        log_ok "google_accounts.json exists"
        log_info "Content:"
        sed 's/^/      /' "$GACCOUNTS_FILE"
        echo ""
    fi

    # ---- state.json ----
    STATE_FILE="$GEMINI_DIR/state.json"
    if [[ -f "$STATE_FILE" ]]; then
        log_info "state.json:"
        sed 's/^/      /' "$STATE_FILE"
        echo ""
    fi

    # ---- projects.json ----
    PROJECTS_FILE="$GEMINI_DIR/projects.json"
    if [[ -f "$PROJECTS_FILE" ]]; then
        log_ok "projects.json exists"
        log_info "Content:"
        sed 's/^/      /' "$PROJECTS_FILE"
        echo ""
    fi

    # ---- installation_id ----
    INSTALL_ID_FILE="$GEMINI_DIR/installation_id"
    if [[ -f "$INSTALL_ID_FILE" ]]; then
        log_info "installation_id: $(cat "$INSTALL_ID_FILE" 2>/dev/null)"
    fi

    # ---- Variables in user's .bashrc / .profile / .zshrc ----
    log_section "  Environment variables for user $username"
    for rcfile in ".bashrc" ".profile" ".zshrc" ".bash_profile"; do
        RCPATH="$homedir/$rcfile"
        if [[ -f "$RCPATH" ]]; then
            GCLOUD_HIT=$(grep -n "GOOGLE_CLOUD_PROJECT\|GOOGLE_APPLICATION_CREDENTIALS\|NODE_USE_SYSTEM_CA\|NODE_EXTRA_CA_CERTS" "$RCPATH" 2>/dev/null || true)
            if [[ -n "$GCLOUD_HIT" ]]; then
                log_ok "$rcfile contains relevant variables:"
                echo "$GCLOUD_HIT" | sed 's/^/        /'
            else
                log_info "$rcfile: no google/node variables found"
            fi
        fi
    done

    # ---- Check variables loaded via /proc (if user has active processes) ----
    USER_PID=$(pgrep -u "$username" -o 2>/dev/null || true)
    if [[ -n "$USER_PID" ]]; then
        log_section "  Variables loaded in runtime (PID: $USER_PID)"
        PROC_ENV=$(cat "/proc/$USER_PID/environ" 2>/dev/null | tr '\0' '\n' || true)

        RUNTIME_PROJECT=$(echo "$PROC_ENV" | grep "GOOGLE_CLOUD_PROJECT" || true)
        if [[ -n "$RUNTIME_PROJECT" ]]; then
            log_ok "Runtime: $RUNTIME_PROJECT"
        else
            log_warn "Runtime: GOOGLE_CLOUD_PROJECT is NOT loaded in the active session"
        fi

        RUNTIME_NODE_CA=$(echo "$PROC_ENV" | grep "NODE_USE_SYSTEM_CA\|NODE_EXTRA_CA_CERTS" || true)
        if [[ -n "$RUNTIME_NODE_CA" ]]; then
            log_info "Runtime: $RUNTIME_NODE_CA"
        fi
    else
        log_info "User $username has no active processes (cannot check runtime)"
    fi

    # ---- Check if gemini is running for this user ----
    GEMINI_PROCS=$(pgrep -u "$username" -a 2>/dev/null | grep -i "gemini" || true)
    if [[ -n "$GEMINI_PROCS" ]]; then
        log_info "Active Gemini processes for $username:"
        echo "$GEMINI_PROCS" | sed 's/^/      /'
    fi

    echo ""

done < <(getent passwd 2>/dev/null || cat /etc/passwd)

# Phase 2: Scan /home/ to discover users that DID NOT appear in getent
# (e.g., Entra ID users with cached sessions, or manually created)
log_section "Scanning /home/ (users not found via getent)"
HOME_SCAN_FOUND=0

for user_home in /home/*/; do
    [[ ! -d "$user_home" ]] && continue
    dir_username=$(basename "$user_home")

    # Skip if already processed in phase 1
    already_seen=false
    for seen in "${USERS_SEEN[@]:-}"; do
        [[ "$seen" == "$dir_username" ]] && already_seen=true && break
    done
    $already_seen && continue

    # Skip ignored
    is_ignored_user "$dir_username" && continue

    # Attempt to resolve user via getent (by name)
    user_entry=$(getent passwd "$dir_username" 2>/dev/null || true)
    if [[ -n "$user_entry" ]]; then
        uid=$(echo "$user_entry" | cut -d: -f3)
        shell=$(echo "$user_entry" | cut -d: -f7)
    else
        # User does not exist in any backend — get UID from filesystem
        uid=$(stat -c '%u' "$user_home" 2>/dev/null || echo "???")
        shell="unknown"
    fi

    ((HOME_SCAN_FOUND++)) || true
    ((USERS_CHECKED++)) || true

    log_section "User: ${BOLD}${dir_username}${NC} (UID: $uid, Home: $user_home) [DISCOVERED VIA /home/]"
    echo -e "  Shell: $shell"
    echo -e "  ${YELLOW}[NOTE]${NC} This user DID NOT appear in getent passwd — might be cached Entra ID/SSSD"

    GEMINI_DIR="${user_home}.gemini"

    if [[ ! -d "$GEMINI_DIR" ]]; then
        log_info "Directory $GEMINI_DIR DOES NOT EXIST (user never ran Gemini CLI)"
        continue
    fi

    ((USERS_WITH_GEMINI++)) || true

    # Folder ownership
    GEMINI_OWNER=$(stat -c '%U:%G' "$GEMINI_DIR" 2>/dev/null || echo "unknown")
    log_info "Ownership of .gemini/: $GEMINI_OWNER"

    # settings.json
    SETTINGS_FILE="$GEMINI_DIR/settings.json"
    if [[ -f "$SETTINGS_FILE" ]]; then
        log_ok "settings.json exists"
        log_info "Content:"
        sed 's/^/      /' "$SETTINGS_FILE"
        echo ""

        USER_AUTH_TYPE=$(get_selected_type "$SETTINGS_FILE")
        if [[ -n "$USER_AUTH_TYPE" ]]; then
            if [[ "$USER_AUTH_TYPE" == "$BAD_AUTH_TYPE" ]]; then
                log_fail "selectedType = \"${BOLD}${USER_AUTH_TYPE}${NC}\" ← PROBLEM: personal authentication"
            else
                log_ok "selectedType = \"${BOLD}${USER_AUTH_TYPE}${NC}\""
            fi
        fi
    else
        log_info "settings.json DOES NOT EXIST"
    fi

    # oauth_creds.json
    OAUTH_FILE="$GEMINI_DIR/oauth_creds.json"
    if [[ -f "$OAUTH_FILE" ]]; then
        OAUTH_PERMS=$(stat -c '%a %U:%G %s bytes' "$OAUTH_FILE" 2>/dev/null || echo "unknown")
        log_ok "oauth_creds.json exists ($OAUTH_PERMS)"
    fi

    # google_accounts.json
    GACCOUNTS_FILE="$GEMINI_DIR/google_accounts.json"
    if [[ -f "$GACCOUNTS_FILE" ]]; then
        log_ok "google_accounts.json exists"
        log_info "Content:"
        sed 's/^/      /' "$GACCOUNTS_FILE"
        echo ""
    fi

    echo ""
done

if [[ $HOME_SCAN_FOUND -eq 0 ]]; then
    log_info "No additional users found in /home/"
else
    log_ok "Found $HOME_SCAN_FOUND additional user(s) via /home/ scan"
fi

# ==============================================================================
# 6. SUMMARY
# ==============================================================================

log_header "6. DIAGNOSTICS SUMMARY"
echo ""
echo -e "  Hostname:                ${BOLD}${HOSTNAME_INFO}${NC}"
echo -e "  Timestamp:               ${TIMESTAMP}"
echo -e "  Users checked:           ${BOLD}${USERS_CHECKED}${NC}"
echo -e "  Users with .gemini/:     ${BOLD}${USERS_WITH_GEMINI}${NC}"
echo -e "  Problems found:          ${BOLD}${PROBLEMS_FOUND}${NC}"
echo ""

if [[ $PROBLEMS_FOUND -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✓ RESULT: COMPLIANT — No problems found${NC}"
    echo ""
    exit 0
else
    echo -e "  ${RED}${BOLD}✗ RESULT: NON-COMPLIANT — $PROBLEMS_FOUND problem(s) found${NC}"
    echo -e "  ${YELLOW}Run the remediation script (Remediate.sh) to fix.${NC}"
    echo ""
    exit 1
fi
