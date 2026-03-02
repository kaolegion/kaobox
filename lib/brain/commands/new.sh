cmd_new() {

    [ $# -lt 1 ] && usage

    title="$1"

    slug=$(echo "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' ' '-' \
        | tr -cd 'a-z0-9-_')

    filepath="$NOTES_DIR/$slug.md"

    cat > "$filepath" <<EOF
# $title

Tags: #

Résumé:

---

EOF

    "$INDEX_SCRIPT" index "$filepath"

    log "New note created: $filepath"

    ${EDITOR:-micro} "$filepath"
}
