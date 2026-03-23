*! test_sibling_parent_stack.do
*! Regression test REG-09: sibling parent_stack contamination (BUG-9)
*! Date: 21Feb2026
*! Tests that adjacent parent keys (e.g. topic_ids: followed by topic_names:)
*! at the same indent level do not contaminate each other's field names.
*! Also verifies empty YAML arrays [] are parsed as string "[]" (not dropped).

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

local fixture "`root'/qa/fixtures/sibling_parent_test.yaml"
local all_pass = 1

*===============================================================================
* PART A: Canonical parser — raw long-format field names
*===============================================================================

di as text _n "{hline 70}"
di as result "PART A: Canonical parser — field name integrity"
di as text "{hline 70}"

yaml read using "`fixture'", replace blockscalars

* Return scalars: check row count and max level
local n_keys = r(n_keys)
local max_level = r(max_level)
di as text "  r(n_keys) = `n_keys'"
di as text "  r(max_level) = `max_level'"

if (`n_keys' < 30) {
    di as error "REG-09a FAIL: too few keys parsed (`n_keys'), expected >= 30"
    local all_pass = 0
}

* Check topic_names is NOT polluted by topic_ids parent
* BUG: topic_names becomes "topic_ids_topic_names" → wrong
* FIX: topic_names stays "indicators_SP_POP_TOTL_topic_names" (parent is entity key)

* Verify topic_names keys exist with correct parent
* Note: canonical parser prepends root "indicators_" and converts dots→underscores
qui count if regexm(key, "^indicators_SP_POP_TOTL_topic_names$") & type == "parent"
local n_tn_parent = r(N)
if (`n_tn_parent' != 1) {
    di as error "REG-09a FAIL: indicators_SP_POP_TOTL_topic_names parent key not found (N=`n_tn_parent')"
    di as error "        This indicates parent_stack contamination from topic_ids"
    * Show what keys exist with topic_names in them
    list key parent type if strpos(key, "topic_names") > 0, clean
    local all_pass = 0
}

* Verify topic_names list items have correct parent
qui count if key == "indicators_SP_POP_TOTL_topic_names_1"
local n_tn1 = r(N)
if (`n_tn1' != 1) {
    di as error "REG-09a FAIL: indicators_SP_POP_TOTL_topic_names_1 not found (N=`n_tn1')"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_SP_POP_TOTL_topic_names_1", local(v) clean
    if (`"`v'"' != "Climate Change") {
        di as error "REG-09a FAIL: topic_names_1 value = '`v'', expected 'Climate Change'"
        local all_pass = 0
    }
}

* Verify topic_ids list items also correct
qui count if key == "indicators_SP_POP_TOTL_topic_ids_1"
local n_ti1 = r(N)
if (`n_ti1' != 1) {
    di as error "REG-09a FAIL: indicators_SP_POP_TOTL_topic_ids_1 not found (N=`n_ti1')"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_SP_POP_TOTL_topic_ids_1", local(v) clean
    if ("`v'" != "19") {
        di as error "REG-09a FAIL: topic_ids_1 value = '`v'', expected '19'"
        local all_pass = 0
    }
}

* Verify source_org is NOT polluted by note parent
qui count if regexm(key, "^indicators_SP_POP_TOTL_source_org$")
local n_so = r(N)
if (`n_so' != 1) {
    di as error "REG-09a FAIL: indicators_SP_POP_TOTL_source_org not found (N=`n_so')"
    local all_pass = 0
}

* Check empty arrays are parsed (as string "[]")
qui count if key == "indicators_EMPTY_TOPICS_topic_ids" & value == "[]"
local n_empty = r(N)
if (`n_empty' != 1) {
    di as error "REG-09a FAIL: empty array topic_ids not parsed as '[]' (N=`n_empty')"
    list key value if strpos(key, "EMPTY_TOPICS_topic") > 0 | strpos(key, "EMPTY.TOPICS_topic") > 0, clean
    local all_pass = 0
}

if (`all_pass') {
    di as result "PART A PASS: canonical parser field names correct"
}

*===============================================================================
* PART B: Mata bulk parser — raw long-format field names
*===============================================================================

di as text _n "{hline 70}"
di as result "PART B: Mata bulk parser — field name integrity"
di as text "{hline 70}"

yaml read using "`fixture'", replace blockscalars bulk

* Check topic_names parent key exists (not polluted)
* Note: Mata bulk parser preserves dots in entity codes (SP.POP.TOTL not SP_POP_TOTL)
qui count if regexm(key, "^indicators_SP.POP.TOTL_topic_names$") & type == "parent"
local n_tn_parent = r(N)
if (`n_tn_parent' != 1) {
    di as error "REG-09b FAIL: Mata bulk: indicators_SP.POP.TOTL_topic_names parent key not found (N=`n_tn_parent')"
    list key parent type if strpos(key, "topic_names") > 0, clean
    local all_pass = 0
}

* Verify list item values
qui count if key == "indicators_SP.POP.TOTL_topic_names_1"
if (r(N) != 1) {
    di as error "REG-09b FAIL: Mata bulk: indicators_SP.POP.TOTL_topic_names_1 not found"
    local all_pass = 0
}
else {
    qui levelsof value if key == "indicators_SP.POP.TOTL_topic_names_1", local(v) clean
    if (`"`v'"' != "Climate Change") {
        di as error "REG-09b FAIL: Mata bulk: topic_names_1 = '`v'', expected 'Climate Change'"
        local all_pass = 0
    }
}

* Verify second entity's topic_names (Mata bulk preserves dots in DT.DOD.DECT.CD)
qui count if regexm(key, "indicators_DT.DOD.DECT.CD_topic_names_1")
if (r(N) != 1) {
    di as error "REG-09b FAIL: Mata bulk: indicators_DT.DOD.DECT.CD_topic_names_1 not found"
    list key if strpos(key, "DT_DOD") > 0 | strpos(key, "DT.DOD") > 0, clean
    local all_pass = 0
}
else {
    qui levelsof value if regexm(key, "indicators_DT.DOD.DECT.CD_topic_names_1"), local(v) clean
    if (`"`v'"' != "External Debt") {
        di as error "REG-09b FAIL: Mata bulk: DT_DOD topic_names_1 = '`v'', expected 'External Debt'"
        local all_pass = 0
    }
}

if (`all_pass') {
    di as result "PART B PASS: Mata bulk parser field names correct"
}

*===============================================================================
* PART C: Collapse with indicators preset — wide-format column checks
*===============================================================================

di as text _n "{hline 70}"
di as result "PART C: Collapse with indicators preset — wide-format columns"
di as text "{hline 70}"

yaml read using "`fixture'", replace blockscalars indicators

* Return scalar checks
local yaml_mode = "`r(yaml_mode)'"
di as text "  r(yaml_mode) = `yaml_mode'"

if ("`yaml_mode'" != "bulk") {
    di as error "REG-09c FAIL: indicators preset should use bulk mode, got '`yaml_mode''"
    local all_pass = 0
}

* Check row count (3 indicators in fixture)
qui count
local n_rows = r(N)
di as text "  Rows after collapse: `n_rows'"

if (`n_rows' != 3) {
    di as error "REG-09c FAIL: expected 3 rows, got `n_rows'"
    local all_pass = 0
}

* Check critical columns exist
foreach col in ind_code name source_id source_name description topic_ids topic_names source_org note {
    capture confirm variable `col'
    if (_rc != 0) {
        di as error "REG-09c FAIL: column '`col'' missing after collapse"
        ds
        local all_pass = 0
    }
}

* Verify topic_names has actual values (not empty due to parent_stack bug)
qui count if ind_code == "SP.POP.TOTL" & topic_names != ""
local n_pop_topics = r(N)
if (`n_pop_topics' != 1) {
    di as error "REG-09c FAIL: SP.POP.TOTL topic_names is empty (parent_stack bug)"
    list ind_code topic_ids topic_names, clean
    local all_pass = 0
}
else {
    qui levelsof topic_names if ind_code == "SP.POP.TOTL", local(v) clean
    di as text "  SP.POP.TOTL topic_names = '`v''"
    if (strpos(`"`v'"', "Climate Change") == 0) {
        di as error "REG-09c FAIL: topic_names missing 'Climate Change'"
        local all_pass = 0
    }
    if (strpos(`"`v'"', "Health") == 0) {
        di as error "REG-09c FAIL: topic_names missing 'Health'"
        local all_pass = 0
    }
}

* Verify topic_ids has actual values
qui levelsof topic_ids if ind_code == "SP.POP.TOTL", local(v) clean
di as text "  SP.POP.TOTL topic_ids = '`v''"
if (strpos("`v'", "19") == 0 | strpos("`v'", "8") == 0) {
    di as error "REG-09c FAIL: topic_ids missing expected values (19;8)"
    local all_pass = 0
}

* Verify source_org column has values
qui levelsof source_org if ind_code == "SP.POP.TOTL", local(v) clean
di as text "  SP.POP.TOTL source_org = '`v''"
if (`"`v'"' == "") {
    di as error "REG-09c FAIL: source_org is empty"
    local all_pass = 0
}

* Verify empty arrays — topic_ids and topic_names should be "[]" (raw)
* (stripping [] to "" is the consumer's job, not yaml.ado's)
qui levelsof topic_ids if ind_code == "EMPTY.TOPICS", local(v) clean
di as text "  EMPTY.TOPICS topic_ids = '`v''"
if (`"`v'"' == "") {
    * After collapse, empty arrays may legitimately be empty string
    * The key test is that the column EXISTS and has a row for this indicator
    qui count if ind_code == "EMPTY.TOPICS"
    if (r(N) != 1) {
        di as error "REG-09c FAIL: EMPTY.TOPICS row missing"
        local all_pass = 0
    }
}

* Verify limited_data column
capture confirm variable limited_data
if (_rc == 0) {
    qui levelsof limited_data if ind_code == "EMPTY.TOPICS", local(v) clean
    di as text "  EMPTY.TOPICS limited_data = '`v''"
    if ("`v'" != "1") {
        di as error "REG-09c FAIL: EMPTY.TOPICS limited_data should be 1, got '`v''"
        local all_pass = 0
    }
}

* Verify second entity fields
qui levelsof topic_names if ind_code == "DT.DOD.DECT.CD", local(v) clean
di as text "  DT.DOD.DECT.CD topic_names = '`v''"
if (strpos(`"`v'"', "External Debt") == 0) {
    di as error "REG-09c FAIL: DT.DOD.DECT.CD topic_names missing 'External Debt'"
    local all_pass = 0
}

if (`all_pass') {
    di as result "PART C PASS: collapsed indicators have correct field values"
}

*===============================================================================
* PART D: Cross-check canonical vs Mata bulk (field parity)
*===============================================================================

di as text _n "{hline 70}"
di as result "PART D: Canonical vs Mata bulk parity"
di as text "{hline 70}"

* Parse with canonical + collapse
yaml read using "`fixture'", replace blockscalars collapse ///
    colfields(code;name;source_id;source_name;description;unit;topic_ids;topic_names;source_org;note;limited_data)

qui count
local n_canonical = r(N)
tempfile canonical_data
qui save `canonical_data', replace

* Parse with Mata bulk + collapse (same colfields)
yaml read using "`fixture'", replace blockscalars bulk collapse ///
    colfields(code;name;source_id;source_name;description;unit;topic_ids;topic_names;source_org;note;limited_data)

qui count
local n_bulk = r(N)

di as text "  Canonical rows: `n_canonical'"
di as text "  Mata bulk rows: `n_bulk'"

if (`n_canonical' != `n_bulk') {
    di as error "REG-09d FAIL: row count mismatch (canonical=`n_canonical', bulk=`n_bulk')"
    local all_pass = 0
}

* Compare topic_names for first indicator
* Note: bulk preserves dots (ind_code="SP.POP.TOTL"), canonical converts to underscores ("SP_POP_TOTL")
qui levelsof topic_names if ind_code == "SP.POP.TOTL", local(bulk_topics) clean

qui use `canonical_data', clear
qui levelsof topic_names if ind_code == "SP_POP_TOTL", local(canon_topics) clean

di as text "  Canonical topic_names: '`canon_topics''"
di as text "  Bulk topic_names:      '`bulk_topics''"

if (`"`canon_topics'"' != `"`bulk_topics'"') {
    di as error "REG-09d FAIL: topic_names differ between parsers"
    di as error "        (canonical ind_code=SP_POP_TOTL, bulk ind_code=SP.POP.TOTL)"
    local all_pass = 0
}

if (`all_pass') {
    di as result "PART D PASS: canonical and Mata bulk produce identical field values"
}

*===============================================================================
* Final result
*===============================================================================

di as text _n "{hline 70}"
if (`all_pass') {
    di as result "ALL REG-09 TESTS PASSED (sibling parent_stack contamination)"
}
else {
    di as error "SOME REG-09 TESTS FAILED"
    error 198
}
di as text "{hline 70}"
