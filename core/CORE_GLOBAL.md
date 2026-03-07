E:\Documents-Kao\kaobox\core\CORE_GLOBAL.md

# KaoBox Core

## Overview

`core/` is the **global deterministic system layer** of KaoBox.

It provides the runtime foundation required by the rest of the project:

- environment initialization
- shell integration
- logging
- sanity checks
- localization
- bootstrap routines

`core/` is infrastructure only.

It must remain independent from domain modules and should contain **no business logic**.

---

# Responsibilities

The Core layer is responsible for:

- defining the global KaoBox environment
- preparing the runtime shell
- exposing aliases and completion
- validating system prerequisites
- handling localization
- supporting bootstrap and profile initialization
- providing shared logging services

It is the **system kernel layer**, not the Brain itself.

---

# Internal Structure

## `env.sh`

Global KaoBox environment contract.

Defines:

- `KAOBOX_ROOT`
- `KAOBOX_CORE`
- `KAOBOX_LIB`
- `KAOBOX_MODULES`
- `KAOBOX_I18N`
- `KAOBOX_PROFILES`
- `KAOBOX_LOG_DIR`
- `KAOBOX_LOG_FILE`
- `KAOBOX_VERSION`
- `KAOBOX_RUNTIME`

Purpose:

- expose stable global runtime paths
- provide shared environment values for subshells and tools

---

## `logger.sh`

Centralized logging service.

Provides:

- `log_debug`
- `log_info`
- `log_warn`
- `log_error`

Features:

- level-based filtering
- optional file output
- deterministic formatting

This module is shared across KaoBox subsystems.

---

## `sanity.sh`

System validation helpers.

Checks:

- required tools
- WSL/runtime assumptions
- log directory existence
- write permissions

Purpose:

- validate the host environment before deeper runtime use

---

## `i18n.sh`

Localization layer.

Responsibilities:

- select system language on first run
- load language definitions from `lang/`
- expose the translation function `t KEY`

This layer keeps user-facing text deterministic and explicit.

---

## `init.sh`

Bootstrap entry for KaoBox profile setup.

Responsibilities:

- initialize user-facing runtime on first launch
- manage profile creation/loading
- integrate localization during bootstrap

This script belongs to the **system bootstrap layer**, not the Brain runtime.

---

## `shell.sh`

Interactive shell integration layer.

Responsibilities:

- expose `KAOBOX_BIN` into `PATH`
- define convenience aliases
- load completion
- set editor defaults

Examples:

- `kb`
- `brainlog`

This module improves operator ergonomics while preserving deterministic behavior.

---

## `completion.sh`

Shell completion layer for Brain commands.

Capabilities:

- list available Brain commands
- suggest note titles
- suggest tags for `brain search tag:*`

Although stored in `core/`, this script acts as a **shell integration bridge** toward the Brain runtime.

---

# Design Rules

The Core layer must:

- remain deterministic
- stay minimal
- avoid domain logic
- avoid direct module mutation
- provide shared infrastructure only

Core may expose integration helpers, but must never become a business layer.

---

# Position in KaoBox

Architecture role:

User / Operator
  ↓
core/
  ↓
bin/
  ↓
lib/brain/
  ↓
modules/

Core provides the runtime substrate on which higher layers rely.

---

## Core vs Brain

core/ and lib/brain/ are distinct by design.

> core/

Global KaoBox infrastructure:

- shell
- bootstrap
- localization
- logging
- sanity

> lib/brain/

Cognitive runtime:

- dispatcher
- commands
- context engine
- think engine
- observability

This separation is a key architectural invariant.

---

## Current Status

Track: v2.9
Phase: 3.3 — Observability Layer Stable

Core status:

- stable
- shellcheck-clean
- modular
- deterministic

core/ is considered a valid infrastructure base for future KaoBox expansion.
