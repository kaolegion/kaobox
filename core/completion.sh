# ==========================================================
# 🧠 KAOBOX BRAIN SMART COMPLETION
# ==========================================================
# Dynamic • Context-aware • Safe • Idempotent
# ==========================================================

[[ $- != *i* ]] && return
[[ -n "${KAOBOX_COMPLETION_LOADED:-}" ]] && return
export KAOBOX_COMPLETION_LOADED=1

KAOBOX_ROOT="/opt/kaobox"
BRAIN_COMMANDS_DIR="$KAOBOX_ROOT/lib/brain/commands"
BRAIN_DB="${BRAIN_DB:-/data/brain/.index/brain.db}"

_brain_completion() {

    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=()

    # ------------------------------------------------------
    # LEVEL 1 → Subcommands
    # ------------------------------------------------------
    if [[ $COMP_CWORD -eq 1 ]]; then
        if [[ -d "$BRAIN_COMMANDS_DIR" ]]; then
            local cmds
            cmds=$(printf "%s\n" "$BRAIN_COMMANDS_DIR"/*.sh 2>/dev/null | \
                   xargs -n1 basename 2>/dev/null | \
                   sed 's/\.sh$//' | sort)

            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        fi
        return 0
    fi

    # ------------------------------------------------------
    # LEVEL 2 → Context
    # ------------------------------------------------------
    case "${COMP_WORDS[1]}" in

        open|graph|backlinks)
            [[ -f "$BRAIN_DB" ]] || return 0
            local titles
            titles=$(sqlite3 "$BRAIN_DB" "SELECT title FROM notes;" 2>/dev/null)
            COMPREPLY=( $(compgen -W "$titles" -- "$cur") )
            return 0
            ;;

        search)

            [[ -f "$BRAIN_DB" ]] || return 0

            # tag completion
            if [[ "$cur" == tag:* ]]; then
                local tags
                tags=$(sqlite3 "$BRAIN_DB" "SELECT name FROM tags;" 2>/dev/null)

                local tag_list=""
                while read -r t; do
                    [[ -n "$t" ]] && tag_list+="tag:$t "
                done <<< "$tags"

                COMPREPLY=( $(compgen -W "$tag_list" -- "$cur") )
                return 0
            fi

            # fallback → titles
            local titles
            titles=$(sqlite3 "$BRAIN_DB" "SELECT title FROM notes;" 2>/dev/null)
            COMPREPLY=( $(compgen -W "$titles" -- "$cur") )
            return 0
            ;;
    esac
}

complete -F _brain_completion brain
