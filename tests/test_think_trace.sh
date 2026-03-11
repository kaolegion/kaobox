#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# TEST: Think engine trace explainability
# Phase 4.0 - Cognitive Ranking Explainability
# ==========================================================

cleanup() {
    rm -f \
      "$FOCUS_NOTE" \
      "$NEIGHBOR_NOTE" \
      "$INDIRECT_NOTE" \
      "$OTHER_NOTE"
    brain reindex >/dev/null 2>&1 || true
}

on_error() {
    echo "[FAIL] Unexpected error"
    cleanup
    exit 1
}

trap on_error ERR

echo "[TEST] Starting think trace test"

: "${BRAIN_ROOT:=/data/brain}"

FOCUS_NOTE="$BRAIN_ROOT/notes/__think_trace_focus__.md"
NEIGHBOR_NOTE="$BRAIN_ROOT/notes/__think_trace_neighbor__.md"
INDIRECT_NOTE="$BRAIN_ROOT/notes/__think_trace_indirect__.md"
OTHER_NOTE="$BRAIN_ROOT/notes/__think_trace_other__.md"

cat > "$FOCUS_NOTE" <<'NOTE'
# Think Trace Focus

Links:
[[__think_trace_neighbor__.md]]
NOTE

cat > "$NEIGHBOR_NOTE" <<'NOTE'
# Think Trace Neighbor

tracegraphterm

Links:
[[__think_trace_indirect__.md]]
NOTE

cat > "$INDIRECT_NOTE" <<'NOTE'
# Think Trace Indirect

tracegraphterm
NOTE

cat > "$OTHER_NOTE" <<'NOTE'
# Think Trace Other

tracegraphterm
NOTE

echo "[TEST] Think trace notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

brain focus "$FOCUS_NOTE" >/dev/null
echo "[TEST] Focus set"

normal_output="$(brain think tracegraphterm)"
printf "%s\n" "$normal_output" | grep -F "__think_trace_neighbor__.md" >/dev/null || {
    echo "[FAIL] Normal think output missing neighbor result"
    echo "$normal_output"
    exit 1
}
printf "%s\n" "$normal_output" | grep -F "__think_trace_indirect__.md" >/dev/null || {
    echo "[FAIL] Normal think output missing indirect result"
    echo "$normal_output"
    exit 1
}
printf "%s\n" "$normal_output" | grep -F "__think_trace_other__.md" >/dev/null || {
    echo "[FAIL] Normal think output missing other result"
    echo "$normal_output"
    exit 1
}
echo "[PASS] Normal think output remains available"

trace_output="$(brain think --trace tracegraphterm)"
printf "%s\n" "$trace_output" | grep -F "TRACE THINK" >/dev/null || {
    echo "[FAIL] Missing TRACE THINK header"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "GRAPH CONTEXT" >/dev/null || {
    echo "[FAIL] Missing GRAPH CONTEXT block"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "RANKED RESULTS" >/dev/null || {
    echo "[FAIL] Missing RANKED RESULTS block"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "__think_trace_neighbor__.md" >/dev/null || {
    echo "[FAIL] Missing neighbor in trace output"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "__think_trace_indirect__.md" >/dev/null || {
    echo "[FAIL] Missing indirect in trace output"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "__think_trace_other__.md" >/dev/null || {
    echo "[FAIL] Missing other in trace output"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "Focus boost" >/dev/null || {
    echo "[FAIL] Missing Focus boost field"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "Graph boost" >/dev/null || {
    echo "[FAIL] Missing Graph boost field"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "Composite" >/dev/null || {
    echo "[FAIL] Missing Composite field"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "Graph dist" >/dev/null || {
    echo "[FAIL] Missing Graph dist field"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "[d=1] Think Trace Neighbor" >/dev/null || {
    echo "[FAIL] Missing direct graph context entry"
    echo "$trace_output"
    exit 1
}
printf "%s\n" "$trace_output" | grep -F "[d=2] Think Trace Indirect" >/dev/null || {
    echo "[FAIL] Missing indirect graph context entry"
    echo "$trace_output"
    exit 1
}
echo "[PASS] Trace think output exposes deterministic scoring details"

cleanup

echo "[TEST] Cleanup done"
echo "[SUCCESS] Think trace test completed"
