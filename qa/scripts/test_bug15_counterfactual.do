*! test_bug15_counterfactual.do
*! REG-17: BUG-15 counterfactual, self-contained. Materializes the v2.0.0
*! yaml_write.ado from git (tag v2.0.0) into an isolated adopath dir and
*! proves the quote-bearing scalar write FAILS there exactly as reported:
*!   (a) aborts r(198),
*!   (b) leaves a truncated file on disk,
*!   (c) the exists-guard then refuses a retry without -replace- (r 602).
*! Then switches back to the CURRENT tree and proves the same scenario
*! passes with a verbatim round-trip. One test, both builds.
*!
*! SKIPs (exit 0) when git or the v2.0.0 tag is unavailable, so the suite
*! stays runnable from an exported tree without history.
*!
*! Adopath caution (the trap that invalidated an earlier ad-hoc demo): any
*! test that does adopath ++ src/y makes the CURRENT code shadow whatever
*! was loaded. Phase A therefore prepends the v2.0.0 dir LAST, so it is
*! searched FIRST, and Phase B removes it again before re-testing.
clear all
set more off

local root = c(pwd)
local tmp  "`root'/qa/tmp"
capture mkdir "`tmp'"
capture mkdir "`tmp'/v200"

* --- materialize v2.0.0's yaml_write.ado from git ---------------------------
capture erase "`tmp'/v200/yaml_write.ado"
* -capture-: shell returns 0 on Windows regardless of the command's fate, but
* on other platforms a missing git or an unresolvable tag returns non-zero and
* would abort the do-file before the SKIP branch below could run -- turning an
* intended skip into a suite failure.
capture quietly shell git -C "`root'" show v2.0.0:src/y/yaml_write.ado > "`tmp'/v200/yaml_write.ado"
capture confirm file "`tmp'/v200/yaml_write.ado"
if (_rc != 0) {
    di as text "REG-17 SKIP: could not materialize v2.0.0 (git or tag unavailable)"
    exit 0
}
tempname fh
file open `fh' using "`tmp'/v200/yaml_write.ado", read
file read `fh' firstline
file close `fh'
if (strpos(`"`firstline'"', "*") != 1) {
    di as text "REG-17 SKIP: v2.0.0 extraction looks empty or invalid"
    exit 0
}

local pass = 1

* ============================================================================
* Phase A: the v2.0.0 build must FAIL in all three documented ways
* ============================================================================
clear all
adopath ++ "`root'/src/_"
adopath ++ "`root'/src/y"
adopath ++ "`tmp'/v200"
* v200 is now searched first: yaml_write resolves to the 2.0.0 build,
* everything else to the current tree.

scalar q = `"say "hi" now"'
capture erase "`tmp'/bug15.yaml"

* (a) the write must abort r(198)
capture yaml_write using "`tmp'/bug15.yaml", scalars(q)
if (_rc != 198) {
    di as error "REG-17 FAIL: v2.0.0 write returned rc=`=_rc' (expected 198 abort)"
    local pass = 0
}

* (b) a truncated file must be left on disk
capture confirm file "`tmp'/bug15.yaml"
if (_rc != 0) {
    di as error "REG-17 FAIL: v2.0.0 abort left no file (expected truncated wreck)"
    local pass = 0
}

* (c) the exists-guard must refuse a retry without -replace-
capture yaml_write using "`tmp'/bug15.yaml", scalars(q)
if (_rc != 602) {
    di as error "REG-17 FAIL: v2.0.0 retry returned rc=`=_rc' (expected 602 lockout)"
    local pass = 0
}

* ============================================================================
* Phase B: the CURRENT build must PASS the same scenario, verbatim round trip
* ============================================================================
adopath - "`tmp'/v200"
clear all
* current src/y is now first for yaml_write again

scalar q = `"say "hi" now"'
capture erase "`tmp'/bug15.yaml"
capture yaml_write using "`tmp'/bug15.yaml", scalars(q)
if (_rc != 0) {
    di as error "REG-17 FAIL: current build write returned rc=`=_rc' (expected 0)"
    local pass = 0
}
capture yaml read using "`tmp'/bug15.yaml", replace
if (_rc != 0) {
    di as error "REG-17 FAIL: could not read back the written file (rc=`=_rc')"
    local pass = 0
}
else {
    qui count if key == "q" & value == `"say "hi" now"'
    if (r(N) != 1) {
        di as error "REG-17 FAIL: quote-bearing value did not round-trip verbatim"
        local pass = 0
    }
}

* --- cleanup ---------------------------------------------------------------
capture erase "`tmp'/bug15.yaml"
capture erase "`tmp'/v200/yaml_write.ado"

if (`pass') {
    di as result "BUG-15 COUNTERFACTUAL PASS (v2.0.0 fails as documented; current build passes)"
}
else {
    error 198
}
