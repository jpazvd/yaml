*! benchmark_yaml_parse.do
*! YAML parsing benchmark (canonical vs fastread)
*! Date: 04Feb2026
*! Targets:
*!  - fastread parse <= 1.1x infix baseline for indicators.yaml
*!  - canonical cache-hit <= 10% of canonical cold parse time
*!  - fastread cache-hit <= 10% of fastread cold parse time

clear all
set more off
set linesize 80
cap log close

* Set project root
local root = c(pwd)

* Add ado path
adopath ++ "`root'/src/y"

* Benchmark inputs
local ind "`root'/examples/data/indicators.yaml"

* Timers
clear
set rmsg on

* Canonical cold parse
timer clear 1
timer on 1
yaml read using "`ind'", replace
timer off 1

* Canonical cache hit
timer clear 2
timer on 2
yaml read using "`ind'", replace cache(ind_cache)
* second call should hit cache
yaml read using "`ind'", replace cache(ind_cache)
timer off 2

* Fastread cold parse
timer clear 3
timer on 3
yaml read using "`ind'", fastread ///
    fields(name description source_id topic_ids) ///
    listkeys(topic_ids topic_names)
timer off 3

* Fastread cache hit
timer clear 4
timer on 4
yaml read using "`ind'", fastread ///
    fields(name description source_id topic_ids) ///
    listkeys(topic_ids topic_names) cache(ind_fast)
* second call should hit cache
yaml read using "`ind'", fastread ///
    fields(name description source_id topic_ids) ///
    listkeys(topic_ids topic_names) cache(ind_fast)
timer off 4

* Report
noi di as text "{hline 70}"
noi di as text "YAML BENCHMARK RESULTS"
noi di as text "{hline 70}"
noi di as text "Canonical cold parse:" 
noi timer list 1
noi di as text "Canonical cache hit:" 
noi timer list 2
noi di as text "Fastread cold parse:" 
noi timer list 3
noi di as text "Fastread cache hit:" 
noi timer list 4
noi di as text "{hline 70}"
