# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.4 completion

---

# DONE (Phase 3.3)

- [x] brain health
- [x] brain stats
- [x] brain session
- [x] brain explain
- [x] brain context --trace
- [x] runtime diagnostics
- [x] CLI observability commands
- [x] graph command stabilization
- [x] shellcheck cleanup
- [x] deterministic CLI dispatcher

Phase 3.3 delivered the **Observability Layer**.

---

# DONE (Phase 3.4 — Graph Navigation)

Goal achieved: exploit the note graph for contextual navigation.

- [x] `brain graph <note>` refactored on memory query API
- [x] `brain backlinks <note>`
- [x] `brain neighbors <note>`
- [x] `brain path <noteA> <noteB>`
- [x] Graph traversal API in memory module
- [x] Deterministic BFS path resolution
- [x] Two-pass batch reindex for reliable graph resolution
- [x] Graph navigation test suite
- [x] CLI graph smoke coverage

Outcome:

Graph is now a first-class navigation surface in Brain.

---

# Immediate (Phase 3.5 — Graph-Aware Cognition)

Goal: promote graph from navigation layer to ranking signal.

- [ ] Graph proximity boost in think ranking
- [ ] Configurable graph weighting
- [ ] Path-aware context expansion
- [ ] Related notes command based on graph distance
- [ ] Stronger ambiguous note resolution policy
- [ ] Graph export groundwork

Outcome:

Graph becomes an active cognition signal, not just a navigation surface.

---

# Short Term (Stabilization Layer)

- [ ] CLI regression test suite
- [ ] Index stress test
- [ ] Concurrent indexing validation
- [ ] Structured logging format (JSON-compatible)
- [ ] State validation command (`brain validate`)
- [ ] Memory indexing performance benchmarks
- [ ] Module capability introspection

---

# Mid Term (Phase 4 Preparation)

- [ ] Hybrid semantic ranking (FTS + graph)
- [ ] Context reinforcement signals
- [ ] Execution policy framework
- [ ] Multi-module orchestration model
- [ ] Agent task routing prototype

---

# Long Term (Distributed Brain)

- [ ] Snapshot export/import
- [ ] Remote node synchronization
- [ ] Multi-instance coordination
- [ ] External toolchain connectors
- [ ] Replication strategy design

---

# Architectural Constraint Reminder

All future work must:

- Preserve Core determinism
- Maintain module isolation
- Avoid hidden state
- Remain reversible where possible
