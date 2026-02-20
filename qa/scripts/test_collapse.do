*! test_collapse.do
*! Feature test FEAT-06: collapse option produces wide-format output
*! Date: 19Feb2026
*! Status: Phase 2 acceptance test — skips until COLLAPSE option is implemented

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/collapse_test.yaml"
local all_pass = 1

*===============================================================================
* TEST: Check if COLLAPSE option exists
*===============================================================================

capture yaml read using "`fixture'", replace blockscalars collapse
if (_rc == 198) {
    di as text "FEAT-06 SKIP: COLLAPSE option not yet implemented"
    exit 0
}
if (_rc != 0) {
    di as error "FEAT-06 FAIL: collapse parse returned unexpected error (rc=`=_rc')"
    error 198
}

*===============================================================================
* TEST: Output should have one row per indicator (3 indicators in fixture)
*===============================================================================

qui count
if (r(N) != 3) {
    di as error "FEAT-06 FAIL: expected 3 rows (one per indicator), got `=r(N)'"
    local all_pass = 0
}

*===============================================================================
* TEST: Output should have named columns from YAML fields
*===============================================================================

* Check that key columns exist
capture confirm variable ind_code
if (_rc != 0) {
    * Try alternative column name
    capture confirm variable key
    if (_rc != 0) {
        di as error "FEAT-06 FAIL: no indicator code column found (ind_code or key)"
        local all_pass = 0
    }
}

* Check that field columns exist (name, unit, source_id, description)
foreach col in name unit source_id description {
    capture confirm variable `col'
    if (_rc != 0) {
        * Try prefixed version
        capture confirm variable field_`col'
        if (_rc != 0) {
            di as error "FEAT-06 FAIL: field column '`col'' (or 'field_`col'') not found"
            local all_pass = 0
        }
    }
}

*===============================================================================
* TEST: Values should be correct
*===============================================================================

* Find the name column (could be 'name' or 'field_name')
local namecol ""
capture confirm variable name
if (_rc == 0) local namecol "name"
else {
    capture confirm variable field_name
    if (_rc == 0) local namecol "field_name"
}

if ("`namecol'" != "") {
    * Check that SP_POP_TOTL has correct name
    capture confirm variable ind_code
    if (_rc == 0) {
        qui count if ind_code == "SP_POP_TOTL" & `namecol' == "Population total"
    }
    else {
        qui count if key == "SP_POP_TOTL" & `namecol' == "Population total"
    }
    if (r(N) != 1) {
        di as error "FEAT-06 FAIL: SP_POP_TOTL name mismatch"
        local all_pass = 0
    }
}

*===============================================================================
* TEST: Block scalar descriptions should be folded into single values
*===============================================================================

local desccol ""
capture confirm variable description
if (_rc == 0) local desccol "description"
else {
    capture confirm variable field_description
    if (_rc == 0) local desccol "field_description"
}

if ("`desccol'" != "") {
    qui levelsof `desccol' if inlist(ind_code, "SP_POP_TOTL") | ///
        inlist(key, "SP_POP_TOTL"), local(v) clean
    if (strpos(`"`v'"', "de facto") == 0) {
        di as error "FEAT-06 FAIL: collapsed description missing expected text"
        local all_pass = 0
    }
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-06 PASS: collapse produces correct wide-format output"
}
else {
    error 198
}
