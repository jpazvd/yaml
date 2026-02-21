*! test_cross_package_sync.do
*! Cross-package version sync check
*! Date: 21Feb2026
*! Purpose: Verify yaml.ado version consistency across yaml-dev, wbopendata-dev, unicefdata-dev

clear all
set more off

local all_match = 1

*===============================================================================
* CONFIGURATION: Package locations (absolute paths)
*===============================================================================

local yaml_dev_src "C:/GitHub/myados/yaml-dev/src/y"
local wbod_dev_src "C:/GitHub/myados/wbopendata-dev/src/y"
local unicef_dev_src "C:/GitHub/myados/unicefdata-dev/stata/src/y"

di as text _n "{hline 70}"
di as result "Cross-Package yaml.ado Version Sync Check"
di as text "{hline 70}"

*===============================================================================
* HELPER: Extract version from yaml.ado header
*===============================================================================

capture program drop _extract_yaml_version
program define _extract_yaml_version, rclass
    args yaml_path
    
    local version ""
    
    capture confirm file "`yaml_path'"
    if (_rc != 0) {
        return local version "NOT_FOUND"
        exit
    }
    
    tempname fh
    file open `fh' using "`yaml_path'", read text
    
    forvalues i = 1/20 {
        file read `fh' line
        if r(eof) continue, break
        
        * Look for version pattern: *! v X.Y.Z or *! yaml vX.Y.Z
        if regexm(`"`line'"', "v[ ]*([0-9]+\.[0-9]+\.[0-9]+)") {
            local version = regexs(1)
            continue, break
        }
    }
    
    file close `fh'
    return local version "`version'"
end

*===============================================================================
* CHECK: yaml-dev (canonical source)
*===============================================================================

di as text _n "Checking yaml.ado versions..."
di as text ""

_extract_yaml_version "`yaml_dev_src'/yaml.ado"
local ver_yaml_dev = r(version)
di as text "  yaml-dev:       " _continue
if ("`ver_yaml_dev'" == "NOT_FOUND") {
    di as error "NOT FOUND"
}
else {
    di as result "v`ver_yaml_dev'" _continue
    di as text " (canonical)"
}

*===============================================================================
* CHECK: wbopendata-dev
*===============================================================================

_extract_yaml_version "`wbod_dev_src'/yaml.ado"
local ver_wbod = r(version)
di as text "  wbopendata-dev: " _continue
if ("`ver_wbod'" == "NOT_FOUND") {
    di as text "NOT FOUND (may need sync)"
}
else if ("`ver_wbod'" == "`ver_yaml_dev'") {
    di as result "v`ver_wbod'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_wbod'" _continue
    di as error " [MISMATCH - expected v`ver_yaml_dev']"
    local all_match = 0
}

*===============================================================================
* CHECK: unicefdata-dev
*===============================================================================

_extract_yaml_version "`unicef_dev_src'/yaml.ado"
local ver_unicef = r(version)
di as text "  unicefdata-dev: " _continue
if ("`ver_unicef'" == "NOT_FOUND") {
    di as text "NOT FOUND (may need sync)"
}
else if ("`ver_unicef'" == "`ver_yaml_dev'") {
    di as result "v`ver_unicef'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_unicef'" _continue
    di as error " [MISMATCH - expected v`ver_yaml_dev']"
    local all_match = 0
}

*===============================================================================
* CHECK: yaml_read.ado (core parser)
*===============================================================================

di as text _n "Checking yaml_read.ado versions..."
di as text ""

_extract_yaml_version "`yaml_dev_src'/yaml_read.ado"
local ver_read_yaml_dev = r(version)
di as text "  yaml-dev:       " _continue
if ("`ver_read_yaml_dev'" == "NOT_FOUND") {
    di as error "NOT FOUND"
}
else {
    di as result "v`ver_read_yaml_dev'" _continue
    di as text " (canonical)"
}

_extract_yaml_version "`wbod_dev_src'/yaml_read.ado"
local ver_read_wbod = r(version)
di as text "  wbopendata-dev: " _continue
if ("`ver_read_wbod'" == "NOT_FOUND") {
    di as text "NOT FOUND"
}
else if ("`ver_read_wbod'" == "`ver_read_yaml_dev'") {
    di as result "v`ver_read_wbod'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_read_wbod'" _continue
    di as error " [MISMATCH]"
    local all_match = 0
}

_extract_yaml_version "`unicef_dev_src'/yaml_read.ado"
local ver_read_unicef = r(version)
di as text "  unicefdata-dev: " _continue
if ("`ver_read_unicef'" == "NOT_FOUND") {
    di as text "NOT FOUND"
}
else if ("`ver_read_unicef'" == "`ver_read_yaml_dev'") {
    di as result "v`ver_read_unicef'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_read_unicef'" _continue
    di as error " [MISMATCH]"
    local all_match = 0
}

*===============================================================================
* CHECK: _yaml_collapse.ado (collapse helper)
*===============================================================================

di as text _n "Checking _yaml_collapse.ado versions..."
di as text ""

_extract_yaml_version "`yaml_dev_src'/../_/_yaml_collapse.ado"
local ver_coll_yaml_dev = r(version)
di as text "  yaml-dev:       " _continue
if ("`ver_coll_yaml_dev'" == "NOT_FOUND") {
    di as text "NOT FOUND"
}
else {
    di as result "v`ver_coll_yaml_dev'" _continue
    di as text " (canonical)"
}

_extract_yaml_version "`wbod_dev_src'/../_/_yaml_collapse.ado"
local ver_coll_wbod = r(version)
di as text "  wbopendata-dev: " _continue
if ("`ver_coll_wbod'" == "NOT_FOUND") {
    di as text "NOT FOUND"
}
else if ("`ver_coll_wbod'" == "`ver_coll_yaml_dev'") {
    di as result "v`ver_coll_wbod'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_coll_wbod'" _continue
    di as error " [MISMATCH]"
    local all_match = 0
}

_extract_yaml_version "`unicef_dev_src'/../_/_yaml_collapse.ado"
local ver_coll_unicef = r(version)
di as text "  unicefdata-dev: " _continue
if ("`ver_coll_unicef'" == "NOT_FOUND") {
    di as text "NOT FOUND"
}
else if ("`ver_coll_unicef'" == "`ver_coll_yaml_dev'") {
    di as result "v`ver_coll_unicef'" _continue
    di as text " [OK]"
}
else {
    di as error "v`ver_coll_unicef'" _continue
    di as error " [MISMATCH]"
    local all_match = 0
}

*===============================================================================
* SUMMARY
*===============================================================================

di as text _n "{hline 70}"
if (`all_match') {
    di as result "All packages are in sync with yaml-dev v`ver_yaml_dev'"
}
else {
    di as error "VERSION MISMATCH DETECTED"
    di as text ""
    di as text "To sync packages, copy yaml.ado files from yaml-dev:"
    di as text "  yaml-dev/src/y/yaml*.ado       → wbopendata-dev/src/y/"
    di as text "  yaml-dev/src/y/yaml*.ado       → unicefdata-dev/stata/src/y/"
    di as text "  yaml-dev/src/_/_yaml*.ado      → wbopendata-dev/src/_/"
    di as text "  yaml-dev/src/_/_yaml*.ado      → unicefdata-dev/stata/src/_/"
    error 198
}
di as text "{hline 70}"
