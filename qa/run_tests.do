*! run_tests.do
*! YAML QA runner
*! Date: 19Feb2026

clear all
discard
set more off
set linesize 80
cap log close _all

*===============================================================================
* PARSE COMMAND LINE ARGUMENTS
*===============================================================================

local args `0'
local target_test ""
local verbose 0

foreach arg of local args {
	if upper("`arg'") == "VERBOSE" {
		local verbose 1
	}
	else if upper("`arg'") == "LIST" {
		di as text _n "Available tests:"
		di as text ""
		di as text "  Environment Checks:"
		di as text "  ENV-01   yaml command is available"
		di as text "  ENV-02   yaml help file is available"
		di as text "  ENV-03   yaml version header format"
		di as text ""
		di as text "  Core Examples (smoke tests):"
		di as text "  EX-01    examples/test_yaml.do"
		di as text "  EX-02    examples/test_yaml_improvements.do"
		di as text "  EX-03    examples/yaml_basic_examples.do"
		di as text ""
		di as text "  Regression Tests:"
		di as text "  REG-01   nested lists and parent hierarchy (BUG-1/BUG-2)"
		di as text "  REG-02   frame return value propagation (BUG-3)"
		di as text "  REG-03   subcommand abbreviations (desc, frame, check)"
		di as text "  REG-04   round-trip read/write produces valid YAML (BUG-4)"
		di as text "  REG-05   yaml validate type check matches correct row (BUG-5)"
		di as text "  REG-06   fastread handles brackets/braces in values (BUG-6)"
		di as text "  REG-07   early-exit does not double-close file handle (BUG-7)"
		di as text "  REG-08   yaml list header with parent filter (BUG-8)"
		di as text ""
		di as text "  Feature Tests (v1.6.0):"
		di as text "  FEAT-01  embedded double quotes via Mata st_sstore"
		di as text "  FEAT-02  block scalar support in canonical parser"
		di as text "  FEAT-03  continuation lines for multi-line scalars"
		di as text "  FEAT-04  strL option prevents value truncation"
		di as text "  FEAT-05  Mata bulk-load produces correct output (Phase 2)"
		di as text "  FEAT-06  collapse option produces wide-format output (Phase 2)"
		exit
	}
	else {
		local target_test "`arg'"
	}
}

*===============================================================================
* SETUP
*===============================================================================

local root = c(pwd)
local exdir "`root'/examples"
local qadir "`root'/qa"
local logfile "`qadir'/logs/run_tests.log"
local histfile "`qadir'/test_history.txt"

adopath ++ "`root'/src/y"
adopath ++ "`root'/src/_"

cap log close _testlog
cap log using "`logfile'", replace text name(_testlog)
if _rc != 0 {
	local timestamp = subinstr(c(current_time),":","-",.)
	local logfile "`qadir'/logs/run_tests_`timestamp'.log"
	log using "`logfile'", replace text name(_testlog)
}

* Capture start time
local start_time = c(current_time)

* Extract yaml.ado version
local ado_version "unknown"
cap findfile yaml.ado
if _rc == 0 {
	local fn = r(fn)
	local fnsafe = subinstr("`fn'","\\","/",.)
	tempname fh
	cap file open `fh' using "`fnsafe'", read
	if _rc == 0 {
		file read `fh' line
		while r(eof)==0 & "`ado_version'"=="unknown" {
			if regexm(`"`line'"', "^[*]! v ([0-9]+[.][0-9]+[.][0-9]+)") {
				local ado_version = regexs(1)
			}
			file read `fh' line
		}
		file close `fh'
	}
}

* Get git branch name
local git_branch "(unknown)"
cap {
	tempfile gitbranch
	shell git -C "`root'" branch --show-current > "`gitbranch'" 2>&1
	tempname gbfh
	file open `gbfh' using "`gitbranch'", read text
	file read `gbfh' git_branch
	file close `gbfh'
	local git_branch = strtrim("`git_branch'")
	if "`git_branch'" == "" local git_branch "(unknown)"
}

if `verbose' == 1 {
	set trace on
	set tracedepth 4
}

global test_count = 0
global pass_count = 0
global fail_count = 0
global skip_count = 0
global failed_tests = ""

*===============================================================================
* HELPER PROGRAMS
*===============================================================================

qui do "`qadir'/_define_helpers.do"

*===============================================================================
* DISPLAY HEADER
*===============================================================================

di as text "{hline 70}"
di as text "YAML QA RUNNER"
di as text "{hline 70}"
di as text "Date: " c(current_date) " " c(current_time)
di as text "Root: " c(pwd)
di as text "Stata: " c(stata_version)
if "`target_test'" != "" {
	di as text "Target Test: " "`target_test'"
}
if `verbose' == 1 {
	di as text "Verbose Mode: ENABLED"
}
di as text "{hline 70}"

*===============================================================================
* TESTS
*===============================================================================

* ENV-01: yaml command is available
if "`target_test'" == "" | "`target_test'" == "ENV-01" {
	test_start, id("ENV-01") desc("yaml command is available")
	capture which yaml
	if _rc == 0 {
		test_pass, id("ENV-01")
	}
	else {
		test_fail, id("ENV-01") msg("yaml not found in adopath (rc=`=_rc')")
	}
}

* ENV-02: help file is available
if "`target_test'" == "" | "`target_test'" == "ENV-02" {
	test_start, id("ENV-02") desc("yaml help file is available")
	capture help yaml
	if _rc == 0 {
		test_pass, id("ENV-02")
	}
	else {
		test_fail, id("ENV-02") msg("help yaml failed (rc=`=_rc')")
	}
}

* ENV-03: version header format
if "`target_test'" == "" | "`target_test'" == "ENV-03" {
	test_start, id("ENV-03") desc("yaml version header format")
	cap findfile yaml.ado
	if _rc != 0 {
		test_fail, id("ENV-03") msg("yaml.ado not found (rc=`=_rc')")
	}
	else {
		local fn = r(fn)
		local fnsafe = subinstr("`fn'","\\","/",.)
		tempname fh
		cap file open `fh' using "`fnsafe'", read
		if _rc != 0 {
			test_fail, id("ENV-03") msg("unable to read yaml.ado (rc=`=_rc')")
		}
		else {
			local vmatch 0
			file read `fh' line
			while r(eof)==0 & `vmatch'==0 {
				if regexm(`"`line'"', "^[*]! v [0-9]+[.][0-9]+[.][0-9]+") {
					local vmatch 1
				}
				file read `fh' line
			}
			file close `fh'
			if `vmatch' == 1 {
				test_pass, id("ENV-03")
			}
			else {
				test_fail, id("ENV-03") msg("version header not found")
			}
		}
	}
}

* EX-01: examples/test_yaml.do
if "`target_test'" == "" | "`target_test'" == "EX-01" {
	test_start, id("EX-01") desc("examples/test_yaml.do")
	quietly cd "`exdir'"
	capture quietly do "test_yaml.do"
	local erc = _rc
	quietly cd "`root'"
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("EX-01")
	}
	else {
		test_fail, id("EX-01") msg("test_yaml.do failed (rc=`erc')")
	}
}

* EX-02: examples/test_yaml_improvements.do
if "`target_test'" == "" | "`target_test'" == "EX-02" {
	test_start, id("EX-02") desc("examples/test_yaml_improvements.do")
	quietly cd "`exdir'"
	capture quietly do "test_yaml_improvements.do"
	local erc = _rc
	quietly cd "`root'"
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("EX-02")
	}
	else {
		test_fail, id("EX-02") msg("test_yaml_improvements.do failed (rc=`erc')")
	}
}

* EX-03: examples/yaml_basic_examples.do
if "`target_test'" == "" | "`target_test'" == "EX-03" {
	test_start, id("EX-03") desc("examples/yaml_basic_examples.do")
	quietly cd "`exdir'"
	capture quietly do "yaml_basic_examples.do"
	local erc = _rc
	quietly cd "`root'"
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("EX-03")
	}
	else {
		test_fail, id("EX-03") msg("yaml_basic_examples.do failed (rc=`erc')")
	}
}

* REG-01: nested lists and parent hierarchy (BUG-1/BUG-2)
if "`target_test'" == "" | "`target_test'" == "REG-01" {
	test_start, id("REG-01") desc("nested lists and parent hierarchy (BUG-1/BUG-2)")
	capture quietly do "`qadir'/scripts/test_bug1_bug2.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-01")
	}
	else {
		test_fail, id("REG-01") msg("test_bug1_bug2.do failed (rc=`erc')")
	}
}

* REG-02: frame return value propagation (BUG-3)
if "`target_test'" == "" | "`target_test'" == "REG-02" {
	test_start, id("REG-02") desc("frame return value propagation (BUG-3)")
	if `c(stata_version)' >= 16 {
		capture quietly do "`qadir'/scripts/test_bug3_frame_returns.do"
		local erc = _rc
		qui do "`qadir'/_define_helpers.do"
		if `erc' == 0 {
			test_pass, id("REG-02")
		}
		else {
			test_fail, id("REG-02") msg("test_bug3_frame_returns.do failed (rc=`erc')")
		}
	}
	else {
		test_skip, id("REG-02") msg("requires Stata 16+ (frames)")
	}
}

* REG-03: subcommand abbreviations (desc, frame, check)
if "`target_test'" == "" | "`target_test'" == "REG-03" {
	test_start, id("REG-03") desc("subcommand abbreviations (desc, frame, check)")
	capture quietly do "`qadir'/scripts/test_abbreviations.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-03")
	}
	else {
		test_fail, id("REG-03") msg("test_abbreviations.do failed (rc=`erc')")
	}
}

* REG-04: round-trip read/write produces valid YAML (BUG-4)
if "`target_test'" == "" | "`target_test'" == "REG-04" {
	test_start, id("REG-04") desc("round-trip read/write produces valid YAML (BUG-4)")
	capture quietly do "`qadir'/scripts/test_roundtrip.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-04")
	}
	else {
		test_fail, id("REG-04") msg("test_roundtrip.do failed (rc=`erc')")
	}
}

* REG-05: yaml validate type check matches correct row (BUG-5)
if "`target_test'" == "" | "`target_test'" == "REG-05" {
	test_start, id("REG-05") desc("yaml validate type check matches correct row (BUG-5)")
	capture quietly do "`qadir'/scripts/test_validate_types.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-05")
	}
	else {
		test_fail, id("REG-05") msg("test_validate_types.do failed (rc=`erc')")
	}
}

* REG-06: fastread handles brackets/braces in values (BUG-6)
if "`target_test'" == "" | "`target_test'" == "REG-06" {
	test_start, id("REG-06") desc("fastread handles brackets/braces in values (BUG-6)")
	capture quietly do "`qadir'/scripts/test_brackets_in_values.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-06")
	}
	else {
		test_fail, id("REG-06") msg("test_brackets_in_values.do failed (rc=`erc')")
	}
}

* REG-07: early-exit does not double-close file handle (BUG-7)
if "`target_test'" == "" | "`target_test'" == "REG-07" {
	test_start, id("REG-07") desc("early-exit does not double-close file handle (BUG-7)")
	capture quietly do "`qadir'/scripts/test_early_exit.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-07")
	}
	else {
		test_fail, id("REG-07") msg("test_early_exit.do failed (rc=`erc')")
	}
}

* REG-08: yaml list header displays correctly with parent filter (BUG-8)
if "`target_test'" == "" | "`target_test'" == "REG-08" {
	test_start, id("REG-08") desc("yaml list header with parent filter (BUG-8)")
	capture quietly do "`qadir'/scripts/test_list_header.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("REG-08")
	}
	else {
		test_fail, id("REG-08") msg("test_list_header.do failed (rc=`erc')")
	}
}

*===============================================================================
* FEATURE TESTS (v1.6.0)
*===============================================================================

* FEAT-01: embedded double quotes via Mata st_sstore
if "`target_test'" == "" | "`target_test'" == "FEAT-01" {
	test_start, id("FEAT-01") desc("embedded double quotes via Mata st_sstore")
	capture quietly do "`qadir'/scripts/test_embedded_quotes.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-01")
	}
	else {
		test_fail, id("FEAT-01") msg("test_embedded_quotes.do failed (rc=`erc')")
	}
}

* FEAT-02: block scalar support in canonical parser
if "`target_test'" == "" | "`target_test'" == "FEAT-02" {
	test_start, id("FEAT-02") desc("block scalar support in canonical parser")
	capture quietly do "`qadir'/scripts/test_block_scalars.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-02")
	}
	else {
		test_fail, id("FEAT-02") msg("test_block_scalars.do failed (rc=`erc')")
	}
}

* FEAT-03: continuation lines for multi-line scalars
if "`target_test'" == "" | "`target_test'" == "FEAT-03" {
	test_start, id("FEAT-03") desc("continuation lines for multi-line scalars")
	capture quietly do "`qadir'/scripts/test_continuation_lines.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-03")
	}
	else {
		test_fail, id("FEAT-03") msg("test_continuation_lines.do failed (rc=`erc')")
	}
}

* FEAT-04: strL option prevents value truncation
if "`target_test'" == "" | "`target_test'" == "FEAT-04" {
	test_start, id("FEAT-04") desc("strL option prevents value truncation")
	capture quietly do "`qadir'/scripts/test_strl_option.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-04")
	}
	else {
		test_fail, id("FEAT-04") msg("test_strl_option.do failed (rc=`erc')")
	}
}

* FEAT-05: Mata bulk-load produces correct output (Phase 2 — skips if not implemented)
if "`target_test'" == "" | "`target_test'" == "FEAT-05" {
	test_start, id("FEAT-05") desc("Mata bulk-load produces correct output")
	capture quietly do "`qadir'/scripts/test_mata_bulk.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-05")
	}
	else {
		test_fail, id("FEAT-05") msg("test_mata_bulk.do failed (rc=`erc')")
	}
}

* FEAT-06: collapse option produces wide-format output (Phase 2 — skips if not implemented)
if "`target_test'" == "" | "`target_test'" == "FEAT-06" {
	test_start, id("FEAT-06") desc("collapse option produces wide-format output")
	capture quietly do "`qadir'/scripts/test_collapse.do"
	local erc = _rc
	qui do "`qadir'/_define_helpers.do"
	if `erc' == 0 {
		test_pass, id("FEAT-06")
	}
	else {
		test_fail, id("FEAT-06") msg("test_collapse.do failed (rc=`erc')")
	}
}

*===============================================================================
* SUMMARY
*===============================================================================

di as text ""
di as text "{hline 70}"
di as text "{bf:{center 70:TEST SUMMARY}}"
di as text "{hline 70}"
di as text ""
di as text "  Total Tests:   " as result $test_count
di as result "  Passed:        " $pass_count
if $fail_count > 0 {
	di as err "  Failed:        " $fail_count
}
else {
	di as text "  Failed:        " as result $fail_count
}
di as text "  Skipped:       " $skip_count
di as text ""

if $fail_count == 0 {
	di as result "  ALL TESTS PASSED"
}
else {
	di as err "  SOME TESTS FAILED"
	di as text "  Failed: $failed_tests"
}
di as text "{hline 70}"

log close _testlog

*===============================================================================
* WRITE TO TEST HISTORY
*===============================================================================

* Capture end time and calculate duration
local end_time = c(current_time)
local start_h = real(substr("`start_time'", 1, 2))
local start_m = real(substr("`start_time'", 4, 2))
local start_s = real(substr("`start_time'", 7, 2))
local end_h = real(substr("`end_time'", 1, 2))
local end_m = real(substr("`end_time'", 4, 2))
local end_s = real(substr("`end_time'", 7, 2))
local start_secs = `start_h' * 3600 + `start_m' * 60 + `start_s'
local end_secs = `end_h' * 3600 + `end_m' * 60 + `end_s'
local duration_secs = `end_secs' - `start_secs'
if `duration_secs' < 0 local duration_secs = `duration_secs' + 86400
local duration_min = floor(`duration_secs' / 60)
local duration_sec = mod(`duration_secs', 60)
local duration_str = "`duration_min'm `duration_sec's"

* Write to history file (only if running all tests)
if "`target_test'" == "" {
	local sep "======================================================================"

	cap file open fh using "`histfile'", write append
	if _rc == 0 {
		file write fh _n "`sep'" _n
		file write fh "Test Run:  `c(current_date)'" _n
		file write fh "Started:   `start_time'" _n
		file write fh "Ended:     `end_time'" _n
		file write fh "Duration:  `duration_str'" _n
		file write fh "Branch:    `git_branch'" _n
		file write fh "Version:   `ado_version'" _n
		file write fh "Stata:     `c(stata_version)'" _n
		file write fh "Tests:     $test_count run, $pass_count passed, $fail_count failed" _n
		file write fh "Skipped:   $skip_count" _n
		if $fail_count == 0 {
			file write fh "Result:    ALL TESTS PASSED" _n
		}
		else {
			file write fh "Result:    FAILED" _n
			file write fh "Failed:    $failed_tests" _n
		}
		file write fh "Log:       run_tests.log" _n
		file write fh "`sep'" _n
		file close fh

		di as text "History appended to: `histfile'"
	}
}
else {
	di as text "(Single test mode - history not updated)"
}
