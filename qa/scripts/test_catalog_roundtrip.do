*! test_catalog_roundtrip.do
*! Round-trip fidelity over the vendored consumer catalogs. yaml write is a
*! NORMALIZED rendering (semantic, not textual: quoting style and quote-
*! protected whitespace are dropped) AND stamps a "# Date:" header, so a
*! recreated file is neither byte-identical to the original nor byte-identical
*! across writes made in different seconds. This test checks the two properties
*! that DO hold:
*!   (a) data preservation: read(orig) and read(write(read(orig))) carry the
*!       same key / value / parent (values compared trimmed, since quoting and
*!       quote-protected whitespace normalize);
*!   (b) byte idempotence modulo the writer's own timestamp: two successive
*!       writes of the normalized form are identical once the "# Date:" /
*!       "# Generated" header lines are removed.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"
local dir "`root'/qa/fixtures/catalogs"

* strip the writer's timestamp/header comment lines so two writes compare equal
capture program drop _rt_strip
program define _rt_strip
    args infile outfile
    tempname fin fout
    file open `fin' using "`infile'", read text
    file open `fout' using "`outfile'", write replace text
    file read `fin' line
    while r(eof) == 0 {
        if !regexm(`"`macval(line)'"', "^# (Date|Generated)") {
            file write `fout' `"`macval(line)'"' _n
        }
        file read `fin' line
    }
    file close `fin'
    file close `fout'
end

local pass = 1
foreach f in unicefdata_regions wbopendata_topics wbopendata_sources ///
             unicefdata_dataflow_cme wbopendata_indicators_sample {
    local fok = 1
    tempfile A B C s1 s2 Bs Cs

    * normalize once; capture data signature D1
    yaml read using "`dir'/`f'.yaml", replace
    yaml write using "`A'", replace
    gen s = key + "|" + strtrim(value) + "|" + parent
    keep s
    sort s
    export delimited s using "`s1'", replace novarnames

    * re-read normalized form; capture D2; write B
    yaml read using "`A'", replace
    yaml write using "`B'", replace
    gen s = key + "|" + strtrim(value) + "|" + parent
    keep s
    sort s
    export delimited s using "`s2'", replace novarnames

    * write C from B for byte idempotence (modulo timestamp)
    yaml read using "`B'", replace
    yaml write using "`C'", replace

    * (a) data preservation
    checksum "`s1'"
    local k1 = r(checksum)
    local l1 = r(filelen)
    checksum "`s2'"
    if (r(checksum) != `k1' | r(filelen) != `l1') {
        di as error "RT FAIL: `f' data changed across a write (beyond quoting/whitespace)"
        local pass = 0
        local fok = 0
    }

    * (b) byte idempotence modulo the writer's timestamp header
    _rt_strip "`B'" "`Bs'"
    _rt_strip "`C'" "`Cs'"
    checksum "`Bs'"
    local kb = r(checksum)
    local lb = r(filelen)
    checksum "`Cs'"
    if (r(checksum) != `kb' | r(filelen) != `lb') {
        di as error "RT FAIL: `f' write not byte-idempotent (after timestamp strip)"
        local pass = 0
        local fok = 0
    }

    if (`fok') di as text "  `f': data preserved, byte-idempotent (mod timestamp)"
}

if (`pass') {
    di as result "CATALOG ROUND-TRIP PASS"
}
else {
    error 198
}
