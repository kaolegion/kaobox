#!/bin/bash

STATE_FILE="/opt/kaobox/state/system.lang"
LANG_DIR="/opt/kaobox/lang"

# First launch → ask language
if [ ! -f "$STATE_FILE" ]; then
    echo "Select language / Choisir la langue:"
    echo "1) English"
    echo "2) Français"
    read -p "Choice: " choice

    case $choice in
        2) echo "fr" > "$STATE_FILE" ;;
        *) echo "en" > "$STATE_FILE" ;;
    esac
fi

KAO_LANG=$(cat "$STATE_FILE")
LANG_FILE="${LANG_DIR}/${KAO_LANG}.sh"

# Load language file
if [ -f "$LANG_FILE" ]; then
    source "$LANG_FILE"
else
    echo "Language file not found: $LANG_FILE"
    exit 1
fi

# Translation function
t() {
    eval echo "\$$1"
}
