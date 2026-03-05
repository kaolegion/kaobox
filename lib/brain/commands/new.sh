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
