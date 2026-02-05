*! yaml_basic_examples.do
*! Basic examples demonstrating yaml command subcommands
*! Author: João Pedro Azevedo
*! Date: December 2025

* ==============================================================================
* SETUP
* ==============================================================================

clear all
set more off
set linesize 80
cap log close
discard

* Resolve repository root
local pwd = c(pwd)
local base ""
if (fileexists("`pwd'/src/y/yaml.ado")) {
    local base "`pwd'"
}
else if (fileexists("`pwd'/../src/y/yaml.ado")) {
    local base "`pwd'/.."
}
else {
    di as err "Cannot locate src/y/yaml.ado from: `pwd'"
    exit 601
}

* Add yaml ado paths
adopath ++ "`base'/src/y"
adopath ++ "`base'/src/_"
capture program drop yaml
run "`base'/src/y/yaml.ado"

* Start log file (will be saved in the examples folder)
log using "`base'/examples/yaml_basic_examples.log", replace text

* Display header
display _n
display as text "{hline 70}"
display as result "yaml command: Stata Journal Article Examples"
display as text "{hline 70}"
display as text "Date: " c(current_date) " " c(current_time)
display as text "Stata version: " c(stata_version)
display as text "Working directory: " c(pwd)
display _n

* Data files are in examples/data/
local datadir "`base'/examples/data"

* ==============================================================================
* SECTION: yaml read
* Basic reading of YAML files
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml read"
display as result "{hline 70}" _n

* Example 1: Basic read
display as text "--- Reading config.yaml ---"
yaml read using "`datadir'/config.yaml", replace
display _n

* Example 2: Read into a frame (Stata 16+)
capture {
    display as text "--- Reading indicators.yaml into frame ---"
    yaml read using "`datadir'/indicators.yaml", frame(ind)
    display _n
}
if _rc {
    display as error "Frame support requires Stata 16+"
}

* Example 3: Fast-scan for large metadata (opt-in)
display as text "--- Fast-scan indicators.yaml (fields + listkeys + cache) ---"
yaml read using "`datadir'/indicators.yaml", fastscan ///
    fields(name description source_id topic_ids) ///
    listkeys(topic_ids topic_names) cache(ind_cache)
list in 1/5, clean noobs
display _n

* ==============================================================================
* SECTION: yaml describe
* Display structure of loaded YAML data
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml describe"
display as result "{hline 70}" _n

* Load config for describe example
yaml read using "`datadir'/config.yaml", replace

display as text "--- Describing YAML structure ---"
yaml describe
display _n

* ==============================================================================
* SECTION: yaml list
* List keys and values
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml list"
display as result "{hline 70}" _n

* Load indicators file
yaml read using "`datadir'/indicators.yaml", replace

display as text "--- Listing all keys ---"
yaml list
display _n

display as text "--- Listing keys under 'indicators' (children only) ---"
yaml list indicators, keys children
return list
display _n

* Demonstrate foreach loop with returned keys
display as text "--- Using returned keys in foreach loop ---"
yaml list indicators, keys children
foreach ind in `r(keys)' {
    display "Processing indicator: `ind'"
}
display _n

* ==============================================================================
* SECTION: yaml get
* Retrieve specific key attributes
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml get"
display as result "{hline 70}" _n

* Get attributes for a specific indicator
display as text "--- Getting attributes for CME_MRY0T4 ---"
yaml get indicators:CME_MRY0T4
return list
display _n

* Get database host from config
yaml read using "`datadir'/config.yaml", replace
display as text "--- Getting database:host ---"
yaml get database:host
return list
display _n

* ==============================================================================
* SECTION: yaml validate
* Validate configuration requirements
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml validate"
display as result "{hline 70}" _n

yaml read using "`datadir'/pipeline_config.yaml", replace

display as text "--- Validating required keys and types ---"
yaml validate, ///
    required(name version database api_endpoint) ///
    types(database_port:numeric api_timeout:numeric debug:boolean)
return list
display _n

* ==============================================================================
* SECTION: yaml dir
* List all YAML data in memory (dataset and frames)
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml dir"
display as result "{hline 70}" _n

* First, show yaml dir with current dataset loaded
display as text "--- yaml dir with YAML in current dataset ---"
yaml read using "`datadir'/config.yaml", replace
yaml dir
display _n

* Show with detail option
display as text "--- yaml dir with detail option ---"
yaml dir, detail
display _n

* ==============================================================================
* SECTION: yaml frames (Stata 16+)
* Working with multiple YAML files in frames
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml frames (Stata 16+)"
display as result "{hline 70}" _n

capture {
    * First clear any existing frames from previous examples
    capture yaml clear, all
    
    * Load multiple configurations into separate frames
    display as text "--- Loading dev and prod configs into frames ---"
    yaml read using "`datadir'/dev_config.yaml", frame(dev)
    yaml read using "`datadir'/prod_config.yaml", frame(prod)
    display _n
    
    * List ONLY frames with yaml frames
    display as text "--- yaml frames: List only YAML frames ---"
    yaml frames, detail
    display _n
    
    * Compare with yaml dir (shows dataset + frames)
    display as text "--- yaml dir: List all YAML data (dataset + frames) ---"
    yaml dir, detail
    display _n
    
    * Compare database hosts across environments
    display as text "--- Comparing database hosts ---"
    yaml get database:host, frame(dev)
    local dev_host "`r(host)'"
    
    yaml get database:host, frame(prod)
    local prod_host "`r(host)'"
    
    display "Development: `dev_host'"
    display "Production:  `prod_host'"
    display _n
}
if _rc {
    display as error "Frame support requires Stata 16+"
}

* ==============================================================================
* SECTION: YAML-driven Stata scripts
* Configuration-driven analysis workflow
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: YAML-driven Stata scripts"
display as result "{hline 70}" _n

yaml read using "`datadir'/settings.yaml", replace

display as text "--- Reading settings for data processing ---"

* Get dataset name
yaml get dataset, quiet
local datasource "`r(value)'"
display "Dataset: `datasource'"

* Get variables list
yaml list variables, values children
local varlist "`r(values)'"
display "Variables: `varlist'"

* Get filter settings
yaml get filters:country, quiet
local filter_country "`r(value)'"
display "Country filter: `filter_country'"

yaml get filters:year, quiet
local filter_year "`r(value)'"
display "Year filter: `filter_year'"
display _n

* ==============================================================================
* SECTION: Metadata harmonization
* Using YAML for consistent metadata across indicators
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: Metadata harmonization"
display as result "{hline 70}" _n

yaml read using "`datadir'/indicators.yaml", replace

display as text "--- Iterating through indicator metadata ---"
yaml list indicators, keys children
foreach ind in `r(keys)' {
    yaml get indicators:`ind', quiet
    display "`ind': `r(label)' (`r(unit)')"
}
display _n

* ==============================================================================
* SECTION: yaml write
* Writing YAML back to file
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml write"
display as result "{hline 70}" _n

* Read, modify, and write back
yaml read using "`datadir'/config.yaml", replace

display as text "--- Original version ---"
yaml get version, quiet
display "Version: `r(value)'"

* Modify the version
replace value = "2.0" if key == "version"

display as text "--- Writing modified config ---"
yaml write using "`datadir'/config_modified.yaml", replace
display _n

* Verify the change
yaml read using "`datadir'/config_modified.yaml", replace
yaml get version, quiet
display "New version: `r(value)'"
display _n

* ==============================================================================
* SECTION: UNICEF API Metadata
* Working with real-world metadata from UNICEF SDMX API
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: UNICEF API Metadata"
display as result "{hline 70}" _n

* Read UNICEF dataflows metadata (simulates API response)
display as text "--- Reading UNICEF dataflows metadata ---"
yaml read using "`datadir'/unicef_dataflows.yaml", replace
display _n

* List available dataflows
display as text "--- Available dataflows ---"
yaml list dataflows, keys children
display _n

* Get details for Child Mortality dataflow
display as text "--- CME (Child Mortality) dataflow details ---"
yaml get dataflows:CME
return list
display _n

* Read indicators metadata
display as text "--- Reading UNICEF indicators metadata ---"
yaml read using "`datadir'/unicef_indicators.yaml", replace
display _n

* Get metadata for key indicators
display as text "--- Key indicator metadata ---"
foreach ind in CME_MRY0T4 NT_ANT_HAZ_NE2_MOD IM_DTP3 {
    yaml get indicators:`ind', quiet
    display "`ind': `r(name)'"
    display "  SDG Target: `r(sdg_target)', Unit: `r(unit)'"
}
display _n

* ==============================================================================
* SECTION: yaml clear
* Clearing YAML data from memory
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE: yaml clear"
display as result "{hline 70}" _n

capture {
    display as text "--- Clearing individual frame ---"
    yaml clear dev
    
    display as text "--- Clearing all YAML frames ---"
    yaml clear, all
    display _n
}
if _rc {
    display as text "(Frame operations require Stata 16+)"
}

* ==============================================================================
* CLEANUP AND SUMMARY
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLES COMPLETED"
display as result "{hline 70}" _n

* Clean up temporary files
cap erase "`datadir'/config_modified.yaml"

display as text "All examples from the Stata Journal article have been executed."
display as text "See the log file for complete output."
display _n

log close

* End of do-file
