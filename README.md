# KaoBox

KaoBox est une infrastructure agentique modulaire conçue pour construire un noyau cognitif local, déterministe et extensible.

Il fournit une base architecturale stable pour développer :

- des systèmes de mémoire structurée
- des moteurs transactionnels
- des agents connectés à une connaissance persistante

---

## ✨ Principes

KaoBox repose sur des fondations strictes :

- **Modularité** — chaque composant est isolé et remplaçable  
- **Déterminisme** — comportement prévisible et traçable  
- **Transactionnalité** — cohérence garantie  
- **Local-first** — aucune dépendance cloud  
- **Portabilité** — Linux-first, reproductible  
- **Architecture avant interface**

KaoBox n’est pas orienté UI-first.  
Il est conçu comme un **kernel cognitif programmable**.

---

## 🧠 Vision

Construire une infrastructure capable de :

- Structurer de la connaissance en Markdown
- Maintenir un index transactionnel robuste
- Générer un graphe cohérent (liens entrants / sortants)
- Prioriser le contexte via un moteur adaptatif
- Alimenter des agents structurés
- Servir de mémoire persistante programmable

---

## 🗂 Structure du projet
# KaoBox

KaoBox est une infrastructure agentique modulaire conçue pour construire un noyau cognitif local, déterministe et extensible.

Il fournit une base architecturale stable pour développer :

- des systèmes de mémoire structurée
- des moteurs transactionnels
- des agents connectés à une connaissance persistante

---

## ✨ Principes

KaoBox repose sur des fondations strictes :

- **Modularité** — chaque composant est isolé et remplaçable  
- **Déterminisme** — comportement prévisible et traçable  
- **Transactionnalité** — cohérence garantie  
- **Local-first** — aucune dépendance cloud  
- **Portabilité** — Linux-first, reproductible  
- **Architecture avant interface**

KaoBox n’est pas orienté UI-first.  
Il est conçu comme un **kernel cognitif programmable**.

---

## 🧠 Vision

Construire une infrastructure capable de :

- Structurer de la connaissance en Markdown
- Maintenir un index transactionnel robuste
- Générer un graphe cohérent (liens entrants / sortants)
- Prioriser le contexte via un moteur adaptatif
- Alimenter des agents structurés
- Servir de mémoire persistante programmable

---

## 🗂 Structure du projet

bin/ → CLI utilisateur
core/ → noyau déterministe (env, logger, sanity, shell)
base/ → manifests système (golden layer)
lib/ → dispatcher & commandes CLI
modules/ → extensions modulaires (ex: memory)
profiles/ → isolation multi-instance
state/ → état runtime et versioning
logs/ → journaux système
doc/ → documentation officielle
tests/ → validation et intégration

---

## 🏗 Architecture

Séparation stricte des couches :

CLI (bin/)
↓
Dispatcher (lib/)
↓
Modules (modules/)
↓
Context Layer (modules//context)
↓
Engine Layer (modules//engine)
↓
SQLite / Filesystem

### Règles fondamentales

- Le CLI ne parle jamais directement à la base de données.
- Les modules sont auto-contenus.
- Le noyau (`core/`) ne dépend d’aucun module.
- Les transactions sont centralisées.
- L’état système est explicitement versionné.
- Le déterminisme du Core est non négociable.

---

## 📦 Module Memory (Brain Engine)

Le module `memory` implémente :

### Engine Layer

- Indexation transactionnelle
- WAL + FULL synchronous
- FTS5 (full-text search)
- Graphe de liens (backlinks)
- Tags sémantiques
- Garbage collection cohérente
- Hash + mtime tracking
- Reindex batch atomique

### Context Layer (Phase 3.2)

- Résolution de contexte
- Ranking adaptatif (SELF / GRAPH_IN / GRAPH_OUT / RECENT)
- Décroissance temporelle
- Session focus boost

## 🧠 Think Engine (Context-Aware Retrieval)

The Think Engine combines:

- SQLite FTS relevance (BM25)
- Session-based focus boost
- Composite ranking pipeline

Scoring formula (v1):

    composite_score = normalized_fts + focus_boost

Future roadmap:
- Graph-based proximity boost
- Tag-based similarity
- Temporal recency weighting

Ce module constitue la première brique opérationnelle du Brain Engine.

---

## 🚀 Installation (dev)

```bash
git clone <repo>
cd kaobox
./init.sh

---
🧪 Tests
./tests/test_memory_index.sh
./tests/test_reindex.sh

---
🛣 Roadmap

Voir :

doc/roadmap/ROADMAP.md

doc/state/PHASE_HISTORY.md

---
📌 Objectif long terme

KaoBox vise à devenir :

Une base stable pour des systèmes cognitifs locaux

Un socle pour agents structurés

Une infrastructure Brain portable et extensible

Un noyau déterministe sur lequel greffer de l’intelligence contrôlée

---
📜 Version

Current Track: v2.9
Status: Phase 3 — Operational Intelligence
Brain Engine: Production Hardened (v2.8)
Context Engine: Stable (Phase 3.2)

---

Maintenant **100% aligné doc ↔ code ↔ roadmap ↔ phase history**.

On peut faire un dernier check ultra strict sur :

- `bin/brain`
- `lib/brain/dispatcher.sh`

puis commit final.
