*! test_validate_types.do
*! Regression test REG-05: yaml validate type check matches correct row (BUG-5)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/validate_types.yaml"
local all_pass = 1

*===============================================================================
* Read the fixture
*===============================================================================

yaml read using "`fixture'", replace

*===============================================================================
* TEST 1: Type check on a key that is NOT in observation 1
*   "eta" has type "numeric" and is NOT the first row
*   Before BUG-5 fix, yaml validate would read type[1] (always "string")
*===============================================================================

yaml validate, types(eta:numeric) quiet
if (r(valid) != 1) {
    di as error "REG-05 FAIL: eta should validate as numeric (r(valid)=`=r(valid)')"
    local all_pass = 0
}

*===============================================================================
* TEST 2: Type check on a key that IS in observation 1
*   "alpha" is the first key and has type "string"
*===============================================================================

yaml validate, types(alpha:string) quiet
if (r(valid) != 1) {
    di as error "REG-05 FAIL: alpha should validate as string (r(valid)=`=r(valid)')"
    local all_pass = 0
}

*===============================================================================
* TEST 3: Type mismatch should be caught for non-first rows
*   "gamma" has type "boolean", validating as "numeric" should fail
*===============================================================================

yaml validate, types(gamma:numeric) quiet
if (r(valid) != 0) {
    di as error "REG-05 FAIL: gamma:numeric should fail validation (r(valid)=`=r(valid)')"
    local all_pass = 0
}
if (r(n_warnings) != 1) {
    di as error "REG-05 FAIL: expected 1 type warning, got `=r(n_warnings)'"
    local all_pass = 0
}

*===============================================================================
* TEST 4: Multiple type checks in a single call
*===============================================================================

yaml validate, types(alpha:string beta:numeric gamma:boolean eta:numeric) quiet
if (r(valid) != 1) {
    di as error "REG-05 FAIL: multi-type check should pass (r(valid)=`=r(valid)')"
    local all_pass = 0
}

*===============================================================================
* TEST 5: Null type check
*   "epsilon" has an empty value, type should be "null"
*===============================================================================

yaml validate, types(epsilon:null) quiet
if (r(valid) != 1) {
    di as error "REG-05 FAIL: epsilon should validate as null (r(valid)=`=r(valid)')"
    local all_pass = 0
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "REG-05 PASS: yaml validate type check matches correct row"
}
else {
    error 198
}
