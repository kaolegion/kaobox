# KaoBox Test Protocol	
Version: v2.9  
Aligned with Phase 3.3 completion

A version can be validated only if all checks pass.

Validation must confirm:
- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1 Core Validation
Core must remain deterministic and stable.

Checks:
- `core/env.sh` loads without error
- `core/sanity.sh` returns success
- `core/logger.sh` initializes correctly
- `core/shell.sh` loads without side effects
- No module directly modifies `core/`

Failure of any check invalidates the release.

---

# 2 SQLite & Memory Engine Validation (Phase 2)
Checks:
- WAL mode enabled
- `PRAGMA synchronous = FULL`
- Integrity check passes (`brain doctor`)
- Transaction wrapper enforces `BEGIN IMMEDIATE`
- No partial writes after simulated crash
- Reindex is idempotent
- No schema drift detected

Memory must be:
- Deterministic to rebuild
- Crash-safe
- Concurrency-safe

---

# 3 Memory Index Validation
Checks:
- Markdown notes are indexed
- Titles extracted correctly
- Tags extracted from `#tags`
- Links extracted from `[[links]]`
- File hash stored
- File mtime stored

Verification commands:
brain reindex
brain stats
brain health

Expected:
- FTS rows == notes count
- tags count stable
- links count consistent

---

# 4 Graph Validation
Checks:
- Markdown links `[[note]]` detected
- Links inserted into `links` table
- `brain graph <note>` resolves edges
- Backlinks returned correctly

Verification:
brain graph <note>
sqlite3 brain.db "SELECT COUNT(*) FROM links;"

---

# 5 Context Engine Validation (Phase 3.2)
Checks:
- Context resolver returns structured layers
- SELF node present
- GRAPH_IN nodes detected
- GRAPH_OUT nodes detected
- RECENT nodes included
- Temporal decay applied

Verification:
brain context <note>
brain context --trace <note>

Scoring must remain reproducible.

---

# 6 Think Engine Validation
Checks:
- FTS results retrieved
- Composite ranking applied
- Focus boost applied to active session
- Ranking stable across repeated queries

Verification:
brain think <query>

Expected:

- results sorted by composite score
- active session note boosted

---

# 7 Observability Validation (Phase 3.3)
Checks:
- Runtime diagnostics available
- Context session visible
- Query explainability functional

Verification commands:
brain status
brain doctor
brain health
brain stats
brain session
brain explain <query>	

Expected:

- DB integrity reported
- runtime metrics visible
- session focus displayed

---

# 8 CLI Validation
Checks:
- `brain` CLI loads correctly
- `brain --help` displays command list
- commands return correct exit codes
- no uncaught errors
- dispatcher contains no business logic
- `set -o pipefail` safe

CLI must orchestrate, not compute.

---

# 9 Module Isolation Validation
Checks:
- Modules load without modifying Core
- memory module initializes safely
- No module overrides `bin/brain`
- No module modifies `base/`
- Module failures do not crash CLI

Isolation is mandatory.

---

# 10 State Validation
Checks:
- `state/golden.version` matches runtime
- `state/system.lang` readable
- state directory writable
- session focus persistence works

State must remain explicit and recoverable.

---

# 11 Determinism Validation
Checks:
- Reindex twice → identical DB state
- Context query twice → identical ordering
- Think query twice → identical ranking
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.

Adaptive behavior must remain bounded to modules.

---

# 12 Validation Result
All checks must pass before:
- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure of any check blocks release.
