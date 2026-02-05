# Paper Revision Guide: YAML Stata Module

**Date:** 04Feb2026  
**Scope:** Updates needed for the next paper revision to reflect v1.4.0 (fastscan, fields, listkeys, cache)

---

## 1. Executive Summary (Abstract/Intro)

- Add a sentence describing the speed-first parsing pathway (`fastscan`) for large YAML catalogs.
- Mention that canonical parsing remains default and YAML-compliant; fastscan is opt-in.
- Highlight frame caching for repeat queries and large metadata workflows.

---

## 2. Command Syntax & Options

Update the syntax table for `yaml read` to include:
- `fastscan`
- `fields(string)`
- `listkeys(string)`
- `cache(string)`

Include the compatibility note: `fastscan` is not compatible with `locals`/`scalars`.

---

## 3. Data Model Section

Add a subsection describing fast-scan output schema:
- `key`, `field`, `value`, `list`, `line`.
- Explain row-wise output for list items.

---

## 4. Performance Section

Add a new benchmark table:
- Canonical parse (no cache)
- Canonical parse (cache hit)
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
```

---

## 6. Limitations / Scope

- State that `fastscan` supports shallow mappings + list blocks.
- Explicitly list unsupported YAML features (anchors/aliases, complex nested mappings, block scalars by default).
- Emphasize that canonical parsing remains available for full YAML compliance.

---

## 7. Replication Notes

- Include Stata version requirement for frame caching (16+).
- Provide a note on cache invalidation (hash-based on file checksum).

---

## 8. What to Update in the Paper Files

- Abstract: add 1–2 sentences for fastscan + cache.
- Syntax table: add new options for `yaml read`.
- Data model: add fastscan schema.
- Examples: insert fastscan example + cache hit example.
- Performance: add benchmark comparison table.
- Limitations: list fastscan scope restrictions.
- Appendix: include a short fastscan usage snippet.

---

## 9. Suggested Wording (Drop-in)

**Abstract add-on:**
“Version 1.4.0 introduces an opt-in fast-scan mode for large metadata catalogs, providing near-infix performance with field-selective extraction and frame caching, while preserving canonical YAML parsing as the default.”

**Limitations add-on:**
“Fast-scan mode is optimized for shallow mappings and list blocks, and does not currently support anchors, aliases, or complex nested structures. Users requiring full YAML compliance should use the canonical parser.”
