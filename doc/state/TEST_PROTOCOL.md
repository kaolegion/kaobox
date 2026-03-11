# KaoBox Test Protocol

Version: v2.9
Aligned with Phase 3.9 CLI regression contract

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
brain related <note>
brain path <a> <b>
query_graph_proximity_by_note <note_id>
sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM links;"

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
- `brain related <note>` returns deterministic direct graph proximity
- `brain path <a> <b>` returns a deterministic traversal when a path exists
- Two-pass batch reindex resolves forward links correctly
- Graph proximity query returns deterministic neighbors
- Ambiguous graph-facing note references are rejected explicitly and deterministically
- Resolver candidate ordering remains deterministic

Verification :
brain graph <note>
brain backlinks <note>
brain neighbors <note>
brain related <note>
brain path <a> <b>
./tests/test_note_ref_resolution.sh
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
- CLI export command dispatches correctly

Verification :

export_graph_edges_tsv

brain export graph
brain export graph --format tsv

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
- Path-aware graph context expansion applied from active focus
- Distance-aware graph weighting remains bounded and deterministic
- Distance 1 path results preserve strongest graph signal
- Distance 2 and distance 3 path results remain eligible through decayed graph weighting
- Ranking stable across repeated queries
- Default graph boost remains stable
- `BRAIN_THINK_GRAPH_BOOST` override is applied only when valid
- Invalid `BRAIN_THINK_GRAPH_BOOST` falls back deterministically to `THINK_GRAPH_BOOST`

Verification :
brain think <query>
./tests/test_think_graph_boost.sh

Expected :
- results sorted by composite score
- active session note boosted
- direct graph neighbor receives strongest graph boost
- indirect path results are eligible through bounded path-aware expansion
- runtime graph weighting remains bounded and deterministic
- direct graph boost compatibility remains preserved

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
- smoke CLI coverage remains lightweight
- explicit regression contract coverage exists for graph-facing and cognition-facing commands

CLI must orchestrate, not compute.

Verification :
./tests/test_brain_cli.sh
./tests/test_cli_regression_contract.sh

Expected :
- smoke command wiring remains valid
- explicit CLI success paths remain stable
- graph-facing ambiguous resolver errors propagate deterministically through the CLI
- cognition-facing CLI results remain contractually covered

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
- Related query twice → identical ordering
- Path query twice → identical traversal
- Note resolution for the same unambiguous reference is identical across repeated calls
- Ambiguous note resolution returns identical candidate ordering across repeated calls
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.

Adaptive behavior must remain bounded to modules.

---

# 12 Validation Result

All checks must pass before :
- Phase closure
- Release tagging
- Push validation
