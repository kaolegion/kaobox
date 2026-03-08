# KaoBox Test Protocol

Version: v2.9  
Aligned with Phase 3.6 graph export groundwork

A version can be validated only if all checks pass.

Validation must confirm:
- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1 Core Validation

Core must remain deterministic and stable.

Checks :
- `core/env.sh` loads without error
- `core/sanity.sh` returns success
- `core/logger.sh` initializes correctly
- `core/shell.sh` loads without side effects
- No module directly modifies `core/`

Failure of any check invalidates the release.

---

# 2 SQLite & Memory Engine Validation

Checks :
- WAL mode enabled
- `PRAGMA synchronous = FULL` or runtime durability policy consistent with current track
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

Checks :
- Markdown notes are indexed
- Titles extracted correctly
- Tags extracted from `#tags`
- Links extracted from `[[links]]`
- File hash stored
- File mtime stored

Verification commands :
Verification:
brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain path <a> <b>
query_graph_proximity_by_note <note_id>
sqlite3 brain.db "SELECT COUNT(*) FROM links;"

Expected :
- FTS rows == notes count
- tags count stable
- links count consistent

---

# 4 Graph Navigation Validation

Checks :
- Markdown links `[[note]]` detected
- Links inserted into `links` table
- `brain graph <note>` resolves outgoing and incoming edges
- `brain backlinks <note>` returns incoming links
- `brain neighbors <note>` returns direct graph neighbors
- `brain path <a> <b>` returns a deterministic traversal when a path exists
- Two-pass batch reindex resolves forward links correctly
- Graph proximity query returns deterministic neighbors

Verification :
brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain path <a> <b>
sqlite3 brain.db "SELECT COUNT(*) FROM links;"

---

# 4.1 Graph Export Validation

The Brain graph must be exportable in a deterministic and reproducible way.

Checks :
- Graph edges can be exported from the memory module
- Export layer remains read-only
- Export ordering is deterministic
- Export output remains stable across repeated runs
- Export does not mutate the database
- Export works even when the Brain contains additional unrelated notes

Verification :
export_graph_edges_tsv

Expected :
- output format:
  source_path<TAB>target_path
- deterministic ordering
- identical results across repeated calls
- export test subset remains stable

---

# 5 Context Engine Validation

Checks :
- Context resolver returns structured layers
- SELF node present
- GRAPH_IN nodes detected
- GRAPH_OUT nodes detected
- RECENT nodes included
- Temporal decay applied

Verification :
brain context <note>
brain context --trace <note>

Scoring must remain reproducible.

---

# 6 Think Engine Validation

Checks :
- FTS results retrieved
- Composite ranking applied
- Focus boost applied to active session
- Graph proximity boost applied when neighbors match
- Ranking stable across repeated queries

Verification :
brain think <query>

Expected :
- results sorted by composite score
- active session note boosted

---

# 7 Observability Validation

Checks :
- Runtime diagnostics available
- Context session visible
- Query explainability functional

Verification commands :
brain status
brain doctor
brain health
brain stats
brain session
brain explain <query>

Expected :
- DB integrity reported
- runtime metrics visible
- session focus displayed

---

# 8 CLI Validation

Checks :
- `brain` CLI loads correctly
- `brain --help` displays command list
- commands return correct exit codes
- no uncaught errors
- dispatcher contains no business logic
- `set -o pipefail` safe

CLI must orchestrate, not compute.

---

# 9 Module Isolation Validation

Checks :
- Modules load without modifying Core
- memory module initializes safely
- No module overrides `bin/brain`
- No module modifies `base/`
- Module failures do not crash CLI

Isolation is mandatory.

---

# 10 State Validation

Checks :
- `state/golden.version` matches runtime
- `state/system.lang` readable
- state directory writable
- session focus persistence works

State must remain explicit and recoverable.

---

# 11 Determinism Validation

Checks :
- Reindex twice → identical DB state
- Context query twice → identical ordering
- Think query twice → identical ranking
- Graph query twice → identical ordering
- Path query twice → identical traversal
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.

Adaptive behavior must remain bounded to modules.

---

# 12 Validation Result

All checks must pass before :
- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure of any check blocks release.

---

# Automated Test Suite

The following scripts must pass :
./tests/run_all.sh

Which includes :
- test_logger.sh
- test_memory_index.sh
- test_graph_navigation.sh
- test_graph_path.sh
- test_graph_proximity.sh
- test_graph_export.sh
- test_think_graph_boost.sh
- test_brain_cli.sh
