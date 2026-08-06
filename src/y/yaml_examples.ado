*******************************************************************************
* yaml_examples
*! v 2.0.0   27Jul2026               by Joao Pedro Azevedo (UNICEF)
* Auxiliary program for -yaml-: runs the example blocks in the help file that
* cannot be launched one line at a time, because a Stata loop or brace block
* must be entered as several lines. Every other example in the help is a single
* command and is clickable on its own.
*
*     . yaml_examples yaml_ex_loop
*
* Each block is self-contained: it locates the demonstration file installed
* with the package (yaml_demo_config.yaml) rather than assuming a directory.
*******************************************************************************

capture program drop yaml_examples
program yaml_examples
    version 14.0
    gettoken EXAMPLE REST : 0
    if ("`EXAMPLE'" == "") {
        di as text "Loop examples from {help yaml##examples:help yaml} that cannot be run line by line:"
        di as text "  {stata yaml_examples yaml_ex_loop:yaml_ex_loop}      loop over indicator codes (Example 4)"
        di as text "  {stata yaml_examples yaml_ex_loopstata:yaml_ex_loopstata} the same loop with compound quotes (Example 5)"
        di as text "  {stata yaml_examples yaml_ex_loopget:yaml_ex_loopget}   loop calling yaml get (Example 8)"
        di as text "  {stata yaml_examples yaml_ex_multikey:yaml_ex_multikey}  several keys and a key pattern (Example 14)"
        di as text "  {stata yaml_examples yaml_ex_harmonize 5:yaml_ex_harmonize 5} crosswalk MICS5 into a do-file (Example 16)"
        di as text "  {stata yaml_examples yaml_ex_harmonize 6:yaml_ex_harmonize 6} the same crosswalk for MICS6 (Example 16)"
        exit 0
    }
    set more off
    `EXAMPLE' `REST'
end

*  ---------------------------------------------------------------------------
*  Locate the demonstration file installed with the package
*  ---------------------------------------------------------------------------

capture program drop _yaml_ex_demo
program _yaml_ex_demo, rclass
    capture findfile yaml_demo_config.yaml
    if (_rc) {
        di as err "yaml_demo_config.yaml not found; reinstall the yaml package"
        exit 601
    }
    return local fn "`r(fn)'"
end

*  ---------------------------------------------------------------------------
*  Example 4: loop over the child keys returned by yaml list
*  ---------------------------------------------------------------------------

capture program drop yaml_ex_loop
program yaml_ex_loop
    _yaml_ex_demo
    yaml read using "`r(fn)'", replace
    yaml list indicators, keys children
    foreach ind in `r(keys)' {
        display "Processing: `ind'"
    }
end

*  ---------------------------------------------------------------------------
*  Example 5: the same loop over compound-quoted keys
*  ---------------------------------------------------------------------------

capture program drop yaml_ex_loopstata
program yaml_ex_loopstata
    _yaml_ex_demo
    yaml read using "`r(fn)'", replace
    yaml list indicators, keys children stata
    foreach ind in `r(keys)' {
        display "Processing: `ind'"
    }
end

*  ---------------------------------------------------------------------------
*  Example 8: loop calling yaml get for each indicator
*  ---------------------------------------------------------------------------

capture program drop yaml_ex_loopget
program yaml_ex_loopget
    _yaml_ex_demo
    yaml read using "`r(fn)'", replace
    yaml list indicators, keys children
    foreach ind in `r(keys)' {
        yaml get indicators:`ind', quiet
        display "`ind': `r(label)' (`r(unit)')"
    }
end

*  ---------------------------------------------------------------------------
*  Example 14: several named keys, then all keys matching a pattern
*  ---------------------------------------------------------------------------

capture program drop yaml_ex_multikey
program yaml_ex_multikey
    _yaml_ex_demo
    yaml read using "`r(fn)'", frame(cfg) replace
    foreach i in CME_MRY0T4 CME_MRY0 {
        yaml get indicators:`i':label, frame(cfg) quiet
        display "`i': `r(value)'"
    }
    frame yaml_cfg {
        quietly levelsof value if regexm(key, "_label$"), local(labs) clean
    }
    display `"`labs'"'
end

*  ---------------------------------------------------------------------------
*  Harmonization crosswalk: drives the yaml_harmonize generator
*  ---------------------------------------------------------------------------

capture program drop yaml_ex_harmonize
program yaml_ex_harmonize
    args round
    if ("`round'" == "") local round 6
    if (!inlist("`round'", "5", "6")) {
        di as err "round must be 5 or 6"
        exit 198
    }
    capture findfile yaml_demo_mics`round'.yaml
    if (_rc) {
        di as err "yaml_demo_mics`round'.yaml not found; reinstall the yaml package"
        exit 601
    }
    local src "`r(fn)'"
    quietly findfile yaml_demo_target.yaml
    local tgt "`r(fn)'"

    yaml_harmonize using "`src'", target("`tgt'") ///
        saving("harmonize_mics`round'.do") replace ddiexport ///
        project("MICS`round' household listing -> IPUMS MICS")

    di as text _n "Generated harmonize_mics`round'.do:" _n
    type "harmonize_mics`round'.do"
end
