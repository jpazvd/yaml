*! test_strl_option.do
*! Feature test FEAT-04: strL option prevents value truncation
*! Date: 19Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/long_values.yaml"
local all_pass = 1

*===============================================================================
* TEST: Without strl, value column is str2000 (default)
*===============================================================================

yaml read using "`fixture'", replace blockscalars

* Check that value variable type is NOT strL (should be strNNN after compress)
local vtype : type value
if ("`vtype'" == "strL") {
    di as error "FEAT-04 FAIL: default (no strl) should not produce strL, got '`vtype''"
    local all_pass = 0
}
else {
    di as text "FEAT-04 CHECK: default value type is `vtype' (not strL, correct)"
}

*===============================================================================
* TEST: With strl, value column is strL and long values are not truncated
*===============================================================================

yaml read using "`fixture'", replace blockscalars strl

* Check that value variable type is strL
local vtype : type value
if ("`vtype'" != "strL") {
    di as error "FEAT-04 FAIL: strl value type = '`vtype'', expected 'strL'"
    local all_pass = 0
}
else {
    di as text "FEAT-04 CHECK: strl value type is strL (correct)"
}

* Check that the long description is not truncated
qui count if key == "metadata_indicator_description"
if (r(N) != 1) {
    di as error "FEAT-04 FAIL: key 'metadata_indicator_description' not found"
    local all_pass = 0
}
else {
    * The description in the fixture is >2000 chars when joined
    qui gen long vlen = length(value) if key == "metadata_indicator_description"
    qui sum vlen, meanonly
    local desc_len = r(mean)
    drop vlen
    * Should contain the end marker text
    qui levelsof value if key == "metadata_indicator_description", local(v) clean
    if (strpos(`"`v'"', "End of description.") == 0) {
        di as error "FEAT-04 FAIL: long description truncated (missing end marker)"
        di as error "  Length: `desc_len' characters"
        local all_pass = 0
    }
    else {
        di as text "FEAT-04 CHECK: long description preserved (`desc_len' chars)"
    }
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-04 PASS: strL option prevents truncation"
}
else {
    error 198
}
