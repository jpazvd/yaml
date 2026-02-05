*! run_tests.do
*! YAML QA runner
*! Date: 04Feb2026

clear all
set more off
set linesize 80
cap log close

* Resolve project root
local root = c(pwd)
local exdir "`root'/examples"

* Add ado path
adopath ++ "`root'/src/y"

* Log output (ignored by git)
log using "`root'/qa/logs/run_tests.log", replace text

noi di as text "{hline 70}"
noi di as text "YAML QA RUNNER"
noi di as text "{hline 70}"
noi di as text "Date: " c(current_date) " " c(current_time)
noi di as text "Root: " c(pwd)
noi di as text "Stata: " c(stata_version)
noi di as text "{hline 70}"

* -----------------------------------------------------------------------------
* Basic regression tests (examples-based)
* -----------------------------------------------------------------------------
quietly cd "`exdir'"
noi di as text "Running examples/test_yaml.do"
do "`exdir'/test_yaml.do"

noi di as text "Running examples/test_yaml_improvements.do"
do "`exdir'/test_yaml_improvements.do"

* Optional: fastscan example run
noi di as text "Running examples/yaml_basic_examples.do"
do "`exdir'/yaml_basic_examples.do"
quietly cd "`root'"

noi di as text "{hline 70}"
noi di as result "QA run completed."
noi di as text "{hline 70}"

log close
