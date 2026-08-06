*! test_catalog_corpus.do
*! Corpus test: every vendored real catalog file shipped by wbopendata and
*! unicefData parses with yaml read (rc==0, keys>0) and known structures
*! resolve. Guards against parser regressions on real consumer YAML,
*! including the flush-dash sequences of mappings fixed in BUG-10.
clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local dir "`root'/qa/fixtures/catalogs"
local pass = 1

* --- every file parses and yields keys --------------------------------------
foreach f in unicefdata_regions wbopendata_topics wbopendata_sources ///
             unicefdata_dataflow_cme wbopendata_indicators_sample {
    capture yaml read using "`dir'/`f'.yaml", replace
    if _rc {
        di as error "CORPUS FAIL: `f'.yaml did not parse (rc=`=_rc')"
        local pass = 0
    }
    else {
        qui count
        if (r(N) == 0) {
            di as error "CORPUS FAIL: `f'.yaml parsed to zero keys"
            local pass = 0
        }
        else di as text "  `f'.yaml: `=r(N)' keys"
    }
}

* --- structural spot-checks -------------------------------------------------
* flat mapping
yaml read using "`dir'/unicefdata_regions.yaml", replace
qui levelsof value if key=="regions_UNICEF_ESA", local(v) clean
if ("`v'" != "Eastern and Southern Africa") {
    di as error "CORPUS FAIL: regions_UNICEF_ESA = '`v''"
    local pass = 0
}

* flush-dash sequence of mappings on a REAL dataflow file (BUG-10 guard)
yaml read using "`dir'/unicefdata_dataflow_cme.yaml", replace
local i = 1
foreach d in REF_AREA INDICATOR SEX WEALTH_QUINTILE {
    qui levelsof value if key=="dimensions_`i'_id", local(dv) clean
    if ("`dv'" != "`d'") {
        di as error "CORPUS FAIL: dimensions_`i'_id = '`dv'', expected `d' (flush-dash)"
        local pass = 0
    }
    local ++i
}

* nested mapping + metadata scalar
yaml read using "`dir'/wbopendata_topics.yaml", replace
qui levelsof value if key=="_metadata_total_topics", local(tt) clean
if ("`tt'" != "21") {
    di as error "CORPUS FAIL: _metadata_total_topics = '`tt''"
    local pass = 0
}

* dotted keys + metadata scalar
yaml read using "`dir'/wbopendata_indicators_sample.yaml", replace
qui levelsof value if key=="_metadata_total_indicators", local(ti) clean
if ("`ti'" != "29243") {
    di as error "CORPUS FAIL: _metadata_total_indicators = '`ti''"
    local pass = 0
}

if (`pass') {
    di as result "CATALOG CORPUS PASS"
}
else {
    error 198
}
