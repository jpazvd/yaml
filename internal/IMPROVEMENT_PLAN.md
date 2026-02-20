# YAML Improvement Plan

**Date:** 20Feb2026
**Owner:** Joao Pedro Azevedo
**Status:** Phase 2 complete; Phase 3 (downstream integration) in progress
**Current Version:** v1.7.0
**Scope:** Bug fixes, consistency issues, performance enhancements, and downstream package integration

---

## 1. Summary

This plan tracks the evolution of the `yaml` package from v1.5.1 bug fixes through
v1.7.0 Phase 2 performance features, and plans for Phase 3 integration with
downstream packages (`wbopendata` and `unicefdata`).

**Completed:**
- Phase 1: v1.5.1 bug fixes and consistency (8 bugs, 7 consistency fixes)
- Phase 2: v1.7.0 Mata bulk parser, collapse mode, strL support

**In Progress:**
- Phase 3 (wbopendata): yaml v1.7.0 bundled; custom indicators parser retained due to collapse limitations
- Phase 3 (unicefdata): Planned (next step)

---

## 2. Phase 2 Features (v1.6.0–v1.7.0) — COMPLETE

### FEAT-1: Mata Bulk-Load Parser

**Status:** Done (v1.6.0, `635264f`)
**File:** `src/_/_yaml_mataread.ado`

**Summary:** New `mataread` parser option that uses `st_sstore()` for vectorized
row insertion. Bypasses macro expansion issues with embedded quotes and provides
10–50× faster parsing for large files.

**Usage:**
```stata
yaml read "file.yaml", clear parser(mataread)
```

---

### FEAT-2: Collapse Post-Processor

**Status:** Done (v1.7.0, `b261088`)
**File:** `src/_/_yaml_collapse.ado`

**Summary:** New `collapse` option that flattens hierarchical YAML to one-row-
per-top-level-key format. Fields become columns. Designed for indicator catalogs.

**Usage:**
```stata
yaml read "indicators.yaml", clear collapse
```

**Output:** Instead of key-value pairs, produces a wide dataset where each
top-level key becomes a row and nested fields become variables.

---

### FEAT-3: strL Support

**Status:** Done (v1.6.0, `635264f`)
**Files:** `src/_/_yaml_mataread.ado`, `src/_/_yaml_collapse.ado`

**Summary:** All value storage uses `strL` type to handle multi-kilobyte text
fields (descriptions, notes) without truncation.

---

### FEAT-4: Block Scalars and Continuation Lines

**Status:** Done (v1.6.0, `635264f`)
**File:** `src/_/_yaml_mataread.ado`

**Summary:** Correct handling of YAML block scalars (`|`, `>`) and continuation
lines. Multi-line values are accumulated and stored as single strL values.

---

## 3. Phase 1 Bugs (v1.5.1) — COMPLETE

### BUG-4: `yaml_write` outputs flattened keys instead of YAML hierarchy

**Status:** Done (`8456e69`)
**File:** `src/y/yaml_write.ado`

**Problem:** `yaml_write` wrote full flattened key names instead of
reconstructing nested YAML structure. `sort key` destroyed insertion order,
the write loop emitted full composite keys, and `indent(#)` was declared but
never used.

**Resolution:** Complete rewrite. Extracted `_yaml_write_impl` helper (also
fixes HYG-2). Removed `sort key`, uses `parent` column for leaf key extraction,
respects `indent(#)` option via `(level - 1) * indent` math. Handles `parent`,
`list_item`, and leaf types correctly.

---

### BUG-5: `yaml_validate` type check reads wrong row

**Status:** Done (`f782545`)
**File:** `src/y/yaml_validate.ado`

**Problem:** After ``qui count if key == "`tkey'"``, the code read ``type[1]``
(always observation 1) instead of the matching observation.

**Resolution:** Replaced `type[1]` with a `forvalues` loop that finds the
observation where `key[i] == "`tkey'"` and reads its type.

---

### BUG-6: `_yaml_fastread` rejects values containing `{`, `}`, `[`, `]`

**Status:** Done (`efd6130`)
**File:** `src/_/_yaml_fastread.ado`

**Problem:** `strpos()` check on full trimmed line caused false errors for
values like `url: https://example.com/path[1]`.

**Resolution:** Split into two targeted checks: (1) `regexm` with `^` for
anchors/aliases, (2) `substr` position 1 for flow collections on full lines,
plus a new check on the value portion after colon extraction.

---

### BUG-7: Double `file close` on early-exit paths in `yaml_read`

**Status:** Done (`fa780fb`)
**File:** `src/y/yaml_read.ado`

**Problem:** Early-exit paths closed the file handle before `continue, break`,
then the post-loop `file close` attempted to close it again.

**Resolution:** Removed `file close` from both early-exit paths. The single
post-loop close handles all exit paths.

---

### BUG-8: `yaml_list` header display broken when filtering

**Status:** Done (`f8e1c25`)
**File:** `src/y/yaml_list.ado`

**Problem:** Column header printed only when `i == 1`, which fails when
filtering skips observation 1.

**Resolution:** Replaced `if (i == 1)` with a `header_shown` flag that
triggers on the first row passing all filters.

---

### BUG-9: `yaml_read` returns different local names by parse mode

**Status:** Done (`fa780fb`)
**File:** `src/y/yaml_read.ado`

**Problem:** Fastread returned `r(yaml_source)` while canonical returned
`r(filename)` for the same information.

**Resolution:** Standardized fastread to return `r(filename)` matching the
canonical path and help file documentation.

---

## 3. Consistency Fixes

### CON-1: Version mismatch across `.ado` files

**Status:** Done (`7b3b8b8` + included in each bug-fix commit)

**Resolution:** Updated `*! v` header from `v 1.5.0 04Feb2026` to
`v 1.5.1 18Feb2026` in all 12 remaining `.ado` files (13th was deleted
per HYG-1).

---

### CON-2: `yaml_dir` return values don't match help file

**Status:** Done (`9451831`)
**File:** `src/y/yaml_dir.ado`

**Resolution:** Added `r(n_total)`, `r(n_dataset)`, `r(n_frames)` as
documented in `yaml.sthlp`. Replaced the undocumented `r(n_yaml)`.

---

### CON-3: Level numbering mismatch (README vs implementation)

**Status:** Done (`b11f2f6`)
**File:** `README.md`

**Resolution:** Changed `(0 = root level)` to `(1 = root level)` in the
data model table.

---

### CON-4: README version references are stale

**Status:** Done (`b11f2f6`)
**File:** `README.md`

**Resolution:** Updated `v1.5.0` to `v1.5.1` (line 13) and `v1.3.1` to
`v1.5.1` (repository structure section).

---

### CON-5: README and `src/y/README.md` show wrong `yaml clear` syntax

**Status:** Done (`b11f2f6`)
**Files:** `README.md`, `src/y/README.md`

**Resolution:** Changed `yaml clear [, all frame(name)]` to
`yaml clear [framename] [, all]` matching the actual code and help file.

---

### CON-6: `src/y/README.md` stale references

**Status:** Done (`b11f2f6`)
**File:** `src/y/README.md`

**Resolution:** Added `yaml dir` to subcommands table, updated file location
paths from `unicefData/` to `yaml-dev/`, removed `_yaml_pop_parents` from
architecture diagram.

---

### CON-7: Submission package is incomplete

**Status:** Done
**Files:** `paper/submission/software/`

**Problem:** The submission directory only contained `yaml.ado` (dispatcher)
and `yaml.sthlp`. The dispatcher alone cannot function since subcommands
are in separate `.ado` files.

**Resolution:** Copied all 15 files listed in `yaml.pkg` (12 `.ado` + 3
`.sthlp`) into the submission software directory. All files are at v1.5.1.

**Note:** LaTeX paper files were verified clean -- no stale references from
our code changes (version numbers, level numbering, yaml clear syntax,
_yaml_pop_parents, return value names all already correct in the `.tex` files).

---

## 4. Code Hygiene

### HYG-1: `_yaml_pop_parents` is unused

**Status:** Done (`f87aa35`)

**Resolution:** Deleted `src/_/_yaml_pop_parents.ado`, removed from
`yaml.pkg`, and removed from `src/y/README.md` architecture diagram.

---

### HYG-2: Duplicated frame/dataset logic in `yaml_write`

**Status:** Done (addressed in BUG-4, `8456e69`)

**Resolution:** Extracted `_yaml_write_impl` helper program, following the
`_impl` pattern used by `yaml_get`, `yaml_list`, `yaml_describe`, and
`yaml_validate`.

---

## 5. Robustness

### ROB-1: Macro expansion with special characters in parsers

**Status:** Done

**Files:**

- `src/y/yaml_read.ado`
- `src/_/_yaml_fastread.ado`
- `src/_/_yaml_tokenize_line.ado`

**Problem:** YAML values containing backticks, dollar signs, or unbalanced
quotes would break macro expansion in lines like:

```stata
local trimmed = strtrim("`line'")
```

**Resolution:** Replaced simple quotes with compound quotes in all parser
lines that handle raw file input or derived values:

```stata
local trimmed = strtrim(`"`line'"')
```

Changed ~50 instances across all 3 parser files: `strtrim()`, `substr()`,
`strpos()`, `regexm()`, `inlist()`, comparisons, and assignments on `line`,
`trimmed`, `templine`, `value`, `item_value`, `right`, `block_val`,
`pending_line`, and `tmp` locals. Submission copies updated.

---

## 6. QA Enhancements

### QA-1: Add regression tests for new bugs

**Status:** Done

Added 5 regression tests to `qa/run_tests.do`:

| Test ID | Script | Fixture |
| ------- | ------ | ------- |
| REG-04 | `qa/scripts/test_roundtrip.do` | `qa/fixtures/roundtrip.yaml` |
| REG-05 | `qa/scripts/test_validate_types.do` | `qa/fixtures/validate_types.yaml` |
| REG-06 | `qa/scripts/test_brackets_in_values.do` | `qa/fixtures/brackets_in_values.yaml` |
| REG-07 | `qa/scripts/test_early_exit.do` | existing fixtures |
| REG-08 | `qa/scripts/test_list_header.do` | existing fixtures |

### QA-2: Add a write-specific test fixture

**Status:** Done

**Resolution:** The round-trip test (REG-04) reads `roundtrip.yaml`, writes
it to a temp file, reads it back, and compares key counts and spot-checked
values including nested keys and list items.

---

## 7. Priority & Sequencing

| Phase | Items | Status |
| ----- | ----- | ------ |
| **Phase 1: v1.5.1 fixes** | BUG-4 to BUG-9, CON-1 to CON-7 | ✅ Done |
| **Phase 2: v1.7.0 performance** | FEAT-1 to FEAT-4 (Mata, collapse, strL) | ✅ Done |
| **Phase 3: Downstream integration** | INT-1 (wbopendata): bundled, parser retained | 🔄 Partial |
| **Phase 3: Downstream integration** | INT-2 (unicefdata): planned | 📋 Planned |

### Phase 2 Commit Log (v1.6.0–v1.7.0)

| Commit | Type | Scope |
| ------ | ---- | ----- |
| `635264f` | feat | v1.6.0: st_sstore, strL, block scalars |
| `b261088` | feat | Mata bulk-load and collapse post-processor |
| `77a9805` | chore | Bump version to v1.7.0 |
| `0fd554f` | fix | Paper citation updates |

---

## 8. Phase 3: Downstream Integration — IN PROGRESS

### INT-1: wbopendata Integration

**Status:** Partial (yaml bundled, parser retained)
**Branch:** `feat/yaml-convergence` (has yaml v1.7.0 bundled)
**Commit:** `6a364d08` — feat(yaml): update bundled yaml package to v1.7.0

**Current State:**

wbopendata has yaml v1.7.0 bundled but retains its custom YAML parser for indicators:

1. **yaml v1.7.0 bundled** ✓ — All 14 ado files + 3 sthlp files copied to `src/y/` and `src/_/`

2. **Custom parser retained** — `__wbod_parse_yaml_ind.ado` (238 lines) still used because:
   - The `collapse` post-processor produces path-based column names (989 columns)
   - Nested YAML structures create columns like `unit_source_org` instead of separate `unit`, `source_org`
   - The simple column mapping expected by wbopendata isn't achievable with current collapse

3. **yaml v1.7.0 available** for simpler YAML files:
   - `_wbopendata_parameters.yaml` — Can use `yaml read`
   - `_wbopendata_sources.yaml` — Can use `yaml read`
   - `_wbopendata_topics.yaml` — Can use `yaml read`

**Migration Blockers:**

The `collapse` post-processor in yaml v1.7.0 is designed for flat YAML structures. 
For the wbopendata indicators YAML with ~29,000 indicators and nested fields, collapse
creates one column per unique YAML path, not one column per top-level field. This
produces 989 columns instead of the expected ~12 columns.

**Options for Future Work:**

1. **Enhance `_yaml_collapse.ado`** — Add `level` or `fields` option to limit collapse depth
2. **Create wrapper function** — Post-process collapse output to select/rename needed columns
3. **Keep custom parser** — Current solution; proven to work, acceptable performance (~40s)

**Lines of Code Impact:**
- Added: 14 yaml ado files + 3 sthlp files (bundled from yaml-dev)
- Retained: `__wbod_parse_yaml_ind.ado` (238 lines)

---

### INT-2: unicefdata Integration

**Status:** Planned (next step)
**Branch:** To be created off `develop`
**Target Files:**
- `stata/src/_/__unicef_parse_indicators_yaml.ado` (270 lines) → Evaluate

**Current State:**

unicefdata has a custom YAML parser (`__unicef_parse_indicators_yaml.ado`) that:
- Reads `_unicefdata_indicators.yaml` (294 KB, 9,674 lines, ~800 indicators)
- Mirrors wbopendata's parser design (documented as "Reference: __wbod_parse_yaml_ind.ado")
- Uses `st_sstore()` for Mata-based row insertion
- Outputs one row per indicator

**Migration Plan (if YAML structure is simpler, same blocker applies if nested):**

1. **Add yaml dependency** to `unicefdata.pkg`

2. **Replace parser call** in `_unicef_load_indicators_cache.ado`:
   ```stata
   yaml read "`yaml_path'", clear collapse parser(mataread)
   rename _key ind_code
   ```

3. **Field mapping** — unicefdata fields:
   | Field | Description |
   |-------|-------------|
   | `code` | Indicator code |
   | `name` | Indicator name |
   | `urn` | URN identifier |
   | `parent` | Parent indicator |
   | `tier` | Data tier |
   | `dataflows` | Associated dataflows |

4. **Delete `__unicef_parse_indicators_yaml.ado`** after validation

5. **Run test suite** (443 tests) to verify parity

**Lines of Code Impact:**
- Delete: 270 lines (`__unicef_parse_indicators_yaml.ado`)
- Add: ~5 lines

---

### INT-3: Shared yaml Dependency Management

**Status:** Planned

**Problem:** Both packages need yaml v1.7.0 as a dependency. Need to ensure:
- yaml is installed before wbopendata/unicefdata
- Version compatibility check

**Options:**

A. **SSC dependency** — yaml is on SSC, add `ssc install yaml` check
B. **Bundled copy** — Include yaml source in each package (duplication)
C. **net install check** — Check for yaml, prompt user if missing

**Recommendation:** Option A with graceful fallback:
```stata
capture which yaml
if _rc {
    di as error "yaml package required. Install with: ssc install yaml"
    exit 198
}
```

---

### INT-4: Performance Validation

**Status:** Planned

**Benchmarks to Run:**

| Test | File | Current Parser | yaml v1.7.0 |
|------|------|----------------|-------------|
| wbopendata indicators | 17.7 MB | TBD | TBD |
| unicefdata indicators | 294 KB | TBD | TBD |

**Success Criteria:**
- yaml v1.7.0 performs within 20% of custom parsers
- All existing tests pass
- No regression in field values

---

## 9. Out of Scope

The following are tracked separately:

- Advanced YAML features (anchors, flow collections, multi-document)
- yaml_write for wbopendata/unicefdata metadata generation
- Python/R parity for YAML parsing
