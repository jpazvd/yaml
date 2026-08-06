*! test_bug3_frame_returns.do
*! Regression test for BUG-3 (return add in frame context)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

*===============================================================================
* Skip if Stata < 16 (frames not available)
*===============================================================================

if (`c(stata_version)' < 16) {
    di as text "SKIP: BUG-3 tests require Stata 16+ (frames)"
    exit
}

*===============================================================================
* Setup: Read YAML into frame
*===============================================================================

yaml read using "`root'/examples/data/test_config.yaml", frame(cfg)

local all_pass = 1

*===============================================================================
* TEST 1: yaml get returns r(found) from frame context
*===============================================================================

yaml get indicators:CME_MRY0T4, frame(cfg)

if (r(found) != 1) {
    di as error "BUG-3 FAIL: yaml get from frame: r(found) = `r(found)', expected 1"
    local all_pass = 0
}
else {
    di as result "BUG-3 PASS: yaml get from frame returns r(found) = 1"
}

*===============================================================================
* TEST 2: yaml get returns attribute values from frame context
*===============================================================================

yaml get indicators:CME_MRY0T4, frame(cfg)
local label_val "`r(label)'"

if ("`label_val'" == "") {
    di as error "BUG-3 FAIL: yaml get from frame: r(label) is empty"
    local all_pass = 0
}
else {
    di as result "BUG-3 PASS: yaml get from frame returns r(label) = `label_val'"
}

*===============================================================================
* TEST 3: yaml list returns r(keys) from frame context
*===============================================================================

yaml list indicators, frame(cfg) keys children

local keys_val `"`r(keys)'"'

if (`"`keys_val'"' == "") {
    di as error "BUG-3 FAIL: yaml list from frame: r(keys) is empty"
    local all_pass = 0
}
else {
    di as result "BUG-3 PASS: yaml list from frame returns r(keys) = `keys_val'"
}

*===============================================================================
* Cleanup and result
*===============================================================================

yaml clear, all

if (`all_pass') {
    di as result "ALL BUG-3 TESTS PASSED"
}
else {
    error 198
}
