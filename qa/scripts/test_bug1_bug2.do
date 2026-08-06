*! test_bug1_bug2.do
*! Regression tests for BUG-1 (last_key) and BUG-2 (parent_stack)
*! Date: 18Feb2026

clear all
set more off

local root = c(pwd)
adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

*===============================================================================
* TEST: Read nested YAML with list items after leaf keys
*===============================================================================

yaml read using "`root'/examples/data/test_nested_lists.yaml", replace

*-----------------------------------------------------------------------
* BUG-1 check: list items after leaf key "tags" should have parent "project_tags"
*   Expected rows: project_tags_1 = alpha, parent = project_tags
*-----------------------------------------------------------------------

local bug1_pass = 1

* Check that project_tags_1 exists with correct parent
qui count if key == "project_tags_1" & parent == "project_tags"
if (r(N) != 1) {
    di as error "BUG-1 FAIL: project_tags_1 not found with parent 'project_tags'"
    local bug1_pass = 0
}

qui count if key == "project_tags_2" & parent == "project_tags"
if (r(N) != 1) {
    di as error "BUG-1 FAIL: project_tags_2 not found with parent 'project_tags'"
    local bug1_pass = 0
}

qui count if key == "project_tags_3" & parent == "project_tags"
if (r(N) != 1) {
    di as error "BUG-1 FAIL: project_tags_3 not found with parent 'project_tags'"
    local bug1_pass = 0
}

* Check values
qui levelsof value if key == "project_tags_1", local(v1) clean
if ("`v1'" != "alpha") {
    di as error "BUG-1 FAIL: project_tags_1 value = '`v1'', expected 'alpha'"
    local bug1_pass = 0
}

if (`bug1_pass') {
    di as result "BUG-1 PASS: list items after leaf key have correct parent"
}

*-----------------------------------------------------------------------
* BUG-2 check: nested parents have correct hierarchy
*   Expected: database_options parent = database
*   Expected: database_options_flags parent = database_options
*   Expected: database_options_flags_1 parent = database_options_flags
*-----------------------------------------------------------------------

local bug2_pass = 1

qui count if key == "database_options" & parent == "database"
if (r(N) != 1) {
    di as error "BUG-2 FAIL: database_options parent should be 'database'"
    local bug2_pass = 0
}

qui count if key == "database_options_flags" & parent == "database_options"
if (r(N) != 1) {
    di as error "BUG-2 FAIL: database_options_flags parent should be 'database_options'"
    local bug2_pass = 0
}

qui count if key == "database_options_flags_1" & parent == "database_options_flags"
if (r(N) != 1) {
    di as error "BUG-2 FAIL: database_options_flags_1 parent should be 'database_options_flags'"
    local bug2_pass = 0
}

qui levelsof value if key == "database_options_flags_1", local(v1) clean
if ("`v1'" != "read_only") {
    di as error "BUG-2 FAIL: database_options_flags_1 value = '`v1'', expected 'read_only'"
    local bug2_pass = 0
}

if (`bug2_pass') {
    di as result "BUG-2 PASS: nested parents have correct hierarchy"
}

*-----------------------------------------------------------------------
* Final result
*-----------------------------------------------------------------------

if (`bug1_pass' & `bug2_pass') {
    di as result "ALL BUG-1/BUG-2 TESTS PASSED"
}
else {
    error 198
}
