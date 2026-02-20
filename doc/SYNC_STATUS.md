# yaml.ado -- Cross-Repo Sync Status

> Generated: 2026-02-17
> Purpose: Track feature parity across the canonical repo and its consumers.

---

## 1. Repo Inventory

| Repo | Path | Version | Structure |
|------|------|---------|-----------|
| **Canonical** | `myados\yaml-dev\src\y\` | v1.5.0 (04Feb2026) | Modular -- 13 separate .ado files |
| **wbopendata-dev** | `myados\wbopendata-dev\src\y\` | v1.3.1 (17Dec2025) | Monolithic -- 1 file, 1673 lines |
| **unicefData-dev** | `myados\unicefData-dev\stata\src\y\` | v1.3.1 (17Dec2025) | Monolithic -- 1 file, 1691 lines |

---

## 2. Feature Matrix

### 2.1 Features in Canonical Only (v1.5.0)

These are **not available** in wbopendata-dev or unicefData-dev.

| Feature | Option/File | Description |
|---------|-------------|-------------|
| fastread mode | `fastread` | Speed-first parser for large, regular YAML |
| Streaming tokenization | `stream`, `_yaml_tokenize_line.ado` | Line-by-line tokenizer |
| Index frames | `index()` | Sorted lookup frame for faster `yaml_get` |
| Cache support | `cache()` | File-checksum cache with hit detection |
| Targets / early-exit | `targets()`, `earlyexit` | Stop parsing once target keys found |
| Fields filter | `fields()` | Keep only specified keys after parse |
| List-keys extraction | `listkeys()` | Extract list blocks (fastread only) |
| Block scalars | `blockscalars` | Capture block scalars in fastread |
| Empty-file check | -- | Validates file is non-empty before parsing |
| Option-combo validation | -- | Rejects incompatible option combinations |

### 2.2 Features in Consumer Repos Only (v1.3.1)

These are present in wbopendata-dev and/or unicefData-dev but **missing from canonical**.

| Feature | wbopendata | unicefData | Canonical |
|---------|:----------:|:----------:|:---------:|
| `desc` abbreviation for `describe` | Yes | Yes | Yes (v1.5.1) |
| `frame` abbreviation for `frames` | Yes | Yes | Yes (v1.5.1) |
| `check` abbreviation for `validate` | Yes | Yes | Yes (v1.5.1) |
| Error message lists valid subcommands | Yes | Yes | Yes (v1.5.1) |
| Separate empty-subcommand handler | Yes | Yes | Yes (v1.5.1) |
| EXAMPLES / SEE ALSO in header comments | Yes | Yes | **No** |
| `_yaml_pop_parents` helper (monolithic) | Yes | Yes | Separate file |

### 2.3 unicefData-Only Fixes (not in wbopendata or canonical)

| Fix | Description |
|-----|-------------|
| Frame return-value propagation in `yaml_get` | Captures `r()` inside frame block, restores outside. `return add` alone does not work across frame boundaries. |
| Frame return-value propagation in `yaml_list` | Same pattern as `yaml_get`. |

---

## 3. Bugs in Canonical v1.5.0 (all fixed in v1.5.1)

### BUG-1: Missing `last_key` assignment for leaf keys (`yaml_read.ado`)

**Location:** `yaml_read.ado`, inside the key-value else branch (~line 546).

**Problem:** `last_key` is only set when `vtype == "parent"` (empty value). For leaf
key-value pairs (string, numeric, boolean, null), `last_key` is never updated. This
means list items (`- item`) that follow a leaf key will be indexed under the wrong parent.

**Fix (from consumer repos):** Add after the type-detection block:
```stata
local last_key "`full_key'"
```

### BUG-2: Missing `parent_stack` update for parent keys (`yaml_read.ado`)

**Location:** `yaml_read.ado`, after the frame/dataset store block.

**Problem:** After storing a key with `vtype == "parent"`, the consumer repos update:
```stata
if ("`vtype'" == "parent") {
    local parent_stack "`full_key'"
}
```
This is absent from canonical, so nested structure tracking is broken -- children at
deeper indent levels will have incorrect parent references.

### BUG-3: `return add` in frame context (`yaml_get.ado`, `yaml_list.ado`)

**Location:** `yaml_get.ado:72`, `yaml_list.ado:40`.

**Problem:** `return add` after a `frame ... { }` block does not propagate `r()` values
set inside the block. Stata clears return values when exiting the frame context.

**Fix (from unicefData v1.3.1):** Capture return values to locals inside the frame block,
then restore them outside:
```stata
frame `frame' {
    _yaml_get_impl ...
    local _found = r(found)
    local _n_attrs = r(n_attrs)
    local _return_names : r(macros)
    foreach _rn of local _return_names {
        local _rv_`_rn' `"`r(`_rn')'"'
    }
}
return scalar found = `_found'
return scalar n_attrs = `_n_attrs'
foreach _rn of local _return_names {
    if (!inlist("`_rn'", "found", "n_attrs")) {
        return local `_rn' `"`_rv_`_rn''"'
    }
}
```

---

## 4. Fastscan Adoption Status

| Repo | Uses fastread? | Notes |
|------|:--------------:|-------|
| Canonical | Defined | Full implementation in `_yaml_fastread.ado` |
| wbopendata-dev | **No** | Bundles v1.3.1 without fastread |
| unicefData-dev | **No** | Bundles v1.3.1 without fastread |

**Action needed:** Update consumer repos to use canonical yaml.ado (modular) and
adopt `fastread` where applicable (e.g., large indicator catalogs).

---

## 5. Recommended Actions

### Priority 1: Fix canonical bugs -- DONE (v1.5.1, 18Feb2026)

1. ~~Fix BUG-1 (`last_key` for leaf keys in `yaml_read.ado`)~~ -- Fixed
2. ~~Fix BUG-2 (`parent_stack` update in `yaml_read.ado`)~~ -- Fixed
3. ~~Fix BUG-3 (`return add` in frame context in `yaml_get.ado` and `yaml_list.ado`)~~ -- Fixed

### Priority 2: Add missing features to canonical -- DONE (v1.5.1, 18Feb2026)

4. ~~Add subcommand abbreviations (`desc`, `frame`, `check`) to `yaml.ado` dispatcher~~ -- Added
5. ~~Add helpful error messages listing valid subcommands~~ -- Added

### Priority 3: Sync consumer repos

6. Update wbopendata-dev to use canonical v1.5.1
7. Update unicefData-dev to use canonical v1.5.1
8. Adopt `fastread` in consumer repos for large YAML files

### Priority 4: Testing -- DONE (v1.5.1, 18Feb2026)

9. ~~Add regression tests for frame return-value propagation~~ -- REG-02
10. ~~Add regression tests for nested YAML structure parsing~~ -- REG-01
11. Benchmark fastread vs canonical in consumer-repo contexts

---

## 6. File Inventory -- Canonical Repo

```
yaml\src\
  y\
    yaml.ado              Main dispatcher (v1.5.0)
    yaml_read.ado         Read/parse YAML files
    yaml_write.ado        Write Stata data to YAML
    yaml_describe.ado     Display YAML structure
    yaml_get.ado          Get attributes for a key
    yaml_list.ado         List keys/values
    yaml_validate.ado     Validate YAML data
    yaml_dir.ado          List all YAML data in memory
    yaml_frames.ado       List YAML frames
    yaml_clear.ado        Clear YAML data
    yaml.sthlp            Help file
    yaml_whatsnew.sthlp    What's new
  _\
    _yaml_fastread.ado    Fast-scan parser
    _yaml_tokenize_line.ado  Streaming tokenizer
    _yaml_pop_parents.ado    Indent/parent stack helper
```
