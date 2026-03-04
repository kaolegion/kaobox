# ==========================================================
# 🧠 KAOBOX CORE SHELL MODULE
# ==========================================================
# Interactive shell loader — Deterministic & Idempotent
# ==========================================================

[[ $- != *i* ]] && return

# Prevent double sourcing
[[ -n "${KAOBOX_SHELL_LOADED:-}" ]] && return
export KAOBOX_SHELL_LOADED=1


# ----------------------------------------------------------
# 📍 ROOT
# ----------------------------------------------------------
export KAOBOX_ROOT="/opt/kaobox"
export KAOBOX_BIN="$KAOBOX_ROOT/bin"
export KAOBOX_LOGS="$KAOBOX_ROOT/logs"


# ----------------------------------------------------------
# 📂 PATH (atomic)
# ----------------------------------------------------------
kaobox_add_to_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

[[ -d "$KAOBOX_BIN" ]] && kaobox_add_to_path "$KAOBOX_BIN"
export PATH


# ----------------------------------------------------------
# ✍️ EDITOR (clean fallback)
# ----------------------------------------------------------
kaobox_detect_editor() {
    command -v micro >/dev/null 2>&1 && { echo micro; return; }
    command -v nano  >/dev/null 2>&1 && { echo nano;  return; }
    echo vi
}

export EDITOR="${EDITOR:-$(kaobox_detect_editor)}"
export VISUAL="${VISUAL:-$EDITOR}"


# ----------------------------------------------------------
# 🎯 SAFE ALIASES
# ----------------------------------------------------------
alias kb="cd \"$KAOBOX_ROOT\""

[[ -d "$KAOBOX_LOGS" ]] && \
alias brainlog="tail -f \"$KAOBOX_LOGS/brain.log\""


# ----------------------------------------------------------
# 🔌 BASH COMPLETION
# ----------------------------------------------------------
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

# Load KaoBox completion layer
[[ -f "$KAOBOX_ROOT/core/completion.sh" ]] && \
source "$KAOBOX_ROOT/core/completion.sh"


# ----------------------------------------------------------
# 🧪 DEBUG (opt-in only)
# ----------------------------------------------------------
if [[ "${KAOBOX_DEBUG:-0}" == "1" ]]; then
    echo "[KAOBOX] shell loaded"
fi
