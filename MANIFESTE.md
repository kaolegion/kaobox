# KAOBOX — MANIFESTE FONDATEUR

### A Modular Deterministic Cognitive System

Version : 1.2  
Author : KaoLegion  
Project : KaoBox + KaoBox Brain

---

# 1. Vision

KaoBox vise à construire un **système cognitif modulaire, déterministe et programmable**.

Ce système doit permettre d’orchestrer :

- la mémoire
- la connaissance
- le contexte
- les graphes de relations
- les outils
- les workflows cognitifs
- les futurs agents

L’objectif n’est pas seulement de stocker des notes.

L’objectif est de bâtir une **infrastructure cognitive explicite**.

---

# 2. Philosophie du projet

## 2.1 Modularité radicale

Chaque composant doit être :

- indépendant
- remplaçable
- testable
- extensible

Aucun composant ne doit devenir un monolithe opaque.

---

## 2.2 Déterminisme

Le système doit rester :

- prévisible
- reproductible
- auditable

Le déterminisme n’est pas une contrainte secondaire.  
Il est au cœur de l’identité KaoBox.

---

## 2.3 Transparence

Les mécanismes internes doivent être :

- lisibles
- traçables
- inspectables

L’intelligence ne doit jamais être cachée dans des effets implicites.

---

## 2.4 IA augmentative

L’IA n’est pas un remplacement humain.

Elle est un **amplificateur cognitif**.

KaoBox doit permettre :

- d’augmenter la mémoire
- d’augmenter la navigation dans la connaissance
- d’augmenter le raisonnement contextualisé
- d’automatiser certaines opérations cognitives

---

# 3. Le concept de Brain

Le Brain est la couche cognitive de KaoBox.

Il agit comme :

- moteur mémoire
- moteur d’indexation
- moteur de recherche
- moteur de contexte
- moteur de graphe
- moteur de raisonnement

Il gère :

- les notes
- les métadonnées
- les tags
- les liens markdown
- les chemins entre notes

---

# 4. Architecture générale

KaoBox repose sur plusieurs couches :

- **Core** → infrastructure déterministe
- **Brain** → runtime cognitif
- **Modules** → moteurs spécialisés
- **Data** → mémoire, index, état
- **Interfaces** → CLI, agents, intégrations futures

Le système doit croître **par composition**, jamais par opacité.

---

# 5. KaoBox Brain aujourd’hui

Le Brain fournit déjà plusieurs moteurs cognitifs.

---

## 5.1 Memory Engine

- indexation transactionnelle
- stockage SQLite
- FTS5
- extraction de tags
- graphe de liens markdown

---

## 5.2 Context Engine

- couches SELF / GRAPH_OUT / GRAPH_IN / RECENT
- scoring temporel
- focus de session

---

## 5.3 Observability Layer

Commandes disponibles :

- `brain health`
- `brain stats`
- `brain session`
- `brain explain`

Le système peut désormais **s’auto-inspecter**.

---

## 5.4 Graph Navigation Layer

Commandes :

- `brain graph`
- `brain backlinks`
- `brain neighbors`
- `brain path`

KaoBox dépasse la simple indexation.

Il entre dans une logique de **navigation cognitive explicite**.

---

## 5.5 Think Engine

Commandes :

- `brain think`

Capacités :

- composite ranking model
- focus-aware retrieval
- graph-aware ranking
- deterministic ranking pipeline

Ranking model :

normalized_fts
focus_boost
graph_boost

Le graphe devient un **signal de pertinence cognitive**.

---

## 5.6 Graph Export Layer

Le Brain expose désormais une surface d’export du graphe de connaissances.

Implémentation : 
modules/memory/export.sh

Commandes :
brain export graph
brain export graph --format tsv

Format :
source_path<TAB>target_path

Propriétés :

- export déterministe
- couche en lecture seule
- extraction du graphe contrôlée par le module mémoire
- CLI strictement orchestration-only

Cette couche permet d’exposer le graphe de connaissances à des outils externes
tout en préservant les garanties de déterminisme de KaoBox.

---

# 6. Le modèle cognitif

Le système vise une chaîne de transformation :
Entrées
↓
Memory
↓
Graph
↓
Context
↓
Think
↓
Action

Les composants principaux sont :

- Inbox
- Memory
- Graph
- Context
- Think
- Action

---

# 7. Portabilité

KaoBox est conçu pour être :

- portable
- installable sur Linux
- indépendant d’une machine spécifique
- lisible sans dépendre d’une interface propriétaire

Le système doit pouvoir être transporté comme un **cerveau externe modulaire**.

---

# 8. Principes d’ingénierie

## Shell First

KaoBox privilégie :

- Bash
- SQLite
- outils Unix
- scripts explicites

Ce choix favorise :

- la portabilité
- l’auditabilité
- la robustesse

---

## Infrastructure before intelligence

L’intelligence n’a de valeur que si l’infrastructure est saine.

---

## Tests as Contract

Les tests ne sont pas accessoires.  
Ils participent au **contrat architectural du système**.

---

# 9. Cas d’usage

KaoBox peut servir à :

- gestion de connaissance
- mémoire personnelle structurée
- recherche contextuelle
- navigation par graphe
- préparation d’agents
- système cognitif personnel portable

---

# 10. Trajectoire

Phase 1 → fondation  
Phase 2 → durcissement production  
Phase 3 → intelligence opérationnelle  

Phase 3.4 → navigation graphe  
Phase 3.5 → cognition graph-aware  
Phase 3.6 → export déterministe du graphe  

Phase 4 → agents structurés  
Phase 5 → cognition distribuée

---

# 11. Vision long terme

Créer une infrastructure où :

- humains
- IA
- agents
- outils

peuvent coopérer dans un **espace cognitif partagé, explicite et modulaire**.

KaoBox n’est pas simplement un gestionnaire de notes.

C’est une tentative de construire un **système cognitif programmable**.

---

# 12. Conclusion

KaoBox cherche à augmenter la pensée humaine sans sacrifier :

- la lisibilité
- le contrôle
- l’auditabilité
- le déterminisme

Ce n’est pas seulement un logiciel.

C’est une **infrastructure cognitive déterministe**.
