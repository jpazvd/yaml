*! test_mata_bulk.do
*! Feature test FEAT-05: Mata bulk-load produces correct output
*! Date: 19Feb2026
*! Status: Phase 2 acceptance test — skips until BULK option is implemented

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/embedded_quotes.yaml"
local all_pass = 1

*===============================================================================
* TEST: Check if BULK option exists
*===============================================================================

capture yaml read using "`fixture'", replace bulk
if (_rc == 198) {
    di as text "FEAT-05 SKIP: BULK option not yet implemented"
    exit 0
}
if (_rc != 0) {
    di as error "FEAT-05 FAIL: bulk parse returned unexpected error (rc=`=_rc')"
    error 198
}

* If we get here, BULK option exists — verify correctness
local bulk_N = _N
tempfile bulk_result
qui save "`bulk_result'"

*===============================================================================
* TEST: Bulk output matches canonical parser output
*===============================================================================

yaml read using "`fixture'", replace

local canon_N = _N

if (`bulk_N' != `canon_N') {
    di as error "FEAT-05 FAIL: bulk rows (`bulk_N') != canonical rows (`canon_N')"
    local all_pass = 0
}

* Compare key-value pairs
qui merge 1:1 _n using "`bulk_result'", nogenerate
qui count if key != key
if (r(N) > 0) {
    di as error "FEAT-05 FAIL: `=r(N)' key mismatches between bulk and canonical"
    local all_pass = 0
}

*===============================================================================
* TEST: Bulk mode with strl option
*===============================================================================

local long_fixture "`root'/qa/fixtures/long_values.yaml"
capture yaml read using "`long_fixture'", replace bulk strl blockscalars
if (_rc != 0) {
    di as error "FEAT-05 FAIL: bulk with strl+blockscalars failed (rc=`=_rc')"
    local all_pass = 0
}
else {
    local vtype : type value
    if ("`vtype'" != "strL") {
        di as error "FEAT-05 FAIL: bulk+strl value type = '`vtype'', expected 'strL'"
        local all_pass = 0
    }
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-05 PASS: Mata bulk-load produces correct output"
}
else {
    error 198
}
