# KaoBox Architecture

## Overview
KaoBox is a modular cognitive infrastructure designed as a **deterministic brain kernel**.

Root path:
/opt/kaobox

The system is layered to enforce:
- Determinism
- Isolation
- Explicit state
- Controlled extensibility

---

# System Layers

---

# Layer 0 — Operating System
Environment:

- Linux
- Bash
- SQLite

KaoBox assumes a controlled POSIX runtime.

---

# Layer 1 — Core (Deterministic Kernel)
Directory:
core/

Components:
- env.sh
- init.sh
- logger.sh
- sanity.sh
- shell.sh
- lang/
- state/

Responsibilities:
- Environment bootstrap
- Logging
- System validation
- Localization
- Deterministic runtime configuration

Rules:

Core must:
- Never depend on modules
- Never contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

# Layer 2 — Cognitive Layer (Brain)
Directory:
lib/brain/

Components:
- dispatcher.sh
- commands/
- context/
- think/
- renderer.sh
- sanitize.sh
- preflight.sh
- lock.sh

This layer implements the **cognitive runtime**.

Responsibilities:
- command dispatch
- context resolution
- ranking logic
- reasoning orchestration
- rendering output

---

# Context Engine
Location:
lib/brain/context/

Components:
- resolver.sh
- scorer.sh
- session.sh

Purpose:
Build contextual signals for ranking.

### Context Layers
- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

### Ranking Model
Score =
(Layer Weight × Temporal Decay)
+ Session Boost

Layer Weights:
SELF → 4  
GRAPH_OUT → 3  
GRAPH_IN → 2  
RECENT → 1

Temporal Decay:
0–1 days → 100%  
2–7 days → 70%  
8–30 days → 40%  
>30 days → 20%

Session Boost:
+5 if note is active focus

---

# Think Engine
Location:
lib/brain/think/

Components:
- engine.sh
- ranker.sh

Purpose:
Composite retrieval and ranking.

Dependencies:
- memory/query.sh
- context/session.sh

Ranking formula:
composite_score =
normalized_fts
+ focus_boost

Focus boost:
+5 if note is active.

---

# Layer 3 — Modules
Directory:
modules/

Modules provide **domain engines**.

Current module:
modules/memory/

---

# Memory Module
Location:
modules/memory/

Structure:
memory/
├── engine/
│ ├── utils.sh
│ ├── metadata.sh
│ ├── fts.sh
│ ├── tags.sh
│ ├── links.sh
│ └── tx.sh
├── index.sh
├── query.sh
├── gc.sh
└── init.sh

Features:
- SQLite WAL
- FTS5 search
- transactional indexing
- tag extraction
- markdown link graph
- file hash tracking

Modules must:
- remain isolated
- not mutate core
- expose explicit interfaces

---

# Layer 4 — CLI Interface
Directory:
bin/

Components:
bin/brain
bin/kaobox-shell

The CLI:

- parses user commands
- invokes the brain dispatcher
- never accesses the database directly

---

# Layer 5 — Runtime State
Directory:
state/

Contains:
- version state
- language state
- runtime flags

Mutable by design.

---

# Layer 6 — Documentation
Directory:
doc/

Contains:
- architecture
- roadmap
- phase history
- agent specifications
- test protocols

Documentation is considered part of the **system contract**.

---

# Think Pipeline
User Query
↓
FTS Query (modules/memory/query.sh)
↓
Think Engine (lib/brain/think/engine.sh)
↓
Ranker
↓
Renderer
↓
CLI Output

---

# Design Principles
1. Deterministic Core  
2. Modular Engines  
3. Explicit State  
4. Minimal Coupling  
5. Infrastructure First  
6. Intelligence as Layered Emergence  

---

# Architectural Identity
KaoBox is not a workspace.

It is a **programmable cognitive kernel**.

Where most systems optimize UI,
KaoBox optimizes **structured cognition**.

---

# Future Extensions
- Graph navigation engine
- semantic ranking layer
- reinforcement signals
- agent orchestration layer

---

# Status
Phase 3.3 — Observability Layer  
System Status: **Stable Cognitive Kernel**
