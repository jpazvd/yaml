*! test_brackets_in_values.do
*! Regression test REG-06: fastread handles brackets/braces in values (BUG-6)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/brackets_in_values.yaml"
local all_pass = 1

*===============================================================================
* TEST: Read YAML with brackets/braces in values using fastread
*   Before BUG-6 fix, _yaml_fastread rejected values containing [ ] { }
*===============================================================================

yaml read using "`fixture'", replace

* Check that all keys were parsed
qui count
if (r(N) < 6) {
    di as error "REG-06 FAIL: expected at least 6 rows, got `=r(N)'"
    local all_pass = 0
}

* Check value with square brackets
qui count if key == "api_base_url"
if (r(N) != 1) {
    di as error "REG-06 FAIL: key 'api_base_url' not found"
    local all_pass = 0
}
qui levelsof value if key == "api_base_url", local(v) clean
if (`"`v'"' != "https://example.com/path[1]/data") {
    di as error `"REG-06 FAIL: api_base_url = '`v'', expected 'https://example.com/path[1]/data'"'
    local all_pass = 0
}

* Check value with another bracket pattern
qui count if key == "api_query"
if (r(N) != 1) {
    di as error "REG-06 FAIL: key 'api_query' not found"
    local all_pass = 0
}
qui levelsof value if key == "api_query", local(v) clean
if ("`v'" != "filter[country]=BRA") {
    di as error "REG-06 FAIL: api_query = '`v'', expected 'filter[country]=BRA'"
    local all_pass = 0
}

* Check value with curly braces
qui count if key == "api_docs"
if (r(N) != 1) {
    di as error "REG-06 FAIL: key 'api_docs' not found"
    local all_pass = 0
}

* Check normal value still works
qui count if key == "api_clean"
if (r(N) != 1) {
    di as error "REG-06 FAIL: key 'api_clean' not found"
    local all_pass = 0
}
qui levelsof value if key == "api_clean", local(v) clean
if ("`v'" != "normal value without special chars") {
    di as error "REG-06 FAIL: api_clean = '`v'', expected 'normal value without special chars'"
    local all_pass = 0
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "REG-06 PASS: fastread handles brackets/braces in values"
}
else {
    error 198
}
