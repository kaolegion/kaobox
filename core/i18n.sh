#!/usr/bin/env bash
# ==========================================================
# KAOBOX CORE: i18n
# ----------------------------------------------------------
# - First run language selection
# - Loads lang/<code>.sh
# - Provides translation function: t KEY
# ==========================================================

[[ -n "${KAOBOX_I18N_LOADED:-}" ]] && return 0
readonly KAOBOX_I18N_LOADED=1

: "${KAOBOX_ROOT:=/opt/kaobox}"

STATE_FILE="${KAOBOX_ROOT}/state/system.lang"
LANG_DIR="${KAOBOX_ROOT}/lang"

# ----------------------------------------------------------
# First launch → ask language
# ----------------------------------------------------------
if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"

    echo "Select language / Choisir la langue:"
    echo "1) English"
    echo "2) Français"

    local_choice=""
    read -r -p "Choice: " local_choice

    case "${local_choice:-}" in
        2) echo "fr" > "$STATE_FILE" ;;
        *) echo "en" > "$STATE_FILE" ;;
    esac
fi

KAO_LANG="$(cat "$STATE_FILE" 2>/dev/null || echo en)"
LANG_FILE="${LANG_DIR}/${KAO_LANG}.sh"

# ----------------------------------------------------------
# Load language file
# ----------------------------------------------------------
if [[ -f "$LANG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LANG_FILE"
else
    echo "Language file not found: $LANG_FILE" >&2
    return 1
fi

# ----------------------------------------------------------
# Translation function
# ----------------------------------------------------------
t() {
    local key="${1:-}"
    [[ -z "$key" ]] && return 0

    # Indirect expansion: variable name stored in $key
    # If not found, echo the key itself (deterministic fallback)
    local val="${!key-}"
    if [[ -n "$val" ]]; then
        echo "$val"
    else
        echo "$key"
    fi
}
