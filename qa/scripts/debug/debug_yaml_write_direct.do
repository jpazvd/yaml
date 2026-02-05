log using "C:/GitHub/myados/yaml/qa/logs/debug_yaml_write_direct.log", replace text
clear all
set more off
discard
adopath + "C:/GitHub/myados/yaml/src/y"
run "C:/GitHub/myados/yaml/src/y/yaml_write.ado"
yaml_write using "C:/GitHub/myados/yaml/examples/data/test_output2.yaml", replace verbose
log close
