*! test_embedded_quotes.do
*! Feature test FEAT-01: Mata st_sstore handles embedded double quotes
*! Date: 19Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/embedded_quotes.yaml"
local all_pass = 1

*===============================================================================
* TEST: Canonical parser handles embedded double quotes via st_sstore
*===============================================================================

yaml read using "`fixture'", replace

* Should have parsed without r(132)
qui count
if (r(N) < 4) {
    di as error "FEAT-01 FAIL: expected at least 4 rows, got `=r(N)'"
    local all_pass = 0
}

* Check value with embedded double quotes
qui count if key == "indicators_SP_POP_TOTL_source_org"
if (r(N) != 1) {
    di as error "FEAT-01 FAIL: key 'indicators_SP_POP_TOTL_source_org' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_SP_POP_TOTL_source_org", local(v) clean
    * Value should contain the word "Out of School" with embedded quotes
    if (strpos(`"`v'"', "Out of School") == 0) {
        di as error `"FEAT-01 FAIL: source_org missing 'Out of School': `v'"'
        local all_pass = 0
    }
}

* Check another value with embedded quotes
qui count if key == "indicators_SP_POP_TOTL_note"
if (r(N) != 1) {
    di as error "FEAT-01 FAIL: key 'indicators_SP_POP_TOTL_note' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_SP_POP_TOTL_note", local(v) clean
    if (strpos(`"`v'"', "estimates") == 0) {
        di as error `"FEAT-01 FAIL: note missing 'estimates': `v'"'
        local all_pass = 0
    }
}

* Check UNESCO "UIS" value
qui count if key == "indicators_SE_PRE_ENRR_source_org"
if (r(N) != 1) {
    di as error "FEAT-01 FAIL: key 'indicators_SE_PRE_ENRR_source_org' not found"
    local all_pass = 0
}

*===============================================================================
* TEST: Fastread parser handles embedded double quotes
*===============================================================================

yaml read using "`fixture'", replace fastread

qui count
if (r(N) < 4) {
    di as error "FEAT-01 FAIL: fastread expected at least 4 rows, got `=r(N)'"
    local all_pass = 0
}

* Check fastread value with embedded quotes
qui count if key == "SP_POP_TOTL" & field == "source_org"
if (r(N) != 1) {
    di as error "FEAT-01 FAIL: fastread key 'SP_POP_TOTL' field 'source_org' not found"
    local all_pass = 0
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-01 PASS: embedded double quotes handled correctly"
}
else {
    error 198
}
