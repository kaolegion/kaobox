# Thermal Cognitive Field

## Definition

The Thermal Cognitive Field is a local propagation mechanism of cognitive heat
through the Brain graph.

It allows KaoBox to slightly influence the ranking of notes that are
structurally close to a cognitively active focus.

This introduces a gradient-based cognition model rather than a purely
structural or semantic ranking.

---

## Cognitive Signals

Three distinct signals participate in contextual ranking:

- graph_boost  
  Structural proximity signal derived from graph distance.

- heat_boost  
  Local signal derived from the intrinsic heat of a note.

- thermal_graph_boost  
  Weak propagated signal derived from the heat of the active focus.

---

## Ranking Composite

The Think Engine ranking composite is defined as:

composite =
 relevance
 + focus_boost
 + graph_boost
 + heat_boost
 + thermal_graph_boost

The thermal_graph_boost is computed as a logarithmic decay over graph distance.

---

## Mental Model

- A hot focus acts as a cognitive heat source.
- Neighbor notes receive a small ranking influence.
- The influence decays with graph distance.
- The focus itself is not influenced by its own propagation.

This creates a local cognitive field rather than a global heat diffusion.

---

## Observability

The thermal field is visible through:

- brain think --trace
- graph distance signals
- explicit thermal_graph_boost values

This ensures deterministic explainability of ranking behavior.

---

## Future Evolution

Potential evolutions include:

- multi-distance propagation
- multi-source heat blending
- temporal heat memory
- graph traversal influence by heat gradients
