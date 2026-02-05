log using "C:/GitHub/myados/yaml/qa/logs/debug_yaml_write.log", replace text
clear all
set more off
discard
adopath + "C:/GitHub/myados/yaml/src/y"
adopath + "C:/GitHub/myados/yaml/src/_"
run "C:/GitHub/myados/yaml/src/y/yaml.ado"
which yaml_write
yaml read using "C:/GitHub/myados/yaml/examples/data/test_config.yaml", replace
yaml write using "C:/GitHub/myados/yaml/examples/data/test_output2.yaml", replace verbose
log close
