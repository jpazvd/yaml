*! yaml_sj_article_examples.do
*! Do-file reproducing examples from the Stata Journal article
*! "Reading and writing YAML files in Stata"
*! Author: João Pedro Azevedo
*! Date: December 2025

* ==============================================================================
* INTRODUCTION
* ==============================================================================
*
* This example demonstrates how to use the yaml command to work with metadata
* downloaded from the UNICEF SDMX API. The UNICEF SDMX API provides access to
* child-related indicators through standardized endpoints:
*
*   Base URL: https://sdmx.data.unicef.org/ws/public/sdmxapi/rest
*
* Key endpoints:
*   - /dataflow/UNICEF    : List of available dataflows (indicator categories)
*   - /codelist/UNICEF/CL_INDICATOR : Indicator codelist with definitions
*   - /data/UNICEF,{flow} : Download data for specific dataflow
*
* The metadata files used here simulate the structure returned by these APIs,
* converted to YAML format for easy processing in Stata.
*
* NOTE: yaml write creates PHYSICAL FILES on disk. It does not write to 
*       frames in memory. Frames are only used for reading/storing YAML
*       data in memory during a session.
*
* ==============================================================================

clear all
set more off
set linesize 80
cap log close

* Set working directory (portable: works from any clone location)
* Override below if your repo root differs
local reporoot "`c(pwd)'"
cap: cd "`reporoot'"

* Load the yaml command
run "`reporoot'/src/y/yaml.ado"

* Start log
log using "examples/yaml_sj_article_examples.log", replace text

* Display header
display _n
display as text "{hline 70}"
display as result "yaml command: UNICEF API Metadata Example"
display as text "{hline 70}"
display as text "Date: " c(current_date) " " c(current_time)
display as text "Stata version: " c(stata_version)
display _n

local datadir "examples/data"

* ==============================================================================
* PART 0: Download Data from UNICEF SDMX API
* ==============================================================================
*
* This section demonstrates downloading indicator data directly from the
* UNICEF SDMX API and then creating YAML metadata files using yaml write.
*
* The UNICEF SDMX API returns data in CSV format when requested:
*   https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,CME,1.0/.CME_MRY0T4.?format=csv&labels=both
*
* Note: The UNICEF SDMX API may be temporarily unavailable. The script handles
* this gracefully by using pre-downloaded sample data when the API is offline.
* See: https://data.unicef.org/sdmx-api-documentation/

display as result _n "{hline 70}"
display as result "PART 0: Download from UNICEF SDMX API"
display as result "{hline 70}" _n

* Define API base URL
local api_base "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

* Download Under-5 Mortality Rate data (CME_MRY0T4)
display as text "--- Downloading CME_MRY0T4 (Under-5 mortality) from API ---"

local indicator "CME_MRY0T4"
local dataflow "CME"
local api_url "`api_base'/data/UNICEF,`dataflow',1.0/.`indicator'.?format=csv&labels=both"

display as text "URL: `api_url'"
display _n

* Download the CSV data
capture {
    import delimited "`api_url'", clear varnames(1)
    local download_ok = 1
}
if _rc {
    display as error "Note: API download failed (requires internet connection)"
    display as text "Using pre-downloaded sample data instead..."
    local download_ok = 0
}

if (`download_ok' == 1) {
    * Rename variables to lowercase for consistency
    * (SDMX API returns uppercase names like REF_AREA, INDICATOR, etc.)
    capture rename REF_AREA ref_area
    capture rename INDICATOR indicator
    capture rename TIME_PERIOD time_period
    capture rename OBS_VALUE obs_value
    capture rename DATAFLOW dataflow
    
    * Generate dataflow from indicator prefix if not present
    capture confirm variable dataflow
    if _rc {
        gen dataflow = substr(indicator, 1, strpos(indicator, "_") - 1)
    }
    
    * Show what we downloaded
    display as text "--- Downloaded data structure ---"
    describe, short
    display _n
    
    * Show first few observations
    display as text "--- Sample of downloaded data ---"
    list dataflow indicator ref_area time_period obs_value in 1/10, clean noobs
    display _n
    
    * Save raw data
    save "`datadir'/api_download_raw.dta", replace
    
    * --------------------------------------------------------------------------
    * Create YAML metadata from downloaded data using yaml write
    * --------------------------------------------------------------------------
    
    display as text "--- Creating YAML metadata from downloaded data ---"
    display _n
    
    * Extract metadata from the download
    preserve
    
    * Get unique values for metadata
    qui levelsof indicator, local(ind_code) clean
    qui levelsof dataflow, local(flow) clean
    qui sum time_period
    local min_year = r(min)
    local max_year = r(max)
    qui count
    local n_obs = r(N)
    qui levelsof ref_area, local(countries)
    local n_countries : word count `countries'
    
    * Create the YAML structure dataset
    clear
    
    * Build YAML structure with key, value, level, parent, type
    local obs = 0
    
    * Root level: download_metadata
    local ++obs
    set obs `obs'
    gen str100 key = "download_metadata" in `obs'
    gen str200 value = "" in `obs'
    gen int level = 0 in `obs'
    gen int parent = 0 in `obs'
    gen str20 type = "mapping" in `obs'
    
    * Level 1: Basic metadata
    local root = `obs'
    
    local ++obs
    set obs `obs'
    replace key = "indicator" in `obs'
    replace value = "`ind_code'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "dataflow" in `obs'
    replace value = "`flow'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "source" in `obs'
    replace value = "UNICEF SDMX API" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "download_date" in `obs'
    replace value = "`c(current_date)'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "observations" in `obs'
    replace value = "`n_obs'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "countries" in `obs'
    replace value = "`n_countries'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "year_range" in `obs'
    replace value = "`min_year'-`max_year'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "api_url" in `obs'
    replace value = "`api_url'" in `obs'
    replace level = 1 in `obs'
    replace parent = `root' in `obs'
    replace type = "scalar" in `obs'
    
    * Write to YAML file (creates PHYSICAL file on disk)
    display as text "Writing metadata to YAML file..."
    yaml write using "`datadir'/api_download_metadata.yaml", replace verbose
    display _n
    
    * Show the created file
    display as text "--- Contents of created YAML file ---"
    type "`datadir'/api_download_metadata.yaml"
    display _n
    
    restore
    
    * Clean up
    cap erase "`datadir'/api_download_raw.dta"
}

* ==============================================================================
* PART 1: Exploring Dataflow Metadata
* ==============================================================================
*
* Dataflows in SDMX represent categories of related indicators. For example:
*   - CME: Child Mortality Estimates
*   - NUTRITION: Child nutrition indicators
*   - IMMUNISATION: Vaccination coverage
*
* This section shows how to read and explore dataflow metadata.

display as result _n "{hline 70}"
display as result "PART 1: Exploring UNICEF Dataflows"
display as result "{hline 70}" _n

* Read the dataflows metadata
display as text "Reading UNICEF dataflows metadata..."
yaml read using "`datadir'/unicef_dataflows.yaml", replace
display _n

* Describe the structure
display as text "--- Structure of dataflows.yaml ---"
yaml describe
display _n

* List all available dataflows
display as text "--- Available UNICEF Dataflows ---"
yaml list dataflows, keys children
return list
display _n

* Store the dataflows for later use
local available_flows "`r(keys)'"
display as text "Found " `: word count `available_flows'' " dataflows"
display _n

* Get detailed information about a specific dataflow
display as text "--- Details for CME (Child Mortality) dataflow ---"
yaml get dataflows:CME
return list
display _n

* Get the description
yaml get dataflows:CME:description, quiet
display "Description: `r(value)'"
display _n

* ==============================================================================
* PART 2: Exploring Indicator Metadata
* ==============================================================================
*
* Indicators are the actual data series available through the API.
* Each indicator has metadata including:
*   - code: Unique identifier (e.g., CME_MRY0T4)
*   - name: Human-readable name
*   - dataflow: Category it belongs to
*   - sdg_target: Related SDG target (if applicable)
*   - unit: Unit of measurement

display as result _n "{hline 70}"
display as result "PART 2: Exploring UNICEF Indicators"
display as result "{hline 70}" _n

* Read indicators metadata
display as text "Reading UNICEF indicators metadata..."
yaml read using "`datadir'/unicef_indicators.yaml", replace
display _n

* List all indicators
display as text "--- Available Indicators ---"
yaml list indicators, keys children
local all_indicators "`r(keys)'"
display _n

* Display indicator count
display as text "Total indicators: `: word count `all_indicators''"
display _n

* Get detailed metadata for key indicators
display as text "--- Key Indicator Metadata ---" _n

foreach ind in CME_MRY0T4 NT_ANT_HAZ_NE2_MOD IM_DTP3 {
    yaml get indicators:`ind'
    display as result "`ind':"
    display as text "  Name:       `r(name)'"
    display as text "  Dataflow:   `r(dataflow)'"
    display as text "  SDG Target: `r(sdg_target)'"
    display as text "  Unit:       `r(unit)'"
    display as text "  Source:     `r(source)'"
    display _n
}

* ==============================================================================
* PART 3: Building an Indicator Lookup Table
* ==============================================================================
*
* Create a Stata dataset from the YAML metadata for further analysis
* 
* NOTE: Since yaml read loads into the current dataset, we need to:
*   Option A (Stata 16+): Use frames to keep YAML separate from lookup table
*   Option B (Stata 14+): Extract info first, then build table

display as result _n "{hline 70}"
display as result "PART 3: Building Indicator Lookup Table"
display as result "{hline 70}" _n

* First, read the YAML and extract all indicator info into locals
yaml read using "`datadir'/unicef_indicators.yaml", replace

* Get list of indicators
yaml list indicators, keys children
local indicators "`r(keys)'"
local n_indicators : word count `indicators'

display as text "Found `n_indicators' indicators"
display _n

* Extract metadata for each indicator into locals
local i = 0
foreach ind of local indicators {
    local ++i
    yaml get indicators:`ind', quiet
    local ind_`i'_code "`ind'"
    local ind_`i'_name "`r(name)'"
    local ind_`i'_dataflow "`r(dataflow)'"
    local ind_`i'_sdg "`r(sdg_target)'"
    local ind_`i'_unit "`r(unit)'"
    local ind_`i'_source "`r(source)'"
}

* Now create a fresh dataset for the lookup table
clear
set obs `n_indicators'

* Define variables
gen str30 indicator_code = ""
gen str60 indicator_name = ""
gen str20 dataflow = ""
gen str10 sdg_target = ""
gen str30 unit = ""
gen str50 source = ""

* Populate from the stored locals
forvalues i = 1/`n_indicators' {
    replace indicator_code = "`ind_`i'_code'" in `i'
    replace indicator_name = "`ind_`i'_name'" in `i'
    replace dataflow = "`ind_`i'_dataflow'" in `i'
    replace sdg_target = "`ind_`i'_sdg'" in `i'
    replace unit = "`ind_`i'_unit'" in `i'
    replace source = "`ind_`i'_source'" in `i'
}

* Display the lookup table
display as text "--- Indicator Lookup Table ---"
list indicator_code indicator_name dataflow sdg_target, sepby(dataflow)
display _n

* Tabulate by dataflow
display as text "--- Indicators per Dataflow ---"
tab dataflow
display _n

* Tabulate by SDG target
display as text "--- Indicators per SDG Target ---"
tab sdg_target
display _n

* Save the lookup table
save "`datadir'/indicator_lookup.dta", replace
display as text "Lookup table saved to indicator_lookup.dta"
display _n

* ==============================================================================
* PART 4: Working with Multiple Metadata Files (Stata 16+)
* ==============================================================================
*
* Use frames to hold both dataflows and indicators metadata simultaneously

display as result _n "{hline 70}"
display as result "PART 4: Multiple Metadata Files with Frames"
display as result "{hline 70}" _n

capture {
    * Clear any existing YAML frames
    capture yaml clear, all
    
    * Load dataflows into one frame
    display as text "Loading dataflows metadata into 'flows' frame..."
    yaml read using "`datadir'/unicef_dataflows.yaml", frame(flows)
    
    * Load indicators into another frame
    display as text "Loading indicators metadata into 'inds' frame..."
    yaml read using "`datadir'/unicef_indicators.yaml", frame(inds)
    display _n
    
    * Use yaml dir to see all YAML data
    display as text "--- yaml dir: All YAML data in memory ---"
    yaml dir, detail
    display _n
    
    * Cross-reference: Find indicators for a specific dataflow
    display as text "--- Finding all indicators for CME dataflow ---"
    
    * First, get indicators from the dataflows metadata
    yaml get dataflows:CME:indicators, frame(flows)
    local cme_indicators "`r(indicators)'"
    display "Indicators listed in CME dataflow: `cme_indicators'"
    display _n
    
    * Then look up each indicator's details
    display as text "--- Indicator details from indicators metadata ---"
    foreach ind in `cme_indicators' {
        capture yaml get indicators:`ind':name, frame(inds) quiet
        if !_rc {
            display as text "  `ind': `r(value)'"
        }
    }
    display _n
    
    * Build a validation check: ensure indicator dataflows match
    display as text "--- Validating indicator-dataflow mapping ---"
    yaml list indicators, keys children frame(inds)
    local all_inds "`r(keys)'"
    
    local valid = 0
    local invalid = 0
    
    foreach ind of local all_inds {
        yaml get indicators:`ind':dataflow, frame(inds) quiet
        local ind_flow "`r(value)'"
        
        * Check if this dataflow exists in flows metadata
        capture yaml get dataflows:`ind_flow':id, frame(flows) quiet
        if !_rc {
            local ++valid
        }
        else {
            local ++invalid
            display as error "  Warning: Indicator `ind' references unknown dataflow `ind_flow'"
        }
    }
    
    display as result "Validation complete: `valid' valid, `invalid' invalid mappings"
    display _n
    
    * Clean up frames
    yaml clear, all
}
if _rc {
    display as error "Frame support requires Stata 16+"
}

* ==============================================================================
* PART 5: Configuration-Driven API Queries
* ==============================================================================
*
* Demonstrate how YAML configuration could drive API data downloads

display as result _n "{hline 70}"
display as result "PART 5: Configuration-Driven API Queries"
display as result "{hline 70}" _n

* Read indicators to build query parameters
yaml read using "`datadir'/unicef_indicators.yaml", replace

* Example: Generate API query URLs for specific indicators
display as text "--- Generating SDMX API Query URLs ---" _n

local base_url "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data"

foreach ind in CME_MRY0T4 NT_ANT_HAZ_NE2_MOD IM_DTP3 {
    * Use yaml get with two-level path to get all attributes
    yaml get indicators:`ind', quiet
    local flow "`r(dataflow)'"
    local name "`r(name)'"
    local unit "`r(unit)'"
    local sdg  "`r(sdg_target)'"
    
    * Build the API URL
    local api_url "`base_url'/UNICEF,`flow',1.0/.`ind'.?format=csv&labels=both"
    
    display as result "`ind' (`name')"
    display as text "  Dataflow: `flow'"
    display as text "  URL: `api_url'"
    
    * Attempt download and labeling (Paper Example Workflow)
    preserve
    capture noisily {
        import delimited "`api_url'", clear varnames(1)
        
        * Rename uppercase variables from SDMX API
        capture rename OBS_VALUE obs_value
        
        * Apply metadata from YAML
        label variable obs_value "`name' (`unit')"
        label data "`name' - SDG `sdg'"
        
        display as text "  > Download successful. Label applied: `name' (`unit')"
        describe obs_value
    }
    if _rc {
        display as text "  > Download skipped (API unavailable or offline)"
    }
    restore
    display _n
}

* ==============================================================================
* PART 6: SDG Mapping
* ==============================================================================
*
* Use YAML metadata to map indicators to SDG targets

display as result _n "{hline 70}"
display as result "PART 6: SDG Indicator Mapping"
display as result "{hline 70}" _n

yaml read using "`datadir'/unicef_indicators.yaml", replace

* Get all indicators
yaml list indicators, keys children
local indicators "`r(keys)'"

* Build SDG target mapping
display as text "--- Indicators by SDG Target ---" _n

* Group indicators by SDG target
foreach target in 2.2.1 2.2.2 3.2.1 3.2.2 3.b.1 4.1.1 4.1.2 6.1.1 6.2.1 {
    local target_inds ""
    
    foreach ind of local indicators {
        * Use yaml get with two-level path, then check r(sdg_target)
        yaml get indicators:`ind', quiet
        if "`r(sdg_target)'" == "`target'" {
            local target_inds "`target_inds' `ind'"
        }
    }
    
    if "`target_inds'" != "" {
        display as result "SDG `target':"
        foreach ind of local target_inds {
            yaml get indicators:`ind', quiet
            display as text "  - `ind': `r(name)'"
        }
        display _n
    }
}

* ==============================================================================
* PART 7: Export Metadata Summary (yaml write)
* ==============================================================================
*
* Write a summary YAML file using yaml write
* 
* IMPORTANT: yaml write creates a PHYSICAL FILE on disk.
* It does NOT write to frames in memory. The workflow is:
*   1. Create a dataset with key/value/level/parent/type structure
*   2. Use yaml write to export to a .yaml file
*   3. Later, use yaml read to load that file back (into dataset or frame)

display as result _n "{hline 70}"
display as result "PART 7: Export Metadata Summary (yaml write)"
display as result "{hline 70}" _n

display as text "NOTE: yaml write creates PHYSICAL files on disk."
display as text "      Frames are for reading/holding YAML in memory."
display _n

* Create a summary dataset
preserve
clear

* Add summary metadata
local obs = 1
set obs 5

gen key = ""
gen value = ""
gen int level = .
gen int parent = .
gen type = ""

* Populate summary
replace key = "summary" in 1
replace level = 0 in 1
replace parent = 0 in 1
replace type = "mapping" in 1

replace key = "generated" in 2
replace value = "`c(current_date)' `c(current_time)'" in 2
replace level = 1 in 2
replace parent = 1 in 2
replace type = "scalar" in 2

replace key = "stata_version" in 3
replace value = "`c(stata_version)'" in 3
replace level = 1 in 3
replace parent = 1 in 3
replace type = "scalar" in 3

replace key = "total_indicators" in 4
replace value = "`: word count `indicators''" in 4
replace level = 1 in 4
replace parent = 1 in 4
replace type = "scalar" in 4

replace key = "source" in 5
replace value = "UNICEF SDMX API" in 5
replace level = 1 in 5
replace parent = 1 in 5
replace type = "scalar" in 5

* Write to YAML (physical file)
display as text "Writing metadata summary to disk..."
yaml write using "`datadir'/metadata_summary.yaml", replace

* Display the written file
display as text "--- Contents of metadata_summary.yaml ---"
type "`datadir'/metadata_summary.yaml"
display _n

* Now demonstrate reading it back
display as text "--- Reading back the file we just wrote ---"
yaml read using "`datadir'/metadata_summary.yaml", replace
yaml describe
display _n

restore

* ==============================================================================
* PART 8: Download Multiple Indicators and Create Comprehensive YAML
* ==============================================================================
*
* Download data for multiple indicators and create a comprehensive
* metadata YAML file documenting all downloads

display as result _n "{hline 70}"
display as result "PART 8: Multi-Indicator Download with YAML Documentation"
display as result "{hline 70}" _n

* List of indicators to download
local indicators_to_download "CME_MRY0T4 CME_MRM0 NT_ANT_HAZ_NE2_MOD"
local api_base "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest"

display as text "Attempting to download indicators: `indicators_to_download'"
display _n

* Create a dataset to track downloads
preserve
clear

* Start building the YAML structure
gen str100 key = ""
gen str500 value = ""
gen int level = .
gen int parent = .
gen str20 type = ""

local obs = 0

* Root element
local ++obs
set obs `obs'
replace key = "unicef_data_downloads" in `obs'
replace level = 0 in `obs'
replace parent = 0 in `obs'
replace type = "mapping" in `obs'
local root = `obs'

* Metadata section
local ++obs
set obs `obs'
replace key = "metadata" in `obs'
replace level = 1 in `obs'
replace parent = `root' in `obs'
replace type = "mapping" in `obs'
local meta_parent = `obs'

local ++obs
set obs `obs'
replace key = "created" in `obs'
replace value = "`c(current_date)' `c(current_time)'" in `obs'
replace level = 2 in `obs'
replace parent = `meta_parent' in `obs'
replace type = "scalar" in `obs'

local ++obs
set obs `obs'
replace key = "stata_version" in `obs'
replace value = "`c(stata_version)'" in `obs'
replace level = 2 in `obs'
replace parent = `meta_parent' in `obs'
replace type = "scalar" in `obs'

local ++obs
set obs `obs'
replace key = "api_base" in `obs'
replace value = "`api_base'" in `obs'
replace level = 2 in `obs'
replace parent = `meta_parent' in `obs'
replace type = "scalar" in `obs'

* Downloads section
local ++obs
set obs `obs'
replace key = "downloads" in `obs'
replace level = 1 in `obs'
replace parent = `root' in `obs'
replace type = "mapping" in `obs'
local downloads_parent = `obs'

* Try to download each indicator
local download_count = 0
foreach ind of local indicators_to_download {
    
    * Determine dataflow from indicator prefix
    local flow = substr("`ind'", 1, 2)
    if "`flow'" == "CM" local flow "CME"
    if "`flow'" == "NT" local flow "NUTRITION"
    if "`flow'" == "IM" local flow "IMMUNISATION"
    
    local api_url "`api_base'/data/UNICEF,`flow',1.0/.`ind'.?format=csv&labels=both"
    
    display as text "Downloading `ind' from `flow' dataflow..."
    
    * Try to download
    tempfile tempdata
    capture {
        preserve
        import delimited "`api_url'", clear varnames(1)
        * Rename uppercase variables from SDMX API
        capture rename TIME_PERIOD time_period
        capture rename REF_AREA ref_area
        qui count
        local n_obs = r(N)
        qui sum time_period
        local min_year = r(min)
        local max_year = r(max)
        qui levelsof ref_area
        local n_countries = r(r)
        restore
        local download_ok = 1
    }
    if _rc {
        local download_ok = 0
        local n_obs = 0
        local min_year = .
        local max_year = .
        local n_countries = 0
    }
    
    * Add entry to YAML structure
    local ++obs
    set obs `obs'
    replace key = "`ind'" in `obs'
    replace level = 2 in `obs'
    replace parent = `downloads_parent' in `obs'
    replace type = "mapping" in `obs'
    local ind_parent = `obs'
    
    local ++obs
    set obs `obs'
    replace key = "dataflow" in `obs'
    replace value = "`flow'" in `obs'
    replace level = 3 in `obs'
    replace parent = `ind_parent' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "status" in `obs'
    if (`download_ok') {
        replace value = "success" in `obs'
        local ++download_count
    }
    else {
        replace value = "failed" in `obs'
    }
    replace level = 3 in `obs'
    replace parent = `ind_parent' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "observations" in `obs'
    replace value = "`n_obs'" in `obs'
    replace level = 3 in `obs'
    replace parent = `ind_parent' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "year_range" in `obs'
    if (`download_ok') {
        replace value = "`min_year'-`max_year'" in `obs'
    }
    else {
        replace value = "N/A" in `obs'
    }
    replace level = 3 in `obs'
    replace parent = `ind_parent' in `obs'
    replace type = "scalar" in `obs'
    
    local ++obs
    set obs `obs'
    replace key = "countries" in `obs'
    replace value = "`n_countries'" in `obs'
    replace level = 3 in `obs'
    replace parent = `ind_parent' in `obs'
    replace type = "scalar" in `obs'
    
    if (`download_ok') {
        display as result "  Success: `n_obs' observations, `n_countries' countries"
    }
    else {
        display as error "  Failed (no internet or API unavailable)"
    }
}

display _n
display as text "Successfully downloaded `download_count' of `: word count `indicators_to_download'' indicators"
display _n

* Write the comprehensive YAML file
display as text "--- Writing comprehensive download log to YAML ---"
yaml write using "`datadir'/download_log.yaml", replace verbose
display _n

* Show the file
display as text "--- Contents of download_log.yaml ---"
type "`datadir'/download_log.yaml"
display _n

restore

* ===========================================================================
* PART 9: Large Catalog Optimization with Frames (Stata 16+)
* ===========================================================================
*
* Mirrors Section 5.2 of the paper: vectorized frame-based queries that scale
* to 700+ metadata entries. The sample file is small, but the pattern matches
* production usage.

display as result _n "{hline 70}"
display as result "PART 9: Frame-based filtering for large catalogs"
display as result "{hline 70}" _n

* Load indicator metadata into an isolated frame
yaml read using "`datadir'/unicef_indicators.yaml", frame(meta) replace

* Vectorized filtering inside the frame (no per-row yaml get calls)
frame yaml_meta {
    gen is_nutrition = (value == "NUTRITION") & ///
        regexm(key, "^indicators_[A-Za-z0-9_]+_dataflow$")
    gen indicator_code = regexs(1) if ///
        regexm(key, "^indicators_([A-Za-z0-9_]+)_dataflow$") & is_nutrition

    levelsof indicator_code if is_nutrition == 1, local(nutrition_codes) clean

    display as text "Nutrition indicators (vectorized lookup):"
    foreach ind of local nutrition_codes {
        levelsof value if key == "indicators_`ind'_name", local(ind_name) clean
        levelsof value if key == "indicators_`ind'_sdg_target", local(ind_sdg) clean
        di as result "  `ind': `ind_name' (SDG `ind_sdg')"
    }
}

* Cleanup frame
frame drop yaml_meta

* ==============================================================================
* CLEANUP
* ==============================================================================

display as result _n "{hline 70}"
display as result "EXAMPLE COMPLETED"
display as result "{hline 70}" _n

* Clean up temporary files
cap erase "`datadir'/indicator_lookup.dta"
cap erase "`datadir'/metadata_summary.yaml"
cap erase "`datadir'/download_log.yaml"
cap erase "`datadir'/api_download_metadata.yaml"

display as text "This example demonstrated:"
display as text "  0. Downloading data directly from UNICEF SDMX API"
display as text "  1. Reading UNICEF SDMX API metadata from YAML files"
display as text "  2. Exploring dataflow and indicator structures"
display as text "  3. Building lookup tables from YAML metadata"
display as text "  4. Using frames for multiple metadata files (Stata 16+)"
display as text "  5. Configuration-driven API query generation"
display as text "  6. SDG indicator mapping"
display as text "  7. Writing metadata summaries with yaml write"
display as text "  8. Creating comprehensive download logs in YAML format"
display as text "  9. Frame-based filtering for large catalogs (vectorized)"
display _n

display as text "KEY POINT: yaml write creates PHYSICAL FILES on disk."
display as text "           Frames are only for holding YAML data in memory."
display _n

display as text "For more information on the UNICEF SDMX API:"
display as text "  https://data.unicef.org/sdmx-api-documentation/"
display _n

log close

* End of do-file