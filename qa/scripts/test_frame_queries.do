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
file write `fh' "    description: Gross domestic product at purchaser prices" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file write `fh' "    topic_ids: '3;5'" _n
file write `fh' "  GDP.MKTP.KD:" _n
file write `fh' "    code: GDP.MKTP.KD" _n
file write `fh' "    name: GDP (constant 2015 US$)" _n
file write `fh' "    description: Real GDP adjusted for inflation" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file write `fh' "    topic_ids: '3;5'" _n
file write `fh' "  SP.POP.TOTL:" _n
file write `fh' "    code: SP.POP.TOTL" _n
file write `fh' "    name: Population, total" _n
file write `fh' "    description: Total population count" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Health" _n
file write `fh' "    topic_ids: '8;19'" _n
file write `fh' "  SE.ADT.LITR.ZS:" _n
file write `fh' "    code: SE.ADT.LITR.ZS" _n
file write `fh' "    name: Literacy rate, adult total (% of people ages 15+)" _n
file write `fh' "    description: Percentage of people who can read and write" _n
file write `fh' "    source_id: '11'" _n
file write `fh' "    topic: Education" _n
file write `fh' "    topic_ids: '4'" _n
file write `fh' "  NY.GDP.PCAP.CD:" _n
file write `fh' "    code: NY.GDP.PCAP.CD" _n
file write `fh' "    name: GDP per capita (current US$)" _n
file write `fh' "    description: GDP divided by midyear population" _n
file write `fh' "    source_id: '2'" _n
file write `fh' "    topic: Economy" _n
file write `fh' "    topic_ids: '3;5'" _n
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
* TEST 7: Source filtering (source_id field)
*===============================================================================

di as text _n "TEST 7: Source filtering"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_source)
frame change _test_source

* Filter by source_id = "2" (WDI)
qui keep if source_id == "2"
local src_count = _N

if (`src_count' != 4) {
    di as error "FEAT-08 FAIL: source_id '2' matched `src_count' rows, expected 4"
    local all_pass = 0
}
else {
    di as result "  PASS: Source filter found 4 WDI indicators"
}

cap frame drop _test_source

*===============================================================================
* TEST 8: Multi-field search (name AND description)
*===============================================================================

di as text _n "TEST 8: Multi-field search"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_multi)
frame change _test_multi

* Search for "population" in name OR description
qui keep if strpos(lower(name), "population") > 0 | strpos(lower(description), "population") > 0
local multi_count = _N

if (`multi_count' != 2) {
    di as error "FEAT-08 FAIL: 'population' multi-field search found `multi_count' rows, expected 2"
    local all_pass = 0
}
else {
    di as result "  PASS: Multi-field search found 2 population-related indicators"
}

cap frame drop _test_multi

*===============================================================================
* TEST 9: Exact code lookup
*===============================================================================

di as text _n "TEST 9: Exact code lookup"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_exact)
frame change _test_exact

* Direct lookup by exact code
qui keep if ind_code == "SP.POP.TOTL"
local exact_count = _N

if (`exact_count' != 1) {
    di as error "FEAT-08 FAIL: exact lookup 'SP.POP.TOTL' found `exact_count' rows, expected 1"
    local all_pass = 0
}
else {
    * Verify we got the right indicator
    local found_name = name[1]
    if (strpos("`found_name'", "Population") == 0) {
        di as error "FEAT-08 FAIL: exact lookup returned wrong indicator"
        local all_pass = 0
    }
    else {
        di as result "  PASS: Exact code lookup returned correct indicator"
    }
}

cap frame drop _test_exact

*===============================================================================
* TEST 10: List field parsing (semicolon-delimited topic_ids)
*===============================================================================

di as text _n "TEST 10: List field parsing (topic_ids)"

* Restore from cache
frame `cache_name': qui frame put *, into(_test_list)
frame change _test_list

* Find indicators with topic_id "5" in their semicolon-delimited list
qui keep if strpos(topic_ids, "5") > 0
local list_count = _N

if (`list_count' != 3) {
    di as error "FEAT-08 FAIL: topic_id '5' found in `list_count' rows, expected 3"
    local all_pass = 0
}
else {
    di as result "  PASS: List field parsing found 3 indicators with topic_id 5"
}

cap frame drop _test_list

*===============================================================================
* TEST 11: Frame persistence (survives clear)
*===============================================================================

di as text _n "TEST 11: Frame persistence"

* Verify frame survives clear (but not clear all - that's expected behavior)
clear

* Frame should still exist
cap frame `cache_name': count
if (_rc != 0) {
    di as error "FEAT-08 FAIL: frame did not survive 'clear'"
    local all_pass = 0
}
else {
    local persist_N = r(N)
    if (`persist_N' != 5) {
        di as error "FEAT-08 FAIL: frame has `persist_N' rows after clear, expected 5"
        local all_pass = 0
    }
    else {
        di as result "  PASS: Frame cache persists after clear"
    }
}

*===============================================================================
* TEST 12: Large file performance (optional - uses wbopendata fixture if present)
*===============================================================================

di as text _n "TEST 12: Large file performance"

local large_fixture "`root'/qa/fixtures/_wbopendata_indicators.yaml"
cap confirm file "`large_fixture'"

if (_rc != 0) {
    di as text "  SKIP: Large fixture not found (optional test)"
}
else {
    * Parse large file
    timer clear 3
    timer on 3
    qui yaml read using "`large_fixture'", replace bulk blockscalars strl
    qui _yaml_collapse
    timer off 3
    
    qui timer list 3
    local parse_time = r(t3)
    local large_N = _N
    
    * Run 100 exact lookups
    timer clear 4
    timer on 4
    forvalues i = 1/100 {
        qui count if ind_code == "SP.POP.TOTL"
    }
    timer off 4
    
    qui timer list 4
    local lookup_time = r(t4)
    
    di as result "  Large file: `large_N' indicators"
    di as result "  Parse time: `parse_time's"
    di as result "  100 lookups: `lookup_time's"
    
    * Performance threshold: parse < 30s, 100 lookups < 1s
    if (`parse_time' < 30 & `lookup_time' < 1) {
        di as result "  PASS: Large file performance within thresholds"
    }
    else {
        di as text "  NOTE: Performance outside ideal thresholds (not a failure)"
    }
}

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
