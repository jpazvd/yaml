# yaml: Stata module for YAML file processing

[![Stata Version](https://img.shields.io/badge/Stata-14%2B-blue)](https://www.stata.com/)
[![YAML 1.2](https://img.shields.io/badge/YAML-1.2-orange)](https://yaml.org/spec/1.2.2/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Description

`yaml` is a Stata command for reading, writing, and manipulating YAML configuration files. It provides a unified interface with nine subcommands that enable Stata users to integrate YAML-based workflows into their data pipelines.

The command implements the **JSON Schema** subset of [YAML 1.2](https://yaml.org/spec/1.2.2/) (3rd Edition, 2021), the current authoritative YAML standard. This JSON-compatible subset covers the most commonly used features for configuration files and metadata management. It is implemented in pure Stata with no external dependencies.

**Latest:** v1.5.0 with canonical early-exit targets, streaming tokenization, index frames, and improved fast-scan support.

### Key Features

- **Read YAML files** into Stata's data structure or frames
- **Write YAML files** from Stata datasets or scalars
- **Query values** using hierarchical key paths
- **Validate configurations** with required keys and type checking
- **Multiple frame support** (Stata 16+) for managing multiple configurations
- **Fast-scan mode** for large metadata catalogs (opt-in)
- **Field-selective extraction** with `fields()`
- **List block extraction** with `listkeys()` (fast-scan)
- **Frame caching** with `cache()` (Stata 16+)

## Installation

### From SSC (when available)

```stata
ssc install yaml
```

### Manual Installation

Copy `yaml.ado` and `yaml.sthlp` from `src/y/` to your personal ado directory:

```stata
adopath
* Copy files to the PERSONAL directory shown
```

## Quick Start

```stata
* Read a YAML configuration file
yaml read using config.yaml, replace

* View the structure
yaml describe

* Get a specific value
yaml get database:host
return list

* Validate required keys
yaml validate, required(name version database)

* Write modified configuration
yaml write using output.yaml, replace

* Speed-first metadata read (fastscan)
yaml read using indicators.yaml, fastscan fields(name description source_id topic_ids) ///
    listkeys(topic_ids topic_names) cache(ind_cache)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              yaml.ado                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────┐    ┌─────────┐    ┌──────────┐                               │
│   │  read   │    │  write  │    │ describe │                               │
│   └────┬────┘    └────┬────┘    └────┬─────┘                               │
│        │              │              │                                       │
│   ┌────┴────┐    ┌────┴────┐    ┌────┴─────┐                               │
│   │  list   │    │   get   │    │ validate │                               │
│   └────┬────┘    └────┬────┘    └────┬─────┘                               │
│        │              │              │                                       │
│   ┌────┴────┐    ┌────┴────┐    ┌────┴─────┐                               │
│   │   dir   │    │  frames │    │  clear   │                               │
│   └─────────┘    └─────────┘    └──────────┘                               │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                         Internal Storage                                     │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Dataset/Frame Structure:                                          │     │
│  │  ┌──────────┬────────────┬───────┬────────────┬──────────┐        │     │
│  │  │   key    │   value    │ level │   parent   │   type   │        │     │
│  │  ├──────────┼────────────┼───────┼────────────┼──────────┤        │     │
│  │  │ str244   │ str2000    │ int   │ str244     │ str32    │        │     │
│  │  └──────────┴────────────┴───────┴────────────┴──────────┘        │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `yaml read` | Parse YAML file into Stata dataset or frame |
| `yaml write` | Export Stata data to YAML format |
| `yaml describe` | Display structure summary of loaded YAML |
| `yaml list` | List keys, values, or children |
| `yaml get` | Retrieve specific key values |
| `yaml validate` | Check required keys and value types |
| `yaml dir` | List all YAML data in memory (dataset and frames) |
| `yaml frames` | List only YAML frames in memory (Stata 16+) |
| `yaml clear` | Clear YAML data from memory or frames |

## Syntax

### yaml read

```stata
yaml read using filename.yaml [, options]
```

**Options:**
- `replace` - Replace existing data
- `frame(name)` - Load into named frame (Stata 16+)
- `locals` - Store values as return locals
- `scalars` - Store numeric values as scalars
- `prefix(string)` - Prefix for local/scalar names (default: `yaml_`)
- `verbose` - Display parsing details
- `fastscan` - Speed-first parsing for large, regular YAML
- `fields(string)` - Restrict extraction to specific keys
- `listkeys(string)` - Extract list blocks for specified keys (fastscan only)
- `blockscalars` - Capture block scalars in fast-scan mode
- `targets(string)` - Early-exit targets for canonical parse (exact keys)
- `earlyexit` - Stop parsing once all targets are found (canonical)
- `stream` - Use streaming tokenization for canonical parse
- `index(string)` - Materialize an index frame for repeated queries (Stata 16+)
- `cache(string)` - Cache parsed results in a frame (Stata 16+)

## What's New

See [src/y/yaml_whatsnew.sthlp](src/y/yaml_whatsnew.sthlp) for version history and release notes.

### yaml write

```stata
yaml write using filename.yaml [, options]
```

**Options:**
- `replace` - Overwrite existing file
- `frame(name)` - Write from named frame
- `scalars(list)` - Write specified scalars
- `indent(#)` - Indentation spaces (default: 2)
- `header(string)` - Custom header comment
- `verbose` - Display write progress

### yaml get

```stata
yaml get keyname [, options]
yaml get parent:child [, options]
```

**Options:**
- `frame(name)` - Read from named frame
- `attributes(list)` - Specific attributes to retrieve
- `quiet` - Suppress output

**Returns:**
- `r(found)` - 1 if key found
- `r(n_attrs)` - Number of attributes
- `r(key)` - Key name
- `r(parent)` - Parent name (if colon syntax used)
- `r(attr_name)` - Value for each attribute

### yaml list

```stata
yaml list [keyname] [, options]
```

**Options:**
- `keys` - Show key names
- `values` - Show values
- `children` - List child keys only
- `level(#)` - Filter by nesting level
- `frame(name)` - Read from named frame

### yaml validate

```stata
yaml validate [, options]
```

**Options:**
- `required(keylist)` - Check that keys exist
- `types(key:type ...)` - Validate key types
- `frame(name)` - Validate named frame
- `quiet` - Suppress output, only set return values

**Returns:**
- `r(valid)` - 1 if validation passed
- `r(n_errors)` - Number of errors
- `r(n_warnings)` - Number of warnings
- `r(missing_keys)` - List of missing required keys
- `r(type_errors)` - List of type validation failures

### yaml describe

```stata
yaml describe [, level(#) frame(name)]
```

### yaml dir

```stata
yaml dir [, detail]
```

Lists all YAML data currently in memory:
- **Current dataset** - if it contains YAML structure (key, value, level, parent, type variables)
- **YAML frames** - all frames with `yaml_` prefix (Stata 16+)

**Options:**
- `detail` - Show number of entries and source file for each

**Detection:**
- YAML data is identified by the `_dta[yaml_source]` characteristic set by `yaml read`
- Datasets with YAML structure but unknown source are also reported

### yaml frames

```stata
yaml frames [, detail]
```

Lists only YAML frames in memory. Requires Stata 16+.

**Options:**
- `detail` - Show number of entries and source file for each frame

**Use case:** When you only need to see frames, not the current dataset.

### yaml clear

```stata
yaml clear [, all frame(name)]
```

## Data Model

### Storage Structure

YAML data is stored in a flat dataset with hierarchical references:

| Column | Type | Description |
|--------|------|-------------|
| `key` | str244 | Full hierarchical key name (e.g., `indicators_CME_MRY0T4_label`) |
| `value` | str2000 | The value associated with the key |
| `level` | int | Nesting depth (0 = root level) |
| `parent` | str244 | Parent key for hierarchical lookups |
| `type` | str32 | Value type: `string`, `numeric`, `boolean`, `parent`, `list_item`, `null` |

### Fast-Scan Output Schema

In `fastscan` mode, the output is row-wise and minimal:

| Column | Type | Description |
|--------|------|-------------|
| `key` | str244 | Top-level key (e.g., indicator code) |
| `field` | str244 | Field name under the key |
| `value` | str2000 | Field value |
| `list` | byte | 1 if list item, 0 otherwise |
| `line` | long | Line number in the YAML file |

### Key Naming Convention

Keys are flattened using underscores to represent hierarchy:

```yaml
# YAML input:
indicators:
  CME_MRY0T4:
    label: Under-five mortality rate
    unit: Deaths per 1000 live births
```

```
# Stored as:
key                              value                         parent                  type
─────────────────────────────────────────────────────────────────────────────────────────────
indicators                       (empty)                       (empty)                 parent
indicators_CME_MRY0T4            (empty)                       indicators              parent
indicators_CME_MRY0T4_label      Under-five mortality rate     indicators_CME_MRY0T4   string
indicators_CME_MRY0T4_unit       Deaths per 1000 live births   indicators_CME_MRY0T4   string
```

### List Item Storage

YAML lists are stored as indexed separate rows:

```yaml
# YAML input:
countries:
  - BRA
  - ARG
  - CHL
```

```
# Stored as:
key             value   parent      type
────────────────────────────────────────────
countries       (empty) (empty)     parent
countries_1     BRA     countries   list_item
countries_2     ARG     countries   list_item
countries_3     CHL     countries   list_item
```

## YAML 1.2 Compliance

This command implements the **JSON Schema** subset of YAML 1.2 as defined in [Chapter 10.2](https://yaml.org/spec/1.2.2/#json-schema) of the YAML 1.2 Specification. This is the recommended schema for "interoperability and consistency" according to the specification.

### ✅ Supported (YAML 1.2 JSON Schema)

| Feature | YAML 1.2 Reference | Example |
|---------|-------------------|---------|
| Mappings | [Chapter 8.2.1](https://yaml.org/spec/1.2.2/#821-block-mappings) | `key: value` |
| Nested mappings | [Chapter 8.2](https://yaml.org/spec/1.2.2/#82-block-collection-styles) | Indentation-based hierarchy |
| Block sequences | [Chapter 8.2.2](https://yaml.org/spec/1.2.2/#822-block-sequences) | `- item1`, `- item2` |
| Comments | [Chapter 6.5](https://yaml.org/spec/1.2.2/#65-comment-indicator) | `# This is a comment` |
| Strings | [Chapter 10.2.1.1](https://yaml.org/spec/1.2.2/#null-1) | `name: "quoted"` or `name: unquoted` |
| Integers | [Chapter 10.2.1.2](https://yaml.org/spec/1.2.2/#integer) | `count: 100` |
| Floats | [Chapter 10.2.1.3](https://yaml.org/spec/1.2.2/#floating-point) | `rate: 3.14` |
| Booleans | [Chapter 10.2.1.4](https://yaml.org/spec/1.2.2/#boolean) | `debug: true`, `verbose: false` |
| Null | [Chapter 10.2.1.1](https://yaml.org/spec/1.2.2/#null-1) | `empty:` or `empty: null` |

### ❌ Not Supported (Advanced YAML 1.2)

These features are part of the full YAML 1.2 specification but are intentionally excluded to maintain simplicity and robustness:

| Feature | YAML 1.2 Reference | Reason |
|---------|-------------------|--------|
| Anchors & Aliases | [Chapter 7.1](https://yaml.org/spec/1.2.2/#71-alias-nodes) | `&anchor`, `*alias` - Complex reference handling |
| Block scalars | [Chapter 8.1](https://yaml.org/spec/1.2.2/#81-block-scalar-styles) | `\|`, `>` - Multi-line literal/folded styles |
| Flow collections | [Chapter 7.4](https://yaml.org/spec/1.2.2/#74-flow-collection-styles) | `{a: 1}`, `[1, 2]` - JSON-like inline syntax |
| Tags | [Chapter 6.9](https://yaml.org/spec/1.2.2/#69-tag) | `!!map`, `!!seq` - Type annotations |
| Multiple documents | [Chapter 9.2](https://yaml.org/spec/1.2.2/#92-streams) | `---` document separators |

## Version Requirements

| Feature | Minimum Version |
|---------|-----------------|
| Basic functionality | Stata 14.0 |
| Frame support | Stata 16.0 |

## Examples

### Reading and Querying

```stata
* Load configuration
yaml read using pipeline_config.yaml, replace

* Get nested value using colon syntax
yaml get database:connection_string
local conn = r(connection_string)

* List all keys at root level
yaml list, keys level(0)
```

### Validation

```stata
* Check required configuration keys
yaml validate, required(name version api_key)

* Validate with type checking
yaml validate, types(port:numeric debug:boolean)

if (r(valid) == 0) {
    di as error "Invalid configuration"
    exit 198
}
```

### Working with Frames (Stata 16+)

```stata
* Load multiple configurations
yaml read using dev.yaml, frame(dev)
yaml read using prod.yaml, frame(prod)

* Query from specific frame
yaml get host, frame(prod)

* List all YAML data in memory
yaml dir, detail

* Clear specific frame
yaml clear, frame(dev)
```

### Round-trip: Read and Write

```stata
* Read configuration
yaml read using original.yaml, replace

* Modify values
replace value = "new_value" if key == "settings_timeout"

* Write back
yaml write using modified.yaml, replace
```

### Working with Lists

```stata
* Read YAML with lists
yaml read using countries.yaml, replace

* List items in a list
yaml list countries, keys children

* Access individual list items
yaml get countries
* Returns: r(1)="BRA" r(2)="ARG" r(3)="CHL"
```

## Performance Optimization for Large Catalogs

For metadata catalogs with 700+ entries, **vectorized frame-based queries** dramatically outperform iterative `yaml get` calls:

| Approach | Time | Relative |
|----------|------|----------|
| Naive: 733 iterative `yaml get` calls | 15+ seconds | 50× |
| **Optimized: Direct frame dataset query** | **0.3 seconds** | **1×** |

**Key Pattern** (see paper Section 5.2):
```stata
yaml read using indicators_catalog.yaml, frame(meta)
frame yaml_meta {
    gen is_nutrition = (value == "NUTRITION") & ///
        regexm(key, "^indicators_[A-Za-z0-9_]+_dataflow$")
    levelsof indicator_code if is_nutrition == 1, local(nutrition_codes)
}
```

Vectorized operations (gen, regexm, levelsof) process all rows at once rather than looping through function calls. Frame isolation provides data protection and instant cleanup. See production examples in `src/y/README.md`.

## Use Cases

- **Pipeline Configuration**: Database connections, API endpoints, timeouts
- **Metadata Management**: Indicator definitions, variable labels, units (optimized for 700+ catalogs)
- **Cross-language Workflows**: Share configurations with R, Python, GitHub Actions
- **Reproducible Research**: Version-controlled configuration files
- **Multi-environment Support**: Dev/staging/prod configurations in separate frames
- **LLM Workflows**: YAML-based tool interfaces and pipeline orchestration

## Design Principles

1. **YAML 1.2 Compliance**: Implements the JSON Schema (Chapter 10.2) of the [YAML 1.2 Specification](https://yaml.org/spec/1.2.2/), which covers 95%+ of configuration use cases.

2. **JSON Compatibility**: Per YAML 1.2's design goal, the supported subset ensures that valid JSON is also valid YAML (Chapter 1.2 of the specification).

3. **Stata-Native**: Pure Stata implementation using `file read/write` - no external dependencies (Python, LibYAML, etc.).

4. **Hierarchical Storage**: Flat storage with parent references enables both simple key-value access and hierarchical queries, following the YAML representation model (Chapter 3.2.1).

5. **Frame Support**: Optional frame storage keeps YAML data separate from working datasets (Stata 16+).

6. **Validation First**: Built-in validation ensures configuration correctness before pipeline execution.

## Repository Structure

```
yaml/
├── README.md              # This file
├── .gitignore
├── src/y/
│   ├── yaml.ado           # Main command (v1.3.1)
│   ├── yaml.sthlp         # Stata help file
│   └── README.md          # Command documentation with production examples
├── examples/              # Examples and test files
│   ├── README.md
│   ├── yaml_sj_article_examples.do   # Stata Journal article examples
│   ├── yaml_basic_examples.do        # Basic usage examples
│   ├── data/              # Sample YAML files
│   └── logs/              # Output logs from examples
└── paper/submission/
    └── latex/
        ├── main-v2.tex         # LaTeX driver (original version, 19 pages)
        ├── main-v3.tex         # LaTeX driver (current with optimization, 21 pages)
        ├── yamlstata-v2.tex    # Article content (original)
        ├── yamlstata-v3.tex    # Article content (Section 5.2: large catalog optimization)
        ├── sj.bib              # Bibliography
        ├── figures/
        │   ├── yaml_layers_bw.tex    # TikZ source for architecture diagram
        │   └── yaml_layers_bw.pdf    # Compiled architecture diagram (36 KB)
        └── [support files]
```

## Suggested Citation

**For the Stata command:**

Azevedo, João Pedro. 2025. "yaml: Stata module for YAML file processing." 
Statistical Software Components, Boston College Department of Economics.

**For the Stata Journal article:**

Azevedo, João Pedro. 2025. "Reading and writing YAML files in Stata: A lightweight framework for reproducible and cross-platform analytics." *The Stata Journal*, v3 (forthcoming). See `paper/submission/latex/main-v3.tex` for current version.

## Author

**João Pedro Azevedo**  
[jpazevedo@unicef.org](mailto:jpazevedo@unicef.org)  
UNICEF  

## References

- **YAML 1.2 Specification**: Ben-Kiki, O., Evans, C., & döt Net, I. (2021). *YAML Ain't Markup Language (YAML™) Version 1.2* (Revision 1.2.2). https://yaml.org/spec/1.2.2/
- **JSON Schema**: YAML 1.2 Specification, Chapter 10.2. https://yaml.org/spec/1.2.2/#json-schema
- **YAML Official Site**: https://yaml.org/

## License

MIT License
