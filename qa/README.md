# YAML QA Framework

This folder contains QA protocols and scripts for validating the `yaml` Stata module.

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
- `test_history.txt`: Log of QA runs (manual)
