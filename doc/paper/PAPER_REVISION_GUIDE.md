# Paper Revision Guide: YAML Stata Module

**Date:** 05Feb2026  
**Scope:** Updates needed for the next paper revision to reflect v1.5.0 (fastscan, fields, listkeys, cache, targets/earlyexit, stream, index frames, blockscalars, file checks)

---

## 1. Executive Summary (Abstract/Intro)

- Add a sentence describing the speed-first parsing pathway (fastscan) for large YAML catalogs.
- Mention that canonical parsing remains default and YAML-compliant; fastscan is opt-in.
- Highlight frame caching for repeat queries and large metadata workflows.
- Add a sentence about canonical early-exit targets for faster lookup in large files.

---

## 2. Command Syntax & Options

Update the syntax table for `yaml read` to include:
- fastscan
- fields(string)
- listkeys(string)
- cache(string)
- targets(string)
- earlyexit
- stream
- index(string)
- blockscalars

Include compatibility notes:
- fastscan is not compatible with locals/scalars.
- targets()/earlyexit, stream, and index() are canonical-only.
- blockscalars applies to fastscan only.

---

## 3. Data Model Section

Add a subsection describing fast-scan output schema:
- key, field, value, list, line.
- Explain row-wise output for list items.

Add a subsection describing index frames:
- index() materializes a separate frame for faster repeated queries (Stata 16+).

---

## 4. Performance Section

Add a new benchmark table:
- Canonical parse (no cache)
- Canonical parse (cache hit)
- Canonical parse with targets()/earlyexit
- Canonical parse with stream
- Fastscan (no cache)
- Fastscan (cache hit)

Report:
- Parse time (ms)
- Memory footprint (approx. rows)
- End-to-end query time (search + filter)

---

## 5. Examples Section

Add a fast-scan example:

```
. yaml read using "indicators.yaml", fastscan \
    fields(name description source_id topic_ids) \
    listkeys(topic_ids topic_names) cache(ind_cache)
. list in 1/5
```

Add a cache hit example:

```
. yaml read using "indicators.yaml", fastscan fields(name) cache(ind_cache)
. return list   // show r(cache_hit)

Add a canonical early-exit example:

```
. yaml read using "indicators.yaml", targets(indicators_CME_MRY0T4_label) earlyexit
. return list
```

Add an index frame example:

```
. yaml read using "indicators.yaml", index(indx) replace
. yaml get indicators:CME_MRY0T4
```
```

---

## 6. Limitations / Scope

- State that fastscan supports shallow mappings + list blocks.
- Explicitly list unsupported YAML features (anchors/aliases, flow style, complex nested mappings; block scalars are opt-in via blockscalars).
- Emphasize that canonical parsing remains available for full YAML compliance.

---

## 7. Replication Notes

- Include Stata version requirement for frame caching and index frames (16+).
- Provide a note on cache invalidation (hash-based on file checksum).
- Mention file readability/empty-file checks in v1.5.0.

---

## 8. What to Update in the Paper Files

- Abstract: add 1–2 sentences for fastscan + cache + early-exit targets.
- Syntax table: add new options for yaml read.
- Data model: add fastscan schema + index frame note.
- Examples: insert fastscan example + cache hit + early-exit + index example.
- Performance: add benchmark comparison table (canonical/fastscan, cache hit/miss, targets/stream).
- Limitations: list fastscan scope restrictions and unsupported YAML features.
- Appendix: include a short fastscan usage snippet.

---

## 9. Suggested Wording (Drop-in)

**Abstract add-on:**
“Version 1.5.0 introduces an opt-in fast-scan mode for large metadata catalogs, providing near-infix performance with field-selective extraction and frame caching, while preserving canonical YAML parsing as the default. It also adds canonical early-exit targets and index frames for faster repeated queries.”

**Limitations add-on:**
“Fast-scan mode is optimized for shallow mappings and list blocks, and does not currently support anchors, aliases, flow-style collections, or complex nested structures. Block scalars are opt-in via blockscalars. Users requiring full YAML compliance should use the canonical parser.”
