#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX CORE: init
# ----------------------------------------------------------
# Bootstrap profile loader / creator
# - Deterministic
# - Interactive
# - Safe
# ==========================================================

kaobox_bootstrap() {

    local kaobox_dir="${KAOBOX_ROOT:-/opt/kaobox}"
    local profiles_dir="$kaobox_dir/profiles"
    local state_dir="$kaobox_dir/state"

    # Load i18n
    # shellcheck source=/dev/null
    source "$kaobox_dir/core/i18n.sh"

    clear
    echo "===================================="
    echo "        $(t WELCOME_TITLE)"
    echo "===================================="
    echo

    # Ensure kaobox group exists
    if ! getent group kaobox >/dev/null 2>&1; then
        groupadd kaobox
    fi

    # ------------------------------------------------------
    # Existing profiles
    # ------------------------------------------------------
    if [[ -d "$profiles_dir" ]] && [[ -n "$(ls -A "$profiles_dir" 2>/dev/null)" ]]; then
        t EXISTING_PROFILES
        ls "$profiles_dir"
        echo
        echo "1) $(t LOAD_PROFILE)"
        echo "2) $(t CREATE_PROFILE)"
        echo "3) $(t EXIT)"
        echo

        local choice=""
        read -r -p "Choice: " choice

        case "${choice:-}" in
            1)
                local username=""
                read -r -p "Username: " username

                if [[ ! -d "$profiles_dir/$username" ]]; then
                    echo "Profile does not exist."
                    exit 1
                fi

                echo "Launching profile..."
                su - "$username" -c "$kaobox_dir/bin/kaobox-shell"
                return 0
                ;;

            2)
                choice="create"
                ;;

            *)
                t EXITING
                exit 0
                ;;
        esac
    fi

    # ------------------------------------------------------
    # Create profile path
    # ------------------------------------------------------
    t NO_PROFILE
    echo
    echo "1) $(t CREATE_PROFILE)"
    echo "2) $(t EXIT)"
    echo

    local choice="${choice:-}"
    if [[ -z "$choice" ]]; then
        read -r -p "Choice: " choice
    fi

    case "${choice:-}" in
        1|create)
            local username=""
            read -r -p "Username: " username

            # Validate username
            if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                echo "Invalid username format."
                exit 1
            fi

            if [[ "$username" == "root" ]]; then
                echo "Username 'root' not allowed."
                exit 1
            fi

            if id "$username" >/dev/null 2>&1; then
                echo "Linux user already exists."
                exit 1
            fi

            if [[ -d "$profiles_dir/$username" ]]; then
                echo "Kaobox profile already exists."
                exit 1
            fi

            # Create Linux user
            adduser "$username"

            # Add to kaobox group
            usermod -aG kaobox "$username"

            # Create Kaobox profile directory
            mkdir -p "$profiles_dir/$username"

            {
                echo "created: $(date)"
                echo "lang: $(cat "$state_dir/system.lang" 2>/dev/null || echo en)"
            } > "$profiles_dir/$username/profile.meta"

            chown -R "$username:$username" "$profiles_dir/$username"

            echo
            t PROFILE_CREATED
            echo "Launching Kaobox profile..."
            su - "$username" -c "$kaobox_dir/bin/kaobox-shell"
            ;;

        *)
            t EXITING
            ;;
    esac
}

# ----------------------------------------------------------
# Execute bootstrap only if not skipped
# ----------------------------------------------------------
if [[ "${KAOBOX_SKIP_PROFILE:-0}" != "1" ]]; then
    kaobox_bootstrap
fi
