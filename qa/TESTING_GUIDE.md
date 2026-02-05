# YAML QA Testing Guide

## Quick Run

From the repository root:

```
cd C:\GitHub\myados\yaml

* In Stata:
. do qa/run_tests.do
```

## What It Runs

- `examples/test_yaml.do`
- `examples/test_yaml_improvements.do`
- `examples/yaml_basic_examples.do`

## Logs

- Logs are written to `qa/logs/run_tests.log`.
- Logs are ignored from version control.

## Notes

- Frame-related tests require Stata 16+.
- Fast-scan examples expect `examples/data/indicators.yaml`.
