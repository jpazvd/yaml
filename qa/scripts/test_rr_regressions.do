*! test_rr_regressions.do
*! QA: regressions found while validating the v2.0.0 behaviors (2026-07).
*! Self-contained: writes its own fixtures to the current directory.
*! Run from a directory where the yaml package is on the adopath.

di as result _n "=== RR/v2.0.0 regression tests ===" _n

*-------------------------------------------------------------------------------
* Fixture 1: nested mapping with scalar list (children/quoting/scalar-get)
*-------------------------------------------------------------------------------
tempname fh
file open `fh' using "rr_fix1.yaml", write text replace
file write `fh' "title: Demo" _n
file write `fh' `"version: "1.10""' _n
file write `fh' `"unbalanced: "abc"' _n
file write `fh' "flag_on: true" _n
file write `fh' "flag_off: no" _n
file write `fh' "nothing: null" _n
file write `fh' "indicators:" _n
file write `fh' "  CME_MRY0T4:" _n
file write `fh' "    name: U5MR" _n
file write `fh' "    dataflow: CME" _n
file write `fh' "  IM_DTP3:" _n
file write `fh' "    name: DTP3" _n
file write `fh' "    dataflow: IMMUNISATION" _n
file write `fh' "countries:" _n
file write `fh' "  - BRA" _n
file write `fh' "  - ARG" _n
file close `fh'

yaml read using "rr_fix1.yaml", replace

* --- RR-1: children returns BARE names; r(found); full keys without children
yaml list indicators, keys children noheader
assert "`r(keys)'" == "CME_MRY0T4 IM_DTP3"
assert r(found) == 1
yaml list no_such_parent, keys children noheader
assert r(found) == 0
assert "`r(keys)'" == ""
di as result "RR-1  yaml list children bare names + r(found)      OK"

* --- RR-2: noheader produces no output (visual; assert return intact)
yaml list indicators, keys children noheader
assert "`r(keys)'" != ""
di as result "RR-2  noheader silent listing                        OK"

* --- RR-3: scalar-leaf yaml get returns r(value)
yaml get title, quiet
assert `"`r(value)'"' == "Demo"
assert r(found) == 1
di as result "RR-3  scalar-leaf yaml get r(value)                  OK"

* --- RR-4: multi-colon path
yaml get indicators:CME_MRY0T4:name, quiet
assert `"`r(value)'"' == "U5MR"
yaml get indicators:IM_DTP3, quiet
assert `"`r(dataflow)'"' == "IMMUNISATION"
di as result "RR-4  multi-colon paths in yaml get                  OK"

* --- RR-5: quoting -- matching pair stripped + typed string; unbalanced kept
yaml get version, quiet
assert `"`r(value)'"' == "1.10"
qui levelsof type if key == "version", local(vt) clean
assert "`vt'" == "string"
qui levelsof value if key == "unbalanced", local(uv)
assert strpos(`"`uv'"', `"""') > 0
di as result "RR-5  matching-pair quoting rule                     OK"

* --- RR-6: boolean/null normalization on read
qui levelsof value if key == "flag_on", local(b1) clean
qui levelsof type  if key == "flag_on", local(t1) clean
assert "`b1'" == "1" & "`t1'" == "boolean"
qui levelsof value if key == "flag_off", local(b0) clean
assert "`b0'" == "0"
di as result "RR-6  boolean normalization on read                  OK"

*-------------------------------------------------------------------------------
* Fixture 2: sequences of mappings (v2.0.0 flagship)
*-------------------------------------------------------------------------------
file open `fh' using "rr_fix2.yaml", write text replace
file write `fh' "variables:" _n
file write `fh' "  male:" _n
file write `fh' "    from: HL4" _n
file write `fh' "    values:" _n
file write `fh' "      - from: 1" _n
file write `fh' "        to: 1" _n
file write `fh' "        label: Male" _n
file write `fh' "      - from: 2" _n
file write `fh' "        to: 0" _n
file write `fh' "        label: Female" _n
file write `fh' "    label: Sex" _n
file close `fh'

yaml read using "rr_fix2.yaml", replace

* --- RR-7: map items become structural rows with per-item children
qui count if key == "variables_male_values_1" & type == "list_map"
assert r(N) == 1
qui count if key == "variables_male_values_2" & type == "list_map"
assert r(N) == 1
yaml get variables_male_values:1, quiet
assert `"`r(from)'"' == "1"
assert `"`r(label)'"' == "Male"
yaml get variables_male_values:2, quiet
assert `"`r(to)'"' == "0"
assert `"`r(label)'"' == "Female"
* sibling AFTER the list must not be swallowed by the item
yaml get variables:male, quiet
assert `"`r(label)'"' == "Sex"
di as result "RR-7  sequences of mappings parse (canonical)        OK"

* --- RR-8: children of the list are the bare item indices
yaml list variables_male_values, keys children noheader
assert "`r(keys)'" == "1 2"
di as result "RR-8  map-list children are item indices             OK"

* --- RR-9: write emits dash form; re-read reproduces the structure
yaml write using "rr_fix2_out.yaml", replace
preserve
yaml read using "rr_fix2_out.yaml", replace
yaml get variables_male_values:1, quiet
assert `"`r(label)'"' == "Male"
yaml get variables_male_values:2, quiet
assert `"`r(from)'"' == "2"
yaml list variables_male_values, keys children noheader
assert "`r(keys)'" == "1 2"
restore
* the emitted file must contain dash-mapping lines
tempname fr
local found_dash = 0
file open `fr' using "rr_fix2_out.yaml", read text
file read `fr' line
while (r(eof) == 0) {
    if (strpos(`"`line'"', "- from: 1") > 0) local found_dash = 1
    file read `fr' line
}
file close `fr'
assert `found_dash' == 1
di as result "RR-9  map-list write round trip (dash form)          OK"

* --- RR-10: boolean/null literal fidelity on write
yaml read using "rr_fix1.yaml", replace
yaml write using "rr_fix1_out.yaml", replace
local saw_true = 0
local saw_false = 0
file open `fr' using "rr_fix1_out.yaml", read text
file read `fr' line
while (r(eof) == 0) {
    if (strpos(`"`line'"', "flag_on: true") > 0) local saw_true = 1
    if (strpos(`"`line'"', "flag_off: false") > 0) local saw_false = 1
    file read `fr' line
}
file close `fr'
assert `saw_true' == 1
assert `saw_false' == 1
di as result "RR-10 boolean true/false on write                    OK"

* --- RR-11: fastread returns r(n_keys); rejects map items
yaml read using "rr_fix1.yaml", fastread replace
assert r(n_keys) == _N
assert r(n_keys) > 0
capture yaml read using "rr_fix2.yaml", fastread replace
assert _rc == 198
di as result "RR-11 fastread n_keys + map-item rejection           OK"

* --- RR-12: bulk parser rejects map items explicitly
capture yaml read using "rr_fix2.yaml", bulk replace
assert _rc != 0
di as result "RR-12 bulk map-item rejection                        OK"

* --- RR-13: frame path -- children + scalar get + colon path in frames
yaml read using "rr_fix2.yaml", frame(rrt) replace
yaml list variables_male_values, keys children frame(rrt) noheader
assert "`r(keys)'" == "1 2"
assert r(found) == 1
yaml get variables:male:from, frame(rrt) quiet
assert `"`r(value)'"' == "HL4"
yaml clear rrt
di as result "RR-13 frame-path children/colon/scalar-get           OK"

*-------------------------------------------------------------------------------
* Fixture 3: nested mappings under sequence items (GitHub Actions shape)
*-------------------------------------------------------------------------------
file open `fh' using "rr_fix3.yaml", write text replace
file write `fh' "steps:" _n
file write `fh' "  - name: build" _n
file write `fh' "    with:" _n
file write `fh' "      os: linux" _n
file write `fh' "      arch: x64" _n
file write `fh' "  - name: test" _n
file write `fh' "    run: make check" _n
file close `fh'

yaml read using "rr_fix3.yaml", replace

* --- RR-14: deep nesting under items parses correctly (no scalar folding)
qui levelsof value if key == "steps_1_name", local(v1) clean
assert "`v1'" == "build"
qui count if key == "steps_1_with" & type == "parent"
assert r(N) == 1
yaml get steps:1:with:os, quiet
assert `"`r(value)'"' == "linux"
yaml get steps:2, quiet
assert `"`r(run)'"' == "make check"
di as result "RR-14 nested mappings under sequence items           OK"

* --- RR-15: deep item write round trip
yaml write using "rr_fix3_out.yaml", replace
yaml read using "rr_fix3_out.yaml", replace
yaml get steps:1:with:arch, quiet
assert `"`r(value)'"' == "x64"
yaml get steps:1, quiet
assert `"`r(name)'"' == "build"
di as result "RR-15 deep item write round trip                      OK"

*-------------------------------------------------------------------------------
* Fixture 4: block sequence of scalars (whole-node get must not error; RR-16)
*-------------------------------------------------------------------------------
file open `fh' using "rr_fix4.yaml", write text replace
file write `fh' "dataflows:" _n
file write `fh' "  CME:" _n
file write `fh' "    indicators:" _n
file write `fh' "      - CME_MRY0T4" _n
file write `fh' "      - CME_MRM0" _n
file write `fh' "      - CME_MRY0" _n
file close `fh'

* --- RR-16: whole-node get on a scalar sequence returns the joined items in
*            r(value) (previously failed with r(198) "invalid name" because the
*            numeric list indices could not be returned as r() macro names)
yaml read using "rr_fix4.yaml", replace
yaml get dataflows:CME:indicators, quiet
assert r(found) == 1
assert r(n_attrs) == 3
assert `"`r(value)'"' == "CME_MRY0T4 CME_MRM0 CME_MRY0"
di as result "RR-16 whole-node get on scalar sequence               OK"

* Cleanup fixtures
foreach f in rr_fix1.yaml rr_fix2.yaml rr_fix1_out.yaml rr_fix2_out.yaml rr_fix3.yaml rr_fix3_out.yaml rr_fix4.yaml {
    cap erase "`f'"
}

di as result _n "=== ALL RR/v2.0.0 REGRESSION TESTS PASSED ===" _n
