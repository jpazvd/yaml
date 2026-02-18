# YAML Architecture Refactor Plan (Modular Subcommands)

**Date:** 04Feb2026  
**Owner:** João Pedro Azevedo  
**Status:** Draft  
**Branch:** feat/yaml-arch-refactor-plan  

## Goals

1. Split `yaml.ado` into modular subcommands for clarity and maintenance.
2. Enforce a consistent `verbose` option and debugging hooks across all functions.
3. Preserve compatibility and performance (fastread, cache, index, streaming).

---

## Proposed Module Layout

- `yaml.ado` — dispatcher only
- `yaml_read.ado` — read/parse, cache/index, fastread
- `yaml_write.ado`
- `yaml_list.ado`
- `yaml_get.ado`
- `yaml_describe.ado`
- `yaml_validate.ado`
- `yaml_dir.ado`
- `yaml_frames.ado`
- `yaml_clear.ado`
- `yaml_utils.ado` — shared helpers (tokenization, key normalization, checksum/cache, logging)
- `yaml_fastread.ado` — fastread engine and related checks

**Naming:** all subcommands are `yaml_<subcommand>`; internal helpers are `_yaml_<helper>`.

---

## Debug/Verbose Standard

### Required Behavior

Every public subcommand should accept:

- `verbose` — standard verbose logging (human-readable)
- `debug` — optional deep logging (program state, line numbers, timing)

### Shared Logging Helpers (yaml_utils.ado)

- `_yaml_log` (respects `verbose`)
- `_yaml_debug` (respects `debug`)
- `_yaml_timer_start` / `_yaml_timer_stop` (optional, Stata 14+)

### Minimum Log Events

All subcommands must log:
- Entry + received arguments (in debug)
- Main actions (read/write/search/validate)
- Return summary (key counts, frame names, cache hit)

---

## Refactor Stages

### Stage 1: Create Skeleton Modules

- Create each new `yaml_<subcommand>.ado` with current code copied from `yaml.ado`.
- Keep behavior identical.
- Add `verbose`/`debug` options to signatures where missing.

### Stage 2: Extract Shared Helpers

Move common helpers into `yaml_utils.ado`:
- key normalization
- checksum + cache lookup
- tokenization
- line trimming + indentation
- error formatting

### Stage 3: Fastread Isolation

Move fastread engine into `yaml_fastread.ado` and:
- isolate unsupported feature checks
- isolate block scalar capture

### Stage 4: Dispatcher Cleanup

Reduce `yaml.ado` to:
- parse subcommand
- call `yaml_<subcommand>`

### Stage 5: QA Updates

- Update `qa/run_tests.do` to load module files
- Add debug/verbose smoke test in QA

---

## Compatibility & Migration

- Keep old syntax intact.
- New options (`verbose`, `debug`) are additive.
- Ensure `yaml` continues to work when only `yaml.ado` is installed (verify with `do` + adopath).

---

## Debugging Mechanisms

1. `verbose` logs: user-friendly, minimal
2. `debug` logs: include program state, line numbers
3. `trace` compatibility: ensure code runs cleanly under `set trace on`

---

## Deliverables Checklist

- [ ] `yaml_<subcommand>.ado` files created
- [ ] `yaml_utils.ado` helpers
- [ ] `yaml_fastread.ado` helper
- [ ] `yaml.ado` slim dispatcher
- [ ] Updated `yaml.sthlp` to document `verbose`/`debug`
- [ ] Updated examples to show debug usage
- [ ] QA updated to cover verbose/debug

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Subcommand split breaks calls | keep function names stable, test all examples |
| Debug output too noisy | restrict `debug` to detailed logs, keep `verbose` short |
| Performance regression | benchmark before/after with `scripts/benchmark_yaml_parse.do` |

---

## Next Steps

1. Approve this plan.
2. Implement Stage 1 skeletons.
3. Migrate helpers and update QA/docs.
