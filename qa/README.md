# YAML QA Framework

This folder contains QA protocols and scripts for validating the `yaml` Stata module.

## Quick Reference

| Metric | Value |
|--------|-------|
| **Test Families** | ENV, EX |
| **Runner** | `qa/run_tests.do` |
| **Log file** | `qa/logs/run_tests.log` (gitignored) |
| **History** | `qa/test_history.txt` |

## Running Tests

### Full suite
```stata
cd C:\GitHub\myados\yaml\qa
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

### 1. Environment (ENV)
Ensures the module is installed and discoverable.

- **ENV-01**: `yaml` command is available
- **ENV-02**: help file exists
- **ENV-03**: version header format

### 2. Example smoke tests (EX)
Runs example scripts to validate core workflows.

- **EX-01**: `examples/test_yaml.do`
- **EX-02**: `examples/test_yaml_improvements.do`
- **EX-03**: `examples/yaml_basic_examples.do`

## Categories (aligned with unicefData + wbopendata)

- **docs/**: QA documentation, checklists, and protocols
- **fixtures/**: Test fixtures and sample YAML files used by QA scripts
- **legacy/**: Legacy QA artifacts kept for reference
- **logs/**: Execution logs (ignored in git)
- **scripts/**: Helper utilities and QA runners

## Entry points

- `run_tests.do`: Primary QA runner
- `test_protocol.md`: Step-by-step QA protocol
- `TESTING_GUIDE.md`: How to run QA locally
- `test_history.txt`: Log of QA runs
