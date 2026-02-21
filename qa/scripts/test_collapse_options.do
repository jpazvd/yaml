*! test_collapse_options.do
*! Feature tests FEAT-09 and FEAT-10: colfields() and maxlevel() collapse options
*! Date: 20Feb2026
*! Status: Tests for v1.8.0 selective collapse features

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/collapse_colfields_test.yaml"
local all_pass = 1
local test_count = 0
local pass_count = 0

*===============================================================================
* Helper macro for test results
*===============================================================================

capture program drop test_result
program define test_result
    syntax, id(string) desc(string) result(string) [msg(string)]
    if "`result'" == "pass" {
        di as result "[PASS] `id': `desc'"
    }
    else if "`result'" == "fail" {
        di as error "[FAIL] `id': `desc'"
        if "`msg'" != "" {
            di as error "       `msg'"
        }
    }
    else if "`result'" == "skip" {
        di as text "[SKIP] `id': `desc'"
    }
end

di as text _n "{hline 70}"
di as text "YAML v1.8.0 Collapse Options Tests"
di as text "{hline 70}" _n

*===============================================================================
* TEST 1: Baseline collapse (no options) - should have many columns
*===============================================================================

local ++test_count
di as text _n "TEST 1: Baseline collapse without options"

qui yaml read using "`fixture'", replace bulk collapse

qui describe, short
local ncols_baseline = r(k)

if (`ncols_baseline' > 10) {
    test_result, id("T1") desc("Baseline collapse produces many columns") result("pass")
    di as text "       `ncols_baseline' columns created"
    local ++pass_count
}
else {
    test_result, id("T1") desc("Baseline collapse produces many columns") result("fail") ///
        msg("Expected >10 columns, got `ncols_baseline'")
    local all_pass = 0
}

*===============================================================================
* TEST 2: colfields() - filter to specific columns
*===============================================================================

local ++test_count
di as text _n "TEST 2: colfields() option - select specific fields"

* Should keep only: code, name, source_id (plus entity key)
qui yaml read using "`fixture'", replace bulk collapse colfields(code;name;source_id)

qui describe, short
local ncols_filtered = r(k)

* Should have far fewer columns now
if (`ncols_filtered' <= 5) {
    test_result, id("T2a") desc("colfields() reduces column count") result("pass")
    di as text "        Filtered to `ncols_filtered' columns (from `ncols_baseline')"
    local ++pass_count
}
else {
    test_result, id("T2a") desc("colfields() reduces column count") result("fail") ///
        msg("Expected <=5 columns, got `ncols_filtered'")
    local all_pass = 0
}

* Check that specified columns exist
local expected_cols "code name source_id"
local missing_cols ""
foreach col of local expected_cols {
    capture confirm variable `col'
    if (_rc != 0) {
        local missing_cols "`missing_cols' `col'"
    }
}

if ("`missing_cols'" == "") {
    test_result, id("T2b") desc("Specified colfields exist") result("pass")
    local ++pass_count
}
else {
    test_result, id("T2b") desc("Specified colfields exist") result("fail") ///
        msg("Missing columns:`missing_cols'")
    ds
    local all_pass = 0
}

*===============================================================================
* TEST 3: maxlevel() - limit column depth
*===============================================================================

local ++test_count
di as text _n "TEST 3: maxlevel() option - limit by underscore depth"

* maxlevel(1) should only keep columns with NO underscores in the field part
* (e.g., 'indicators_EDU_PRIMARY_code' has 'code' as the field, depth=1 since no underscore)

qui yaml read using "`fixture'", replace bulk collapse maxlevel(1)

qui describe, short
local ncols_level1 = r(k)

di as text "       maxlevel(1): `ncols_level1' columns"

* Check that we don't have topic_ids_1, topic_ids_2, etc. (these are depth > 1)
capture confirm variable topic_ids_1
local has_nested = (_rc == 0)

if (!`has_nested') {
    test_result, id("T3a") desc("maxlevel(1) excludes nested arrays") result("pass")
    local ++pass_count
}
else {
    test_result, id("T3a") desc("maxlevel(1) excludes nested arrays") result("fail") ///
        msg("topic_ids_1 should not exist at maxlevel(1)")
    local all_pass = 0
}

*===============================================================================
* TEST 4: maxlevel(2) - allows one underscore in field name
*===============================================================================

local ++test_count
di as text _n "TEST 4: maxlevel(2) - allows one underscore in field name"

qui yaml read using "`fixture'", replace bulk collapse maxlevel(2)

qui describe, short
local ncols_level2 = r(k)

di as text "       maxlevel(2): `ncols_level2' columns"

* source_id and source_name should be included (one underscore = level 2)
capture confirm variable source_id
local has_source_id = (_rc == 0)

capture confirm variable source_name
local has_source_name = (_rc == 0)

if (`has_source_id' & `has_source_name') {
    test_result, id("T4") desc("maxlevel(2) includes compound field names") result("pass")
    local ++pass_count
}
else {
    test_result, id("T4") desc("maxlevel(2) includes compound field names") result("fail") ///
        msg("source_id or source_name missing at maxlevel(2)")
    ds
    local all_pass = 0
}

*===============================================================================
* TEST 5: Combined colfields + maxlevel (both options together)
*===============================================================================

local ++test_count
di as text _n "TEST 5: Combined colfields() and maxlevel()"

* This should apply both filters - colfields takes precedence for explicit selection,
* but maxlevel could further filter if needed in user's workflow

qui yaml read using "`fixture'", replace bulk collapse colfields(code;name;description) maxlevel(3)

qui describe, short
local ncols_combined = r(k)

* Should have the colfields columns
capture confirm variable code
local has_code = (_rc == 0)
capture confirm variable name
local has_name = (_rc == 0)
capture confirm variable description
local has_desc = (_rc == 0)

if (`has_code' & `has_name' & `has_desc') {
    test_result, id("T5") desc("Combined options work together") result("pass")
    di as text "       Combined: `ncols_combined' columns"
    local ++pass_count
}
else {
    test_result, id("T5") desc("Combined options work together") result("fail")
    ds
    local all_pass = 0
}

*===============================================================================
* TEST 6: colfields() case sensitivity (exact match required)
*===============================================================================

local ++test_count
di as text _n "TEST 6: colfields() exact match (case sensitivity)"

* 'CODE' instead of 'code' - should not match, producing empty or no dataset
capture noisily yaml read using "`fixture'", replace bulk collapse colfields(CODE;NAME)
local case_rc = _rc

* If no fields match, we expect either error or empty dataset
if (`case_rc' != 0) {
    test_result, id("T6") desc("colfields() requires exact case match") result("pass")
    di as text "       Case mismatch correctly produced error/empty result"
    local ++pass_count
}
else {
    * If call succeeded, check that wrong-case fields are not present
    capture confirm variable code
    local has_code_exact = (_rc == 0)
    
    if (!`has_code_exact') {
        test_result, id("T6") desc("colfields() requires exact case match") result("pass")
        di as text "       'CODE' did not match 'code' (case sensitive)"
        local ++pass_count  
    }
    else {
        test_result, id("T6") desc("colfields() requires exact case match") result("fail") ///
            msg("Expected case-sensitive matching but 'code' was found")
        local all_pass = 0
    }
}

*===============================================================================
* TEST 7: Validate row count preserved across all modes
*===============================================================================

local ++test_count
di as text _n "TEST 7: Row count preserved across all modes"

* All modes should produce same number of rows (one per indicator)
local expected_rows = 3

* Test each mode
local modes_ok = 1
foreach mode in "collapse" "collapse colfields(code)" "collapse maxlevel(1)" {
    qui yaml read using "`fixture'", replace bulk `mode'
    qui count
    if (r(N) != `expected_rows') {
        di as error "       Mode '`mode'': expected `expected_rows' rows, got `r(N)'"
        local modes_ok = 0
    }
}

if (`modes_ok') {
    test_result, id("T7") desc("Row count preserved across modes") result("pass")
    local ++pass_count
}
else {
    test_result, id("T7") desc("Row count preserved across modes") result("fail")
    local all_pass = 0
}

*===============================================================================
* Summary
*===============================================================================

di as text _n "{hline 70}"
di as text "RESULTS: `pass_count'/`test_count' tests passed"
di as text "{hline 70}"

if (!`all_pass') {
    di as error "Some tests failed"
    error 198
}
else {
    di as result "All tests passed"
    exit 0
}
