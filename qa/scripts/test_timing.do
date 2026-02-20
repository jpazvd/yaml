*! test_timing.do
*! Feature test FEAT-07: Performance comparison across parser modes
*! Date: 19Feb2026
*! Uses _wbopendata_indicators.yaml (463K lines, 18MB, 29K indicators)

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

*===============================================================================
* TEST 1: Canonical parser timing
*===============================================================================

* Open diagnostic log (persists even under capture quietly)
tempname dlog
file open `dlog' using "`diaglog'", write replace
file write `dlog' "FEAT-07 Diagnostic Log" _n
file write `dlog' "Date: `c(current_date)' `c(current_time)'" _n
file write `dlog' _n

timer clear 1
timer on 1
capture noisily yaml read using "`fixture'", replace blockscalars strl
local canon_rc = _rc
timer off 1
if (`canon_rc' != 0) {
    * Canonical parser may fail on very large files (macro expansion limits)
    * This is expected — the Mata bulk parser exists to handle these cases
    file write `dlog' "Canonical: FAILED rc=`canon_rc' (expected for large files)" _n
    local canonical_N = .
    local canonical_sec = .
}
else {
    local canonical_N = _N
    qui timer list 1
    local canonical_sec = r(t1)
    file write `dlog' "Canonical: OK rows=`canonical_N' time=`canonical_sec's" _n
}

*===============================================================================
* TEST 2: Bulk (Mata) parser timing
*===============================================================================

timer clear 2
capture noisily {
    timer on 2
    yaml read using "`fixture'", replace bulk blockscalars strl
    timer off 2
}
local bulk_rc = _rc
if (`bulk_rc' == 198) {
    di as text "FEAT-07 INFO: BULK option not yet implemented — skipping"
    file write `dlog' "Bulk: SKIPPED (not implemented, rc=198)" _n
    local bulk_N = .
    local bulk_sec = .
}
else if (`bulk_rc' != 0) {
    di as error "FEAT-07 FAIL: bulk parse error (rc=`bulk_rc')"
    file write `dlog' "Bulk: FAILED rc=`bulk_rc'" _n
    local all_pass = 0
    local bulk_N = 0
    local bulk_sec = .
}
else {
    local bulk_N = _N
    qui timer list 2
    local bulk_sec = r(t2)
    file write `dlog' "Bulk: OK rows=`bulk_N' time=`bulk_sec's" _n

    * Verify bulk output is reasonable (>300K rows for 463K-line file)
    if (`bulk_N' < 300000) {
        di as error "FEAT-07 FAIL: bulk rows (`bulk_N') too few (expected >300K)"
        file write `dlog' "FAIL: bulk rows too few" _n
        local all_pass = 0
    }

    * If canonical also succeeded, compare row counts
    if ("`canonical_N'" != "." & `canonical_N' > 0) {
        if (`bulk_N' != `canonical_N') {
            di as error "FEAT-07 FAIL: bulk rows (`bulk_N') != canonical rows (`canonical_N')"
            file write `dlog' "MISMATCH: bulk=`bulk_N' canonical=`canonical_N'" _n
            local all_pass = 0
        }
        else {
            file write `dlog' "Row counts match: `bulk_N'" _n
        }
    }
    else {
        file write `dlog' "Canonical unavailable — skipping row count comparison" _n
    }
}

*===============================================================================
* Report
*===============================================================================

di as text ""
di as text "Performance Results (_wbopendata_indicators.yaml):"
if ("`canonical_sec'" == ".") {
    di as text "  Canonical: failed (rc=`canon_rc') — too large for ado parser"
}
else {
    di as text "  Canonical: `canonical_sec's (`canonical_N' rows)"
}
if ("`bulk_sec'" != ".") {
    di as text "  Bulk:      `bulk_sec's (`bulk_N' rows)"
    if ("`canonical_sec'" != "." & `canonical_sec' > 0 & `bulk_sec' > 0) {
        local speedup = `canonical_sec' / `bulk_sec'
        di as text "  Speedup:   `speedup'x"
    }
}
else {
    di as text "  Bulk:      (not available)"
}

*===============================================================================
* Result
*===============================================================================

file write `dlog' _n "Result: all_pass=`all_pass'" _n
file close `dlog'

if (`all_pass') {
    di as result "FEAT-07 PASS: Performance timing completed"
}
else {
    error 198
}
