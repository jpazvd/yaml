*******************************************************************************
* yaml_harmonize
*! v 2.0.0   27Jul2026               by Joao Pedro Azevedo (UNICEF)
* Generate a Stata harmonization do-file from a pair of YAML crosswalk files.
*
*     yaml_harmonize using source.yaml, target(target.yaml) saving(out.do)
*
* The source file carries one entry per crosswalk row: what this survey round
* calls the variable, plus the canonical name, label and unit of analysis. The
* target file carries what is true of the canonical variable whatever round it
* came from: value labels, and any documentation identifiers.
*
* Nothing in the emitted do-file is hand-written, so metadata added once to the
* target file reaches every do-file the crosswalk produces.
*******************************************************************************

capture program drop yaml_harmonize
program yaml_harmonize, rclass
    version 14.0
    syntax using/, TARGET(string) [SAVING(string) replace TIMEstamp ///
                                   PROJECT(string) AUTHOR(string) DDIexport]

    if ("`saving'" == "") local saving "harmonize.do"
    if ("`replace'" == "") {
        capture confirm file "`saving'"
        if (_rc == 0) {
            di as err "file `saving' already exists; use replace"
            exit 602
        }
    }

    * ---------------------------------------------------------------- inputs
    capture confirm file "`using'"
    if (_rc) {
        di as err "source crosswalk file not found: `using'"
        exit 601
    }
    capture confirm file "`target'"
    if (_rc) {
        di as err "target crosswalk file not found: `target'"
        exit 601
    }

    yaml read using "`using'", frame(_xwsrc) replace
    yaml read using "`target'", frame(_xwtgt) replace

    yaml get source, frame(_xwsrc) quiet
    local srclabel "`r(value)'"
    yaml get standard, frame(_xwtgt) quiet
    local tgtlabel "`r(value)'"

    * count first, so the header can report coverage
    yaml list variables, keys children frame(_xwsrc) noheader
    local items "`r(keys)'"
    local n_map = 0
    local n_skip = 0
    foreach i of local items {
        yaml get variables:`i':ipums_name, frame(_xwsrc) quiet
        if ("`r(value)'" != "") local ++n_map
        else local ++n_skip
    }

    * ---------------------------------------------------------------- header
    tempname fh
    * quietly: -write replace- notes "(file ... not found)" when there is
    * nothing to replace, which is not worth reporting
    quietly file open `fh' using "`saving'", write replace text
    local rule "*==============================================================================="
    local sub  "*-------------------------------------------------------------------------------"

    file write `fh' "`rule'" _n
    file write `fh' "* `saving'" _n
    file write `fh' "*" _n
    if ("`project'" != "") file write `fh' "* Project:   `project'" _n
    file write `fh' "* Purpose:   Rename and label a `srclabel' extract to the `tgtlabel'" _n
    file write `fh' "*            canonical variables." _n
    file write `fh' "*" _n
    file write `fh' "* GENERATED FILE - DO NOT EDIT." _n
    file write `fh' "* Edit the crosswalk files below and regenerate with yaml_harmonize." _n
    file write `fh' "*" _n
    file write `fh' "* Inputs" _n
    file write `fh' "*   Source:  `using'" _n
    file write `fh' "*            what `srclabel' calls each variable, with the canonical" _n
    file write `fh' "*            name, label and unit of analysis for that row" _n
    file write `fh' "*   Target:  `target'" _n
    file write `fh' "*            what is true of the canonical variable in any round:" _n
    file write `fh' "*            value labels and documentation identifiers" _n
    file write `fh' "*" _n
    file write `fh' "* Coverage:  `n_map' variable(s) mapped, `n_skip' skipped" _n
    if ("`author'" != "")    file write `fh' "* Author:    `author'" _n
    if ("`timestamp'" != "") file write `fh' "* Generated: `c(current_date)' `c(current_time)'" _n
    file write `fh' "* Generator: yaml_harmonize (yaml package)" _n
    file write `fh' "`rule'" _n _n
    file write `fh' "version 14.0" _n _n

    * ------------------------------------------------------------------ body
    local skipped ""
    foreach i of local items {
        yaml get variables:`i':name, frame(_xwsrc) quiet
        local oldname "`r(value)'"
        yaml get variables:`i':ipums_name, frame(_xwsrc) quiet
        local newname "`r(value)'"
        yaml get variables:`i':ipums_label, frame(_xwsrc) quiet
        local newlabel "`r(value)'"
        yaml get variables:`i':unit, frame(_xwsrc) quiet
        local unit "`r(value)'"
        yaml get variables:`i':concept, frame(_xwsrc) quiet
        local concept "`r(value)'"

        if ("`newname'" == "") {
            local skipped "`skipped' `oldname'"
            continue
        }

        * ---- resolve the target side first, so the whole block can be guarded
        local grp ""
        yaml list concepts, keys children frame(_xwtgt) noheader
        foreach j in `r(keys)' {
            yaml get concepts:`j':concept, frame(_xwtgt) quiet
            if ("`r(value)'" == "`concept'") local grp "`j'"
        }

        local ddi ""
        local defn ""
        local hascodes = 0
        if ("`grp'" != "") {
            yaml get concepts:`grp':ddi, frame(_xwtgt) quiet
            local ddi "`r(value)'"

            capture yaml list concepts:`grp':codes, keys children frame(_xwtgt) noheader
            if (_rc == 0 & `"`r(keys)'"' != "") {
                local hascodes = 1
                foreach v in `r(keys)' {
                    yaml get concepts:`grp':codes:`v':code, frame(_xwtgt) quiet
                    local code "`r(value)'"
                    yaml get concepts:`grp':codes:`v':label, frame(_xwtgt) quiet
                    local lab "`r(value)'"
                    local defn `"`defn' `code' "`lab'""'
                }
            }
        }

        file write `fh' "`sub'" _n
        file write `fh' "* `concept'" _n
        file write `fh' "*   `srclabel': `oldname'   ->   `tgtlabel': `newname'" _n
        if ("`unit'" != "") file write `fh' "*   unit of analysis: `unit'" _n
        file write `fh' "`sub'" _n

        * a value label does not need the variable, so define it either way
        if (`hascodes') {
            file write `fh' `"label define `newname'_lbl`defn', replace"' _n
        }

        * Everything that touches the variable goes inside one guard. A round that
        * does not carry this variable then skips the block and says so, instead of
        * renaming nothing and failing on the next line.
        file write `fh' "capture confirm variable `oldname'" _n
        file write `fh' "if (_rc) {" _n
        file write `fh' `"    display as text "  `oldname' not in data; `newname' skipped""' _n
        file write `fh' "}" _n
        file write `fh' "else {" _n
        if ("`oldname'" != "`newname'") {
            file write `fh' "    rename `oldname' `newname'" _n
        }
        else {
            file write `fh' "    * name unchanged in `srclabel'" _n
        }
        file write `fh' `"    label variable `newname' "`newlabel'""' _n
        if ("`ddi'" != "") {
            file write `fh' `"    char `newname'[ddi] "`ddi'""' _n
        }
        if (`hascodes') {
            file write `fh' "    label values `newname' `newname'_lbl" _n
        }
        file write `fh' "}" _n
        file write `fh' _n
    }

    * ------------------------------------------------- optional DDI export
    if ("`ddiexport'" != "") {
        yaml get study:id, frame(_xwsrc) quiet
        local st_id "`r(value)'"
        yaml get study:extract, frame(_xwsrc) quiet
        local st_extract "`r(value)'"
        yaml get ddi:template, frame(_xwtgt) quiet
        local dd_tpl "`r(value)'"
        yaml get ddi:stats, frame(_xwtgt) quiet
        local dd_stats "`r(value)'"

        if ("`st_id'" == "") {
            di as text "  (ddiexport: no study: block in the source file; skipped)"
        }
        else {
            file write `fh' "`sub'" _n
            file write `fh' "* DDI export" _n
            file write `fh' "*   dta2ddi replaces ;XXX;-style markers in the appended" _n
            file write `fh' "*   template with the values of its xxx()...vvv() options." _n
            file write `fh' "*   Each slot below is named in the target crosswalk:" _n

            * resolve each slot to its meaning, then to this study's value
            local slotopts ""
            yaml list ddi:slots, keys children frame(_xwtgt) noheader
            foreach k in `r(keys)' {
                yaml get ddi:slots:`k':slot, frame(_xwtgt) quiet
                local slot "`r(value)'"
                yaml get ddi:slots:`k':means, frame(_xwtgt) quiet
                local means "`r(value)'"
                if ("`slot'" == "" | "`means'" == "") continue
                yaml get study:`means', frame(_xwsrc) quiet
                local val "`r(value)'"
                if ("`val'" == "") {
                    file write `fh' "*     `slot' = `means' -> (not set for this study)" _n
                    continue
                }
                file write `fh' "*     `slot' = `means' -> `val'" _n
                local slotopts `"`slotopts' `slot'(`val')"'
            }
            file write `fh' "*" _n
            file write `fh' "*   dta2ddi documents a dataset on disk, so the export runs on the" _n
            file write `fh' "*   harmonized data saved below, not on the raw `st_extract'." _n
            file write `fh' "`sub'" _n
            file write `fh' "capture which dta2ddi" _n
            file write `fh' "if (_rc) {" _n
            file write `fh' `"    display as text "dta2ddi not installed; skipping DDI export (ssc install dta2ddi)""' _n
            file write `fh' "}" _n
            file write `fh' "else {" _n
            file write `fh' "    tempfile _harmonized" _n
            file write `fh' `"    quietly save "\`_harmonized'", replace"' _n
            if ("`dd_tpl'" != "") {
                file write `fh' `"    capture confirm file "`dd_tpl'""' _n
                file write `fh' "    if (_rc) {" _n
                file write `fh' `"        display as text "`dd_tpl' not found; skipping DDI export""' _n
                file write `fh' "    }" _n
                file write `fh' "    else {" _n
                file write `fh' `"        dta2ddi, using("\`_harmonized'") save("`st_id'.xml") ///"' _n
                file write `fh' `"            append("`dd_tpl'") ///"' _n
                if ("`dd_stats'" != "") file write `fh' `"            id(`st_id') stats(`dd_stats') ///"' _n
                else                    file write `fh' `"            id(`st_id') ///"' _n
                file write `fh' `"           `slotopts'"' _n
                file write `fh' "    }" _n
            }
            else {
                file write `fh' `"    dta2ddi, using("\`_harmonized'") save("`st_id'.xml") ///"' _n
                if ("`dd_stats'" != "") file write `fh' `"        id(`st_id') stats(`dd_stats') ///"' _n
                else                    file write `fh' `"        id(`st_id') ///"' _n
                file write `fh' `"       `slotopts'"' _n
            }
            file write `fh' "}" _n _n
        }
    }

    file write `fh' "`rule'" _n
    file write `fh' "* end of `saving'" _n
    file write `fh' "`rule'" _n
    file close `fh'

    * ------------------------------------------------- drop the work frames
    * the crosswalks were read into frames only to be queried; leaving them
    * behind would surprise a later -yaml frames- in the caller's session
    capture frame drop yaml__xwsrc
    capture frame drop yaml__xwtgt

    * ----------------------------------------------------------------- report
    di as text "yaml_harmonize: wrote " as result "`saving'" ///
       as text " (`n_map' mapped, `n_skip' skipped)"
    if ("`skipped'" != "") {
        di as text "  no canonical name for:" as result "`skipped'"
    }

    return local saving "`saving'"
    return scalar n_mapped  = `n_map'
    return scalar n_skipped = `n_skip'
end
