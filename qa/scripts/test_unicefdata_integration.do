*! test_unicefdata_integration.do
*! Integration smoke test: yaml.ado → unicefdata cache → indicator lookup
*! Date: 21Feb2026
*! Purpose: Verify yaml.ado works correctly with unicefdata-dev v2 parser

clear all
set more off

local all_pass = 1

* Absolute paths to source directories
local yaml_dev_src "C:/GitHub/myados/yaml-dev/src"
local unicef_src "C:/GitHub/myados/unicefdata-dev/stata/src"
local yaml_file "`unicef_src'/_/_unicefdata_indicators_metadata.yaml"

* Check if unicefdata-dev exists
capture confirm file "`yaml_file'"
if (_rc != 0) {
    di as text "SKIP: unicefdata-dev not found at expected location"
    di as text "      Expected: `yaml_file'"
    exit 0
}

*===============================================================================
* SETUP: Add required adopaths
*===============================================================================

di as text _n "{hline 70}"
di as result "Integration Test: yaml.ado → unicefdata cache pipeline"
di as text "{hline 70}"

* Use yaml-dev source (this repo)
adopath ++ "`yaml_dev_src'/y"
adopath ++ "`yaml_dev_src'/_"

* Add unicefdata-dev paths
adopath ++ "`unicef_src'/y"
adopath ++ "`unicef_src'/_"

*===============================================================================
* TEST 1: Direct yaml read with unicefdata-specific colfields
*===============================================================================

di as text _n "TEST 1: Direct yaml read with UNICEF colfields"

timer clear 1
timer on 1
capture noisily {
    yaml read using "`yaml_file'", ///
        bulk collapse replace ///
        colfields(code;name;description;urn;parent;tier;tier_reason)
}
local rc1 = _rc
timer off 1

if (`rc1' == 0) {
    qui timer list 1
    local t1 = r(t1)
    local n1 = _N
    
    * Check expected columns exist
    local cols_ok = 1
    foreach col in ind_code name description {
        capture confirm variable `col'
        if (_rc != 0) {
            di as error "  FAIL: Missing expected column '`col''"
            local cols_ok = 0
        }
    }
    
    if (`cols_ok' & `n1' > 700) {
        di as result "  PASS: yaml read OK (`n1' indicators in `t1's)"
    }
    else {
        di as error "  FAIL: Unexpected result (N=`n1', cols_ok=`cols_ok')"
        local all_pass = 0
    }
}
else {
    di as error "  FAIL: yaml read returned rc=`rc1'"
    local all_pass = 0
}

*===============================================================================
* TEST 2: unicefdata v2 parser wrapper
*===============================================================================

di as text _n "TEST 2: __unicef_parse_ind_yaml_v2 wrapper"

* Reset yaml check global
macro drop UNICEF_yaml_checked

timer clear 2
timer on 2
capture noisily __unicef_parse_ind_yaml_v2 "`yaml_file'"
local rc2 = _rc
timer off 2

if (`rc2' == 0) {
    qui timer list 2
    local t2 = r(t2)
    local n2 = _N
    
    * Check wrapper-produced columns (field_ prefix)
    local cols_ok = 1
    foreach col in ind_code field_name field_desc {
        capture confirm variable `col'
        if (_rc != 0) {
            di as error "  FAIL: Missing expected column '`col''"
            local cols_ok = 0
        }
    }
    
    if (`cols_ok' & `n2' > 700) {
        di as result "  PASS: v2 parser OK (`n2' indicators in `t2's)"
    }
    else {
        di as error "  FAIL: Unexpected result (N=`n2', cols_ok=`cols_ok')"
        local all_pass = 0
    }
}
else {
    di as error "  FAIL: v2 parser returned rc=`rc2'"
    local all_pass = 0
}

*===============================================================================
* TEST 3: Indicator lookup simulation
*===============================================================================

di as text _n "TEST 3: Indicator lookup simulation"

* Load indicators using v2 parser
capture noisily __unicef_parse_ind_yaml_v2 "`yaml_file'"
if (_rc == 0) {
    * Try to find a known indicator (CME_MRY0T4 - under-5 mortality)
    qui count if strpos(ind_code, "CME_MRY0") > 0
    local found = r(N)
    
    if (`found' > 0) {
        di as result "  PASS: Found `found' CME_MRY0* indicators"
        qui levelsof ind_code if strpos(ind_code, "CME_MRY0") > 0, local(codes) clean
        di as text "        Codes: `codes'"
    }
    else {
        di as text "  WARN: No CME_MRY0* indicators found (may be expected)"
    }
    
    * Check dataflows field exists
    capture confirm variable field_dataflows
    if (_rc == 0) {
        di as result "  PASS: field_dataflows column exists"
    }
    else {
        di as text "  INFO: field_dataflows not present (optional)"
    }
}
else {
    di as error "  FAIL: Could not reload indicators"
    local all_pass = 0
}

*===============================================================================
* TEST 4: yaml check utility
*===============================================================================

di as text _n "TEST 4: _unicefdata_check_yaml utility"

* Reset check
macro drop UNICEF_yaml_checked

capture noisily _unicefdata_check_yaml, minversion(1.9.0)
local rc4 = _rc

if (`rc4' == 0) {
    di as result "  PASS: yaml check OK (v`r(version)')"
}
else {
    di as error "  FAIL: yaml check returned rc=`rc4'"
    local all_pass = 0
}

*===============================================================================
* SUMMARY
*===============================================================================

di as text _n "{hline 70}"
if (`all_pass') {
    di as result "All integration tests PASSED"
}
else {
    di as error "Some integration tests FAILED"
    error 198
}
di as text "{hline 70}"
