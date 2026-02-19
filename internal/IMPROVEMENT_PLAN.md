# YAML Improvement Plan

**Date:** 18Feb2026
**Owner:** Joao Pedro Azevedo
**Status:** Phases 1-3 complete; Phase 4 partially complete
**Scope:** Bug fixes, consistency issues, and targeted enhancements identified during code review

---

## 1. Summary

This plan addresses bugs, version inconsistencies, and documentation mismatches
found in the `yaml` package at v1.5.1. Items are ordered by severity: bugs first,
then consistency fixes, then enhancements.

---

## 2. Bugs

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

**Status:** Pending
**Files:** `paper/submission/software/`

**Problem:** The submission directory only contains `yaml.ado` (dispatcher)
and `yaml.sthlp`. The dispatcher alone cannot function since subcommands
are in separate `.ado` files.

**Fix:** Copy all files listed in `yaml.pkg` (12 `.ado` + 3 `.sthlp`) into
the submission software directory.

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

**Status:** Pending

**Files:**

- `src/y/yaml_read.ado` (line 329)
- `src/_/_yaml_fastread.ado` (lines 40, 140, 153, 156)

**Problem:** YAML values containing backticks, dollar signs, or unbalanced
quotes will break macro expansion in lines like:

```stata
local trimmed = strtrim("`line'")
```

**Fix:** Use compound quotes in all parser lines that handle raw file input:

```stata
local trimmed = strtrim(`"`line'"')
```

**Risk:** High blast radius -- touches the core parser loops in both the
canonical and fastread parsers. Should be done on its own branch with
before/after testing against all existing YAML fixtures.

---

## 6. QA Enhancements

### QA-1: Add regression tests for new bugs

**Status:** Pending

Add to `qa/run_tests.do`:

| Test ID | Description | Fixture needed |
| ------- | ----------- | -------------- |
| REG-04 | Round-trip read/write produces valid YAML | `qa/fixtures/roundtrip.yaml` |
| REG-05 | `yaml validate` type check matches correct row | `qa/fixtures/validate_types.yaml` |
| REG-06 | Fastread handles brackets/braces in values | `qa/fixtures/brackets_in_values.yaml` |
| REG-07 | Early-exit with targets does not double-close file | existing fixtures suffice |
| REG-08 | `yaml list` header displays correctly with parent filter | existing fixtures suffice |

### QA-2: Add a write-specific test fixture

**Status:** Pending

Currently there are no tests that exercise `yaml write` and verify the output
file content. The round-trip test (REG-04) would be the first.

---

## 7. Priority & Sequencing

| Phase | Items | Rationale |
| ----- | ----- | --------- |
| **Phase 1: Critical fixes** | ~~BUG-4, BUG-5, BUG-6, BUG-7~~ | Done |
| **Phase 2: Consistency** | ~~CON-1, CON-2, CON-3, CON-4, CON-5, CON-6, HYG-1~~ | Done |
| **Phase 3: Low-severity bugs** | ~~BUG-8, BUG-9~~ | Done |
| **Phase 4: Robustness** | ~~HYG-2~~, ROB-1 | HYG-2 done (BUG-4); ROB-1 pending |
| **Phase 5: Packaging** | CON-7 | Submission copy matches source |
| **Phase 6: QA** | QA-1, QA-2 | Regression coverage for all fixes |

### Commit Log

| Commit | Type | Scope |
| ------ | ---- | ----- |
| `8456e69` | fix | yaml_write rewrite (BUG-4, HYG-2) |
| `f782545` | fix | yaml_validate type check (BUG-5) |
| `efd6130` | fix | fastread bracket/brace (BUG-6) |
| `fa780fb` | fix | yaml_read double close + return values (BUG-7, BUG-9) |
| `f8e1c25` | fix | yaml_list header display (BUG-8) |
| `9451831` | fix | yaml_dir return values (CON-2) |
| `7b3b8b8` | chore | Version headers to v1.5.1 (CON-1) |
| `f87aa35` | refactor | Remove _yaml_pop_parents (HYG-1) |
| `b11f2f6` | docs | README fixes (CON-3, CON-4, CON-5, CON-6) |
| `5cc4f77` | docs | Add improvement plan |

---

## 8. Out of Scope

The following are tracked in existing plans and not duplicated here:

- Architecture refactor to shared `yaml_utils.ado` (see `doc/plans/YAML_ARCH_REFACTOR_PLAN.md`)
- Further fastread performance work (see `doc/plans/YAML_FAST_SCAN_PLAN.md`)
- New YAML features (anchors, flow collections, multi-document)
