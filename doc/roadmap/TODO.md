# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.2 completion

---

# Immediate (Phase 3.3 — Observability)

- [ ] Implement context explainability output (`brain context --explain`)
- [ ] Add health scoring command (`brain health`)
- [ ] Add session inspection command (`brain session`)
- [ ] Add runtime diagnostics summary
- [ ] Validate CLI exit codes consistency
- [ ] Harden pipefail across dispatcher
- [ ] add CLI regression tests
- [ ] add index stress test
- [ ] add concurrent indexing test
- [ ] brain explain
- [ ] brain health
- [ ] brain session
- [ ] brain context --trace
- [ ] runtime diagnostics

---

# Short Term (Stabilization Layer)

- [ ] Structured logging format (JSON-compatible)
- [ ] Add state validation script (`brain validate`)
- [ ] Improve memory indexing performance benchmarks
- [ ] Add module enable/disable mechanism
- [ ] Add module capability introspection

---

# Mid Term (Phase 4 Preparation)

- [ ] Hybrid semantic indexing (FTS + graph ranking)
- [ ] Context reinforcement signals
- [ ] Execution policy framework
- [ ] Multi-module orchestration model
- [ ] Agent task routing prototype

---

# Long Term (Distributed Brain)

- [ ] Snapshot export/import mechanism
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

---

# Next: Graph Boost

- Boost notes linked to active note
- Weight configurable
- Based on links table
