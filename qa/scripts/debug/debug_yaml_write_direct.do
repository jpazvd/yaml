log using "C:/GitHub/myados/yaml-dev/qa/logs/debug_yaml_write_direct.log", replace text
clear all
set more off
discard
adopath + "C:/GitHub/myados/yaml-dev/src/y"
run "C:/GitHub/myados/yaml-dev/src/y/yaml_write.ado"
yaml_write using "C:/GitHub/myados/yaml-dev/examples/data/test_output2.yaml", replace verbose
log close
