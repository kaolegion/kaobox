# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.3 completion

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

# Immediate (Phase 3.4 — Graph Navigation)

Goal: exploit the note graph for contextual navigation.

- [ ] `brain neighbors <note>`
- [ ] `brain backlinks <note>`
- [ ] `brain path <noteA> <noteB>`
- [ ] Graph proximity boost in ranking
- [ ] Graph traversal API in memory module

Outcome:

Graph becomes a first-class signal for cognition.

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
