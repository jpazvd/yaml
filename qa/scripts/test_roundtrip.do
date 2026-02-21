*! test_roundtrip.do
*! Regression test REG-04: round-trip read/write produces valid YAML (BUG-4)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/roundtrip.yaml"
local outfile "`root'/qa/fixtures/roundtrip_output.yaml"
local all_pass = 1

*===============================================================================
* Step 1: Read the fixture
*===============================================================================

yaml read using "`fixture'", replace

* Verify key rows were parsed
qui count
if (r(N) < 10) {
    di as error "REG-04 FAIL: expected at least 10 rows, got `=r(N)'"
    local all_pass = 0
}

*===============================================================================
* Step 2: Write to output file
*===============================================================================

yaml write using "`outfile'", replace

*===============================================================================
* Step 3: Read the output back into a frame and compare
*===============================================================================

if (`c(stata_version)' >= 16) {
    capture frame drop yaml_rt
    yaml read using "`outfile'", frame(rt)

    * Compare key counts
    local orig_n = _N
    frame yaml_rt {
        local rt_n = _N
    }
    if (`orig_n' != `rt_n') {
        di as error "REG-04 FAIL: original has `orig_n' rows, round-trip has `rt_n'"
        local all_pass = 0
    }

    * Spot-check specific keys survived the round-trip
    frame yaml_rt {
        qui count if key == "name"
        if (r(N) != 1) {
            di as error "REG-04 FAIL: key 'name' missing after round-trip"
            local all_pass = 0
        }
        qui levelsof value if key == "name", local(v) clean
        if (`"`v'"' != "Round-Trip Test") {
            di as error "REG-04 FAIL: name value = '`v'', expected 'Round-Trip Test'"
            local all_pass = 0
        }

        qui count if key == "database_port"
        if (r(N) != 1) {
            di as error "REG-04 FAIL: key 'database_port' missing after round-trip"
            local all_pass = 0
        }
        qui levelsof value if key == "database_port", local(v) clean
        if ("`v'" != "5432") {
            di as error "REG-04 FAIL: database_port = '`v'', expected '5432'"
            local all_pass = 0
        }

        * Check list items survived
        qui count if key == "countries_1"
        if (r(N) != 1) {
            di as error "REG-04 FAIL: list item 'countries_1' missing after round-trip"
            local all_pass = 0
        }
        qui levelsof value if key == "countries_1", local(v) clean
        if ("`v'" != "BRA") {
            di as error "REG-04 FAIL: countries_1 = '`v'', expected 'BRA'"
            local all_pass = 0
        }
    }

    capture frame drop yaml_rt
}
else {
    * Stata < 16: re-read into dataset and compare
    preserve
    yaml read using "`outfile'", replace

    qui count if key == "name"
    if (r(N) != 1) {
        di as error "REG-04 FAIL: key 'name' missing after round-trip"
        local all_pass = 0
    }

    qui count if key == "countries_1"
    if (r(N) != 1) {
        di as error "REG-04 FAIL: list item 'countries_1' missing after round-trip"
        local all_pass = 0
    }

    restore
}

*===============================================================================
* Cleanup
*===============================================================================

capture erase "`outfile'"

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "REG-04 PASS: round-trip read/write produces valid YAML"
}
else {
    error 198
}
