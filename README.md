# KaoBox

KaoBox est une infrastructure agentique modulaire conçue pour construire un noyau cognitif local, déterministe et extensible.

Il fournit une base architecturale stable pour développer des systèmes de mémoire structurée, des moteurs transactionnels et des agents connectés à une connaissance persistante.

---

## ✨ Principes

KaoBox repose sur des fondations simples et strictes :

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
- Maintenir un index transactionnel
- Générer un graphe sémantique cohérent
- Alimenter des agents autonomes
- Servir de mémoire persistante programmable

---

## 🗂 Structure du projet


bin/ → CLI et interfaces utilisateur
core/ → moteur système (env, logger, shell, sanity)
base/ → manifests système (golden layer)
lib/ → logique des commandes et dispatcher
modules/ → extensions modulaires (ex: memory)
profiles/ → isolation multi-instance
state/ → état runtime et versioning
logs/ → journaux système
doc/ → documentation officielle
tests/ → validation et intégration


---

## 🏗 Architecture

KaoBox respecte une séparation stricte des couches :


CLI (bin/)
↓
Dispatcher (lib/)
↓
Modules (modules/)
↓
Engines internes (modules/*/engine)
↓
SQLite / Filesystem


### Règles d’architecture

- Le CLI ne parle jamais directement à la base de données.
- Les modules sont auto-contenus.
- Le noyau (`core/`) ne dépend d’aucun module.
- Les transactions sont centralisées.
- L’état système est explicitement versionné.

---

## 📦 Module Memory (Brain Engine)

Le module `memory` implémente :

- Indexation transactionnelle
- FTS5 (full-text search)
- Tags sémantiques
- Graphe de liens (backlinks / relations)
- Garbage collection cohérente
- Hash + mtime tracking
- Reindex batch atomique

Il constitue la première brique du Brain Engine.

---

## 🚀 Installation (dev)

```bash
git clone <repo>
cd kaobox
./init.sh
🧪 Tests
./tests/test_memory_index.sh
./tests/test_reindex.sh
🛣 Roadmap

Voir :

doc/roadmap/ROADMAP.md

doc/state/PHASE_HISTORY.md

📌 Objectif long terme

KaoBox vise à devenir une base stable pour :

Des systèmes cognitifs locaux

Des agents connectés à une mémoire structurée

Une infrastructure Brain portable et extensible

📜 Version

Brain v2 — Modular Transactional Architecture Stable


---

### Ce que j’ai corrigé :

- Suppression des duplications
- Fermeture correcte des blocs ```bash
- Hiérarchie Markdown cohérente
- Sections réorganisées proprement
- Mise en forme GitHub-ready

---

Si tu veux, prochaine étape :

- Ajouter un badge version / status
- Ajouter un schéma ASCII plus avancé
- Ajouter une section “Why KaoBox”
- Ou écrire une version minimaliste ultra-kernel style (très sobre, très clean)
