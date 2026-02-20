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

timer clear 1
timer on 1
capture noisily yaml read using "`fixture'", replace blockscalars strl
timer off 1
if (_rc != 0) {
    di as error "FEAT-07 FAIL: canonical parse error (rc=`=_rc')"
    local all_pass = 0
    local canonical_N = 0
    local canonical_sec = .
}
else {
    local canonical_N = _N
    qui timer list 1
    local canonical_sec = r(t1)
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
if (_rc == 198) {
    di as text "FEAT-07 INFO: BULK option not yet implemented — skipping"
    local bulk_N = .
    local bulk_sec = .
}
else if (_rc != 0) {
    di as error "FEAT-07 FAIL: bulk parse error (rc=`=_rc')"
    local all_pass = 0
    local bulk_N = 0
    local bulk_sec = .
}
else {
    local bulk_N = _N
    qui timer list 2
    local bulk_sec = r(t2)
    * Verify row count matches canonical
    if (`bulk_N' != `canonical_N') {
        di as error "FEAT-07 FAIL: bulk rows (`bulk_N') != canonical rows (`canonical_N')"
        local all_pass = 0
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

if (`all_pass') {
    di as result "FEAT-07 PASS: Performance timing completed"
}
else {
    error 198
}
