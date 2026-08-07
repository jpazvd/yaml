# Changelog

All notable changes to the yaml Stata package will be documented in this file.

## [2.0.1] - 2026-08-06

### Fixed

- `yaml write, scalars()`: a string scalar whose value contains a double
  quote no longer aborts the write with r(198) (which also left a truncated
  file on disk). The scalar line now uses compound quotes, matching the
  main write path. Regression covered in `qa/scripts/test_write_scalars.do`
  (BUG-15).

## [2.0.0] - 2026-07-26

Major version. Driven by re-running the documented examples end-to-end
against the split package, which surfaced the behaviors and regressions
below.

### Added

- **Sequences of mappings** (`- key: value` items): the canonical parser now
  stores each item as a structural row `<list>_N` (type `list_map`) with its
  keys as children; `yaml write` re-emits dash form (first pair folded onto
  the dash line); items may contain nested mappings. `bulk` and `fastread`
  reject such items with an explicit error instead of storing a corrupted
  representation.
- Multi-level colon paths in `yaml get` and `yaml list` (`a:b:c` = `a_b_c`;
  parent/key split at the last colon).
- `yaml list` returns `r(found)`; fast-read `yaml read` returns `r(n_keys)`.
- QA: `qa/scripts/test_rr_regressions.do` (16 tests) covering all of the
  above plus the regressions below.

### Changed

- One quoting rule in all parsers: surrounding quotes are stripped only when
  the first and last characters are the same quote character; quoted values
  are always typed string; escape sequences are kept literal.
- `yaml write` literal fidelity: boolean rows are emitted as `true`/`false`
  (not `1`/`0`) and null rows as an empty value (`key:`).

### Fixed

- `yaml list, children` again returns bare child names (parent prefix
  stripped), as in v1.3.x and as documented; the modular refactor had
  silently switched to full flattened keys.
- Malformed option declaration `NoHeader` -> `NOHeader`: `noheader` was
  rejected and option parsing corrupted.
- `_yaml_list_impl` now strips the quotes the wrapper adds around the parent
  argument; the parent filter previously matched everything.
- `noheader` suppresses all printed output, not just the header line.
- Scalar-leaf `yaml get` (a key holding a value, no children) returns
  `r(value)` under the normal parent-variable path and the index path;
  previously only the legacy no-parent fallback did.
- A whole-node `yaml get` on a block sequence of scalars (children indexed
  `<key>_1`, `<key>_2`, ...) now returns the item values space-joined in
  `r(value)` and their count in `r(n_attrs)`, instead of failing with
  `r(198)` ("invalid name") when it tried to return numeric index names as
  `r()` macros. Individual items remain addressable by index (`<key>:1`).

## [1.9.2] - 2026-02-22

### Fixed

- Fix list-item quote stripping
- Fix sibling parent_stack contamination

## [1.9.0] - 2026-02-20

### Added

- INDICATORS preset for wbopendata/unicefdata parsing

## [1.8.0] - 2026-02-20

### Added

- `collapse` command with `colfields()` and `maxlevel()` options for selective columns

## [1.7.0] - 2026-02-19

### Added

- Mata bulk-load (BULK) mode
- Collapsed wide-format output (COLLAPSE)

## [1.5.0] - 2026-02-18

### Added

- Canonical early-exit targets
- Streaming tokenization
- Index frames

## [1.3.1] - 2025-12-17

### Fixed

- Return value propagation from frame context in `yaml_get` and `yaml_list`

## [1.3.0] - 2025-12-04

### Added

- Initial public release with `yaml_read`, `yaml_write`, `yaml_describe`, `yaml_list`, `yaml_get`, `yaml_validate`, `yaml_dir`
