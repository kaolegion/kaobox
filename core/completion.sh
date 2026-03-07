#!/usr/bin/env bash
# ==========================================================
# 🧠 KAOBOX BRAIN SMART COMPLETION
# ==========================================================
# Dynamic • Context-aware • Safe • Idempotent
# ==========================================================

[[ $- != *i* ]] && return 0
[[ -n "${KAOBOX_COMPLETION_LOADED:-}" ]] && return 0
export KAOBOX_COMPLETION_LOADED=1

# ----------------------------------------------------------
# Resolve KaoBox root (prefer env, fallback to /opt/kaobox)
# ----------------------------------------------------------
: "${KAOBOX_ROOT:=/opt/kaobox}"

# Brain command directory
BRAIN_COMMANDS_DIR="$KAOBOX_ROOT/lib/brain/commands"

# DB (prefer env, fallback)
: "${BRAIN_DB:=/data/brain/.index/brain.db}"

# ----------------------------------------------------------
# Helpers
# ----------------------------------------------------------
_brain__list_commands() {
    [[ -d "$BRAIN_COMMANDS_DIR" ]] || return 0

    local f
    for f in "$BRAIN_COMMANDS_DIR"/*.sh; do
        [[ -e "$f" ]] || continue
        basename "$f" .sh
    done | sort -u
}

_brain__sqlite_list() {
    # $1 = SQL
    [[ -f "$BRAIN_DB" ]] || return 0
    sqlite3 -batch -noheader -cmd ".timeout 1000" "$BRAIN_DB" "$1" 2>/dev/null || true
}

_brain_completion() {

    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"

    COMPREPLY=()

    # ------------------------------------------------------
    # LEVEL 1 → Subcommands
    # ------------------------------------------------------
    if [[ $COMP_CWORD -eq 1 ]]; then
        local cmds
        cmds="$(_brain__list_commands)"
        [[ -n "$cmds" ]] || return 0
        mapfile -t COMPREPLY < <(compgen -W "$cmds" -- "$cur")
        return 0
    fi

    # ------------------------------------------------------
    # LEVEL 2 → Context-aware completion
    # ------------------------------------------------------
    case "${COMP_WORDS[1]}" in

        open|graph|backlinks)
            # Suggest note titles
            local titles
            titles="$(_brain__sqlite_list "SELECT title FROM notes WHERE title IS NOT NULL AND title != '' ORDER BY updated_at DESC;")"
            [[ -n "$titles" ]] || return 0
            mapfile -t COMPREPLY < <(compgen -W "$titles" -- "$cur")
            return 0
            ;;

        search)
            # Tag completion: tag:<name>
            if [[ "$cur" == tag:* ]]; then
                local tag_names tag_list=""
                tag_names="$(_brain__sqlite_list "SELECT name FROM tags WHERE name IS NOT NULL AND name != '' ORDER BY name;")"
                [[ -n "$tag_names" ]] || return 0

                local t
                while IFS= read -r t; do
                    [[ -n "$t" ]] && tag_list+="tag:$t "
                done <<< "$tag_names"

                mapfile -t COMPREPLY < <(compgen -W "$tag_list" -- "$cur")
                return 0
            fi

            # Fallback: titles
            local titles
            titles="$(_brain__sqlite_list "SELECT title FROM notes WHERE title IS NOT NULL AND title != '' ORDER BY updated_at DESC;")"
            [[ -n "$titles" ]] || return 0
            mapfile -t COMPREPLY < <(compgen -W "$titles" -- "$cur")
            return 0
            ;;
    esac

    return 0
}

complete -F _brain_completion brain
