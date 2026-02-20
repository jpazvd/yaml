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
    di as error "FEAT-07 FAIL: canonical parse error (rc=`canon_rc')"
    file write `dlog' "Canonical: FAILED rc=`canon_rc'" _n
    local all_pass = 0
    local canonical_N = 0
    local canonical_sec = .
}
else {
    local canonical_N = _N
    qui timer list 1
    local canonical_sec = r(t1)
    file write `dlog' "Canonical: OK rows=`canonical_N' time=`canonical_sec's" _n

    * Save canonical dataset for comparison
    tempfile canon_data
    qui save "`canon_data'"
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

    * Verify row count matches canonical
    if (`bulk_N' != `canonical_N') {
        di as error "FEAT-07 FAIL: bulk rows (`bulk_N') != canonical rows (`canonical_N')"
        file write `dlog' "MISMATCH: bulk=`bulk_N' canonical=`canonical_N'" _n
        local all_pass = 0

        * Lightweight tail comparison (no row-by-row loops)
        if (`canon_rc' == 0) {
            * Show last key from bulk (already in memory)
            local bk_last = key[_N]
            local bt_last = type[_N]
            file write `dlog' "Bulk last row: key=[`bk_last'] type=[`bt_last']" _n

            * Show last key from canonical
            qui use "`canon_data'", clear
            local ck_last = key[_N]
            local ct_last = type[_N]
            file write `dlog' "Canon last row: key=[`ck_last'] type=[`ct_last']" _n
        }
    }
}

*===============================================================================
* Report
*===============================================================================

di as text ""
di as text "Performance Results (_wbopendata_indicators.yaml):"
di as text "  Canonical: `canonical_sec's (`canonical_N' rows)"
if ("`bulk_sec'" != ".") {
    di as text "  Bulk:      `bulk_sec's (`bulk_N' rows)"
    if (`canonical_sec' > 0 & `bulk_sec' > 0) {
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
