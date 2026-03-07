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
