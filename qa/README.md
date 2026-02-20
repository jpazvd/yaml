# YAML QA Framework

This folder contains QA protocols and scripts for validating the `yaml` Stata module.

## Quick Reference

| Metric | Value |
|--------|-------|
| **Total Tests** | 22 |
| **Test Families** | ENV, EX, REG, FEAT |
| **Runner** | `qa/run_tests.do` |
| **Log file** | `qa/logs/run_tests.log` (gitignored) |
| **History** | `qa/test_history.txt` |

## Running Tests

### Full suite
```stata
cd C:\GitHub\myados\yaml-dev\qa
do run_tests.do
```

### Single test
```stata
do run_tests.do EX-01
```

### List available tests
```stata
do run_tests.do list
```

### Verbose mode
```stata
do run_tests.do verbose
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

### 3. Regression Tests (REG) - 8 tests
Targeted regression tests for specific bug fixes.

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

### 4. Feature Tests (FEAT) - 8 tests
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

## Directory Structure

| Directory | Contents |
|-----------|----------|
| `docs/` | QA documentation, checklists, and protocols |
| `fixtures/` | Test fixtures and sample YAML files |
| `legacy/` | Legacy QA artifacts kept for reference |
| `logs/` | Execution logs (gitignored) |
| `scripts/` | Test scripts (20 files) |

## Entry Points

| File | Purpose |
|------|---------|
| `run_tests.do` | Primary QA runner |
| `test_protocol.md` | Step-by-step QA protocol |
| `TESTING_GUIDE.md` | How to run QA locally |
| `test_history.txt` | Log of QA runs |
| `_define_helpers.do` | Helper programs |
| `_unpack_fixtures.do` | Fixture extraction |
