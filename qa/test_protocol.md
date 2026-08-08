# YAML QA Protocol

**Date:** 06Aug2026  
**Version:** 2.2  
**Total Tests:** 35 (the runner prints the authoritative per-run count in its summary)

## Purpose

**Bug-fix principle (adopted 2026-08-06, first applied to BUG-15/REG-17):**
every bug fixed in the package MUST be reproduced by a test wired into
`qa/run_tests.do` before the fix lands, and the bug counts as fixed only
when that test (a) demonstrably FAILS against the pre-fix build and
(b) passes against the fixed build. Where practical, encode the
counterfactual inside the test itself by materializing the pre-fix code
from git (see `test_bug15_counterfactual.do` / REG-17); otherwise run the
test once against the pre-fix tree and record the failing rc in the
commit message. A regression test that has never been seen to fail proves
nothing -- the suite's own history shows why: EX-01 asserted only on
return codes and passed for two major versions while `scalars()` wrote
nothing at all.



Ensure the `yaml` Stata module works correctly across all subcommands
(read/write/list/get/validate) and Phase 2 features (bulk/collapse/frame operations).

## Pre-Checks

1. Open Stata 14+ (16+ required for frame tests)
2. Set working directory to repo root:
   ```stata
   cd <repo-root>
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

This runs all 36 tests and writes logs to `qa/logs/run_tests.log`.

### Run Specific Test

```stata
do qa/run_tests.do FEAT-08
do qa/run_tests.do REG-05
```

### List Available Tests

```stata
do qa/run_tests.do list
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

- **34/36 tests pass** - every ENV, EX, REG, FEAT and CON test completes
  without error.
- **INT-02 and INT-03 are RED BY DESIGN** and are the only accepted
  failures. They compare this package against sibling repos on disk and
  stay red until those siblings re-vendor at the SSC release. Any *other*
  failure is a stop. Do not "fix" the suite by making these green.
- **No unexplained rc != 0** - the runner summary count is authoritative,
  and is reconciled against the declared roster in the listing block, so a
  test that silently stops running shows as a shortfall rather than as a
  smaller number of passes.
- **Log parseable** - `qa/logs/run_tests.log` carries line-initial `PASS:`
  / `FAIL:` / `SKIP:` watermarks plus the completion sentinel, so
  `stqa_scanlog` can re-derive the verdict independently of the runner own
  counters.

## Logging

| File | Purpose |
|------|---------|
| `qa/logs/run_tests.log` | Current run log (gitignored) |
| `qa/test_history.txt` | Append-only test history (maintainer-local; excluded from the public package) |
