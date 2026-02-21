# Examples

This folder contains example scripts demonstrating the `yaml` command functionality.

## Files

| File | Description |
|------|-------------|
| `test_yaml.do` | Main example script - tests all 9 subcommands |
| `test_yaml_debug.do` | Debugging examples for `yaml get` and `yaml list` |
| `test_yaml_improvements.do` | Tests for truncation fix, validation, and list support |
| `test_yaml_unicef_integration.do` | Integration tests (requires unicefData package) |

## Subfolders

- **`data/`** - Sample YAML configuration files used by the examples
- **`logs/`** - Output logs from running examples (for reference)

## Running Examples

```stata
* Navigate to examples folder
cd "path/to/yaml/examples"

* Run main example
do test_yaml.do

* Or run with logging
log using "logs/test_yaml.log", replace
do test_yaml.do
log close
```

## Notes

- Examples use relative paths (`../src/y` for ado files, `data/` for YAML files)
- `test_yaml_unicef_integration.do` requires the full unicefData repository and won't run standalone
- Frame-related tests (17-24 in `test_yaml.do`) require Stata 16+
- Fast-scan examples are in `yaml_basic_examples.do` and `test_yaml.do`
