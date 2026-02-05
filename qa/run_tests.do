*! run_tests.do
*! YAML QA runner
*! Date: 05Feb2026

clear all
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

capture program drop test_start
program define test_start
	syntax, id(string) desc(string)

	global test_count = $test_count + 1
	di as text ""
	di as text "{hline 70}"
	di as result "TEST `id': " as text "`desc'"
	di as text "{hline 70}"
end

capture program drop test_pass
program define test_pass
	syntax, id(string)
	global pass_count = $pass_count + 1
	di as result "PASS `id'"
end

capture program drop test_fail
program define test_fail
	syntax, id(string) msg(string)
	global fail_count = $fail_count + 1
	global failed_tests = "$failed_tests `id'"
	di as error "FAIL `id': `msg'"
end

capture program drop test_skip
program define test_skip
	syntax, id(string) msg(string)
	global skip_count = $skip_count + 1
	di as text "SKIP `id': `msg'"
end

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
				if regexm("`line'", "^\\*! v [0-9]+\\.[0-9]+\\.[0-9]+") {
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
	capture quietly do "`exdir'/test_yaml.do"
	if _rc == 0 {
		test_pass, id("EX-01")
	}
	else {
		test_fail, id("EX-01") msg("test_yaml.do failed (rc=`=_rc')")
	}
}

* EX-02: examples/test_yaml_improvements.do
if "`target_test'" == "" | "`target_test'" == "EX-02" {
	test_start, id("EX-02") desc("examples/test_yaml_improvements.do")
	capture quietly do "`exdir'/test_yaml_improvements.do"
	if _rc == 0 {
		test_pass, id("EX-02")
	}
	else {
		test_fail, id("EX-02") msg("test_yaml_improvements.do failed (rc=`=_rc')")
	}
}

* EX-03: examples/yaml_basic_examples.do
if "`target_test'" == "" | "`target_test'" == "EX-03" {
	test_start, id("EX-03") desc("examples/yaml_basic_examples.do")
	capture quietly do "`exdir'/yaml_basic_examples.do"
	if _rc == 0 {
		test_pass, id("EX-03")
	}
	else {
		test_fail, id("EX-03") msg("yaml_basic_examples.do failed (rc=`=_rc')")
	}
}

*===============================================================================
* SUMMARY
*===============================================================================

di as text ""
di as text "{hline 70}"
di as text "SUMMARY"
di as text "{hline 70}"
di as text "Tests run: " $test_count
di as text "Passed:    " $pass_count
di as text "Failed:    " $fail_count
di as text "Skipped:   " $skip_count
if "$failed_tests" != "" {
	di as text "Failed tests: " "$failed_tests"
}
di as text "{hline 70}"

cap file open fh using "`histfile'", write append
if _rc == 0 {
	file write fh "`c(current_date)' `c(current_time)'" _tab "pass=$pass_count fail=$fail_count skip=$skip_count" _n
	file close fh
}

log close _testlog
