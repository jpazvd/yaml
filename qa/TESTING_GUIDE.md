# YAML QA Testing Guide

## Quick Run

From the repository root:

```
cd C:\GitHub\myados\yaml-dev

* In Stata:
. do qa/run_tests.do
```

## What It Runs (22 Tests)

### Environment Checks (ENV)
- ENV-01: `yaml` command is available
- ENV-02: `yaml` help file is available
- ENV-03: Version header format

### Example Scripts (EX)
- `examples/test_yaml.do`
- `examples/test_yaml_improvements.do`
- `examples/yaml_basic_examples.do`

### Regression Tests (REG)
| Script | Test ID | Description |
|--------|---------|-------------|
| `test_bug1_bug2.do` | REG-01 | Nested lists / parent hierarchy |
| `test_bug3_frame_returns.do` | REG-02 | Frame return propagation (Stata 16+) |
| `test_abbreviations.do` | REG-03 | Subcommand abbreviations |
| `test_bug4_roundtrip.do` | REG-04 | Round-trip read/write |
| `test_bug5_validate_row.do` | REG-05 | Validate type check row match |
| `test_bug6_brackets.do` | REG-06 | Brackets/braces in values |
| `test_bug7_early_exit.do` | REG-07 | Early-exit file handle |
| `test_bug8_list_header.do` | REG-08 | List header with parent filter |

### Feature Tests (FEAT)
| Script | Test ID | Description |
|--------|---------|-------------|
| `test_double_quotes.do` | FEAT-01 | Embedded double quotes |
| `test_block_scalars.do` | FEAT-02 | Block scalar support |
| `test_continuation.do` | FEAT-03 | Continuation lines |
| `test_strl.do` | FEAT-04 | strL option for long values |
| `test_mata_bulk.do` | FEAT-05 | Mata bulk-load parsing |
| `test_collapse.do` | FEAT-06 | Collapse option (wide format) |
| `test_parser_performance.do` | FEAT-07 | Performance comparison |
| `test_frame_queries.do` | FEAT-08 | Frame-based query operations |

## Required Fixtures

Fixtures are extracted automatically from `qa/fixtures/fixtures.zip` on first run.

Key fixtures:
- `fixtures/indicators.yaml` - Test indicator metadata
- `fixtures/_wbopendata_indicators.yaml` - Large file performance (optional)

## Single Test Run

To run a specific test:

```stata
do run_tests.do FEAT-08
do run_tests.do REG-05
```

## Logs

- Logs are written to `qa/logs/run_tests.log`
- Logs are gitignored
- Test history appended to `qa/test_history.txt`

## Requirements

| Requirement | Notes |
|-------------|-------|
| Stata 14+ | Minimum for core tests |
| Stata 16+ | Required for frame-related tests (REG-02, FEAT-05-08) |
| Mata | Required for Phase 2 tests |

## Verbose Mode

For detailed trace output:

```stata
do run_tests.do verbose
```
