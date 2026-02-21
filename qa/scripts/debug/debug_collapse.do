*! debug_collapse.do
*! Run this in Stata to see why FEAT-06 is failing

clear all
discard
set more off

local root "c:/GitHub/myados/yaml-dev"
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

di as text _n "{hline 60}"
di as text "Step 0: Force recompilation of Mata functions"
di as text "{hline 60}"

* Clear any cached Mata code and recompile from source
capture mata: mata clear
qui do "`root'/src/_/_yaml_collapse.ado"
di as text "Mata functions recompiled"

local fixture "`root'/qa/fixtures/collapse_test.yaml"

di as text _n "{hline 60}"
di as text "Step 1: Read fixture with collapse"
di as text "{hline 60}"

capture noisily yaml read using "`fixture'", replace blockscalars collapse
di "Return code: " _rc

if (_rc != 0) {
    di as error "Failed to read/collapse YAML"
    exit
}

di as text _n "{hline 60}"
di as text "Step 2: List dataset structure"
di as text "{hline 60}"

di as text "Observations: `=_N'"
ds

di as text _n "{hline 60}"
di as text "Step 3: Browse first 5 rows"
di as text "{hline 60}"

list in 1/5

di as text _n "{hline 60}"
di as text "Step 4: Check for expected columns"
di as text "{hline 60}"

foreach col in ind_code name unit source_id description {
    capture confirm variable `col'
    if (_rc == 0) {
        di as result "  Found: `col'"
    }
    else {
        di as error "  Missing: `col'"
    }
}

di as text _n "{hline 60}"
di as text "Step 5: Check SP_POP_TOTL values"
di as text "{hline 60}"

capture confirm variable name
if (_rc == 0) {
    list ind_code name if ind_code == "SP_POP_TOTL"
}
else {
    di as error "Cannot check - 'name' column missing"
}

di as text _n "{hline 60}"
di as text "Done"
di as text "{hline 60}"
