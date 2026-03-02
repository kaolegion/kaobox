sanitize_sql() {
    echo "$1" | sed "s/'/''/g"
}

sanitize_fts() {
    echo "$1" \
    | sed "s/['\";()]//g" \
    | sed "s/--//g" \
    | sed "s/[^a-zA-Z0-9_ ]//g"
}
