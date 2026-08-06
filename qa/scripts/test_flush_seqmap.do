*! test_flush_seqmap.do
*! Regression test: block sequences of mappings whose dash sits at the parent
*! key's indentation (flush-dash, the PyYAML default) must parse as sibling
*! items <list>_N, not nested under the previous item's last key.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

yaml read using "`root'/examples/data/test_flush_seqmap.yaml", replace

local pass = 1

* --- flush-dash: three sibling items flush_1..flush_3 -----------------------
foreach n in 1 2 3 {
    qui count if key == "flush_`n'_id" & parent == "flush_`n'"
    if (r(N) != 1) {
        di as error "FLUSH FAIL: flush_`n'_id missing (flush-dash items not siblings)"
        local pass = 0
    }
}
* old-bug signature: later items nested under the first item's last key
qui count if strpos(key, "flush_1_position_") == 1
if (r(N) != 0) {
    di as error "FLUSH FAIL: nested key under flush_1_position (pre-fix misparse)"
    local pass = 0
}
* values land on the right items
qui levelsof value if key == "flush_2_id", local(v2) clean
if ("`v2'" != "INDICATOR") {
    di as error "FLUSH FAIL: flush_2_id = '`v2'', expected INDICATOR"
    local pass = 0
}
qui levelsof value if key == "flush_3_position", local(p3) clean
if ("`p3'" != "3") {
    di as error "FLUSH FAIL: flush_3_position = '`p3'', expected 3"
    local pass = 0
}

* --- indented-dash: unchanged (no regression) ------------------------------
foreach n in 1 2 {
    qui count if key == "indented_`n'_id" & parent == "indented_`n'"
    if (r(N) != 1) {
        di as error "INDENT FAIL: indented_`n'_id missing (indented-dash regressed)"
        local pass = 0
    }
}
qui levelsof value if key == "indented_2_id", local(iv2) clean
if ("`iv2'" != "B") {
    di as error "INDENT FAIL: indented_2_id = '`iv2'', expected B"
    local pass = 0
}

if (`pass') {
    di as result "FLUSH/INDENTED SEQ-OF-MAPPINGS PASS"
}
else {
    error 198
}
