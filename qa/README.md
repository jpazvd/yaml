# YAML QA Framework

This folder contains QA protocols and scripts for validating the `yaml` Stata module.

## Quick Reference

| Metric | Value |
|--------|-------|
| **Total Tests** | 36 |
| **Test Families** | ENV (3), EX (3), REG (18), FEAT (9), INT (3) |
| **Runner** | `qa/run_tests.do` |
| **Log file** | `qa/logs/run_tests.log` (gitignored) |
| **History** | `qa/test_history.txt` |

## Running Tests

Run from the **repository root**, not from `qa/`. The runner takes `c(pwd)`
as the repo root and derives `qa/`, `src/y` and `src/_` from it, so a
different working directory points every one of those at a path that does
not exist. `adopath` then fails to pick up the working tree and `yaml`
resolves to whatever copy is already installed — the suite runs green
against code you did not change.

Nothing in the suite currently detects this. ENV-01 checks that a `yaml`
command is available, and one is: the installed one. That is why the
working directory matters more than it looks.

### Full suite
```stata
cd <repo-root>
do qa/run_tests.do
```

### Single test
```stata
do qa/run_tests.do EX-01
```

### List available tests
```stata
do qa/run_tests.do list
```

### Verbose mode
```stata
do qa/run_tests.do verbose
```

## Test Families

### 1. Environment (ENV) - 3 tests
Ensures the module is installed and discoverable.

| Test ID | Description |
|---------|-------------|
| ENV-01 | `yaml` command is available |
| ENV-02 | `yaml` help file is available |
| ENV-03 | Version header format matches pattern |

### 2. Example Smoke Tests (EX) - 3 tests
Runs example scripts to validate core workflows.

| Test ID | Description |
|---------|-------------|
| EX-01 | `examples/test_yaml.do` |
| EX-02 | `examples/test_yaml_improvements.do` |
| EX-03 | `examples/yaml_basic_examples.do` |

### 3. Regression Tests (REG) - 18 tests
Targeted regression tests for specific bug fixes. Every fixed bug gets a REG
test that fails before the fix and passes after, so a regression cannot pass
silently.

| Test ID | Description | Bug Ref |
|---------|-------------|---------|
| REG-01 | Nested lists and parent hierarchy | BUG-1/BUG-2 |
| REG-02 | Frame return value propagation (Stata 16+) | BUG-3 |
| REG-03 | Subcommand abbreviations (`desc`, `frame`, `check`) | - |
| REG-04 | Round-trip read/write produces valid YAML | BUG-4 |
| REG-05 | `yaml validate` type check matches correct row | BUG-5 |
| REG-06 | Fastread handles brackets/braces in values | BUG-6 |
| REG-07 | Early-exit does not double-close file handle | BUG-7 |
| REG-08 | `yaml list header` with parent filter | BUG-8 |
| REG-09 | Sibling parent_stack contamination | BUG-9 |
| REG-10 | Flush-dash sequences of mappings | BUG-10 |
| REG-11 | Consumer catalog corpus parses | BUG-10 |
| REG-12 | Consumer catalog round-trip fidelity | - |
| REG-13 | `yaml list` `stata` option compound quotes | BUG-11 |
| REG-14 | `yaml write, scalars()` emits scalars | BUG-12 |
| REG-15 | Generated harmonization do-file runs | BUG-13 |
| REG-16 | Quote characters in values parse | BUG-14 |
| REG-17 | Counterfactual: v2.0.0 fails, current passes | BUG-15 |
| REG-18 | RR suite: 16 checks (RR-01…RR-16) from v2.0.0 validation | v2.0.0 |

REG-17 is the pattern worth copying. It materialises the *previous* build from
git history, asserts the bug still reproduces against it, and only then asserts
the current tree is clean. A test that merely checks the fixed behaviour can
quietly degrade into one that would pass against the broken code too; this one
cannot.

### 4. Feature Tests (FEAT) - 9 tests
New feature validation for v1.6.0+ and Phase 2 (Mata parser).

| Test ID | Description | Version |
|---------|-------------|---------|
| FEAT-01 | Embedded double quotes via Mata `st_sstore` | v1.6.0 |
| FEAT-02 | Block scalar support in canonical parser | v1.6.0 |
| FEAT-03 | Continuation lines for multi-line scalars | v1.6.0 |
| FEAT-04 | `strL` option prevents value truncation | v1.6.0 |
| FEAT-05 | Mata bulk-load produces correct output | Phase 2 |
| FEAT-06 | `collapse` option produces wide-format output | Phase 2 |
| FEAT-07 | Performance comparison across parser modes | Phase 2 |
| FEAT-08 | Frame-based query operations (wbopendata-style) | Phase 2 |
| FEAT-09 | `colfields()` and `maxlevel()` collapse options | v1.8.0 |

#### FEAT-08 Sub-tests (15 sub-tests)
Validates frame caching and query patterns used by wbopendata/unicefData:

1. **Parse with bulk+collapse** - verify 8-indicator structure
2. **Frame cache operations** - put/get pattern
3. **Keyword search** - strpos-based matching
4. **Topic filter** - field-based filtering
5. **Cache hit timing** - performance vs re-parse
6. **Code pattern match** - regex on indicator codes
7. **Source filtering** - source_id field filter
8. **Multi-field search** - name AND description
9. **Exact code lookup** - direct code match
10. **List field parsing** - semicolon-delimited topic_ids
11. **Frame persistence** - survives `clear`
12. **Large file performance** - optional wbopendata fixture
13. **Regex wildcard `*`** - zero or more pattern
14. **Regex wildcard `+`** - one or more pattern
15. **Regex wildcard `.`** - single character pattern

### 5. Integration Tests (INT) - 3 tests
Cross-package integration with downstream consumers. These are skipped when the
sibling repos are absent from the machine.

**INT-02 and INT-03 are red by design** and are the only accepted failures: they
check sibling packages that have not yet re-aligned to v2.0.x, and stay red
until they do at the SSC release. Any *other* failure is a stop. Do not "fix"
the suite by making these two green.

| Test ID | Description |
|---------|-------------|
| INT-01 | unicefdata yaml → cache integration |
| INT-02 | wbopendata yaml → cache integration |
| INT-03 | Cross-package yaml.ado version sync |

## Directory Structure

| Directory | Contents |
|-----------|----------|
| `docs/` | QA documentation, checklists, and protocols |
| `fixtures/` | Test fixtures and sample YAML files |
| `legacy/` | Legacy QA artifacts kept for reference |
| `logs/` | Execution logs (gitignored) |
| `scripts/` | Test scripts (32 files) |
| `tmp/` | Scratch space written during a run (gitignored) |

## Entry Points

| File | Purpose |
|------|---------|
| `run_tests.do` | Primary QA runner |
| `test_protocol.md` | Step-by-step QA protocol |
| `TESTING_GUIDE.md` | How to run QA locally |
| `test_history.txt` | Append-only record of every QA run (see note) |
| `_define_helpers.do` | Helper programs |
| `_unpack_fixtures.do` | Fixture extraction |

### About `test_history.txt`

Each run appends a stanza recording the date, start and end time, duration,
branch, package version, Stata version, and the pass / fail / skip counts with
the ids of anything that failed. It is append-only: entries are never edited or
removed, so a run that went badly stays in the record.

In this published copy, branch names are shown as `(feature branch)` unless the
run was made on `main`, `dev` or `develop`. The redaction is an allow-list
applied at publication time — everything not explicitly permitted is replaced,
so no future branch name can reach this file by being overlooked. Nothing else
in the stanza is altered, and no run is omitted.
