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

bin/               → CLI utilisateur
core/              → noyau déterministe (env, logger, sanity, shell)
lib/brain          → dispatcher & commandes CLI
lib/brain/context/   ""
lib/brain/think/     "" 
modules/memory/    → moteur mémoire transactionnel 
profiles/          → isolation multi-instance
state/             → état runtime  
logs/              → journaux  
doc/               → documentation officielle  
tests/             → validation n

---

## 🏗 Architecture

Séparation stricte des couches :

CLI (bin/)
↓
Dispatcher (lib/brain/dispatcher.sh)
↓
Commands (lib/brain/commands/)
↓
Cognitive Layer (lib/brain/context + think)
↓
Memory Module (modules/memory/)
↓
SQLite + Filesystem

### Règles fondamentales

- Le CLI ne parle jamais directement à la base de données.
- Les modules sont auto-contenus.
- Le noyau (`core/`) ne dépend d’aucun module.
- Les transactions sont centralisées.
- L’état système est explicitement versionné.
- Le déterminisme du Core est non négociable.

---

## 📦 Module Memory (Brain Engine)

### Engine Layer

- FTS5
- WAL
- Transaction control
- Link graph
- Tag system
- Hash + mtime tracking

### Context Layer (Phase 3.2)

- Layered context resolution
- Temporal decay
- Session focus boost

## 🧠 Think Engine (Context-Aware Retrieval)

The Think Engine combines:
Composite ranking:
composite_score = normalized_fts + focus_boost
Focus Boost: +5 on active note

---

## 🚀 Installation (dev)

```bash
git clone <repo>
cd kaobox
./init.sh

---
🧪 Tests
./tests/test_memory_index.sh

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

Track: v2.9
Phase: 3.2 — Context Engine Stable
Think Engine: v1 Stable
Status: Operational Intelligence Base
