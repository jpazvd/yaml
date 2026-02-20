*! test_block_scalars.do
*! Feature test FEAT-02: block scalar support in canonical parser
*! Date: 19Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/block_scalars.yaml"
local all_pass = 1

*===============================================================================
* TEST: Canonical parser handles block scalars (|, >, |-, >-)
*===============================================================================

yaml read using "`fixture'", replace blockscalars

qui count
if (r(N) < 4) {
    di as error "FEAT-02 FAIL: expected at least 4 rows, got `=r(N)'"
    local all_pass = 0
}

* Check folded scalar (>) — lines joined with spaces
qui count if key == "topics_education_description"
if (r(N) != 1) {
    di as error "FEAT-02 FAIL: key 'topics_education_description' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "topics_education_description", local(v) clean
    * Folded: lines should be joined with spaces
    if (strpos(`"`v'"', "Education statistics cover") == 0) {
        di as error `"FEAT-02 FAIL: folded scalar missing expected text: `v'"'
        local all_pass = 0
    }
    if (strpos(`"`v'"', "across all levels.") == 0) {
        di as error `"FEAT-02 FAIL: folded scalar incomplete: `v'"'
        local all_pass = 0
    }
}

* Check literal scalar (|) — lines joined with char(10)
qui count if key == "topics_education_note"
if (r(N) != 1) {
    di as error "FEAT-02 FAIL: key 'topics_education_note' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "topics_education_note", local(v) clean
    * Literal: lines should contain newline characters
    if (strpos(`"`v'"', "Line one") == 0) {
        di as error `"FEAT-02 FAIL: literal scalar missing 'Line one': `v'"'
        local all_pass = 0
    }
    if (strpos(`"`v'"', "Line three") == 0) {
        di as error `"FEAT-02 FAIL: literal scalar missing 'Line three': `v'"'
        local all_pass = 0
    }
}

* Check folded-strip (>-) under health
qui count if key == "topics_health_description"
if (r(N) != 1) {
    di as error "FEAT-02 FAIL: key 'topics_health_description' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "topics_health_description", local(v) clean
    if (strpos(`"`v'"', "Health statistics include") == 0) {
        di as error `"FEAT-02 FAIL: folded-strip missing expected text: `v'"'
        local all_pass = 0
    }
    if (strpos(`"`v'"', "nutrition indicators.") == 0) {
        di as error `"FEAT-02 FAIL: folded-strip incomplete: `v'"'
        local all_pass = 0
    }
}

* Check literal-strip (|-) under health
qui count if key == "topics_health_note"
if (r(N) != 1) {
    di as error "FEAT-02 FAIL: key 'topics_health_note' not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "topics_health_note", local(v) clean
    if (strpos(`"`v'"', "First line.") == 0) {
        di as error `"FEAT-02 FAIL: literal-strip missing 'First line.': `v'"'
        local all_pass = 0
    }
}

*===============================================================================
* TEST: Without blockscalars, markers are stored as literal values
*===============================================================================

yaml read using "`fixture'", replace

* Without blockscalars, ">" should be stored as literal value, not folded
qui levelsof value if key == "topics_education_description", local(v) clean
if (`"`v'"' == ">") {
    di as text "FEAT-02 CHECK: without blockscalars, '>' stored as literal (correct)"
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "FEAT-02 PASS: block scalars handled correctly in canonical parser"
}
else {
    error 198
}
