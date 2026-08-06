*! test_list_stata_quotes.do
*! Regression test: the stata option of yaml list must return compound-quoted
*! names in r(keys)/r(values). Before the fix, the trailing strtrim() wrapped a
*! compound-quoted list in plain double quotes, so the expression collapsed to a
*! single backtick and any foreach over r(keys) iterated once on garbage.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

yaml read using "`root'/examples/data/test_flush_seqmap.yaml", replace

local pass = 1

* --- without the option: plain space-separated names ------------------------
yaml list flush, keys children
local plain "`r(keys)'"
if ("`plain'" != "1 2 3") {
    di as error "STATA-OPT FAIL: plain r(keys) = '`plain'', expected '1 2 3'"
    local pass = 0
}

* --- with the option: compound-quoted, and usable in foreach ----------------
* Checked behaviourally (no quote literals in this file): the quoted form must
* be strictly longer than the plain one (the added quote pairs) and must still
* loop to the same bare names. Pre-fix it collapsed to a single character.
yaml list flush, keys children stata
local quoted `"`r(keys)'"'
local lq = length(`"`quoted'"')
local lp = length("`plain'")
if (`lq' <= `lp') {
    di as error "STATA-OPT FAIL: quoted r(keys) length `lq' <= plain `lp' (collapsed)"
    local pass = 0
}

* the loop must iterate once per key, yielding the bare names
local n = 0
local seen ""
foreach k in `quoted' {
    local ++n
    local seen "`seen' `k'"
}
local seen = strtrim("`seen'")
if (`n' != 3 | "`seen'" != "1 2 3") {
    di as error "STATA-OPT FAIL: loop gave `n' item(s) '`seen'', expected 3 '1 2 3'"
    local pass = 0
}

if (`pass') {
    di as result "LIST STATA-QUOTES PASS"
}
else {
    error 198
}
