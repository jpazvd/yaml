*! test_continuation_lines.do
*! Feature test FEAT-03: continuation lines for multi-line plain scalars
*! Date: 19Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/continuation_lines.yaml"
local all_pass = 1

*===============================================================================
* TEST: Canonical parser joins continuation lines with spaces
*===============================================================================

yaml read using "`fixture'", replace

qui count
if (r(N) < 4) {
    di as error "FEAT-03 FAIL: expected at least 4 rows, got `=r(N)'"
    local all_pass = 0
}

* Check that multi-line name is fully joined
qui count if key == "indicators_CME_MRY0T4_name"
if (r(N) != 1) {
    di as error "FEAT-03 FAIL: key 'indicators_CME_MRY0T4_name' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_CME_MRY0T4_name", local(v) clean
    * Should contain text from first line
    if (strpos(`"`v'"', "Under-five mortality rate") == 0) {
        di as error `"FEAT-03 FAIL: name missing first line text: `v'"'
        local all_pass = 0
    }
    * Should contain text from continuation lines
    if (strpos(`"`v'"', "live births)") == 0) {
        di as error `"FEAT-03 FAIL: name missing continuation text: `v'"'
        local all_pass = 0
    }
    * Should contain text from middle continuation line
    if (strpos(`"`v'"', "between birth and exact age 5") == 0) {
        di as error `"FEAT-03 FAIL: name missing middle continuation: `v'"'
        local all_pass = 0
    }
}

* Check that the next field after continuation is parsed correctly
qui count if key == "indicators_CME_MRY0T4_unit"
if (r(N) != 1) {
    di as error "FEAT-03 FAIL: key 'indicators_CME_MRY0T4_unit' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_CME_MRY0T4_unit", local(v) clean
    if ("`v'" != "per 1,000 live births") {
        di as error "FEAT-03 FAIL: unit = '`v'', expected 'per 1,000 live births'"
        local all_pass = 0
    }
}

* Check second indicator also parsed correctly
qui count if key == "indicators_NT_ANT_HAZ_name"
if (r(N) != 1) {
    di as error "FEAT-03 FAIL: key 'indicators_NT_ANT_HAZ_name' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_NT_ANT_HAZ_name", local(v) clean
    if (strpos(`"`v'"', "Prevalence of stunting") == 0) {
        di as error `"FEAT-03 FAIL: second indicator name missing text: `v'"'
        local all_pass = 0
    }
    if (strpos(`"`v'"', "5 years of age") == 0) {
        di as error `"FEAT-03 FAIL: second indicator continuation missing: `v'"'
        local all_pass = 0
    }
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-03 PASS: continuation lines joined correctly"
}
else {
    error 198
}
