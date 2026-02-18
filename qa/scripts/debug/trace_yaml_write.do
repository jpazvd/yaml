log using "C:/GitHub/myados/yaml-dev/qa/logs/trace_yaml_write.log", replace text
clear all
set more off
discard
adopath + "C:/GitHub/myados/yaml-dev/src/y"
adopath + "C:/GitHub/myados/yaml-dev/src/_"
run "C:/GitHub/myados/yaml-dev/src/y/yaml.ado"
yaml read using "C:/GitHub/myados/yaml-dev/examples/data/test_config.yaml", replace
set tracedepth 2
set trace on
yaml write using "C:/GitHub/myados/yaml-dev/examples/data/test_output2.yaml", replace verbose
set trace off
log close
