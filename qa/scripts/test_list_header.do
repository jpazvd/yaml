*! test_list_header.do
*! Regression test REG-08: yaml list header displays correctly with parent filter (BUG-8)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local all_pass = 1

*===============================================================================
* Setup: Read YAML with nested structure
*===============================================================================

yaml read using "`root'/examples/data/test_config.yaml", replace

*===============================================================================
* TEST 1: yaml list with parent filter should not error
*   Before BUG-8, the header only displayed when i==1, which fails when
*   filtering skips observation 1.
*===============================================================================

capture noisily yaml list api, keys values children
if (_rc != 0) {
    di as error "REG-08 FAIL: yaml list api failed (rc=`=_rc')"
    local all_pass = 0
}

*===============================================================================
* TEST 2: yaml list with a parent deeper in the dataset
*   "settings" is not the first key, so filtering definitely skips obs 1
*===============================================================================

capture noisily yaml list settings, keys values children
if (_rc != 0) {
    di as error "REG-08 FAIL: yaml list settings failed (rc=`=_rc')"
    local all_pass = 0
}

*===============================================================================
* TEST 3: yaml list without filter should still work (baseline)
*===============================================================================

capture noisily yaml list, keys values
if (_rc != 0) {
    di as error "REG-08 FAIL: yaml list (unfiltered) failed (rc=`=_rc')"
    local all_pass = 0
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "REG-08 PASS: yaml list header displays correctly with parent filter"
}
else {
    error 198
}
