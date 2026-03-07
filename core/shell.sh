#!/usr/bin/env bash
# ==========================================================
# 🧠 KAOBOX CORE SHELL MODULE
# ==========================================================
# Interactive shell loader — Deterministic & Idempotent
# ==========================================================

[[ $- != *i* ]] && return 0

# Prevent double sourcing
[[ -n "${KAOBOX_SHELL_LOADED:-}" ]] && return 0
export KAOBOX_SHELL_LOADED=1

# ----------------------------------------------------------
# 📍 ROOT (prefer env, fallback)
# ----------------------------------------------------------
: "${KAOBOX_ROOT:=/opt/kaobox}"
export KAOBOX_ROOT

export KAOBOX_BIN="$KAOBOX_ROOT/bin"
export KAOBOX_LOGS="$KAOBOX_ROOT/logs"

# ----------------------------------------------------------
# 📂 PATH (atomic)
# ----------------------------------------------------------
kaobox_add_to_path() {
    local dir="$1"
    [[ -n "${dir:-}" ]] || return 0

    case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$dir:$PATH" ;;
    esac
}

[[ -d "$KAOBOX_BIN" ]] && kaobox_add_to_path "$KAOBOX_BIN"
export PATH

# ----------------------------------------------------------
# ✍️ EDITOR (clean fallback)
# ----------------------------------------------------------
kaobox_detect_editor() {
    command -v micro >/dev/null 2>&1 && { echo micro; return 0; }
    command -v nano  >/dev/null 2>&1 && { echo nano;  return 0; }
    echo vi
    return 0
}

export EDITOR="${EDITOR:-$(kaobox_detect_editor)}"
export VISUAL="${VISUAL:-$EDITOR}"

# ----------------------------------------------------------
# 🎯 SAFE ALIASES (evaluate vars at use time)
# ----------------------------------------------------------
alias kb='cd "$KAOBOX_ROOT"'

if [[ -d "$KAOBOX_LOGS" ]]; then
    alias brainlog='tail -f "$KAOBOX_LOGS/brain.log"'
fi

# ----------------------------------------------------------
# 🔌 BASH COMPLETION
# ----------------------------------------------------------
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    # shellcheck disable=SC1091
    source /etc/bash_completion
fi

if [[ -f "$KAOBOX_ROOT/core/completion.sh" ]]; then
    # shellcheck source=/dev/null
    source "$KAOBOX_ROOT/core/completion.sh"
fi

# ----------------------------------------------------------
# 🧪 DEBUG (opt-in only)
# ----------------------------------------------------------
if [[ "${KAOBOX_DEBUG:-0}" == "1" ]]; then
    echo "[KAOBOX] shell loaded"
fi
