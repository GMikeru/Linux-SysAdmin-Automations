#!/usr/bin/env bash
# =============================================================================
# Remediate.sh — Gemini CLI Remediation Script (Ubuntu)
# Compatible with: Microsoft Intune for Linux / Canonical Landscape
#
# Usage: sudo bash Remediate.sh
#
# What this script does:
#   1. Creates /etc/gemini-cli/settings.json with corporate auth (Machine Scope)
#   2. Injects GOOGLE_CLOUD_PROJECT into /etc/environment and /etc/profile.d/
#   3. For each user with .gemini/:
#      - BACKS UP the original settings.json and oauth_creds.json
#      - Fixes selectedType to the corporate type
#      - Injects GOOGLE_CLOUD_PROJECT into .bashrc and .profile
#      - Fixes ownership of the entire .gemini/ folder
#   4. Generates a complete log of actions taken
#
# Exit codes:
#   0 = Remediation completed successfully
#   1 = Errors during remediation (check log)
# =============================================================================

set -uo pipefail
# Note: We DO NOT use "set -e" here to avoid aborting on partial failures
# Every failure is registered and counted

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  CONFIGURATION — ADJUST THESE VALUES BEFORE PRODUCTION DEPLOYMENT         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Organization GCP Project
GOOGLE_CLOUD_PROJECT="YOUR_GCP_PROJECT_ID"

# Corporate authentication type
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ IMPORTANT: Run Detect.sh on a WORKING machine and copy the exact        │
# │ value of selectedType that appears in its settings.json.                │
# │                                                                         │
# │ Possible values (verify which one is used in your environment):         │
# │   "gcp"                   — Google Cloud Platform auth                  │
# │   "oauth-google-cloud"    — OAuth via Google Cloud                      │
# │   "google-cloud"          — Google Cloud variant                        │
# │   "oauth-personal"        — Personal OAuth (DO NOT USE — this is the bug) │
# └─────────────────────────────────────────────────────────────────────────┘
AUTH_TYPE="gcp"

# Authentication type to be replaced (the problematic value)
BAD_AUTH_TYPE="oauth-personal"

# Minimum UID to consider as a human user
MIN_UID=1000

# System users to ignore even if UID >= 1000
IGNORE_USERS=("nobody" "nfsnobody" "splunk")

# Backup directory
BACKUP_BASE="/var/backups/gemini-cli-remediation"

# ==============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
ACTIONS_OK=0
ACTIONS_FAIL=0
USERS_REMEDIATED=0

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
TIMESTAMP_HUMAN=$(date '+%Y-%m-%d %H:%M:%S %Z')
HOSTNAME_INFO=$(hostname -f 2>/dev/null || hostname)
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"

# Log file
LOG_FILE="/var/log/gemini-cli-remediation-${TIMESTAMP}.log"

# ==============================================================================
# Functions
# ==============================================================================

log_header() {
    local msg="$1"
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${CYAN}  $msg${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BOLD}── $1 ──${NC}" | tee -a "$LOG_FILE"
}

log_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
    ((ACTIONS_OK++)) || true
}

log_fail() {
    echo -e "  ${RED}[FAILED]${NC} $1" | tee -a "$LOG_FILE"
    ((ACTIONS_FAIL++)) || true
}

log_info() {
    echo -e "  ${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_action() {
    echo -e "  ${YELLOW}[ACTION]${NC} $1" | tee -a "$LOG_FILE"
}

is_ignored_user() {
    local user="$1"
    for ignored in "${IGNORE_USERS[@]}"; do
        [[ "$user" == "$ignored" ]] && return 0
    done
    return 1
}

get_selected_type() {
    local file="$1"
    [[ -f "$file" ]] && grep -oP '"selectedType"\s*:\s*"\K[^"]+' "$file" 2>/dev/null | head -1
}

# Safely back up a file
backup_file() {
    local src="$1"
    local username="$2"

    if [[ -f "$src" ]]; then
        local dest_dir="${BACKUP_DIR}/${username}"
        mkdir -p "$dest_dir"
        local basename_file=$(basename "$src")
        cp -p "$src" "${dest_dir}/${basename_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            log_info "Backup: $src → ${dest_dir}/${basename_file}"
        else
            log_fail "Failed to backup $src"
        fi
    fi
}

# Inject a line into a file if it doesn't already exist
# If it does exist (including duplicates), remove ALL occurrences and add a single clean line
inject_line() {
    local file="$1"
    local line="$2"
    local search_pattern="$3"

    if [[ -f "$file" ]]; then
        local count
        count=$(grep -c "$search_pattern" "$file" 2>/dev/null) || count=0

        if [[ "$count" -gt 0 ]]; then
            # Remove ALL lines containing the pattern (clear duplicates)
            sed -i "/${search_pattern}/d" "$file" 2>/dev/null
            # Add a single clean line at the end
            echo "$line" >> "$file"
            if [[ "$count" -gt 1 ]]; then
                log_info "Removed $count duplicates and added 1 clean line in $file: $line"
            else
                log_info "Updated in $file: $line"
            fi
        else
            # Add at the end
            echo "$line" >> "$file"
            log_info "Added in $file: $line"
        fi
    else
        # Create the file
        echo "$line" > "$file"
        log_info "Created $file with: $line"
    fi
}

# ==============================================================================
# Prerequisites Check
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: This script must be run as root (sudo).${NC}"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# ==============================================================================
# REMEDIATION START
# ==============================================================================

log_header "GEMINI CLI REMEDIATION — $TIMESTAMP_HUMAN"
echo -e "  Hostname:     ${BOLD}${HOSTNAME_INFO}${NC}" | tee -a "$LOG_FILE"
echo -e "  GCP Project:  ${BOLD}${GOOGLE_CLOUD_PROJECT}${NC}" | tee -a "$LOG_FILE"
echo -e "  Auth Type:    ${BOLD}${AUTH_TYPE}${NC}" | tee -a "$LOG_FILE"
echo -e "  Backup Dir:   ${BOLD}${BACKUP_DIR}${NC}" | tee -a "$LOG_FILE"
echo -e "  Log File:     ${BOLD}${LOG_FILE}${NC}" | tee -a "$LOG_FILE"

# ==============================================================================
# STEP 1: MACHINE SCOPE — /etc/gemini-cli/settings.json
# ==============================================================================

log_header "STEP 1: Machine Scope Configuration"

log_action "Creating /etc/gemini-cli/"
mkdir -p /etc/gemini-cli

# Backup existing
if [[ -f /etc/gemini-cli/settings.json ]]; then
    backup_file "/etc/gemini-cli/settings.json" "_system"
fi

log_action "Writing /etc/gemini-cli/settings.json"
cat << EOF > /etc/gemini-cli/settings.json
{
  "security": {
    "auth": {
      "selectedType": "${AUTH_TYPE}"
    }
  }
}
EOF

if [[ $? -eq 0 ]]; then
    log_ok "/etc/gemini-cli/settings.json created with selectedType=\"${AUTH_TYPE}\""
else
    log_fail "Failed to create /etc/gemini-cli/settings.json"
fi

# Permissions: readable by all, writable only by root
chmod 644 /etc/gemini-cli/settings.json 2>/dev/null
chmod 755 /etc/gemini-cli 2>/dev/null

# ==============================================================================
# STEP 2: SYSTEM ENVIRONMENT VARIABLES
# ==============================================================================

log_header "STEP 2: System Environment Variables"

# ---- /etc/environment (loaded by PAM in login sessions) ----
log_section "/etc/environment"

if [[ -f /etc/environment ]]; then
    backup_file "/etc/environment" "_system"
fi

# /etc/environment DOES NOT use 'export' — correct format is KEY="value"
inject_line "/etc/environment" "GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\"" "GOOGLE_CLOUD_PROJECT"
log_ok "GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\" defined in /etc/environment"

# ---- /etc/profile.d/ (loaded by login shells: bash, zsh, etc.) ----
log_section "/etc/profile.d/gemini-cli.sh"

PROFILED_FILE="/etc/profile.d/gemini-cli.sh"
if [[ -f "$PROFILED_FILE" ]]; then
    backup_file "$PROFILED_FILE" "_system"
fi

cat << EOF > "$PROFILED_FILE"
# Gemini CLI — Corporate configuration
# Automatically generated by Remediate.sh on ${TIMESTAMP_HUMAN}
# DO NOT EDIT MANUALLY — will be overwritten on the next script execution
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT}"
EOF

chmod 644 "$PROFILED_FILE" 2>/dev/null
log_ok "Created /etc/profile.d/gemini-cli.sh with export GOOGLE_CLOUD_PROJECT"

# ==============================================================================
# STEP 3: PER-USER REMEDIATION
# ==============================================================================

log_header "STEP 3: Per-User Remediation"

# Phase 1: Users from ALL sources (local + SSSD/LDAP/Entra ID)
log_info "Source: getent passwd (local + SSSD/LDAP/Entra ID)"
USERS_SEEN=()

while IFS=: read -r username _ uid gid _ homedir shell; do
    # Filters
    [[ "$uid" -lt "$MIN_UID" ]] && continue
    is_ignored_user "$username" && continue
    [[ "$shell" == */nologin ]] && continue
    [[ "$shell" == */false ]] && continue
    [[ ! -d "$homedir" ]] && continue

    log_section "User: ${BOLD}${username}${NC} (UID: $uid)"

    GEMINI_DIR="$homedir/.gemini"
    SETTINGS_FILE="$GEMINI_DIR/settings.json"
    OAUTH_FILE="$GEMINI_DIR/oauth_creds.json"

    # Get user's primary group
    USER_GROUP=$(id -gn "$username" 2>/dev/null || echo "$username")

    # ---- Create .gemini/ if it doesn't exist ----
    if [[ ! -d "$GEMINI_DIR" ]]; then
        log_info "Directory $GEMINI_DIR does not exist — creating"
        mkdir -p "$GEMINI_DIR"
        chown "${username}:${USER_GROUP}" "$GEMINI_DIR"
        chmod 755 "$GEMINI_DIR"
    fi

    # ---- settings.json ----
    if [[ -f "$SETTINGS_FILE" ]]; then
        CURRENT_AUTH=$(get_selected_type "$SETTINGS_FILE")

        if [[ "$CURRENT_AUTH" == "$BAD_AUTH_TYPE" ]]; then
            log_action "selectedType is \"${BAD_AUTH_TYPE}\" — FIXING to \"${AUTH_TYPE}\""

            # Backup
            backup_file "$SETTINGS_FILE" "$username"

            # Replace value
            sed -i "s/\"selectedType\":\s*\"${BAD_AUTH_TYPE}\"/\"selectedType\": \"${AUTH_TYPE}\"/" "$SETTINGS_FILE" 2>/dev/null

            # Verify if it worked
            NEW_AUTH=$(get_selected_type "$SETTINGS_FILE")
            if [[ "$NEW_AUTH" == "$AUTH_TYPE" ]]; then
                log_ok "settings.json fixed: selectedType=\"${AUTH_TYPE}\""
            else
                # Fallback: rewrite the entire file
                log_info "sed failed, rewriting settings.json from scratch"
                cat << EOF > "$SETTINGS_FILE"
{
  "security": {
    "auth": {
      "selectedType": "${AUTH_TYPE}"
    }
  },
  "ide": {
    "hasSeenNudge": true,
    "enabled": true
  }
}
EOF
                log_ok "settings.json recreated with selectedType=\"${AUTH_TYPE}\""
            fi

        elif [[ "$CURRENT_AUTH" == "$AUTH_TYPE" ]]; then
            log_ok "selectedType is already correct: \"${AUTH_TYPE}\" — no action needed"

        elif [[ -z "$CURRENT_AUTH" ]]; then
            log_action "selectedType not found — adding configuration"
            backup_file "$SETTINGS_FILE" "$username"
            cat << EOF > "$SETTINGS_FILE"
{
  "security": {
    "auth": {
      "selectedType": "${AUTH_TYPE}"
    }
  },
  "ide": {
    "hasSeenNudge": true,
    "enabled": true
  }
}
EOF
            log_ok "settings.json recreated with selectedType=\"${AUTH_TYPE}\""

        else
            log_info "Current selectedType: \"${CURRENT_AUTH}\" (is not \"${BAD_AUTH_TYPE}\") — keeping"
        fi
    else
        # Create settings.json from scratch
        log_action "settings.json does not exist — creating"
        cat << EOF > "$SETTINGS_FILE"
{
  "security": {
    "auth": {
      "selectedType": "${AUTH_TYPE}"
    }
  },
  "ide": {
    "hasSeenNudge": true,
    "enabled": true
  }
}
EOF
        log_ok "settings.json created with selectedType=\"${AUTH_TYPE}\""
    fi

    # ---- Invalidate personal flow credentials ----
    if [[ -f "$OAUTH_FILE" ]]; then
        # Only remove if the type WAS wrong (to force new corporate login)
        ORIGINAL_AUTH=$(get_selected_type "${BACKUP_DIR}/${username}/settings.json" 2>/dev/null || echo "")
        if [[ "$ORIGINAL_AUTH" == "$BAD_AUTH_TYPE" ]]; then
            backup_file "$OAUTH_FILE" "$username"
            rm -f "$OAUTH_FILE"
            log_action "oauth_creds.json removed (invalid personal flow credentials)"
            log_info "Backup saved at: ${BACKUP_DIR}/${username}/oauth_creds.json"
        else
            log_info "oauth_creds.json kept (auth type was not \"${BAD_AUTH_TYPE}\")"
        fi
    fi

    # ---- Variables in .bashrc ----
    BASHRC="$homedir/.bashrc"
    if [[ -f "$BASHRC" ]]; then
        inject_line "$BASHRC" "export GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\"" "GOOGLE_CLOUD_PROJECT"
    fi

    # ---- Variables in .profile ----
    PROFILE="$homedir/.profile"
    if [[ -f "$PROFILE" ]]; then
        inject_line "$PROFILE" "export GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\"" "GOOGLE_CLOUD_PROJECT"
    fi

    # ---- Variables in .zshrc (if it exists) ----
    ZSHRC="$homedir/.zshrc"
    if [[ -f "$ZSHRC" ]]; then
        inject_line "$ZSHRC" "export GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\"" "GOOGLE_CLOUD_PROJECT"
    fi

    # ---- Fix ownership of EVERYTHING in the .gemini/ folder ----
    log_action "Fixing ownership of $GEMINI_DIR/"
    chown -R "${username}:${USER_GROUP}" "$GEMINI_DIR" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        log_ok "Ownership fixed to ${username}:${USER_GROUP}"
    else
        log_fail "Failed to fix ownership of $GEMINI_DIR/"
    fi

    # ---- Fix ownership of profile files ----
    for rcfile in "$BASHRC" "$PROFILE" "$ZSHRC"; do
        if [[ -f "$rcfile" ]]; then
            chown "${username}:${USER_GROUP}" "$rcfile" 2>/dev/null
        fi
    done

    ((USERS_REMEDIATED++)) || true
    USERS_SEEN+=("$username")

done < <(getent passwd 2>/dev/null || cat /etc/passwd)

# Phase 2: Scan /home/ for Entra ID/SSSD users that didn't appear in getent
log_section "Scanning /home/ (users not found via getent)"

for user_home in /home/*/; do
    [[ ! -d "$user_home" ]] && continue
    dir_username=$(basename "$user_home")

    # Skip if already processed
    already_seen=false
    for seen in "${USERS_SEEN[@]:-}"; do
        [[ "$seen" == "$dir_username" ]] && already_seen=true && break
    done
    $already_seen && continue

    # Skip ignored
    is_ignored_user "$dir_username" && continue

    log_section "User: ${BOLD}${dir_username}${NC} (Home: $user_home) [DISCOVERED VIA /home/]"
    log_info "This user did not appear in getent passwd — might be cached Entra ID/SSSD"

    # Attempt to get group
    USER_GROUP=$(id -gn "$dir_username" 2>/dev/null || stat -c '%G' "$user_home" 2>/dev/null || echo "$dir_username")

    GEMINI_DIR="${user_home}.gemini"
    SETTINGS_FILE="$GEMINI_DIR/settings.json"
    OAUTH_FILE="$GEMINI_DIR/oauth_creds.json"

    # Create .gemini/ if it doesn't exist
    if [[ ! -d "$GEMINI_DIR" ]]; then
        log_info "Directory $GEMINI_DIR does not exist — creating"
        mkdir -p "$GEMINI_DIR"
        chown "${dir_username}:${USER_GROUP}" "$GEMINI_DIR" 2>/dev/null || \
            chown $(stat -c '%u:%g' "$user_home"):$(stat -c '%g' "$user_home") "$GEMINI_DIR" 2>/dev/null
        chmod 755 "$GEMINI_DIR"
    fi

    # settings.json
    if [[ -f "$SETTINGS_FILE" ]]; then
        CURRENT_AUTH=$(get_selected_type "$SETTINGS_FILE")
        if [[ "$CURRENT_AUTH" == "$BAD_AUTH_TYPE" ]]; then
            log_action "selectedType is \"${BAD_AUTH_TYPE}\" — FIXING to \"${AUTH_TYPE}\""
            backup_file "$SETTINGS_FILE" "$dir_username"
            sed -i "s/\"selectedType\":\s*\"${BAD_AUTH_TYPE}\"/\"selectedType\": \"${AUTH_TYPE}\"/" "$SETTINGS_FILE" 2>/dev/null
            log_ok "settings.json fixed"
        else
            log_info "Current selectedType: \"${CURRENT_AUTH}\" — keeping"
        fi
    else
        log_action "settings.json does not exist — creating"
        cat << EOF > "$SETTINGS_FILE"
{
  "security": {
    "auth": {
      "selectedType": "${AUTH_TYPE}"
    }
  },
  "ide": {
    "hasSeenNudge": true,
    "enabled": true
  }
}
EOF
        log_ok "settings.json created with selectedType=\"${AUTH_TYPE}\""
    fi

    # Invalidate personal flow credentials
    if [[ -f "$OAUTH_FILE" ]]; then
        ORIGINAL_AUTH=$(get_selected_type "${BACKUP_DIR}/${dir_username}/settings.json" 2>/dev/null || echo "")
        if [[ "$ORIGINAL_AUTH" == "$BAD_AUTH_TYPE" ]]; then
            backup_file "$OAUTH_FILE" "$dir_username"
            rm -f "$OAUTH_FILE"
            log_action "oauth_creds.json removed (personal flow credentials)"
        fi
    fi

    # Variables in .bashrc / .profile
    for rcfile in ".bashrc" ".profile" ".zshrc"; do
        RCPATH="${user_home}${rcfile}"
        if [[ -f "$RCPATH" ]]; then
            inject_line "$RCPATH" "export GOOGLE_CLOUD_PROJECT=\"${GOOGLE_CLOUD_PROJECT}\"" "GOOGLE_CLOUD_PROJECT"
        fi
    done

    # Fix ownership
    log_action "Fixing ownership of $GEMINI_DIR/"
    chown -R "${dir_username}:${USER_GROUP}" "$GEMINI_DIR" 2>/dev/null || \
        chown -R $(stat -c '%u:%g' "$user_home") "$GEMINI_DIR" 2>/dev/null
    log_ok "Ownership fixed"

    # Fix ownership of rc files
    for rcfile in ".bashrc" ".profile" ".zshrc"; do
        RCPATH="${user_home}${rcfile}"
        if [[ -f "$RCPATH" ]]; then
            chown "${dir_username}:${USER_GROUP}" "$RCPATH" 2>/dev/null || true
        fi
    done

    ((USERS_REMEDIATED++)) || true
done

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

log_header "REMEDIATION SUMMARY"
echo "" | tee -a "$LOG_FILE"
echo -e "  Hostname:               ${BOLD}${HOSTNAME_INFO}${NC}" | tee -a "$LOG_FILE"
echo -e "  Timestamp:              ${TIMESTAMP_HUMAN}" | tee -a "$LOG_FILE"
echo -e "  GCP Project:            ${BOLD}${GOOGLE_CLOUD_PROJECT}${NC}" | tee -a "$LOG_FILE"
echo -e "  Auth Type applied:      ${BOLD}${AUTH_TYPE}${NC}" | tee -a "$LOG_FILE"
echo -e "  Users remediated:       ${BOLD}${USERS_REMEDIATED}${NC}" | tee -a "$LOG_FILE"
echo -e "  Successful actions:     ${BOLD}${GREEN}${ACTIONS_OK}${NC}" | tee -a "$LOG_FILE"
echo -e "  Failed actions:         ${BOLD}${RED}${ACTIONS_FAIL}${NC}" | tee -a "$LOG_FILE"
echo -e "  Backups saved at:       ${BOLD}${BACKUP_DIR}${NC}" | tee -a "$LOG_FILE"
echo -e "  Full log:               ${BOLD}${LOG_FILE}${NC}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ $ACTIONS_FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✓ REMEDIATION COMPLETED SUCCESSFULLY${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo -e "  ${CYAN}Next steps:${NC}" | tee -a "$LOG_FILE"
    echo -e "    1. Ask employees to open a new terminal" | tee -a "$LOG_FILE"
    echo -e "    2. Run: ${BOLD}gemini${NC}" | tee -a "$LOG_FILE"
    echo -e "    3. The login should automatically present the corporate flow" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 0
else
    echo -e "  ${RED}${BOLD}✗ REMEDIATION COMPLETED WITH ERRORS — check the log: ${LOG_FILE}${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    exit 1
fi
