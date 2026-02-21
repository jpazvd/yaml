*******************************************************************************
*! ex_wbod_vectorized_parse.do
*! Vectorized YAML parser — wbopendata approach
*! Reference: __wbod_parse_yaml_ind.ado v1.0.10 (wbopendata-dev)
*!
*! Architecture:
*!   1. file read → slurp ALL lines into strL column (one obs per line)
*!   2. Mata st_sstore() to bypass macro expansion (avoids rc=132)
*!   3. Vectorized gen/replace to detect structure (indicators, fields, lists)
*!   4. cond() single-pass accumulation for multi-row fields
*!   5. collapse to one row per indicator
*!
*! This approach works on large files (463K lines) where the canonical
*! ado line-by-line parser fails due to Stata macro expansion limits.
*******************************************************************************

program define ex_wbod_vectorized_parse
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
            * Use Mata st_sstore to avoid macro expansion breaking on
            * embedded quotes, dollar signs, etc. (rc=132)
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
        * excluding known metadata/section keys)
        gen byte is_indicator = 0
        replace is_indicator = 1 if indent == 2 & regexm(raw_trim, ":$") & ///
            substr(raw_trim,1,5) != "code:" & ///
            substr(raw_trim,1,5) != "name:" & ///
            substr(raw_trim,1,10) != "source_id:" & ///
            substr(raw_trim,1,12) != "source_name:" & ///
            substr(raw_trim,1,11) != "source_org:" & ///
            substr(raw_trim,1,10) != "topic_ids:" & ///
            substr(raw_trim,1,12) != "topic_names:" & ///
            substr(raw_trim,1,12) != "description:" & ///
            substr(raw_trim,1,5) != "unit:" & ///
            substr(raw_trim,1,5) != "note:" & ///
            substr(raw_trim,1,13) != "limited_data:" & ///
            substr(raw_trim,1,9) != "_metadata" & ///
            substr(raw_trim,1,11) != "indicators:" & ///
            substr(raw_trim,1,1) != "-"

        * Detect field lines (indent == 4, has colon)
        gen byte is_field = 0
        replace is_field = 1 if indent == 4 & strpos(raw_trim, ":") > 0 & ///
            is_indicator == 0 & linenum > 9

        * Extract indicator code
        gen str100 ind_code = ""
        replace ind_code = strtrim(substr(rawline, 1, length(rawline) - 1)) ///
            if is_indicator

        * Propagate indicator code down to its fields
        gen long ind_group = sum(is_indicator)
        bysort ind_group: replace ind_code = ind_code[1]

        *-------------------------------------------------------------------
        * STEP 3: Extract field type and value
        *-------------------------------------------------------------------
        gen str20 field_type = ""
        gen int colon_pos = strpos(rawline, ":")
        replace field_type = strtrim(substr(rawline, 1, colon_pos - 1)) ///
            if is_field & colon_pos > 0

        gen strL field_val = ""
        replace field_val = strtrim(substr(rawline, colon_pos + 1, .)) ///
            if is_field & colon_pos > 0
        * Remove surrounding quotes
        replace field_val = substr(field_val, 2, length(field_val)-2) ///
            if is_field & length(field_val) >= 2 & ///
            ((substr(field_val,1,1) == `"""' & ///
              substr(field_val,length(field_val),1) == `"""') | ///
             (substr(field_val,1,1) == "'" & ///
              substr(field_val,length(field_val),1) == "'"))

        * Handle YAML block scalars (folded/literal)
        gen byte block_start = is_field & inlist(field_val, ">", ">-", "|", "|-")
        replace field_val = "" if block_start
        gen byte is_blank = raw_trim == ""

        * Forward-fill block_active for continuation lines
        gen byte block_active = 0
        replace block_active = 1 if block_start
        forvalues iter = 1/20 {
            replace block_active = 1 if _n > 1 & block_active[_n-1] == 1 & ///
                !block_start & (indent >= 6 | is_blank)
        }
        replace block_active = 0 if (is_field | is_indicator) & !block_start

        gen str20 block_field = ""
        replace block_field = field_type if block_start
        forvalues iter = 1/20 {
            replace block_field = block_field[_n-1] ///
                if block_field == "" & block_active == 1 & _n > 1
        }

        gen byte block_line = block_active == 1 & !block_start & ///
            indent >= 6 & !is_blank
        replace field_type = block_field if block_line
        replace field_val = strtrim(regexr(rawline, "^[ ]+", "")) if block_line

        *-------------------------------------------------------------------
        * STEP 4: Assign to typed columns
        *-------------------------------------------------------------------
        gen strL field_name = ""
        gen strL field_desc = ""
        gen strL field_source = ""
        gen strL field_source_name = ""
        gen strL field_topic = ""
        gen strL field_note = ""
        gen str20 field_source_id = ""
        gen str50 field_topic_ids = ""
        gen str100 field_unit = ""
        gen byte field_limited_data = 0
        replace field_name = field_val if field_type == "name"
        replace field_desc = field_val if field_type == "description"
        replace field_source = field_val if field_type == "source_org"
        replace field_source_name = field_val if field_type == "source_name"
        replace field_topic = field_val if field_type == "topic_names"
        replace field_note = field_val if field_type == "note"
        replace field_source_id = field_val if field_type == "source_id"
        replace field_topic_ids = field_val if field_type == "topic_ids"
        replace field_unit = field_val if field_type == "unit"
        replace field_limited_data = (strlower(field_val) == "true") ///
            if field_type == "limited_data"

        replace field_topic_ids = "" if field_topic_ids == "[]"
        replace field_topic = "" if field_topic == "[]"

        *-------------------------------------------------------------------
        * STEP 5: Handle YAML list items (topic_ids, topic_names)
        *-------------------------------------------------------------------
        gen byte is_list_item = regexm(raw_trim, "^- ")
        gen str100 list_item_val = ""
        replace list_item_val = strtrim(substr(raw_trim, 3, .)) if is_list_item
        replace list_item_val = substr(list_item_val, 2, ///
            length(list_item_val)-2) if is_list_item & ///
            length(list_item_val) >= 2 & ///
            ((substr(list_item_val,1,1) == "'" & ///
              substr(list_item_val,length(list_item_val),1) == "'") | ///
             (substr(list_item_val,1,1) == `"""' & ///
              substr(list_item_val,length(list_item_val),1) == `"""'))

        gen str20 last_field_header = ""
        replace last_field_header = field_type ///
            if field_type == "topic_ids" | field_type == "topic_names"
        replace last_field_header = last_field_header[_n-1] ///
            if last_field_header == "" & _n > 1

        replace field_topic_ids = list_item_val ///
            if is_list_item & last_field_header == "topic_ids"
        replace field_topic = list_item_val ///
            if is_list_item & last_field_header == "topic_names"

        drop is_list_item list_item_val last_field_header

        *-------------------------------------------------------------------
        * STEP 6: Accumulate multi-row fields (cond() single-pass)
        *-------------------------------------------------------------------
        sort ind_group linenum

        foreach v in field_desc field_note field_source {
            gen strL `v'_acc = ""
            by ind_group: replace `v'_acc = `v' if _n == 1
            by ind_group: replace `v'_acc = cond(`v' != "", ///
                cond(`v'_acc[_n-1] != "", `v'_acc[_n-1] + " " + `v', `v'), ///
                `v'_acc[_n-1]) if _n > 1
            by ind_group: replace `v' = `v'_acc[_N]
            drop `v'_acc
        }

        * Accumulate topic_ids (semicolon-separated)
        gen str500 all_topic_ids = ""
        by ind_group: replace all_topic_ids = field_topic_ids if _n == 1
        by ind_group: replace all_topic_ids = cond(field_topic_ids != "", ///
            cond(all_topic_ids[_n-1] != "", ///
                all_topic_ids[_n-1] + ";" + field_topic_ids, field_topic_ids), ///
            all_topic_ids[_n-1]) if _n > 1
        by ind_group: replace all_topic_ids = all_topic_ids[_N]
        replace field_topic_ids = all_topic_ids
        drop all_topic_ids

        * Accumulate topic_names (semicolon-separated)
        gen strL all_topic_names = ""
        by ind_group: replace all_topic_names = field_topic if _n == 1
        by ind_group: replace all_topic_names = cond(field_topic != "", ///
            cond(all_topic_names[_n-1] != "", ///
                all_topic_names[_n-1] + "; " + field_topic, field_topic), ///
            all_topic_names[_n-1]) if _n > 1
        by ind_group: replace all_topic_names = all_topic_names[_N]
        replace field_topic = all_topic_names
        drop all_topic_names

        *-------------------------------------------------------------------
        * STEP 7: Collapse to one row per indicator
        *-------------------------------------------------------------------
        collapse (firstnm) ind_code (firstnm) field_name (firstnm) field_desc ///
                 (firstnm) field_source (firstnm) field_source_name ///
                 (firstnm) field_topic (firstnm) field_note ///
                 (firstnm) field_source_id (firstnm) field_topic_ids ///
                 (firstnm) field_unit (max) field_limited_data, by(ind_group)
        drop if ind_code == ""

        keep ind_code field_name field_desc field_source field_source_name ///
             field_topic field_note field_source_id field_topic_ids ///
             field_unit field_limited_data
    }
end
