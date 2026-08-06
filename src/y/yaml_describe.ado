*******************************************************************************
* yaml_describe
*! v 2.0.0   26Jul2026               by Joao Pedro Azevedo (UNICEF)
* Display structure of loaded YAML data
*******************************************************************************

program define yaml_describe
    version 14.0
    
    syntax [, Frame(string) Level(integer 0)]
    
    * If frame specified, add yaml_ prefix if not present
    if ("`frame'" != "") {
        if (`c(stata_version)' < 16) {
            di as err "frame() option requires Stata 16 or later"
            exit 198
        }
        if (substr("`frame'", 1, 5) != "yaml_") {
            local frame "yaml_`frame'"
        }
        
        * Check frame exists
        capture frame `frame': describe, short
        if (_rc != 0) {
            di as err "frame `frame' not found"
            exit 198
        }
        
        * Run describe in frame context
        frame `frame' {
            _yaml_describe_impl, level(`level')
        }
    }
    else {
        * Use current dataset
        _yaml_describe_impl, level(`level')
    }
end

program define _yaml_describe_impl
    syntax [, Level(integer 0)]
    
    * Ensure required variables exist
    capture confirm variable key value level type
    if (_rc != 0) {
        di as err "No YAML data in memory. Use 'yaml read using file.yaml' first."
        exit 198
    }
    
    * Default level = max
    if (`level' == 0) {
        summarize level, meanonly
        local level = r(max)
    }
    
    * parent is optional; when present it lets each row be shown by its leaf
    * name so the tree mirrors the source file
    capture confirm variable parent
    local has_parent = (_rc == 0)

    local n = _N
    di as text "{hline 70}"
    di as text "YAML structure (showing up to level `level'):"
    di as text "{hline 70}"

    forvalues i = 1/`n' {
        local k = key[`i']
        local v = value[`i']
        local l = level[`i']
        local t = type[`i']

        * Skip if beyond requested level
        if (`l' > `level') continue

        * Create indentation
        local spaces ""
        forvalues j = 1/`=`l'-1' {
            local spaces "`spaces'  "
        }

        * Display the leaf name, not the flattened key: the indentation already
        * carries the path, so printing "database_host" under "database:" both
        * repeats the parent and stops the tree from mirroring the YAML file.
        local dk "`k'"
        if (`has_parent') {
            local p = parent[`i']
            if ("`p'" != "" & strpos("`k'", "`p'_") == 1) {
                local dk = substr("`k'", length("`p'") + 2, .)
            }
        }

        if ("`t'" == "parent") {
            di as text "`spaces'" as result "`dk'" as text ":"
        }
        else {
            local display_val = substr("`v'", 1, 40)
            if (length("`v'") > 40) local display_val "`display_val'..."
            di as text "`spaces'" as result "`dk'" as text ": " as text `"`display_val'"'
        }
    }
    
    di as text "{hline 70}"
    di as text "Total keys: " as result `n'
    di as text "{hline 70}"
end
