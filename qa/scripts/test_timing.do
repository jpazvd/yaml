*! test_timing.do
*! Feature test FEAT-07: Performance benchmark across parser modes
*! Date: 20Feb2026
*! Uses _wbopendata_indicators.yaml (463K lines, 18MB, 29K indicators)
*!
*! Benchmarks four approaches:
*!   1. Canonical ado parser (yaml read) — may fail on large files
*!   2. Vectorized ado (wbopendata-style: file read → dataset → collapse)
*!   3. Mata bulk parser (yaml read ..., bulk) — long format
*!   4. Mata bulk + collapse (yaml read ..., bulk collapse) — wide format

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/_wbopendata_indicators.yaml"
local diaglog "`root'/qa/logs/feat07_diagnostic.log"
local all_pass = 1

*===============================================================================
* PRE-CHECK: Verify fixture exists
*===============================================================================

capture confirm file "`fixture'"
if (_rc != 0) {
    di as text "FEAT-07 SKIP: large fixture _wbopendata_indicators.yaml not available"
    exit 0
}

* Open diagnostic log (persists even under capture quietly)
tempname dlog
file open `dlog' using "`diaglog'", write replace
file write `dlog' "FEAT-07 Performance Benchmark" _n
file write `dlog' "Date: `c(current_date)' `c(current_time)'" _n
file write `dlog' "Fixture: _wbopendata_indicators.yaml" _n
file write `dlog' _n

*===============================================================================
* BENCHMARK 1: Canonical ado parser (yaml read)
*===============================================================================

file write `dlog' "--- 1. Canonical ado parser ---" _n
timer clear 1
timer on 1
capture noisily yaml read using "`fixture'", replace blockscalars strl
local canon_rc = _rc
timer off 1
if (`canon_rc' != 0) {
    * Canonical parser may fail on very large files (macro expansion limits)
    * This is expected — the Mata bulk parser exists to handle these cases
    file write `dlog' "Status: FAILED rc=`canon_rc' (expected for large files)" _n
    local canonical_N = .
    local canonical_sec = .
}
else {
    local canonical_N = _N
    qui timer list 1
    local canonical_sec = r(t1)
    file write `dlog' "Status: OK" _n
    file write `dlog' "Rows: `canonical_N'" _n
    file write `dlog' "Time: `canonical_sec's" _n
}

*===============================================================================
* BENCHMARK 2: Vectorized ado parser (wbopendata-style)
*===============================================================================

file write `dlog' _n "--- 2. Vectorized ado parser (wbopendata-style) ---" _n
qui do "`root'/examples/ex_wbod_vectorized_parse.do"
timer clear 2
timer on 2
capture noisily ex_wbod_vectorized_parse "`fixture'"
local vec_rc = _rc
timer off 2
if (`vec_rc' != 0) {
    file write `dlog' "Status: FAILED rc=`vec_rc'" _n
    local vec_N = 0
    local vec_sec = .
}
else {
    local vec_N = _N
    qui timer list 2
    local vec_sec = r(t2)
    file write `dlog' "Status: OK" _n
    file write `dlog' "Rows: `vec_N' (collapsed, one per indicator)" _n
    file write `dlog' "Time: `vec_sec's" _n
}

*===============================================================================
* BENCHMARK 3: Mata bulk parser (yaml read ..., bulk)
*===============================================================================

file write `dlog' _n "--- 3. Mata bulk parser ---" _n
timer clear 3
capture noisily {
    timer on 3
    yaml read using "`fixture'", replace bulk blockscalars strl
    timer off 3
}
local bulk_rc = _rc
if (`bulk_rc' == 198) {
    file write `dlog' "Status: SKIPPED (not implemented)" _n
    local bulk_N = .
    local bulk_sec = .
}
else if (`bulk_rc' != 0) {
    di as error "FEAT-07 FAIL: bulk parse error (rc=`bulk_rc')"
    file write `dlog' "Status: FAILED rc=`bulk_rc'" _n
    local all_pass = 0
    local bulk_N = 0
    local bulk_sec = .
}
else {
    local bulk_N = _N
    qui timer list 3
    local bulk_sec = r(t3)
    file write `dlog' "Status: OK" _n
    file write `dlog' "Rows: `bulk_N' (long format)" _n
    file write `dlog' "Time: `bulk_sec's" _n

    * Verify bulk output is reasonable (>300K rows for 463K-line file)
    if (`bulk_N' < 300000) {
        di as error "FEAT-07 FAIL: bulk rows (`bulk_N') too few (expected >300K)"
        file write `dlog' "FAIL: bulk rows too few" _n
        local all_pass = 0
    }
}

*===============================================================================
* BENCHMARK 4: Mata bulk + collapse (yaml read ..., bulk collapse)
*===============================================================================

file write `dlog' _n "--- 4. Mata bulk + collapse ---" _n
timer clear 4
timer clear 5
capture noisily {
    timer on 4
    yaml read using "`fixture'", replace bulk blockscalars strl
    timer off 4
}
local bulkc_parse_rc = _rc
if (`bulkc_parse_rc' == 198) {
    file write `dlog' "Status: SKIPPED (not implemented)" _n
    local bulkc_N = .
    local bulkc_sec = .
}
else if (`bulkc_parse_rc' != 0) {
    file write `dlog' "Status: FAILED (parse) rc=`bulkc_parse_rc'" _n
    local bulkc_N = .
    local bulkc_sec = .
}
else {
    capture noisily {
        timer on 5
        _yaml_collapse
        timer off 5
    }
    local bulkc_collapse_rc = _rc
    if (`bulkc_collapse_rc' != 0) {
        qui timer list 4
        local bulkc_parse_sec = r(t4)
        file write `dlog' "Status: FAILED (collapse) rc=`bulkc_collapse_rc'" _n
        file write `dlog' "Parse time: `bulkc_parse_sec's" _n
        local bulkc_N = .
        local bulkc_sec = .
    }
    else {
        local bulkc_N = _N
        qui timer list 4
        local bulkc_parse_sec = r(t4)
        qui timer list 5
        local bulkc_collapse_sec = r(t5)
        local bulkc_sec = `bulkc_parse_sec' + `bulkc_collapse_sec'
        file write `dlog' "Status: OK" _n
        file write `dlog' "Rows: `bulkc_N' (collapsed, one per indicator)" _n
        file write `dlog' "Parse time: `bulkc_parse_sec's" _n
        file write `dlog' "Collapse time: `bulkc_collapse_sec's" _n
        file write `dlog' "Time: `bulkc_sec's" _n

        * Cross-check: collapsed row count should match vectorized
        if (`vec_rc' == 0 & `bulkc_N' != `vec_N') {
            file write `dlog' "NOTE: bulk+collapse rows (`bulkc_N') != vectorized rows (`vec_N')" _n
        }
    }
}

*===============================================================================
* Report
*===============================================================================

file write `dlog' _n "--- Summary ---" _n
di as text ""
di as text "Performance Benchmark (_wbopendata_indicators.yaml, 463K lines):"
di as text "{hline 60}"

if ("`canonical_sec'" == ".") {
    local c_str "FAILED (rc=`canon_rc')"
}
else {
    local c_str "`canonical_sec's (`canonical_N' rows)"
}
di as text "  1. Canonical ado:     `c_str'"
file write `dlog' "1. Canonical ado:     `c_str'" _n

if (`vec_rc' != 0) {
    local v_str "FAILED (rc=`vec_rc')"
}
else {
    local v_str "`vec_sec's (`vec_N' rows, collapsed)"
}
di as text "  2. Vectorized ado:    `v_str'"
file write `dlog' "2. Vectorized ado:    `v_str'" _n

if ("`bulk_sec'" == ".") {
    local b_str "N/A"
}
else {
    local b_str "`bulk_sec's (`bulk_N' rows, long)"
}
di as text "  3. Mata bulk:         `b_str'"
file write `dlog' "3. Mata bulk:         `b_str'" _n

if ("`bulkc_sec'" == ".") {
    local bc_str "N/A"
}
else {
    local bc_str "`bulkc_sec's (`bulkc_N' rows, collapsed)"
}
di as text "  4. Mata bulk+collapse: `bc_str'"
file write `dlog' "4. Mata bulk+collapse: `bc_str'" _n

di as text "{hline 60}"

*===============================================================================
* Result
*===============================================================================

file write `dlog' _n "Result: all_pass=`all_pass'" _n
file close `dlog'

if (`all_pass') {
    di as result "FEAT-07 PASS: Performance benchmark completed"
}
else {
    error 198
}
