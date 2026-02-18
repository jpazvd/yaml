# YAML QA Testing Guide

## Quick Run

From the repository root:

```
cd C:\GitHub\myados\yaml-dev

* In Stata:
. do qa/run_tests.do
```

## What It Runs

- `examples/test_yaml.do`
- `examples/test_yaml_improvements.do`
- `examples/yaml_basic_examples.do`
- `qa/scripts/test_bug1_bug2.do` (REG-01: nested lists / parent hierarchy)
- `qa/scripts/test_bug3_frame_returns.do` (REG-02: frame return propagation, Stata 16+)
- `qa/scripts/test_abbreviations.do` (REG-03: subcommand abbreviations)

## Logs

- Logs are written to `qa/logs/run_tests.log`.
- Logs are ignored from version control.

## Notes

- Frame-related tests require Stata 16+.
- Fast-scan examples expect `examples/data/indicators.yaml`.
