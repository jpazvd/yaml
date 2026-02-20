*! test_frame_queries.do
*! Feature test FEAT-08: Frame-based query operations (wbopendata-style)
*! Date: 20Feb2026
*! Tests frame caching, keyword search, and field filtering patterns

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local all_pass = 1

*===============================================================================
* PREREQ: Stata 16+ required for frames
*===============================================================================

if `c(stata_version)' < 16 {
    di as text "FEAT-08 SKIP: requires Stata 16+ (frames)"
    exit 0
}

*===============================================================================
* SETUP: Create test YAML with indicator-like structure
*===============================================================================

tempfile test_yaml
tempname fh
file open `fh' using "`test_yaml'", write replace
file write `fh' "indicators:" _n
file write `fh' "  GDP.MKTP.CD:" _n
file write `fh' "    code: GDP.MKTP.CD" _n
file write `fh' "    name: GDP (current US$)" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file write `fh' "  GDP.MKTP.KD:" _n
file write `fh' "    code: GDP.MKTP.KD" _n
file write `fh' "    name: GDP (constant 2015 US$)" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file write `fh' "  SP.POP.TOTL:" _n
file write `fh' "    code: SP.POP.TOTL" _n
file write `fh' "    name: Population, total" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Health" _n
file write `fh' "  SE.ADT.LITR.ZS:" _n
file write `fh' "    code: SE.ADT.LITR.ZS" _n
file write `fh' "    name: Literacy rate, adult total (% of people ages 15+)" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Education" _n
file write `fh' "  NY.GDP.PCAP.CD:" _n
file write `fh' "    code: NY.GDP.PCAP.CD" _n
file write `fh' "    name: GDP per capita (current US$)" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file close `fh'

*===============================================================================
* TEST 1: Parse with bulk+collapse and verify structure
*===============================================================================

di as text _n "TEST 1: Parse with bulk+collapse"

capture yaml read using "`test_yaml'", replace bulk blockscalars
if (_rc != 0) {
    di as error "FEAT-08 FAIL: bulk parse failed (rc=`=_rc')"
    local all_pass = 0
}
else {
    qui _yaml_collapse
    local N = _N
    if (`N' != 5) {
        di as error "FEAT-08 FAIL: expected 5 indicators, got `N'"
        local all_pass = 0
    }
    else {
        di as result "  PASS: Parsed 5 indicators"
    }
}

*===============================================================================
* TEST 2: Frame caching (put/get pattern)
*===============================================================================

di as text _n "TEST 2: Frame cache operations"

* Store in frame cache
local cache_name "_yaml_test_cache"
cap frame drop `cache_name'
frame put *, into(`cache_name')

* Verify frame exists
cap frame `cache_name': count
if (_rc != 0) {
    di as error "FEAT-08 FAIL: frame put failed"
    local all_pass = 0
}
else {
    local cached_N = r(N)
    if (`cached_N' != 5) {
        di as error "FEAT-08 FAIL: frame cache has `cached_N' rows, expected 5"
        local all_pass = 0
    }
    else {
        di as result "  PASS: Frame cache created with 5 rows"
    }
}

*===============================================================================
* TEST 3: Keyword search (strpos pattern - wbopendata style)
*===============================================================================

di as text _n "TEST 3: Keyword search (strpos)"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_search)
frame change _test_search

* Search for "GDP" in name
qui keep if strpos(lower(name), "gdp") > 0
local gdp_count = _N

if (`gdp_count' != 3) {
    di as error "FEAT-08 FAIL: keyword 'GDP' matched `gdp_count' rows, expected 3"
    local all_pass = 0
}
else {
    di as result "  PASS: Keyword search found 3 GDP indicators"
}

cap frame drop _test_search

*===============================================================================
* TEST 4: Field filter (topic-based filtering)
*===============================================================================

di as text _n "TEST 4: Field filter (topic)"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_filter)
frame change _test_filter

* Filter by topic = "Economy"
qui keep if topic == "Economy"
local econ_count = _N

if (`econ_count' != 3) {
    di as error "FEAT-08 FAIL: topic 'Economy' matched `econ_count' rows, expected 3"
    local all_pass = 0
}
else {
    di as result "  PASS: Topic filter found 3 Economy indicators"
}

cap frame drop _test_filter

*===============================================================================
* TEST 5: Frame cache hit timing (performance pattern)
*===============================================================================

di as text _n "TEST 5: Frame cache hit timing"

timer clear 1
timer clear 2

* Time cache miss (re-parse)
timer on 1
qui yaml read using "`test_yaml'", replace bulk blockscalars
qui _yaml_collapse
timer off 1

* Time cache hit (frame restore)
timer on 2
frame `cache_name': qui frame put *, into(_test_timing)
frame change _test_timing
timer off 2

qui timer list 1
local parse_time = r(t1)
qui timer list 2
local cache_time = r(t2)

if (`cache_time' < `parse_time') {
    di as result "  PASS: Cache hit (`cache_time's) faster than parse (`parse_time's)"
}
else {
    * Not a failure - small files may not show difference
    di as text "  NOTE: Cache timing inconclusive for small fixture"
}

cap frame drop _test_timing

*===============================================================================
* TEST 6: Multi-field query (code pattern match)
*===============================================================================

di as text _n "TEST 6: Code pattern match"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_pattern)
frame change _test_pattern

* Find indicators starting with "GDP"
qui keep if regexm(ind_code, "^GDP")
local pattern_count = _N

if (`pattern_count' != 2) {
    di as error "FEAT-08 FAIL: pattern ^GDP matched `pattern_count' rows, expected 2"
    local all_pass = 0
}
else {
    di as result "  PASS: Code pattern found 2 GDP.* indicators"
}

cap frame drop _test_pattern

*===============================================================================
* CLEANUP
*===============================================================================

cap frame drop `cache_name'
frame change default

*===============================================================================
* RESULT
*===============================================================================

di as text _n "{hline 60}"
if (`all_pass') {
    di as result "FEAT-08 PASS: Frame-based query operations working correctly"
}
else {
    di as error "FEAT-08 FAIL: Some frame query tests failed"
    error 198
}
