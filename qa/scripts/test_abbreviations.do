*! test_abbreviations.do
*! Test subcommand abbreviations (desc, frame, check)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local all_pass = 1

*===============================================================================
* Setup: Read YAML
*===============================================================================

yaml read using "`root'/examples/data/test_config.yaml", replace

*===============================================================================
* TEST 1: "yaml desc" should work like "yaml describe"
*===============================================================================

capture noisily yaml desc
if (_rc != 0) {
    di as error "ABBREV FAIL: 'yaml desc' returned error (rc=`=_rc')"
    local all_pass = 0
}
else {
    di as result "ABBREV PASS: 'yaml desc' works"
}

*===============================================================================
* TEST 2: "yaml check" should work like "yaml validate"
*===============================================================================

capture noisily yaml check, required(name version)
if (_rc != 0) {
    di as error "ABBREV FAIL: 'yaml check' returned error (rc=`=_rc')"
    local all_pass = 0
}
else {
    di as result "ABBREV PASS: 'yaml check' works"
}

*===============================================================================
* TEST 3: "yaml frame" should work like "yaml frames" (Stata 16+ only)
*===============================================================================

if (`c(stata_version)' >= 16) {
    yaml read using "`root'/examples/data/test_config.yaml", frame(cfg)

    capture noisily yaml frame
    if (_rc != 0) {
        di as error "ABBREV FAIL: 'yaml frame' returned error (rc=`=_rc')"
        local all_pass = 0
    }
    else {
        di as result "ABBREV PASS: 'yaml frame' works"
    }

    yaml clear, all
}
else {
    di as text "SKIP: 'yaml frame' test requires Stata 16+"
}

*===============================================================================
* TEST 4: unknown subcommand shows valid list
*===============================================================================

capture yaml notacommand
if (_rc != 198) {
    di as error "ABBREV FAIL: unknown subcommand should return rc=198"
    local all_pass = 0
}
else {
    di as result "ABBREV PASS: unknown subcommand returns rc=198"
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "ALL ABBREVIATION TESTS PASSED"
}
else {
    error 198
}
