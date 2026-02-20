*******************************************************************************
*! _yaml_collapse
*! v 1.7.0   19Feb2026               by Joao Pedro Azevedo (UNICEF)
*! Post-process: pivot long YAML output to wide format (one row per entity)
*! Expects standard canonical schema in memory: key value level parent type
*******************************************************************************

program define _yaml_collapse
    version 14.0

    quietly {
        * Preserve observation order
        gen long _n = _n

        * Step 1: Forward-fill entity from level-2 parent keys
        gen _entity = key if type == "parent" & level == 2
        replace _entity = _entity[_n-1] if _entity == "" & _n > 1

        * Step 2: Identify root prefix (level-1 parent)
        qui levelsof key if type == "parent" & level == 1, local(root_keys) clean
        local root : word 1 of `root_keys'

        * Step 3: Extract entity code (strip root prefix + underscore)
        if ("`root'" != "") {
            gen _ind_code = substr(_entity, length("`root'") + 2, .) if _entity != ""
        }
        else {
            * No root parent — entity keys ARE the codes
            gen _ind_code = _entity if _entity != ""
        }

        * Step 4: Drop parent rows and rows without entity assignment
        drop if type == "parent"
        drop if _ind_code == "" | _ind_code == "."

        * Step 5: Extract field name (strip entity prefix from key)
        gen _field = substr(key, length(_entity) + 2, .)
        * For list items, strip numeric suffix (e.g., topic_ids_1 -> topic_ids)
        replace _field = regexs(1) if type == "list_item" & ///
            regexm(_field, "^(.+)_[0-9]+$")

        * Drop rows with empty field names
        drop if _field == ""

        * Step 6: Concatenate list items (semicolon-separated)
        sort _ind_code _field _n
        by _ind_code _field: replace value = cond(value != "", ///
            cond(value[_n-1] != "", value[_n-1] + ";" + value, value), ///
            value[_n-1]) if _n > 1
        by _ind_code _field: keep if _n == _N

        * Step 7: Reshape to wide format
        keep _ind_code _field value
        reshape wide value, i(_ind_code) j(_field) string
        rename value* *
        rename _ind_code ind_code
    }
end
