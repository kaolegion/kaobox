#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Command Layer
# ----------------------------------------------------------
# Layer: Cognitive (Kernel Extension)
# Depends on: context/{resolver,scorer,session}
# ==========================================================

# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_CMD_LOADED=1

# ----------------------------------------------------------
# Load Context Layer (Kernel level)
# ----------------------------------------------------------
source "$KAOBOX_ROOT/lib/brain/context/resolver.sh"
source "$KAOBOX_ROOT/lib/brain/context/scorer.sh"
source "$KAOBOX_ROOT/lib/brain/context/session.sh"

# ==========================================================
# Command: brain context
# ==========================================================

cmd_context() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain context <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    log_info "[context] Resolving for $file"

    set -o pipefail

    resolve_context "$file" \
        | score_context \
        | head -10 \
        | while IFS="|" read -r score path; do
            printf "[%2s] %s\n" "$score" "$path"
        done

    local status=$?
    set +o pipefail

    return $status
}

# ==========================================================
# Command: brain focus
# ==========================================================

cmd_focus() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain focus <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    session_set_active "$file"
    log_info "[context] Focused on: $file"

    cmd_context "$file"
}
cmd_doctor() {

    echo "[Brain] Running diagnostics..."

    # ----------------------------------
    # Check database file
    # ----------------------------------

    if [[ ! -f "$BRAIN_DB" ]]; then
        echo "❌ Database missing: $BRAIN_DB"
        return 1
    fi

    if [[ ! -d "$NOTES_DIR" ]]; then
        echo "❌ Notes directory missing: $NOTES_DIR"
        return 1
    fi

    echo "✅ Database present"
    echo "✅ Notes directory present"

    # ----------------------------------
    # Check tables existence (safe timeout)
    # ----------------------------------

    tables=$(sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
        "SELECT name FROM sqlite_master WHERE type='table';" 2>/dev/null)

    for t in notes tags note_tags notes_fts; do
        if ! echo "$tables" | grep -qx "$t"; then
            echo "❌ Table '$t' missing"
            return 1
        fi
    done

    echo "✅ Schema OK"

    # ----------------------------------
    # Integrity check (WAL-safe)
    # ----------------------------------

    integrity=$(sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
        "PRAGMA integrity_check;" 2>/dev/null)

    if [[ "$integrity" == "ok" ]]; then
        echo "✅ Integrity check: OK"
    else
        echo "❌ Integrity check failed"
        echo "Details: $integrity"
        echo "🧠 Brain status: CORRUPTED"
        return 1
    fi

    echo "🧠 Brain status: HEALTHY"
    return 0
}
cmd_fuzzy() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    command -v fzf >/dev/null 2>&1 || {
        echo "[ERROR] fzf not installed"
        return 1
    }

    local selected
    selected=$(
        sqlite3 -separator "|" "$BRAIN_DB" "
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT('#' || t2.name, ' ')
                   FROM (
                       SELECT t2.name
                       FROM note_tags nt2
                       JOIN tags t2 ON t2.id = nt2.tag_id
                       WHERE nt2.note_id = n.id
                       ORDER BY t2.name
                   )
               ), '')
        FROM notes n
        ORDER BY n.updated_at DESC;
        " | while IFS="|" read -r id title date tags; do
            printf "%s|%-30s | %s | %s\n" "$id" "$title" "$date" "$tags"
        done | fzf \
            --delimiter="|" \
            --layout=reverse \
            --height=90% \
            --border \
            --prompt="🧠 Brain > "
    )

    [[ -z "$selected" ]] && return 0

    local note_id
    note_id=$(echo "$selected" | cut -d'|' -f1)

    # Validate numeric id
    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[ERROR] Invalid selection"
        return 1
    }

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "
        SELECT path FROM notes WHERE id=$note_id LIMIT 1;
    ")

    if [[ -z "$filepath" || ! -f "$filepath" ]]; then
        echo "[ERROR] File missing on disk."
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
cmd_ls() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    local query
    query="
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT(name, ',')
                   FROM (
                       SELECT t2.name
                       FROM note_tags nt2
                       JOIN tags t2 ON t2.id = nt2.tag_id
                       WHERE nt2.note_id = n.id
                       ORDER BY t2.name
                   )
               ), '')
        FROM notes n
        ORDER BY n.updated_at DESC;
    "

    local count=0

    while IFS=$'\t' read -r id title date tags; do
        count=$((count+1))
        printf "\n%s\n" "$title"
        printf "Date: %s\n" "$date"
        [[ -n "$tags" ]] && printf "Tags: %s\n" "$tags"
        printf "%s\n" "----------------------------------------"
    done < <(
        sqlite3 -separator $'\t' "$BRAIN_DB" "$query"
    )

    if [[ $count -eq 0 ]]; then
        echo "[Brain] No notes indexed."
    fi
}
cmd_new() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        log_error "NOTES_DIR not defined"
        return 1
    }

    [[ $# -lt 1 ]] && {
        usage
        return 1
    }

    local title="$1"

    # ------------------------------------------------------
    # Slug generation
    # ------------------------------------------------------

    local slug
    slug=$(printf "%s" "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' ' '-' \
        | tr -cd 'a-z0-9-_')

    [[ -z "$slug" ]] && {
        log_error "Invalid title"
        return 1
    }

    local filepath="$NOTES_DIR/$slug.md"

    # ------------------------------------------------------
    # Prevent overwrite
    # ------------------------------------------------------

    if [[ -f "$filepath" ]]; then
        log_error "Note already exists: $filepath"
        return 1
    fi

    # ------------------------------------------------------
    # Create file
    # ------------------------------------------------------

    cat > "$filepath" <<EOF
# $title

Tags: #

Résumé:

---

EOF

    # ------------------------------------------------------
    # Indexing (transactional)
    # ------------------------------------------------------

    acquire_lock || {
        log_error "Could not acquire lock"
        rm -f "$filepath"
        return 1
    }

    safe_source "$MEMORY_INDEX"

    if ! index_note "$filepath"; then
        log_error "Indexing failed. Rolling back file."
        rm -f "$filepath"
        release_lock
        return 1
    fi

    release_lock

    log_info "Note created and indexed: $filepath"
}
cmd_open() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    local raw_filename="$1"

    # Escape single quotes safely
    local filename_safe
    filename_safe="$(printf "%s" "$raw_filename" | sed "s/'/''/g")"

    local query="
        SELECT path
        FROM notes
        WHERE path LIKE '%' || '$filename_safe' || '%'
        ORDER BY updated_at DESC
        LIMIT 1;
    "

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "$query")

    if [[ -z "$filepath" ]]; then
        echo "Note not found."
        return 1
    fi

    if [[ ! -f "$filepath" ]]; then
        echo "File missing on disk: $filepath"
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
#!/usr/bin/env bash

# ==========================================
# KAOBOX BRAIN — REINDEX COMMAND
# Batch rebuild (single transaction)
# ==========================================

set -euo pipefail


#!/usr/bin/env bash
# ------------------------------------------
# Security — Absolute path guard
# ------------------------------------------

_check_absolute_path() {
    local path="$1"
    [[ "$path" == /* ]] || {
        echo "[ERROR] Absolute path required: $path"
        return 1
    }
}

# ------------------------------------------
# Command implementation
# ------------------------------------------

cmd_reindex() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        echo "[ERROR] NOTES_DIR not defined"
        return 1
    }

    _check_absolute_path "$NOTES_DIR" || return 1

    if [[ ! -d "$NOTES_DIR" ]]; then
        echo "[ERROR] Notes directory missing: $NOTES_DIR"
        return 1
    fi

    echo "[Brain] Reindexing all notes..."

    mapfile -d '' files < <(
        find "$NOTES_DIR" -type f -name "*.md" -print0 | sort -z
    )

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "[Brain] No notes found."
        return 0
    fi

    acquire_lock || {
      echo "❌ Could not acquire lock"
      return 1
    }
    
    reindex_all "${files[@]}"
    
    release_lock

    echo "[Brain] Reindex complete."
    echo "[Brain] Files processed: ${#files[@]}"
}
cmd_search() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    [[ $# -lt 1 ]] && {
        usage
        return 1
    }

    local mode="table"
    local limit=""
    local args=()

    # ------------------------------------------------------
    # Parse flags
    # ------------------------------------------------------

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                mode="json"
                shift
                ;;
            --raw)
                mode="raw"
                shift
                ;;
            --limit=*)
                limit="${1#--limit=}"
                shift
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    local raw_query="${args[*]}"

    [[ -z "$raw_query" ]] && {
        echo "Empty query."
        return 1
    }

    log INFO "Search query: $raw_query | mode=$mode | limit=${limit:-default}"

    # ------------------------------------------------------
    # Execute query and capture results
    # ------------------------------------------------------

    local results=()

    if [[ "$raw_query" == tag:* ]]; then

        local tag="${raw_query#tag:}"
        [[ -z "$tag" ]] && { echo "Empty tag."; return 1; }

        if ! mapfile -t results < <(query_by_tag "$tag" "${limit:-}"); then
            echo "[ERROR] Tag query failed"
            return 1
        fi

    elif [[ "$raw_query" == backlinks:* ]]; then

        local path="${raw_query#backlinks:}"
        [[ -z "$path" ]] && { echo "Empty backlink path."; return 1; }

        if ! mapfile -t results < <(query_backlinks "$path"); then
            echo "[ERROR] Backlink query failed"
            return 1
        fi

    else

        if ! mapfile -t results < <(query_fts "$raw_query" "${limit:-}"); then
            echo "[ERROR] FTS query failed"
            return 1
        fi

    fi

    # ------------------------------------------------------
    # Render output
    # ------------------------------------------------------

    render_results "$mode" "${results[@]}"
}
#!/usr/bin/env bash
# ==========================================================
# KAOBOX - Status Command
# ----------------------------------------------------------
# Displays Brain system health and environment state
# ==========================================================

cmd_status() {

    log_info "KaoBox Brain Status"

    echo "----------------------------------------"
    echo "KAOBOX_ROOT : $KAOBOX_ROOT"
    echo "BRAIN_ROOT  : $BRAIN_ROOT"
    echo "BRAIN_DB    : $BRAIN_DB"
    echo "LOG_DIR     : $LOG_DIR"
    echo "Log Level   : ${KAOBOX_LOG_LEVEL:-INFO}"
    echo "----------------------------------------"

    if [[ -f "$BRAIN_DB" ]]; then
        log_info "Brain DB detected."
    else
        log_warn "Brain DB not found."
    fi

    echo "System OK"
}
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${BRAIN_THINK_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_CMD_LOADED=1

safe_source "$KAOBOX_ROOT/lib/brain/think/engine.sh"

cmd_think() {

    local query="$*"

    [[ -z "$query" ]] && {
        log_error "Usage: brain think <query>"
        return 1
    }

    log_info "[think] Query: $query"

    think_engine_run "$query"
}
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
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Engine (Orchestration Layer v1.1)
# ==========================================================

[[ -n "${BRAIN_THINK_ENGINE_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_ENGINE_LOADED=1

# ----------------------------------------------------------
# Dependencies
# ----------------------------------------------------------

safe_source "$MODULES_ROOT/memory/query.sh"
safe_source "$KAOBOX_ROOT/lib/brain/context/session.sh"
safe_source "$KAOBOX_ROOT/lib/brain/think/ranker.sh"


# ==========================================================
# THINK ENGINE RUNNER
# ==========================================================

think_engine_run() {

    local query="$1"

    [[ -z "$query" ]] && return 0

    # ------------------------------------------------------
    # Active focus (if context available)
    # ------------------------------------------------------
    
    local active_focus=""
    
    if declare -f session_get_active >/dev/null 2>&1; then
        active_focus="$(session_get_active 2>/dev/null || true)"
    fi

    # ------------------------------------------------------
    # FTS retrieval (raw layer)
    # ------------------------------------------------------

    mapfile -t fts_results < <(query_fts "$query" 10)

    [[ ${#fts_results[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    # ------------------------------------------------------
    # Ranking (cognitive layer)
    # ------------------------------------------------------

    think_rank_results "$active_focus" "${fts_results[@]}" \
    | while IFS='|' read -r composite raw; do
        echo "$raw"
      done
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Ranker (Composite Scoring v1.2 ready)
# ==========================================================

[[ -n "${BRAIN_THINK_RANKER_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_RANKER_LOADED=1

# ----------------------------------------------------------
# Configurable weights
# ----------------------------------------------------------

: "${THINK_FOCUS_BOOST:=5}"

# ==========================================================
# Helpers
# ==========================================================

_extract_path() {
    # Extract second column safely (tab or space separated)
    local line="$1"

    # Try tab first
    local path
    IFS=$'\t' read -r _ path _ <<< "$line"

    if [[ -n "$path" ]]; then
        printf "%s\n" "$path"
        return
    fi

    # Fallback to space parsing
    printf "%s\n" "$line" | awk '{print $2}'
}

_extract_score() {
    # Extract last field (score)
    printf "%s\n" "$1" | awk '{print $NF}'
}

# ==========================================================
# Ranking Function
# ==========================================================

think_rank_results() {

    local focus="$1"
    shift
    local results=("$@")

    local line id path title raw_score relevance composite

    for line in "${results[@]}"; do

        [[ -z "${line:-}" ]] && continue

        # Safe parsing (TAB separated)
        IFS=$'\t' read -r id path title raw_score <<< "$line"

        # Skip malformed lines
        [[ -z "${path:-}" || -z "${raw_score:-}" ]] && continue

        # Normalize FTS score (bm25 negative → positive relevance)
        relevance=$(awk "BEGIN {print -1 * ($raw_score)}")

        composite="$relevance"

        # Focus boost
        if [[ -n "${focus:-}" && "$path" == "$focus" ]]; then
            composite=$(awk "BEGIN {print $relevance + $THINK_FOCUS_BOOST}")
        fi

        printf "%s|%s\n" "$composite" "$line"

    done | sort -t'|' -k1 -nr
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - CLI Dispatcher (Kernel v3.0)
# Deterministic • Modular • Safe
# ==========================================================

# ----------------------------------------------------------
# Prevent double loading
# ----------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    [[ -n "${BRAIN_DISPATCHER_LOADED:-}" ]] && return 0
    readonly BRAIN_DISPATCHER_LOADED=1
fi

# ----------------------------------------------------------
# Detect Root
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export KAOBOX_ROOT

# ----------------------------------------------------------
# Safe source helper
# ----------------------------------------------------------

safe_source() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Fatal: missing file $file"
        exit 1
    }
    # shellcheck source=/dev/null
    source "$file"
}

# ----------------------------------------------------------
# Load Core (ORDER MATTERS)
# ----------------------------------------------------------

safe_source "$KAOBOX_ROOT/lib/brain/env.sh"
safe_source "$KAOBOX_ROOT/core/logger.sh"
safe_source "$KAOBOX_ROOT/lib/brain/preflight.sh"
safe_source "$KAOBOX_ROOT/lib/brain/sanitize.sh"
safe_source "$KAOBOX_ROOT/lib/brain/lock.sh"
safe_source "$KAOBOX_ROOT/lib/brain/renderer.sh"

# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------

readonly COMMANDS_DIR="$KAOBOX_ROOT/lib/brain/commands"
readonly MEMORY_QUERY="$MODULES_ROOT/memory/query.sh"
readonly MEMORY_INDEX="$MODULES_ROOT/memory/index.sh"

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------

usage() {
cat <<EOF
🧠 KaoBox Brain CLI

Usage:
  brain status
  brain doctor
  brain new "Title"
  brain search <query>
  brain open <file>
  brain ls
  brain reindex
  brain fuzzy
  brain context <file>
  brain focus <file>
  brain think <query>
EOF
}

# ----------------------------------------------------------
# Command Loader
# ----------------------------------------------------------

load_command() {
    local file="$1"
    safe_source "$COMMANDS_DIR/$file"
}

# ----------------------------------------------------------
# Dispatcher
# ----------------------------------------------------------

brain_dispatch() {

    local cmd="${1:-help}"
    [[ $# -gt 0 ]] && shift

    case "$cmd" in

        # ---- System ----
        status)
            load_command "status.sh"
            cmd_status "$@"
            ;;

        doctor)
            load_command "doctor.sh"
            cmd_doctor "$@"
            ;;

        # ---- Memory ----
        new)
            preflight_check
            load_command "new.sh"
            cmd_new "$@"
            ;;

        search)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "search.sh"
            cmd_search "$@"
            ;;

        open)
            preflight_check
            load_command "open.sh"
            cmd_open "$@"
            ;;

        ls)
            preflight_check
            load_command "ls.sh"
            cmd_ls "$@"
            ;;

        reindex)
            preflight_check
            safe_source "$MEMORY_INDEX"
            load_command "reindex.sh"
            cmd_reindex "$@"
            ;;

        fuzzy)
            preflight_check
            load_command "fuzzy.sh"
            cmd_fuzzy "$@"
            ;;

        # ---- Context Layer ----
        context)
            preflight_check
            load_command "context.sh"
            cmd_context "$@"
            ;;

        focus)
            preflight_check
            load_command "context.sh"
            cmd_focus "$@"
            ;;

        # ---- Cognitive Layer ----
        think)
            preflight_check
            load_command "think.sh"
            cmd_think "$@"
            ;;

        help|--help|-h)
            usage
            ;;

        *)
            log_error "Unknown command: $cmd"
            echo
            usage
            exit 1
            ;;
    esac
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Environment Configuration
# ----------------------------------------------------------
# - Idempotent
# - Portable (auto-detect root)
# - Safe overrides
# - Readonly guarantees
# - Future multi-brain ready
# ==========================================================

# Prevent double loading
[[ -n "${BRAIN_ENV_LOADED:-}" ]] && return 0
readonly BRAIN_ENV_LOADED=1

# ----------------------------------------------------------
# Detect KaoBox root (portable install)
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

readonly KAOBOX_ROOT
export KAOBOX_ROOT

# ----------------------------------------------------------
# Base paths (allow override BEFORE sourcing)
# ----------------------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

# Modules live relative to installation
: "${MODULES_ROOT:=$KAOBOX_ROOT/modules}"

readonly BRAIN_ROOT
readonly MODULES_ROOT

# ----------------------------------------------------------
# Derived paths
# ----------------------------------------------------------

: "${NOTES_DIR:=$BRAIN_ROOT/notes}"
: "${INDEX_DIR:=$BRAIN_ROOT/.index}"
: "${BRAIN_DB:=$INDEX_DIR/brain.db}"
: "${LOG_DIR:=$KAOBOX_ROOT/logs}"

# Memory Engine entrypoint
: "${INDEX_SCRIPT:=$MODULES_ROOT/memory/index.sh}"

readonly NOTES_DIR
readonly INDEX_DIR
readonly BRAIN_DB
readonly LOG_DIR
readonly INDEX_SCRIPT

# ----------------------------------------------------------
# Ensure critical directories exist
# ----------------------------------------------------------

mkdir -p "$BRAIN_ROOT" "$INDEX_DIR" "$LOG_DIR" 2>/dev/null

# ----------------------------------------------------------
# Export environment
# ----------------------------------------------------------

export BRAIN_ROOT
export MODULES_ROOT
export NOTES_DIR
export INDEX_DIR
export BRAIN_DB
export LOG_DIR
export INDEX_SCRIPT
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - Lock System
# ----------------------------------------------------------
# - Deterministic
# - Idempotent
# - Dynamic FD allocation
# - Safe release
# ==========================================================

[[ -n "${BRAIN_LOCK_LOADED:-}" ]] && return 0
readonly BRAIN_LOCK_LOADED=1

: "${LOCK_DIR:=$INDEX_DIR/.lock}"
: "${LOCK_FILE:=$LOCK_DIR/brain.lock}"

readonly LOCK_DIR
readonly LOCK_FILE

# Dynamic FD (assigned at runtime)
BRAIN_LOCK_FD=""

acquire_lock() {

    # Prevent double acquisition in same process
    if [[ -n "${BRAIN_LOCK_FD:-}" ]]; then
        echo "[Brain] Lock already acquired in this process."
        return 1
    fi

    mkdir -p "$LOCK_DIR"

    exec {BRAIN_LOCK_FD}>"$LOCK_FILE"

    if ! flock -n "$BRAIN_LOCK_FD"; then
        exec {BRAIN_LOCK_FD}>&-
        BRAIN_LOCK_FD=""
        echo "[Brain] Another process is running. Aborting."
        return 1
    fi
}

release_lock() {

    if [[ -z "${BRAIN_LOCK_FD:-}" ]]; then
        return 0
    fi

    flock -u "$BRAIN_LOCK_FD" 2>/dev/null || true
    exec {BRAIN_LOCK_FD}>&- 2>/dev/null || true

    BRAIN_LOCK_FD=""
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Preflight Checks
# ----------------------------------------------------------
# - Idempotent
# - Non-destructive
# - Validates DB integrity
# ==========================================================

[[ -n "${BRAIN_PREFLIGHT_LOADED:-}" ]] && return 0
readonly BRAIN_PREFLIGHT_LOADED=1

preflight_check() {

    # 1️⃣ Environment sanity
    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[FATAL] BRAIN_DB not defined"
        return 1
    }

    [[ -n "${INDEX_DIR:-}" ]] || {
        echo "[FATAL] INDEX_DIR not defined"
        return 1
    }

    # 2️⃣ Directory existence
    [[ -d "$INDEX_DIR" ]] || {
        echo "[FATAL] Index directory not found: $INDEX_DIR"
        return 1
    }

    # 3️⃣ Database existence
    [[ -f "$BRAIN_DB" ]] || {
        echo "[FATAL] Brain database not found at $BRAIN_DB"
        return 1
    }

    # 4️⃣ SQLite integrity check
    if ! sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "[FATAL] Brain database integrity check failed"
        return 1
    fi

    return 0
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Output Renderer
# ----------------------------------------------------------
# - Idempotent
# - CLI Table mode
# - JSON mode
# - Unified formatting layer
# ==========================================================

[[ -n "${BRAIN_RENDERER_LOADED:-}" ]] && return 0
readonly BRAIN_RENDERER_LOADED=1

RENDER_MODE="${RENDER_MODE:-table}"   # table | json | raw

# ----------------------------------------------------------
# Internal: escape JSON
# ----------------------------------------------------------

_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ----------------------------------------------------------
# Render Table
# ----------------------------------------------------------

_render_table() {

    local rows=("$@")

    [[ ${#rows[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    printf "%-6s %-30s %s\n" "ID" "TITLE" "PATH"
    printf "%-6s %-30s %s\n" "----" "------------------------------" "---------------------------"

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"
        printf "%-6s %-30s %s\n" "$id" "${title:0:28}" "$path"
    done
}

# ----------------------------------------------------------
# Render JSON
# ----------------------------------------------------------

_render_json() {

    local rows=("$@")

    printf "[\n"
    local first=1

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"

        [[ $first -eq 0 ]] && printf ",\n"
        first=0

        printf "  {\n"
        printf "    \"id\": \"%s\",\n" "$(_json_escape "$id")"
        printf "    \"path\": \"%s\",\n" "$(_json_escape "$path")"
        printf "    \"title\": \"%s\",\n" "$(_json_escape "$title")"
        printf "    \"score\": \"%s\"\n" "$(_json_escape "${score:-}")"
        printf "  }"
    done

    printf "\n]\n"
}

# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

render_results() {

    local mode="${1:-$RENDER_MODE}"
    shift || true

    local rows=("$@")

    case "$mode" in
        table)
            _render_table "${rows[@]}"
            ;;
        json)
            _render_json "${rows[@]}"
            ;;
        raw)
            printf "%s\n" "${rows[@]}"
            ;;
        *)
            echo "[Renderer] Unknown mode: $mode"
            return 1
            ;;
    esac
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Input Sanitization
# ----------------------------------------------------------
# - Idempotent
# - Safe for SQL
# - Preserves FTS operators
# ==========================================================

[[ -n "${BRAIN_SANITIZE_LOADED:-}" ]] && return 0
readonly BRAIN_SANITIZE_LOADED=1

sanitize_sql() {
    # Escape single quotes for SQLite
    local input="$1"
    printf "%s" "$input" | sed "s/'/''/g"
}

sanitize_fts() {
    local input="$1"

    # Remove only dangerous SQL control characters
    # Preserve: letters, numbers, space, _, -, *, :, ", parentheses
    printf "%s" "$input" \
        | tr -cd '[:alnum:] _-*:"()'
}
