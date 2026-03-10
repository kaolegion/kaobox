#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Brain CLI Smoke Test
# ----------------------------------------------------------
# Goal:
#   - Validate public CLI surface
#   - Catch command wiring regressions
#   - Keep test lightweight and deterministic
# ==========================================================

echo "[TEST] Brain CLI smoke test"

# ----------------------------------------------------------
# System
# ----------------------------------------------------------
echo "[TEST] brain status"
brain status >/dev/null

echo "[TEST] brain doctor"
brain doctor >/dev/null

# ----------------------------------------------------------
# Observability
# ----------------------------------------------------------
echo "[TEST] brain health"
brain health >/dev/null

echo "[TEST] brain stats"
brain stats >/dev/null

echo "[TEST] brain session"
brain session >/dev/null

# ----------------------------------------------------------
# Memory
# ----------------------------------------------------------
echo "[TEST] brain search"
brain search test >/dev/null || true

# ----------------------------------------------------------
# Graph
# ----------------------------------------------------------
echo "[TEST] brain graph"
brain graph test-modular >/dev/null || true

echo "[TEST] brain backlinks"
brain backlinks test >/dev/null || true

echo "[TEST] brain neighbors"
brain neighbors test >/dev/null || true

echo "[TEST] brain related"
brain related test >/dev/null || true

echo "[TEST] brain path"
brain path test-modular test >/dev/null || true

# ----------------------------------------------------------
# Export
# ----------------------------------------------------------
echo "[TEST] brain export graph"
brain export graph >/dev/null

echo "[TEST] brain export graph --format tsv"
brain export graph --format tsv >/dev/null

# ----------------------------------------------------------
# Cognition
# ----------------------------------------------------------
echo "[TEST] brain think"
brain think test >/dev/null || true

echo "[PASS] Brain CLI smoke test passed"
