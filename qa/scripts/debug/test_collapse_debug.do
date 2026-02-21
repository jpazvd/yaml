*! test_collapse_debug.do - Check yaml collapse output structure
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/_wbopendata_indicators.yaml"

di "=== Testing yaml collapse output structure ==="

* Test 1: bulk collapse (default)
di _n "--- Test 1: yaml bulk collapse (default) ---"
yaml read using "`fixture'", replace bulk collapse blockscalars strl
di "Rows: `=_N'"
di "Cols: `=c(k)'"
di "First 10 variable names:"
describe, short
ds

* Test 2: bulk only, then manual collapse
di _n "--- Test 2: yaml bulk only (long format) ---"
yaml read using "`fixture'", replace bulk blockscalars strl
di "Rows: `=_N'"
di "First 20 observations:"
list in 1/20

* Show structure for indicators
di _n "Key patterns:"
tab level, missing
tab type, missing

di _n "Keys at level 2 (first 10):"
list key value level in 1/50 if level == 2

exit 0
