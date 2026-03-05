# KaoBox Brain – Context Layer

## Role

The Context Layer is a cognitive extension of the Brain Kernel.

It is responsible for:
- Resolving graph relationships
- Ranking contextual relevance
- Managing active session focus

## Architecture

Input:
resolve_context(file)

Output format (pipe-separated):
path | layer | updated_at

Scoring:
score_context() applies:
- Layer base weights
- Temporal decay
- Session boost

Session:
Managed via $BRAIN_ROOT/.session

## Layer Separation

- Does NOT belong to modules/
- Depends on BRAIN_DB runtime
- Extends the kernel, not the memory backend

## Future Roadmap

- Adaptive scoring weights
- Frequency learning
- Configurable decay
- Multi-session support
- Agent-driven prioritization
