*! test_harmonize.do
*! Regression test: yaml_harmonize must generate a do-file that RUNS.
*! The generator previously guarded only the rename and then emitted
*! "label variable", "char" and "label values" unguarded, so a dataset missing
*! any source variable aborted the generated do-file with r(111) -- the opposite
*! of what help yaml promises ("a round that does not carry a variable skips it").
*! This test executes the generated do-file, which no other test did.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local src "`root'/src/y/yaml_demo_mics5.yaml"
local tgt "`root'/src/y/yaml_demo_target.yaml"

local pass = 1

* ---------------------------------------------------------------- generate
tempfile dofile
yaml_harmonize using "`src'", target("`tgt'") saving("`dofile'") replace ddiexport
if (r(n_mapped) != 6) {
    di as error "HARMONIZE FAIL: expected 6 mapped variables, got `=r(n_mapped)'"
    local pass = 0
}

* ------------------------------------------------- 1. complete extract runs
* every source variable present: all six must be renamed and labelled
clear
set obs 10
foreach v in HL3 hl4 hl6 hl11 ed3 ed4a {
    quietly generate byte `v' = 1
}
capture noisily do "`dofile'"
if (_rc) {
    di as error "HARMONIZE FAIL: generated do-file failed on a complete extract (rc=`=_rc')"
    local pass = 0
}
foreach v in RELATE SEX AGE MOTHERALIVE SCHOOLEVER EDLEVEL {
    capture confirm variable `v'
    if (_rc) {
        di as error "HARMONIZE FAIL: `v' not created on a complete extract"
        local pass = 0
    }
}
* labels and the DDI characteristic must travel with the rename
local lab : variable label SEX
if ("`lab'" != "Sex of household member") {
    di as error "HARMONIZE FAIL: SEX label is '`lab''"
    local pass = 0
}
local ch : char SEX[ddi]
if ("`ch'" != "individual.sex") {
    di as error "HARMONIZE FAIL: SEX[ddi] is '`ch''"
    local pass = 0
}
* the target's codes must be attached, not merely defined
local vl : value label SEX
if ("`vl'" != "SEX_lbl") {
    di as error "HARMONIZE FAIL: SEX has value label '`vl''"
    local pass = 0
}

* ------------------------------------------- 2. incomplete extract also runs
* This is the case that used to abort. Drop two source variables; the do-file
* must still complete, harmonize the rest, and create nothing for the missing.
clear
set obs 10
foreach v in HL3 hl4 hl6 ed3 {
    quietly generate byte `v' = 1
}
capture noisily do "`dofile'"
if (_rc) {
    di as error "HARMONIZE FAIL: generated do-file aborted on a partial extract (rc=`=_rc')"
    local pass = 0
}
foreach v in RELATE SEX AGE SCHOOLEVER {
    capture confirm variable `v'
    if (_rc) {
        di as error "HARMONIZE FAIL: `v' missing after a partial extract"
        local pass = 0
    }
}
foreach v in MOTHERALIVE EDLEVEL {
    capture confirm variable `v'
    if (_rc == 0) {
        di as error "HARMONIZE FAIL: `v' created although its source was absent"
        local pass = 0
    }
}

* ------------------------------------------------ 3. empty extract also runs
* Nothing to rename at all: still no error, just six skip messages.
clear
set obs 10
quietly generate byte filler = 1
capture noisily do "`dofile'"
if (_rc) {
    di as error "HARMONIZE FAIL: generated do-file aborted on an empty extract (rc=`=_rc')"
    local pass = 0
}

* --------------------------------------------- 4. the DDI slots are resolved
* xxx()/yyy()/zzz() must carry this study's values, named once in the target.
tempname fh
tempfile txt
quietly copy "`dofile'" "`txt'", replace
file open `fh' using "`txt'", read text
local seen_call = 0
file read `fh' line
while (r(eof) == 0) {
    if (strpos(`"`macval(line)'"', "xxx(ETH) yyy(2014) zzz(MICS5)")) local seen_call = 1
    file read `fh' line
}
file close `fh'
if (!`seen_call') {
    di as error "HARMONIZE FAIL: ddiexport did not resolve the slots to xxx(ETH) yyy(2014) zzz(MICS5)"
    local pass = 0
}

if (`pass') {
    di as result "HARMONIZE PASS"
}
else {
    error 198
}
