# YAML Fast-Scan & Cache Plan (Speed-First)

**Date:** 04Feb2026  
**Owner:** João Pedro Azevedo  
**Status:** Draft (performance-first design)  
**Primary Consumer:** wbopendata (Stata)  
**Goal:** Deliver speed-first parsing for large YAML metadata while preserving canonical YAML correctness. Achieve this via (1) canonical parser optimizations and caching, and (2) an opt-in fast-scan path for wbopendata-class workloads.

---

## 1. Problem Statement (Performance First)

`wbopendata` currently uses direct `infix` scanning and custom field extraction for large YAML (indicators, sources, topics). This is fast because it:
- reads the file once,
- performs very limited parsing,
- extracts only a small subset of keys,
- uses cached frames to avoid re-parsing.

In contrast, `yaml.ado` is a general-purpose YAML parser that:
- builds full object structures,
- processes the whole document, and
- incurs overhead in string parsing and data structure creation.

**Result:** `yaml.ado` is correct, but slower than the specialized infix path for large metadata files.

**Objective:** Add two complementary capabilities:
- **Canonical optimizations** to make standard parsing faster and cacheable.
- **Opt-in fast-scan** for near-infix speed on large, regular YAML subsets.

---

## 2. Non-Negotiable Performance Targets

1. **Speed parity** with current infix-based scanning for large indicator YAML (target: within 5–10%).
2. **Single pass file read** in fast-scan mode.
3. **Field-selective extraction** (avoid parsing the entire file).
4. **Cacheability** at the dataset level (frame cache for Stata 16+).
5. **Backward-compatible API**: existing `yaml read` must remain unchanged unless fast-scan is explicitly requested.

---

## 3. Proposed Architecture

### 3.1 Dual-Path Parsing + Canonical Optimizations

Introduce two internal pathways for `yaml.ado`, plus canonical optimizations that benefit *both*:

- **Standard Parse (default):** Canonical YAML parsing, but optimized for large files.
- **Fast-Scan Parse (opt-in):** Lightweight line scanner with a restricted YAML subset.

**Why dual-path?** Canonical parsing stays correct and general; fast-scan provides speed for constrained schemas. Optimizations make canonical parsing faster without changing semantics.

### 3.2 Canonical Parser Optimizations (No Semantics Change)

**Purpose:** Improve performance of the standard parser while remaining fully YAML-compliant.

1. **Selective extraction**
  - Add `fields()` to standard parsing as well (not only fastscan).
  - Skip building nodes outside requested keys/paths.

2. **Early exit**
  - If the caller requests a single key or key list, stop parsing once found.

3. **Streaming parse (tokenized, not full object)**
  - Read and emit tokens incrementally to reduce memory and avoid full tree build when not required.

4. **Persistent cache**
  - Cache parsed output (as .dta or frame) keyed by file hash (modtime + size + checksum).
  - Use cache for subsequent reads (canonical parse once per session or per file change).

5. **Index materialization**
  - Optional: build lightweight indexes (key → fields) from canonical parse, then serve queries from index.

---

### 3.3 Fast-Scan Mode: Behavior

**Fast-scan design:**
- Line-based scanning (no full YAML parse tree).
- Extracts only requested keys or blocks.
- Supports shallow mappings and list blocks.
- Avoids recursive parsing of nested structures.

**Supported patterns (v1):**
- Top-level mapping: `key:`
- Nested scalar fields: `field: value`
- List blocks:
  - `field:` followed by `- value` lines
- Quoted and unquoted scalars

**Not supported (fast mode):**
- Anchors/aliases
- Complex nested mappings
- Multiline block scalars (unless explicitly opted in with simple capture)

---

## 4. Proposed User-Facing API Additions

### 4.1 New Option: `fastscan`

A new option for `yaml read`:

```
yaml read using "file.yaml", fastscan
```

Fast-scan mode can optionally accept field filters:

```
yaml read using "file.yaml", fastscan fields(name description source_id topic_ids)
```

### 4.2 New Option: `fields()`

Filter extraction to specific keys, greatly reducing work.

Example:
```
yaml read using "_wbopendata_indicators.yaml", fastscan fields(name description source_id topic_ids)
```

### 4.3 New Option: `listkeys()`

Identify list blocks and return flattened list rows.

Example:
```
yaml read using "_wbopendata_indicators.yaml", fastscan listkeys(topic_ids topic_names)
```

### 4.4 Cache Hook (Stata 16+)

Allow callers to request caching to a frame:

```
yaml read using "_wbopendata_indicators.yaml", fastscan fields(...) cache(frame=_yaml_ind_cache)
```

If frame exists with same schema/hash, skip re-parse.

---

## 5. Checks & Error Messages (Canonical vs Fast-Scan)

### 5.1 Common Checks (Both Paths)

- **File exists**
  - Error: `YAML file not found: <path>` (exit 601)
- **Readable file** (permissions/locking)
  - Error: `YAML file not readable: <path>` (exit 603)
- **Empty file**
  - Error: `YAML file is empty: <path>` (exit 198)
- **Invalid option values** (e.g., `fields()` empty after parsing)
  - Error: `fields() must include at least one key` (exit 198)

### 5.2 Canonical Parse Checks

- **Syntax errors**
  - Error: `YAML syntax error at line <n>: <summary>` (exit 198)
- **Unknown keys in `fields()`**
  - Error: `Unknown field: <name>. Valid fields: ...` (exit 198)
- **Cache integrity**
  - If cached dataset exists but schema or hash mismatch:
    - Warning: `Cache invalidated (schema/hash mismatch). Rebuilding...`
    - Proceed with fresh parse

### 5.3 Fast-Scan Checks

- **Unsupported YAML feature** (anchors, aliases, nested mappings, block scalars when disabled)
  - Error: `fastscan unsupported YAML feature at line <n>. Rerun without fastscan.` (exit 198)
- **List key requested but list not found**
  - Return empty rows (no error)
- **`listkeys()` without `fastscan`**
  - Error: `listkeys() requires fastscan` (exit 198)
- **`fastscan` with unsupported option combos** (e.g., `fastscan` + deep path selectors)
  - Error: `fastscan does not support nested path selectors` (exit 198)

---

## 6. Minimal Output Schema (Fast-Scan Mode)

For speed, output is row-wise and minimal:

| var | type | description |
|-----|------|-------------|
| key | str | top-level key (e.g., indicator code) |
| field | str | field name (e.g., source_id, description) |
| value | str | scalar or list item value |
| list | byte | 1 if list item, else 0 |
| line | long | line number for trace/debug |

This minimal table can be collapsed by caller into wide format.

---

## 7. Staged Implementation Plan

### Phase 1: Canonical Optimizations (No behavior change)
- Add `fields()` and early-exit support to canonical parse.
- Add cache layer (file hash → cached dataset/frame).
- Add optional index build for repeated queries.
- Keep wbopendata infix path as default.

### Phase 2: Fast-Scan Prototype (Opt-in)
- Add `fastscan` API and `listkeys()` support.
- Add frame caching for fast-scan results (Stata 16+).
- Add a hidden option in wbopendata to toggle yaml fastscan.
- Benchmark vs infix and canonical-optimized paths.

### Phase 3: Adoption Decision
- If canonical + cache meets targets for wbopendata, switch to canonical path.
- If not, switch wbopendata to fast-scan path (keep canonical default for general users).

---

## 8. Benchmark Plan

### 7.1 Files
- `metadata/_wbopendata_indicators.yaml`
- `metadata/_wbopendata_sources.yaml`
- `metadata/_wbopendata_topics.yaml`

### 7.2 Metrics
- Total parse time (ms)
- Memory footprint (approx. dataset size)
- End-to-end search time (search + filter)

### 7.3 Success Criteria
- Fast-scan parse within 10% of infix approach
- No functional regression in returned keys
- No errors on typical YAML subsets used by wbopendata

---

## 9. Internal Implementation Sketch

### 8.1 Fast-Scan Engine

Pseudo steps:
1. Read file with `infix str2045 rawline 1-2045 using ...`
2. Track current top-level key (indicator code)
3. When `field:` encountered, set field context
4. If `- value` lines follow, emit list rows for that field
5. Apply `fields()` filter at extraction time
6. Output minimal dataset (key, field, value, list)

### 8.2 Optional Block Scalars

Allow simple block capture if enabled:
- If `description:` is followed by `|` or `>-`, collect subsequent indented lines until indent decreases.
- Store joined lines as value.

This is optional and should default to OFF for speed.

---

## 10. Stata Version Strategy

- **Stata 11–15:** fastscan works, no caching
- **Stata 16+:** optional frame caching for parsed datasets

---

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Fast-scan misses YAML edge cases | Low for wbopendata | Keep default parser unchanged; opt-in only |
| YAML block scalars | Medium | Add optional block-scalar capture | 
| Cache invalidation | Medium | Hash file modtime + size; store in frame attributes |
| Maintenance complexity | Medium | Keep fastscan code path compact and documented |

---

## 12. Next Steps

1. Implement canonical `fields()` and early-exit support
2. Add canonical cache layer (frame + file hash)
3. Add optional index materialization for repeated queries
4. Implement `fastscan` + `listkeys()`
5. Add fast-scan frame caching
6. Add benchmark script comparing infix vs canonical-optimized vs fastscan
7. Add wbopendata test flag to switch parser

---

## 13. Success Definition

`wbopendata` can use `yaml.ado` for all discovery and metadata parsing **without any measurable slowdown** versus its current custom infix parser.
