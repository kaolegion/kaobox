# KaoBox Test Protocol

Version: v2.9  
Aligned with Phase 3.2 completion

A version can be validated only if all checks pass.

Validation must confirm:

- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1️⃣ Core Validation

Core must remain deterministic and stable.

Checks:

- env.sh loads without error
- sanity.sh returns success
- logger.sh initializes properly
- shell bootstrap executes without side effects
- No module directly modifies core/

Failure of any check invalidates the release.

---

# 2️⃣ SQLite & Memory Engine Validation (Phase 2)

Checks:

- WAL mode enabled
- PRAGMA synchronous = FULL
- Integrity check passes (`brain doctor`)
- Transaction wrapper enforces BEGIN IMMEDIATE
- No partial writes after simulated crash
- Reindex is idempotent
- No schema drift detected

Memory must be:

- Deterministic to rebuild
- Crash-safe
- Concurrency-safe

---

# 3️⃣ Context Engine Validation (Phase 3.2)

Checks:

- resolve_context returns structured layers
- score_context returns sorted numeric scores
- SELF note appears in results
- Session boost applied correctly
- Temporal decay behaves consistently
- No direct SQL inside CLI commands

Scoring must be reproducible.

Context must not mutate state unexpectedly.

---

# 4️⃣ CLI Validation

Checks:

- brain --help executes
- brain exits cleanly
- Commands return proper exit codes
- No uncaught errors
- Dispatcher does not contain business logic
- set -o pipefail behavior validated

CLI must orchestrate, not compute.

---

# 5️⃣ Module Validation

Checks:

- Modules load without breaking Core
- memory module initializes safely
- No module overrides bin/brain
- No module modifies base/
- Modules handle failure gracefully

Isolation is mandatory.

---

# 6️⃣ State Validation

Checks:

- golden.version matches runtime
- state directory writable
- No forbidden file mutation
- Session focus persistence works
- Runtime flags consistent

State must be explicit and recoverable.

---

# 7️⃣ Determinism Validation

Checks:

- Reindex twice → identical DB state
- Context query twice → identical ordering (if no new writes)
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.
Adaptive behavior must remain bounded to modules.

---

# 8️⃣ Validation Result

All checks must pass before:

- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure to meet any check blocks release.
