log using "C:/GitHub/myados/yaml/qa/logs/trace_yaml_clear.log", replace text
clear all
set more off
discard
adopath + "C:/GitHub/myados/yaml/src/y"
adopath + "C:/GitHub/myados/yaml/src/_"
run "C:/GitHub/myados/yaml/src/y/yaml.ado"
yaml read using "C:/GitHub/myados/yaml/examples/data/test_config.yaml", frame(cfg)
yaml read using "C:/GitHub/myados/yaml/examples/data/test_config.yaml", frame(cfg2)
set tracedepth 2
set trace on
yaml clear, all
set trace off
log close
