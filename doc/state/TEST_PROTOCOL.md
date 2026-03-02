## Test Protocol

### Architecture Validation
- Ensure no direct modification of Core by modules.
- Verify all modules interact with Core through predefined interfaces.

---
# MAJ-OLD

# KaoBox Test Protocol

A version can be validated only if all checks pass.

---

## Core Validation

- env.sh loads without error
- sanity.sh returns success
- logger.sh initializes properly

---

## CLI Validation

- brain --help executes
- brain exits cleanly
- No uncaught errors

---

## Module Validation

- modules load without breaking core
- memory module initializes safely

---

## State Validation

- golden.version matches runtime
- state directory writable
- no forbidden file mutation

---

## Validation Result

All checks must pass before:

- Phase closure
- Version bump
