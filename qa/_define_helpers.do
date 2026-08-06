*! _define_helpers.do
*! Define (or restore) test helper programs for run_tests.do
*! Sourced at start and after each sub-do-file that may clear all

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
