# Changelog

All notable changes to the yaml Stata package will be documented in this file.

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

## [1.3.1] - 2026-02-14

### Fixed

- Return value propagation from frame context in `yaml_get` and `yaml_list`

## [1.3.0] - 2026-02-13

### Added

- Initial public release with `yaml_read`, `yaml_write`, `yaml_describe`, `yaml_list`, `yaml_get`, `yaml_validate`, `yaml_dir`
