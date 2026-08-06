*! test_quotes_in_values.do
*! Regression test: values containing quote characters or unmatched
*! parentheses must parse (BUG-14). Both parsers previously did the
*! outer-quote strip by expanding the value into a substr() expression,
*!     local _fc = substr(`"`value'"', 1, 1)
*! which re-exposes the value's own quote characters to Stata's parser: a
*! real wbopendata description, '... if it a) is long-lasting, b) ...',
*! aborted the read with "unknown function ()" (r(133)). The strip is now
*! done in Mata via st_local(), which never expands macro contents.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local pass = 1

* the fixture reproduces the killer shapes from the wbopendata catalog
tempname fh
tempfile fx
file open `fh' using "`fx'", write text
file write `fh' "indicators:" _n
file write `fh' "  A:" _n
file write `fh' `"    description: 'treated if it a) is long-lasting, b) pre-treated'"' _n
file write `fh' "  B:" _n
file write `fh' `"    name: ')'"' _n
file write `fh' "  C:" _n
file write `fh' `"    note: 'has "' `"""' `"dq"' `"""' `" and ) paren'"' _n
file write `fh' "  D:" _n
file write `fh' "    unit: (balanced)" _n
file write `fh' "    items:" _n
file write `fh' `"      - 'x) y'"' _n
file close `fh'

foreach mode in "" "fastread" {
    clear
    capture yaml read using "`fx'", replace `mode'
    if (_rc) {
        di as error "QUOTES FAIL: `=cond("`mode'"=="","canonical","`mode'")' parser rc=`=_rc' (BUG-14)"
        local pass = 0
        continue
    }
    if ("`mode'" != "") continue   // content checks on the canonical layout only

    * quotes stripped, content byte-intact
    qui count if key == "indicators_A_description" & ///
        value == "treated if it a) is long-lasting, b) pre-treated"
    if (r(N) != 1) {
        di as error "QUOTES FAIL: description not stored verbatim"
        local pass = 0
    }
    qui count if key == "indicators_B_name" & value == ")"
    if (r(N) != 1) {
        di as error "QUOTES FAIL: lone-paren value not stored"
        local pass = 0
    }
    * quoted list item with an unmatched paren
    qui count if strpos(key, "indicators_D_items") > 0 & value == "x) y"
    if (r(N) != 1) {
        di as error "QUOTES FAIL: quoted list item 'x) y' not stored"
        local pass = 0
    }
}

if (`pass') {
    di as result "QUOTES-IN-VALUES PASS"
}
else {
    error 198
}
