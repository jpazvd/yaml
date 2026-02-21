# YAML QA Protocol

**Date:** 21Feb2026  
**Version:** 2.1  
**Total Tests:** 26

## Purpose

Ensure the `yaml` Stata module works correctly across all subcommands
(read/write/list/get/validate) and Phase 2 features (bulk/collapse/frame operations).

## Pre-Checks

1. Open Stata 14+ (16+ required for frame tests)
2. Set working directory to repo root:
   ```stata
   cd C:/GitHub/myados/yaml-dev
   ```
3. Ensure adopath includes dev source:
   ```stata
   adopath ++ "./src/y"
   adopath ++ "./src/_"
   ```

## Automated Execution (Recommended)

Run the QA runner:

```stata
do qa/run_tests.do
```

This runs all 26 tests and writes logs to `qa/logs/run_tests.log`.

### Run Specific Test

```stata
do run_tests.do FEAT-08
do run_tests.do REG-05
```

### List Available Tests

```stata
do run_tests.do list
```

## Test Coverage

### Environment (ENV) - 3 tests
| Test | Description | Pass Criteria |
|------|-------------|---------------|
| ENV-01 | `yaml` command available | `which yaml` returns path |
| ENV-02 | Help file available | `help yaml` succeeds |
| ENV-03 | Version header format | Matches `*! v[0-9]+.[0-9]+.[0-9]+` |

### Example Scripts (EX) - 3 tests
| Test | Script | Pass Criteria |
|------|--------|---------------|
| EX-01 | `test_yaml.do` | Runs without error |
| EX-02 | `test_yaml_improvements.do` | Runs without error |
| EX-03 | `yaml_basic_examples.do` | Runs without error |

### Regression (REG) - 8 tests
| Test | Bug | Pass Criteria |
|------|-----|---------------|
| REG-01 | BUG-1/2 | Nested lists preserve hierarchy |
| REG-02 | BUG-3 | Frame returns populated (Stata 16+) |
| REG-03 | - | Abbreviations `desc`, `frame`, `check` work |
| REG-04 | BUG-4 | Round-trip produces valid YAML |
| REG-05 | BUG-5 | Validate matches correct row |
| REG-06 | BUG-6 | Brackets/braces preserved in values |
| REG-07 | BUG-7 | Early-exit doesn't double-close handle |
| REG-08 | BUG-8 | List header respects parent filter |

### Feature (FEAT) - 9 tests
| Test | Feature | Pass Criteria |
|------|---------|---------------|
| FEAT-01 | Double quotes | Mata `st_sstore` handles embedded quotes |
| FEAT-02 | Block scalars | `|` and `>` scalars parsed correctly |
| FEAT-03 | Continuation | Multi-line scalars preserved |
| FEAT-04 | strL | Long values not truncated at 2045 chars |
| FEAT-05 | Mata bulk | Bulk parser matches canonical output |
| FEAT-06 | Collapse | Wide-format output correct |
| FEAT-07 | Performance | All parser modes complete within thresholds |
| FEAT-08 | Frame queries | wbopendata-style operations work |
| FEAT-09 | Collapse filters | colfields() and maxlevel() options work |

### Integration (INT) - 3 tests
| Test | Scope | Pass Criteria |
|------|-------|---------------|
| INT-01 | unicefdata | yaml → cache → lookup pipeline works |
| INT-02 | wbopendata | yaml → cache → lookup pipeline works |
| INT-03 | Version sync | yaml.ado versions match across packages |

### FEAT-08 Sub-tests (15 operations)
1. Parse with bulk+collapse
2. Frame cache put/get
3. Keyword search (strpos)
4. Topic filter
5. Cache hit timing
6. Code pattern match (regex)
7. Source filtering
8. Multi-field search
9. Exact code lookup
10. List field parsing (semicolon-delimited)
11. Frame persistence after `clear`
12. Large file performance (optional)
13. Regex wildcard `*` (zero or more)
14. Regex wildcard `+` (one or more)
15. Regex wildcard `.` (single char)

## Manual Checks (if needed)

Only if automated tests fail or for exploratory validation:

| Check | Command | Expected |
|-------|---------|----------|
| Read | `yaml read using "fixtures/test.yaml", replace` | Loads without error |
| Get | `yaml get attr using "fixtures/test.yaml"` | Returns expected value |
| List | `yaml list using "fixtures/test.yaml"` | Shows keys/values |
| Validate | `yaml validate using "fixtures/test.yaml", schema(...)` | Flags missing keys |
| Fastread | `yaml read using "...", fastread` | Returns `key field value list line` |
| Cache | `yaml read using "...", cache()` | Second run returns `r(cache_hit)=1` |
| Bulk | `yaml read using "...", bulk` | Mata-based parsing succeeds |
| Collapse | `_yaml_collapse` after bulk | Wide-format rows correct |

## Success Criteria

- **26/26 tests pass** - All ENV, EX, REG, FEAT, INT tests complete without error
- **No rc != 0** - Automated runner reports zero failures
- **Log clean** - `qa/logs/run_tests.log` shows all PASS

## Logging

| File | Purpose |
|------|---------|
| `qa/logs/run_tests.log` | Current run log (gitignored) |
| `qa/test_history.txt` | Append-only test history |
