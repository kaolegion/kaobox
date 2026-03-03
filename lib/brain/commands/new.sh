cmd_new() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        echo "[ERROR] NOTES_DIR not defined"
        return 1
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    local title="$1"

    # Generate slug
    local slug
    slug=$(printf "%s" "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' ' '-' \
        | tr -cd 'a-z0-9-_')

    if [[ -z "$slug" ]]; then
        echo "[ERROR] Invalid title"
        return 1
    fi

    local filepath="$NOTES_DIR/$slug.md"

    # Avoid overwrite
    if [[ -f "$filepath" ]]; then
        echo "[ERROR] Note already exists: $filepath"
        return 1
    fi

    cat > "$filepath" <<EOF
# $title

Tags: #

Résumé:

---

EOF

    # Use internal index function (modular architecture)
    index_note "$filepath"

    log "New note created: $filepath"

    "${EDITOR:-micro}" "$filepath"
}
