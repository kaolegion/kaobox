#!/usr/bin/env bash

SESSION_FILE="$BRAIN_ROOT/.session"

session_set_active() {
    echo "$1" > "$SESSION_FILE"
}

session_get_active() {
    [[ -f "$SESSION_FILE" ]] && cat "$SESSION_FILE"
}
