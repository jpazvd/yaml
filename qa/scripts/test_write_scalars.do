*! test_write_scalars.do
*! Regression test: yaml write, scalars() must actually emit the named scalars.
*! Before the fix the guard was "capture scalar `s'", which is not a validity
*! test (a bare "scalar name" is not a command and returns rc 100 even when the
*! scalar exists), so every scalar was skipped and only the header was written.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

sysuse auto, clear
quietly summarize price
scalar n_cars = r(N)
scalar mean_price = round(r(mean), .01)
scalar src = "1978 Automobile Data"

tempfile out
yaml write using "`out'", scalars(n_cars mean_price src) replace

* read the emitted file back and check every scalar survived
yaml read using "`out'", replace

local pass = 1

qui count if key == "n_cars" & value == "74"
if (r(N) != 1) {
    di as error "WRITE-SCALARS FAIL: n_cars not emitted as 74"
    local pass = 0
}
qui count if key == "mean_price"
if (r(N) != 1) {
    di as error "WRITE-SCALARS FAIL: mean_price not emitted"
    local pass = 0
}
* string scalars must round-trip too (numeric-only extraction would drop this)
qui count if key == "src" & value == "1978 Automobile Data"
if (r(N) != 1) {
    di as error "WRITE-SCALARS FAIL: string scalar src not emitted verbatim"
    local pass = 0
}
* pre-fix signature: nothing but the header, i.e. zero parsed keys
qui count
if (r(N) < 3) {
    di as error "WRITE-SCALARS FAIL: only `=r(N)' key(s) written (pre-fix defect)"
    local pass = 0
}

if (`pass') {
    di as result "WRITE SCALARS PASS"
}
else {
    error 198
}
