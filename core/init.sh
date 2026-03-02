#!/usr/bin/env bash

set -e

KAOBOX_DIR="/opt/kaobox"
PROFILES_DIR="$KAOBOX_DIR/profiles"
STATE_DIR="$KAOBOX_DIR/state"

# Load i18n
source "$KAOBOX_DIR/core/i18n.sh"

clear
echo "===================================="
echo "        $(t WELCOME_TITLE)"
echo "===================================="
echo ""

# Ensure kaobox group exists
if ! getent group kaobox > /dev/null; then
    groupadd kaobox
fi

# If profiles exist → propose load
if [ -d "$PROFILES_DIR" ] && [ "$(ls -A "$PROFILES_DIR")" ]; then
    echo "$(t EXISTING_PROFILES)"
    ls "$PROFILES_DIR"
    echo ""
    echo "1) $(t LOAD_PROFILE)"
    echo "2) $(t CREATE_PROFILE)"
    echo "3) $(t EXIT)"
    echo ""

    read -p "Choice: " choice

    case "$choice" in
        1)
            read -p "Username: " username

            if [ ! -d "$PROFILES_DIR/$username" ]; then
                echo "Profile does not exist."
                exit 1
            fi

            echo "Launching profile..."
            su - "$username" -c "/opt/kaobox/bin/kaobox-shell"
            ;;

        2)
            choice="create"
            ;;

        *)
            echo "$(t EXITING)"
            exit 0
            ;;
    esac
fi

# Create profile path
echo "$(t NO_PROFILE)"
echo ""
echo "1) $(t CREATE_PROFILE)"
echo "2) $(t EXIT)"
echo ""

read -p "Choice: " choice

case "$choice" in
    1|create)

        read -p "Username: " username

        # Validate username
        if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            echo "Invalid username format."
            exit 1
        fi

        if [ "$username" = "root" ]; then
            echo "Username 'root' not allowed."
            exit 1
        fi

        if id "$username" &>/dev/null; then
            echo "Linux user already exists."
            exit 1
        fi

        if [ -d "$PROFILES_DIR/$username" ]; then
            echo "Kaobox profile already exists."
            exit 1
        fi

        # Create Linux user
        adduser "$username"

        # Add to kaobox group
        usermod -aG kaobox "$username"

        # Create Kaobox profile directory
        mkdir -p "$PROFILES_DIR/$username"

        {
            echo "created: $(date)"
            echo "lang: $(cat "$STATE_DIR/system.lang")"
        } > "$PROFILES_DIR/$username/profile.meta"

        chown -R "$username:$username" "$PROFILES_DIR/$username"

        echo ""
        echo "$(t PROFILE_CREATED)"
        echo "Launching Kaobox profile..."
        su - "$username" -c "/opt/kaobox/bin/kaobox-shell"
        ;;

    *)
        echo "$(t EXITING)"
        ;;
esac
