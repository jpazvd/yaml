*! paper_examples.do
*! Reproduces every runnable Stata example from yamlstata-v3.tex
*!
*! Usage:  Run from the repository root:
*!   cd <repo-root>
*!   do paper/examples/paper_examples.do
*!
*! Requires: Stata 16+ (for frame examples; earlier sections work on 14+)
*! Author: Joao Pedro Azevedo
*! Date:   February 2026

clear all
set more off
set linesize 80
cap log close _paper

* Resolve repo root from script location
local paperdir "`c(pwd)'/paper/examples"
local datadir  "`paperdir'/data"
local logdir   "`paperdir'/logs"

* Create log directory if needed
cap mkdir "`logdir'"

* Add source to adopath
adopath ++ "`c(pwd)'/src/y"
adopath ++ "`c(pwd)'/src/_"

log using "`logdir'/paper_examples.log", replace text name(_paper)

di as text _n "{hline 70}"
di as result "PAPER EXAMPLES: yamlstata-v3.tex"
di as text "{hline 70}"
di as text "Date:  " c(current_date) " " c(current_time)
di as text "Stata: " c(stata_version)
di as text "{hline 70}" _n

* ============================================================================
* SECTION 4.1: yaml read  (stlog blocks 5, line 265)
* ============================================================================

di as result _n "=== Section 4.1: yaml read ===" _n

* Block 5: basic read
yaml read using "`datadir'/config.yaml", replace

* Block 5: read into frame
cap yaml clear, all
yaml read using "`datadir'/unicef_indicators.yaml", frame(ind)

* Block 5: fastread (uses indicators file)
yaml read using "`datadir'/unicef_indicators.yaml", fastread replace ///
    fields(name description)

* ============================================================================
* SECTION 4.2: yaml write  (stlog block 6, line 308)
* ============================================================================

di as result _n "=== Section 4.2: yaml write ===" _n

yaml read using "`datadir'/config.yaml", replace
yaml write using "`logdir'/output.yaml", replace

* ============================================================================
* SECTION 4.3: yaml describe  (stlog block 7, line 325)
* ============================================================================

di as result _n "=== Section 4.3: yaml describe ===" _n

yaml read using "`datadir'/config.yaml", replace
yaml describe

* Also test abbreviation (paper notes yaml desc)
yaml desc

* ============================================================================
* SECTION 4.4: yaml list  (stlog block 8, line 361)
* ============================================================================

di as result _n "=== Section 4.4: yaml list ===" _n

yaml read using "`datadir'/unicef_indicators.yaml", replace
yaml list indicators, keys children
return list

* ============================================================================
* SECTION 4.5: yaml get  (stlog block 9, line 383)
* ============================================================================

di as result _n "=== Section 4.5: yaml get ===" _n

yaml get indicators:CME_MRY0T4
return list

* ============================================================================
* SECTION 4.6: yaml validate  (stlog block 10, line 416)
* ============================================================================

di as result _n "=== Section 4.6: yaml validate ===" _n

yaml read using "`datadir'/pipeline_config.yaml", replace
yaml validate, required(name version database api_endpoint) ///
    types(database_port:numeric debug:boolean)

* Also test abbreviation (paper notes yaml check)
yaml check, required(name version) quiet

* ============================================================================
* SECTION 4.7: yaml dir  (stlog block 11, line 434)
* ============================================================================

di as result _n "=== Section 4.7: yaml dir ===" _n

yaml read using "`datadir'/config.yaml", replace
yaml dir, detail

* ============================================================================
* SECTION 4.8: yaml frames  (stlog block 12, line 449)
* ============================================================================

di as result _n "=== Section 4.8: yaml frames ===" _n

cap yaml clear, all
yaml read using "`datadir'/dev_config.yaml", frame(dev)
yaml read using "`datadir'/prod_config.yaml", frame(prod)
yaml frames, detail

* Also test abbreviation (paper notes yaml frame)
yaml frame

* ============================================================================
* SECTION 4.9: yaml clear  (stlog block 13, line 476)
* ============================================================================

di as result _n "=== Section 4.9: yaml clear ===" _n

* Clear specific frame
yaml clear dev
* Clear all remaining
yaml clear, all

* ============================================================================
* SECTION 5.1: Indicator metadata  (stlog blocks 15-18, lines 515-545)
* ============================================================================

di as result _n "=== Section 5.1: Indicator metadata management ===" _n

* Block 15: read into frame
cap yaml clear, all
yaml read using "`datadir'/unicef_indicators.yaml", frame(meta)
yaml list indicators, keys children frame(meta)

* Block 16: build API URL
local api_base "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data"
yaml get indicators:CME_MRY0T4, frame(meta) quiet
local flow "`r(dataflow)'"
local api_url "`api_base'/UNICEF,`flow',1.0/.CME_MRY0T4.?format=csv"
di "API URL: `api_url'"

* Block 17: label variable
yaml get indicators:CME_MRY0T4, frame(meta) quiet
di "Label: `r(name)' (`r(unit)')"

* Block 18: loop over indicators
yaml list indicators, keys children frame(meta)
local indicators "`r(keys)'"
foreach ind of local indicators {
    yaml get indicators:`ind', frame(meta) quiet
    local flow "`r(dataflow)'"
    di "`ind' -> dataflow: `flow'"
}

* ============================================================================
* SECTION 5.2: Efficient metadata ingestion  (stlog blocks 19-20, lines 569-583)
* ============================================================================

di as result _n "=== Section 5.2: Frame-based filtering ===" _n

* Block 20: optimized frame-based query
yaml read using "`datadir'/unicef_indicators.yaml", frame(meta2) replace

frame yaml_meta2 {
    gen is_nutrition = (value == "NUTRITION") & ///
        regexm(key, "^indicators_[A-Za-z0-9_]+_dataflow$")
    gen indicator_code = regexs(1) if ///
        regexm(key, "^indicators_([A-Za-z0-9_]+)_dataflow$") & is_nutrition

    levelsof indicator_code if is_nutrition == 1, local(nutrition_codes) clean

    foreach ind of local nutrition_codes {
        levelsof value if key == "indicators_`ind'_name", local(ind_name) clean
        di "`ind': `ind_name'"
    }
}

frame drop yaml_meta2

* ============================================================================
* SECTION 5.4: Configuration validation  (stlog block 25, line 715)
* ============================================================================

di as result _n "=== Section 5.4: Configuration validation ===" _n

yaml read using "`datadir'/pipeline_config.yaml", replace
yaml validate, required(name version database api_endpoint) ///
    types(database_port:numeric api_timeout:numeric debug:boolean)

if (r(valid) == 0) {
    di as error "Configuration validation failed!"
}
else {
    di as result "Configuration validation passed."
}

* ============================================================================
* SECTION 5.5: Multiple YAML files  (stlog blocks 26-28, lines 733-752)
* ============================================================================

di as result _n "=== Section 5.5: Multiple YAML files ===" _n

* Block 26: load dev and prod
cap yaml clear, all
yaml read using "`datadir'/dev_config.yaml", frame(dev)
yaml read using "`datadir'/prod_config.yaml", frame(prod)

* Block 27: frames inventory
yaml frames, detail

* Block 28: compare settings
yaml get database:host, frame(dev)
local dev_host "`r(host)'"
yaml get database:host, frame(prod)
local prod_host "`r(host)'"
di "Dev: `dev_host', Prod: `prod_host'"

cap yaml clear, all

* ============================================================================
* SECTION 5.6: Round-trip  (stlog block 29, line 769)
* ============================================================================

di as result _n "=== Section 5.6: Round-trip ===" _n

yaml read using "`datadir'/config.yaml", replace
replace value = "3.0" if key == "version"
replace value = "`c(current_date)'" if key == "last_modified"
yaml write using "`logdir'/config_updated.yaml", replace

* ============================================================================
* SECTION 5.7: User profiles  (stlog block 31, line 800)
* ============================================================================

di as result _n "=== Section 5.7: User profiles ===" _n

yaml read using "`datadir'/user_config.yml", frame(usercfg)
yaml get analyst1, frame(usercfg) quiet
di "githubFolder: `r(githubFolder)'"
cap yaml clear, all

* ============================================================================
* CLEANUP
* ============================================================================

di as result _n "{hline 70}"
di as result "ALL PAPER EXAMPLES COMPLETED SUCCESSFULLY"
di as result "{hline 70}" _n

cap erase "`logdir'/output.yaml"
cap erase "`logdir'/config_updated.yaml"

log close _paper

* End of paper_examples.do
