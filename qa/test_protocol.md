# YAML QA Protocol

**Date:** 04Feb2026  
**Version:** 1.0

## Purpose

Ensure the `yaml` Stata module works correctly across read/write/list/get/validate
and new fast-read features.

## Pre-Checks

1. Open Stata 14+ (16+ for frames/cache).
2. Set working directory to repo root:
   - `cd C:/GitHub/myados/yaml-dev`
3. Ensure `src/y` is in the adopath:
   - `adopath ++ "./src/y"`

## Execution

Run the QA runner:

```
. do qa/run_tests.do
```

## Manual Checks

- Confirm `yaml read` parses `examples/data/test_config.yaml` without errors.
- Confirm `yaml get` returns expected attributes.
- Confirm `yaml list` returns keys and values.
- Confirm `yaml validate` flags missing keys.
- Confirm `fastread` returns row-wise output with variables: `key`, `field`, `value`, `list`, `line`.
- Confirm `cache()` returns `r(cache_hit) = 1` on second run.

## Expected Outputs

- `examples/test_yaml.do` completes without errors.
- `examples/test_yaml_improvements.do` passes list-item and truncation checks.
- `examples/yaml_basic_examples.do` runs end-to-end without failures.
- `qa/scripts/test_bug1_bug2.do` passes nested list and parent hierarchy checks.
- `qa/scripts/test_bug3_frame_returns.do` passes frame return propagation checks (Stata 16+).
- `qa/scripts/test_abbreviations.do` passes subcommand abbreviation checks.

## Logging

The QA runner writes logs to `qa/logs/run_tests.log`.
