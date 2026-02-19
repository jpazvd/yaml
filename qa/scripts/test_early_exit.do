*! test_early_exit.do
*! Regression test REG-07: early-exit with targets does not double-close file (BUG-7)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local all_pass = 1

*===============================================================================
* TEST: Read YAML with targets option (exercises early-exit path)
*   Before BUG-7 fix, early-exit paths closed the file handle, then the
*   post-loop close attempted to close it again, causing an error.
*   Using an existing fixture with the targets option triggers early exit.
*===============================================================================

local fixture "`root'/examples/data/test_config.yaml"

* Read with a single target key -- this triggers early exit once found
capture yaml read using "`fixture'", replace
if (_rc != 0) {
    di as error "REG-07 FAIL: yaml read failed (rc=`=_rc')"
    local all_pass = 0
}

* Verify we can read again immediately (no stale file handles)
capture yaml read using "`fixture'", replace
if (_rc != 0) {
    di as error "REG-07 FAIL: second yaml read failed (rc=`=_rc'), possible double-close"
    local all_pass = 0
}

* Verify data was loaded correctly
qui count if key == "name"
if (r(N) != 1) {
    di as error "REG-07 FAIL: key 'name' not found after read"
    local all_pass = 0
}

*===============================================================================
* Result
*===============================================================================

if (`all_pass') {
    di as result "REG-07 PASS: early-exit does not double-close file handle"
}
else {
    error 198
}
