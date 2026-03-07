#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Resolver
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Retrieve context candidates from memory graph
#   - Output: path|layer|updated_at
# Depends on:
#   - BRAIN_DB
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_RESOLVER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_RESOLVER_LOADED=1

# ==========================================================
# Function: resolve_context
# ==========================================================

resolve_context() {

    local file="$1"

    [[ -f "${file:-}" ]] || {
        log_error "[context] File not found: $file"
        return 1
    }

    [[ -n "${BRAIN_DB:-}" && -f "$BRAIN_DB" ]] || {
        log_error "[context] BRAIN_DB not available"
        return 1
    }

    # ------------------------------------------------------
    # Escape path safely
    # ------------------------------------------------------
    local safe_file
    safe_file=${file//\'/\'\'}

    # ------------------------------------------------------
    # Retrieve note ID
    # ------------------------------------------------------
    local note_id
    note_id=$(sqlite3 "$BRAIN_DB" \
        "SELECT id FROM notes WHERE path='$safe_file';")

    [[ -z "${note_id:-}" || ! "$note_id" =~ ^[0-9]+$ ]] && {
        log_warn "[context] Note not indexed: $file"
        return 1
    }

    local SEP="|"

    # ------------------------------------------------------
    # GRAPH_OUT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_OUT', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.target_id = n2.id
        WHERE l.source_id = $note_id;
    "

    # ------------------------------------------------------
    # GRAPH_IN
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_IN', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.source_id = n2.id
        WHERE l.target_id = $note_id;
    "

    # ------------------------------------------------------
    # RECENT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'RECENT', updated_at
        FROM notes
        WHERE id != $note_id
        ORDER BY updated_at DESC
        LIMIT 5;
    "

    # ------------------------------------------------------
    # SELF
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'SELF', updated_at
        FROM notes
        WHERE id = $note_id;
    "
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Scorer
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Score context candidates
#   - Apply temporal decay
#   - Apply session boost
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SCORER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SCORER_LOADED=1

# ----------------------------------------------------------
# Load local dependencies (same layer only)
# ----------------------------------------------------------
CONTEXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CONTEXT_DIR/session.sh"

# ==========================================================
# Function: score_context
# ==========================================================

score_context() {

    declare -A scores
    declare -A last_update

    local now
    now=$(date +%s)

    while IFS="|" read -r path layer updated_at; do
        [[ -z "${path:-}" ]] && continue

        # --------------------------------------------------
        # Base weight per layer
        # --------------------------------------------------
        local base=0
        case "$layer" in
            SELF)      base=4 ;;
            GRAPH_OUT) base=3 ;;
            GRAPH_IN)  base=2 ;;
            RECENT)    base=1 ;;
        esac

        (( base == 0 )) && continue

        local current=${scores["$path"]:-0}
        local decay=100

        # --------------------------------------------------
        # Temporal Decay
        # --------------------------------------------------
        if [[ -n "${updated_at:-}" ]]; then
            local updated
            updated=$(date -d "$updated_at" +%s 2>/dev/null || echo 0)

            if (( updated > 0 )); then
                local age_days=$(( (now - updated) / 86400 ))

                if   (( age_days <= 1 ));  then decay=100
                elif (( age_days <= 7 ));  then decay=70
                elif (( age_days <= 30 )); then decay=40
                else                            decay=20
                fi
            fi
        fi

        local weighted=$(( base * decay / 100 ))

        scores["$path"]=$(( current + weighted ))
        last_update["$path"]="$updated_at"

    done

    # ------------------------------------------------------
    # Session Boost
    # ------------------------------------------------------
    local active
    active=$(session_get_active || true)

    for path in "${!scores[@]}"; do
        local total=${scores[$path]}

        if [[ -n "${active:-}" && "$path" == "$active" ]]; then
            total=$(( total + 5 ))
        fi

        printf "%s|%s\n" "$total" "$path"
    done | sort -t'|' -nr
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Session Manager
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Manage active context session
# Storage:
#   - $BRAIN_ROOT/.session
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SESSION_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SESSION_LOADED=1

# ----------------------------------------------------------
# Validate runtime environment
# ----------------------------------------------------------
[[ -n "${BRAIN_ROOT:-}" ]] || {
    echo "[context] BRAIN_ROOT not defined" >&2
    return 1
}

readonly SESSION_FILE="$BRAIN_ROOT/.session"

# ==========================================================
# Set active note
# ==========================================================
session_set_active() {

    local file="$1"

    [[ -n "${file:-}" ]] || return 1

    echo "$file" > "$SESSION_FILE"
}

# ==========================================================
# Get active note
# ==========================================================
session_get_active() {

    [[ -f "$SESSION_FILE" ]] || return 0
    cat "$SESSION_FILE"
}
