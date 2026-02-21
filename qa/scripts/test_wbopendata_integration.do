*! test_wbopendata_integration.do
*! Integration smoke test: yaml.ado → wbopendata cache → indicator lookup
*! Date: 21Feb2026
*! Purpose: Verify yaml.ado works correctly with wbopendata-dev v2 parser

clear all
set more off

local all_pass = 1

* Absolute paths to source directories
local yaml_dev_src "C:/GitHub/myados/yaml-dev/src"
local wbod_src "C:/GitHub/myados/wbopendata-dev/src"
local yaml_file "`wbod_src'/_/_wbopendata_indicators.yaml"

* Check if wbopendata-dev exists
capture confirm file "`yaml_file'"
if (_rc != 0) {
    di as text "SKIP: wbopendata-dev not found at expected location"
    di as text "      Expected: `yaml_file'"
    exit 0
}

*===============================================================================
* SETUP: Add required adopaths
*===============================================================================

di as text _n "{hline 70}"
di as result "Integration Test: yaml.ado → wbopendata cache pipeline"
di as text "{hline 70}"

* Use yaml-dev source (this repo)
adopath ++ "`yaml_dev_src'/y"
adopath ++ "`yaml_dev_src'/_"

* Add wbopendata-dev paths
adopath ++ "`wbod_src'/y"
adopath ++ "`wbod_src'/_"

*===============================================================================
* TEST 1: Direct yaml read with wbopendata indicator structure
*===============================================================================

di as text _n "TEST 1: Direct yaml read of wbopendata indicators"

timer clear 1
timer on 1
capture noisily {
    yaml read using "`yaml_file'", ///
        bulk collapse replace ///
        colfields(code;name;source_id;description)
}
local rc1 = _rc
timer off 1

if (`rc1' == 0) {
    qui timer list 1
    local t1 = r(t1)
    local n1 = _N
    
    * Check expected columns exist
    local cols_ok = 1
    foreach col in ind_code name {
        capture confirm variable `col'
        if (_rc != 0) {
            di as error "  FAIL: Missing expected column '`col''"
            local cols_ok = 0
        }
    }
    
    if (`cols_ok' & `n1' > 10000) {
        di as result "  PASS: yaml read OK (`n1' indicators in `t1's)"
    }
    else if (`cols_ok' & `n1' > 0) {
        di as text "  WARN: Only `n1' indicators (expected >10000)"
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
* TEST 2: wbopendata v2 parser wrapper (if exists)
*===============================================================================

di as text _n "TEST 2: __wbod_parse_yaml_ind_v2 wrapper"

* Reset yaml check global
capture macro drop WBOD_yaml_checked

capture which __wbod_parse_yaml_ind_v2
if (_rc == 0) {
    timer clear 2
    timer on 2
    capture noisily __wbod_parse_yaml_ind_v2 "`yaml_file'"
    local rc2 = _rc
    timer off 2
    
    if (`rc2' == 0) {
        qui timer list 2
        local t2 = r(t2)
        local n2 = _N
        
        if (`n2' > 10000) {
            di as result "  PASS: v2 parser OK (`n2' indicators in `t2's)"
        }
        else {
            di as text "  WARN: Only `n2' indicators parsed"
        }
    }
    else {
        di as error "  FAIL: v2 parser returned rc=`rc2'"
        local all_pass = 0
    }
}
else {
    di as text "  SKIP: __wbod_parse_yaml_ind_v2 not found"
}

*===============================================================================
* TEST 3: Indicator lookup simulation
*===============================================================================

di as text _n "TEST 3: Indicator lookup simulation"

* Load indicators directly
capture noisily {
    yaml read using "`yaml_file'", ///
        bulk collapse replace ///
        colfields(code;name;source_id;description)
}

if (_rc == 0) {
    * Try to find known WDI indicators
    qui count if strpos(ind_code, "SP.POP") > 0
    local found = r(N)
    
    if (`found' > 0) {
        di as result "  PASS: Found `found' SP.POP* indicators"
        qui levelsof ind_code if strpos(ind_code, "SP.POP") > 0, local(codes) clean
        local first5 : word 1 of `codes'
        local second : word 2 of `codes'
        local third : word 3 of `codes'
        di as text "        Sample: `first5' `second' `third' ..."
    }
    else {
        di as text "  WARN: No SP.POP* indicators found"
    }
    
    * Check source_id field exists
    capture confirm variable source_id
    if (_rc == 0) {
        qui tab source_id
        local nsrc = r(r)
        di as result "  PASS: source_id column exists (`nsrc' unique sources)"
    }
    else {
        di as text "  INFO: source_id not present"
    }
}
else {
    di as error "  FAIL: Could not load indicators"
    local all_pass = 0
}

*===============================================================================
* TEST 4: Indicators preset — topic and source_org field validation
*===============================================================================

di as text _n "TEST 4: indicators preset field validation (REG-09 regression)"

capture noisily {
    yaml read using "`yaml_file'", indicators replace blockscalars strl
}
local rc4a = _rc

if (`rc4a' == 0) {
    local n4 = _N
    di as text "  Parsed `n4' indicators with indicators preset"

    * Check topic_names column exists (parent_stack fix)
    capture confirm variable topic_names
    if (_rc != 0) {
        di as error "  FAIL: topic_names column missing (parent_stack contamination bug)"
        local all_pass = 0
    }
    else {
        * Count indicators with non-empty topic_names
        qui count if topic_names != "" & topic_names != "[]"
        local n_with_topics = r(N)
        di as text "  Indicators with topic_names: `n_with_topics' / `n4'"

        if (`n_with_topics' < 1000) {
            di as error "  FAIL: too few indicators have topic_names (`n_with_topics')"
            di as error "        This suggests parent_stack contamination is still present"
            local all_pass = 0
        }
        else {
            di as result "  PASS: topic_names populated (`n_with_topics' indicators)"
        }
    }

    * Check topic_ids column exists
    capture confirm variable topic_ids
    if (_rc != 0) {
        di as error "  FAIL: topic_ids column missing"
        local all_pass = 0
    }
    else {
        qui count if topic_ids != "" & topic_ids != "[]"
        local n_with_tids = r(N)
        di as text "  Indicators with topic_ids: `n_with_tids' / `n4'"

        if (`n_with_tids' < 1000) {
            di as error "  FAIL: too few indicators have topic_ids (`n_with_tids')"
            local all_pass = 0
        }
        else {
            di as result "  PASS: topic_ids populated (`n_with_tids' indicators)"
        }
    }

    * Check source_org column exists (added to indicators preset colfields)
    capture confirm variable source_org
    if (_rc != 0) {
        di as error "  FAIL: source_org column missing (not in indicators preset colfields)"
        local all_pass = 0
    }
    else {
        qui count if source_org != ""
        local n_with_src = r(N)
        di as text "  Indicators with source_org: `n_with_src' / `n4'"

        if (`n_with_src' < 1000) {
            di as error "  FAIL: too few indicators have source_org (`n_with_src')"
            local all_pass = 0
        }
        else {
            di as result "  PASS: source_org populated (`n_with_src' indicators)"
        }
    }

    * Spot-check SP.POP.TOTL
    qui count if ind_code == "SP.POP.TOTL"
    if (r(N) == 1) {
        qui levelsof topic_names if ind_code == "SP.POP.TOTL", local(v) clean
        di as text "  SP.POP.TOTL topic_names = '`v''"
        if (`"`v'"' == "" | `"`v'"' == "[]") {
            di as error "  FAIL: SP.POP.TOTL has empty topic_names"
            local all_pass = 0
        }
    }
}
else {
    di as error "  FAIL: indicators preset parse returned rc=`rc4a'"
    local all_pass = 0
}

*===============================================================================
* TEST 5: yaml check utility
*===============================================================================

di as text _n "TEST 5: _wbopendata_check_yaml utility"

capture which _wbopendata_check_yaml
if (_rc == 0) {
    * Reset check
    capture macro drop WBOD_yaml_checked
    
    capture noisily _wbopendata_check_yaml, minversion(1.9.0)
    local rc4 = _rc
    
    if (`rc4' == 0) {
        di as result "  PASS: yaml check OK (v`r(version)')"
    }
    else {
        di as error "  FAIL: yaml check returned rc=`rc4'"
        local all_pass = 0
    }
}
else {
    di as text "  SKIP: _wbopendata_check_yaml not found"
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
