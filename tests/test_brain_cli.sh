#!/usr/bin/env bash
set -euo pipefail

echo "[TEST] Brain CLI smoke test"

echo "[TEST] brain status"
brain status >/dev/null

echo "[TEST] brain doctor"
brain doctor >/dev/null

echo "[TEST] brain health"
brain health >/dev/null

echo "[TEST] brain stats"
brain stats >/dev/null

echo "[TEST] brain session"
brain session >/dev/null

echo "[TEST] brain search"
brain search test >/dev/null || true

echo "[TEST] brain graph"
brain graph test-modular >/dev/null || true

echo "[TEST] brain backlinks"
brain backlinks test >/dev/null || true

echo "[TEST] brain neighbors"
brain neighbors test >/dev/null || true

echo "[TEST] brain path"
brain path test-modular test >/dev/null || true

echo "[TEST] brain think"
brain think test >/dev/null || true

echo "[PASS] Brain CLI smoke test passed"
