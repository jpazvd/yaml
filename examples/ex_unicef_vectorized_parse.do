*******************************************************************************
*! ex_unicef_vectorized_parse.do
*! Vectorized YAML parser — unicefData approach
*! Reference: __unicef_parse_indicators_yaml.ado v1.0.0 (unicefData-dev)
*!
*! Architecture: Same as wbopendata vectorized parser but with
*! UNICEF-specific fields (urn, tier, dataflows, disaggregations).
*! Handles continuation lines (indent >= 6) instead of block scalars.
*!
*! Key differences from wbopendata:
*!   - Different metadata exclusion list (platform, agency, tier_counts, etc.)
*!   - Continuation line support (indent >= 6, not list items)
*!   - List fields: dataflows, disaggregations, disaggregations_with_totals
*!   - Parser version tracking for cache invalidation
*******************************************************************************

program define ex_unicef_vectorized_parse
    version 14.0
    args yaml_path

    quietly {
        *-------------------------------------------------------------------
        * STEP 1: Slurp all lines into dataset
        *-------------------------------------------------------------------
        tempname fh
        clear
        gen strL rawline = ""
        local i = 0
        file open `fh' using "`yaml_path'", read
        file read `fh' line
        while (r(eof) == 0) {
            local i = `i' + 1
            set obs `i'
            mata: st_sstore(`i', "rawline", st_local("line"))
            file read `fh' line
        }
        file close `fh'

        *-------------------------------------------------------------------
        * STEP 2: Compute structure columns (vectorized)
        *-------------------------------------------------------------------
        gen long linenum = _n
        gen strL raw_trim = strtrim(subinstr(rawline, char(13), "", .))
        gen int indent = length(rawline) - length(strtrim(rawline))

        * Detect indicator header lines (indent == 2, ends with colon,
        * excluding known UNICEF metadata/section keys)
        gen byte is_indicator = 0
        replace is_indicator = 1 if indent == 2 & regexm(raw_trim, ":$") & ///
            substr(raw_trim,1,9) != "metadata:" & ///
            substr(raw_trim,1,11) != "indicators:" & ///
            substr(raw_trim,1,9) != "platform:" & ///
            substr(raw_trim,1,8) != "version:" & ///
            substr(raw_trim,1,10) != "synced_at:" & ///
            substr(raw_trim,1,7) != "source:" & ///
            substr(raw_trim,1,7) != "agency:" & ///
            substr(raw_trim,1,13) != "content_type:" & ///
            substr(raw_trim,1,4) != "url:" & ///
            substr(raw_trim,1,13) != "last_updated:" & ///
            substr(raw_trim,1,12) != "description:" & ///
            substr(raw_trim,1,16) != "indicator_count:" & ///
            substr(raw_trim,1,12) != "tier_counts:" & ///
            substr(raw_trim,1,1) != "-" & ///
            substr(raw_trim,1,5) != "code:" & ///
            substr(raw_trim,1,5) != "name:" & ///
            substr(raw_trim,1,4) != "urn:" & ///
            substr(raw_trim,1,7) != "parent:" & ///
            substr(raw_trim,1,5) != "tier:" & ///
            substr(raw_trim,1,12) != "tier_reason:" & ///
            substr(raw_trim,1,10) != "dataflows:"

        * Detect field lines (indent == 4, has colon, not list item)
        gen byte is_field = 0
        replace is_field = 1 if indent == 4 & strpos(raw_trim, ":") > 0 & ///
            is_indicator == 0 & substr(raw_trim,1,1) != "-"

        * Extract indicator code
        gen str100 ind_code = ""
        replace ind_code = strtrim(substr(rawline, 1, length(rawline) - 1)) ///
            if is_indicator
        * Strip surrounding quotes from indicator codes
        replace ind_code = substr(ind_code, 2, length(ind_code) - 2) ///
            if is_indicator & length(ind_code) >= 3 & ///
            substr(ind_code,1,1) == "'" & ///
            substr(ind_code, length(ind_code), 1) == "'"

        * Propagate indicator code down to its fields
        gen long ind_group = sum(is_indicator)
        bysort ind_group: replace ind_code = ind_code[1]

        *-------------------------------------------------------------------
        * STEP 3: Extract field type and value
        *-------------------------------------------------------------------
        gen str30 field_type = ""
        gen int colon_pos = strpos(rawline, ":")
        replace field_type = strtrim(substr(rawline, 1, colon_pos - 1)) ///
            if is_field & colon_pos > 0

        gen strL field_val = ""
        replace field_val = strtrim(substr(rawline, colon_pos + 1, .)) ///
            if is_field & colon_pos > 0
        * Remove surrounding quotes
        replace field_val = substr(field_val, 2, length(field_val) - 2) ///
            if is_field & length(field_val) >= 2 & ///
            ((substr(field_val,1,1) == `"""' & ///
              substr(field_val, length(field_val), 1) == `"""') | ///
             (substr(field_val,1,1) == "'" & ///
              substr(field_val, length(field_val), 1) == "'"))

        *-------------------------------------------------------------------
        * STEP 4: Handle continuation lines (indent >= 6)
        *-------------------------------------------------------------------
        gen byte is_continuation = 0
        replace is_continuation = 1 if indent >= 6 & !is_field & ///
            !is_indicator & substr(raw_trim,1,1) != "-" & raw_trim != ""

        gen str30 cont_field = ""
        replace cont_field = field_type if is_field & field_val != ""
        replace cont_field = field_type if is_field & field_val == "" & ///
            _n < _N & indent[_n+1] >= 6
        forvalues iter = 1/5 {
            replace cont_field = cont_field[_n-1] if cont_field == "" & ///
                is_continuation & _n > 1
        }

        replace field_type = cont_field if is_continuation & cont_field != ""
        replace field_val = raw_trim if is_continuation & cont_field != ""

        *-------------------------------------------------------------------
        * STEP 5: Handle YAML list items
        *-------------------------------------------------------------------
        gen byte is_list_item = indent == 4 & regexm(raw_trim, "^- ")
        gen str100 list_item_val = ""
        replace list_item_val = strtrim(substr(raw_trim, 3, .)) if is_list_item
        replace list_item_val = substr(list_item_val, 2, ///
            length(list_item_val) - 2) if is_list_item & ///
            length(list_item_val) >= 2 & ///
            ((substr(list_item_val,1,1) == "'" & ///
              substr(list_item_val, length(list_item_val), 1) == "'") | ///
             (substr(list_item_val,1,1) == `"""' & ///
              substr(list_item_val, length(list_item_val), 1) == `"""'))

        gen str30 last_list_header = ""
        replace last_list_header = field_type ///
            if inlist(field_type, "dataflows", "disaggregations", ///
                "disaggregations_with_totals")
        replace last_list_header = last_list_header[_n-1] ///
            if last_list_header == "" & _n > 1

        *-------------------------------------------------------------------
        * STEP 6: Assign to typed columns
        *-------------------------------------------------------------------
        gen strL field_name = ""
        gen strL field_desc = ""
        gen strL field_urn = ""
        gen str100 field_parent = ""
        gen str244 field_dataflows = ""
        gen str10 field_tier = ""
        gen str50 field_tier_reason = ""
        gen str244 field_disagg = ""
        gen str244 field_disagg_totals = ""

        replace field_name        = field_val if field_type == "name"
        replace field_desc        = field_val if field_type == "description"
        replace field_urn         = field_val if field_type == "urn"
        replace field_parent      = field_val if field_type == "parent"
        replace field_tier        = field_val if field_type == "tier"
        replace field_tier_reason = field_val if field_type == "tier_reason"
        replace field_dataflows   = field_val ///
            if field_type == "dataflows" & field_val != ""

        replace field_dataflows    = list_item_val ///
            if is_list_item & last_list_header == "dataflows"
        replace field_disagg       = list_item_val ///
            if is_list_item & last_list_header == "disaggregations"
        replace field_disagg_totals = list_item_val ///
            if is_list_item & last_list_header == "disaggregations_with_totals"

        drop is_list_item list_item_val last_list_header

        *-------------------------------------------------------------------
        * STEP 7: Accumulate multi-row fields (cond() single-pass)
        *-------------------------------------------------------------------
        sort ind_group linenum

        * Accumulate name and description continuation lines
        foreach v in field_name field_desc {
            gen strL `v'_acc = ""
            by ind_group: replace `v'_acc = `v' if _n == 1
            by ind_group: replace `v'_acc = ///
                cond(`v' != "", ///
                    cond(`v'_acc[_n-1] != "", ///
                        `v'_acc[_n-1] + " " + `v', `v'), ///
                    `v'_acc[_n-1]) if _n > 1
            by ind_group: replace `v' = `v'_acc[_N]
            drop `v'_acc
        }

        * Accumulate list fields (semicolon-separated)
        foreach v in field_dataflows field_disagg field_disagg_totals {
            gen str500 all_`v' = ""
            by ind_group: replace all_`v' = `v' if _n == 1
            by ind_group: replace all_`v' = ///
                cond(`v' != "", ///
                    cond(all_`v'[_n-1] != "", ///
                        all_`v'[_n-1] + ";" + `v', `v'), ///
                    all_`v'[_n-1]) if _n > 1
            by ind_group: replace all_`v' = all_`v'[_N]
            replace `v' = all_`v'
            drop all_`v'
        }

        *-------------------------------------------------------------------
        * STEP 8: Collapse to one row per indicator
        *-------------------------------------------------------------------
        collapse (firstnm) ind_code (firstnm) field_name ///
                 (firstnm) field_desc (firstnm) field_urn ///
                 (firstnm) field_parent (firstnm) field_dataflows ///
                 (firstnm) field_tier (firstnm) field_tier_reason ///
                 (firstnm) field_disagg (firstnm) field_disagg_totals, ///
                 by(ind_group)
        drop if ind_code == ""

        keep ind_code field_name field_desc field_urn field_parent ///
             field_dataflows field_tier field_tier_reason ///
             field_disagg field_disagg_totals
    }
end
