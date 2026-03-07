#!/usr/bin/env bash
# ==========================================================
# KAOBOX - Memory Engine Transaction Layer (v2.5)
# ----------------------------------------------------------
# Emits SQL only. Never calls sqlite3 directly.
# Orchestrator is responsible for piping to sqlite3.
# ==========================================================

begin_tx() {
    echo "PRAGMA foreign_keys=ON;"
    echo "BEGIN IMMEDIATE;"
}

commit_tx() {
    echo "COMMIT;"
}

rollback_tx() {
    echo "ROLLBACK;"
}
