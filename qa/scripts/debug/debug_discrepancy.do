*! debug_discrepancy.do
*! Investigate 10-row difference between vectorized and bulk+collapse

clear all
set more off

local root "c:/GitHub/myados/yaml-dev"
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/_wbopendata_indicators.yaml"
local logfile "`root'/qa/logs/debug_discrepancy.log"

cap log close _disclog
log using "`logfile'", replace text name(_disclog)

di _n "{hline 60}"
di "Investigating row count discrepancy"
di "{hline 60}"

*===============================================================================
* Load vectorized output (29,189 rows expected)
*===============================================================================

di _n as text "1. Loading with vectorized parser..."
qui do "`root'/examples/ex_wbod_vectorized_parse.do"
qui ex_wbod_vectorized_parse "`fixture'"
local vec_N = _N
di as result "   Vectorized rows: `vec_N'"

* Save indicator codes (no normalization - dots should now be preserved)
tempfile vec_codes
qui keep ind_code
qui replace ind_code = strtrim(ind_code)
qui duplicates drop
local vec_unique = _N
di as text "   Unique ind_codes: `vec_unique'"
di as text "   First 3 codes:"
list ind_code in 1/3, noobs
di as text "   Variable type:"
describe ind_code
qui save `vec_codes'

*===============================================================================
* Load bulk+collapse output (29,179 rows expected)
*===============================================================================

di _n as text "2. Loading with bulk+collapse..."
qui yaml read using "`fixture'", replace bulk blockscalars strl
di as text "   Long format rows before collapse: `=_N'"
qui _yaml_collapse
local bulk_N = _N
di as result "   Bulk+collapse rows: `bulk_N'"

* Save indicator codes (dots should now be preserved after fix)
tempfile bulk_codes
qui keep ind_code
qui replace ind_code = strtrim(ind_code)
qui duplicates drop
local bulk_unique = _N
di as text "   Unique ind_codes: `bulk_unique'"
di as text "   First 3 codes:"
list ind_code in 1/3, noobs
di as text "   Variable type:"
describe ind_code
qui save `bulk_codes'

*===============================================================================
* Find codes in vectorized but not in bulk+collapse
*===============================================================================

di _n as text "3. Finding codes in vectorized but NOT in bulk+collapse..."
qui use `vec_codes', clear
qui merge 1:1 ind_code using `bulk_codes', keep(master) nogen
local in_vec_only = _N
if (`in_vec_only' > 0) {
    di as result "   Found `in_vec_only' codes in vectorized only:"
    local show_n = min(20, `in_vec_only')
    list ind_code in 1/`show_n', noobs abbrev(30)
}
else {
    di as text "   None found."
}

*===============================================================================
* Find codes in bulk+collapse but not in vectorized
*===============================================================================

di _n as text "4. Finding codes in bulk+collapse but NOT in vectorized..."
qui use `bulk_codes', clear
qui merge 1:1 ind_code using `vec_codes', keep(master) nogen
local in_bulk_only = _N
if (`in_bulk_only' > 0) {
    di as result "   Found `in_bulk_only' codes in bulk+collapse only:"
    local show_n = min(20, `in_bulk_only')
    list ind_code in 1/`show_n', noobs abbrev(30)
}
else {
    di as text "   None found."
}

*===============================================================================
* Summary
*===============================================================================

di _n "{hline 60}"
di "Summary:"
di "  Vectorized:     `vec_N' rows, `vec_unique' unique codes"
di "  Bulk+collapse:  `bulk_N' rows, `bulk_unique' unique codes"
di "  In vectorized only: `in_vec_only'"
di "  In bulk+collapse only: `in_bulk_only'"
di "  Net difference: " as result (`vec_N' - `bulk_N')
di "{hline 60}"

log close _disclog
di as text "Log saved to: qa/logs/debug_discrepancy.log"
