*******************************************************************************
* _yaml_fastread
*! v 2.0.0   26Jul2026               by Joao Pedro Azevedo (UNICEF)
* Fast-read parser (opt-in): shallow mappings + list blocks
*
* Data model (differs from canonical parser):
*   key   (str)  - Top-level section header (first-level mapping key)
*   field (str)  - Field name within that section
*   value (str)  - Scalar value or list item text
*   list  (int)  - 1 = list item, 0 = scalar field
*   line  (int)  - Source file line number
*
* Canonical parser produces: key / value / level / parent / type
* Fastread produces:         key / field / value / list  / line
*
* Options:
*   fields(list)       - Keep only these field names (semicolon- or space-separated)
*   listkeys(list)     - Keep list items only under these field names
*   blockscalars       - Capture | and > block scalars (joined with char(10))
*
* Limitations:
*   - Rejects anchors (&), aliases (*), merge keys (<<:)
*   - Rejects flow collections ({ } [ ]) at line start or value position
*   - Designed for shallow YAML (1-2 levels of nesting)
*******************************************************************************

program define _yaml_fastread
    version 14.0

    syntax using/ [, FIELDS(string) LISTKEYS(string) BLOCKSCALARS]

    local fields_list = lower("`fields'")
    local fields_list = subinstr("`fields_list'", ";", " ", .)
    local list_list = lower("`listkeys'")
    local list_list = subinstr("`list_list'", ";", " ", .)

    local use_fields = ("`fields_list'" != "")
    local use_listkeys = ("`list_list'" != "")

    tempname fh
    file open `fh' using "`using'", read text

    local linenum = 0
    local current_key ""
    local current_field ""
    local current_indent = 0
    local n_levels = 0

    local has_pending = 0
    local pending_line ""

    file read `fh' line
    while r(eof) == 0 | `has_pending' == 1 {
        if (`has_pending' == 1) {
            local line `"`pending_line'"'
            local has_pending = 0
        }
        local linenum = `linenum' + 1

        local trimmed = strtrim(`"`line'"')
        if (`"`trimmed'"' == "" | substr(`"`trimmed'"', 1, 1) == "#") {
            if (`has_pending' == 0) file read `fh' line
            continue
        }

        * Unsupported YAML features in fastread: anchors, aliases, merge keys
        if (regexm(`"`trimmed'"', "^&") | regexm(`"`trimmed'"', "^[*]") | ///
            regexm(`"`trimmed'"', "^<<:")) {
            di as err "fastread unsupported YAML feature at line `linenum'. Rerun without fastread."
            exit 198
        }
        * Flow collections: only flag when line or value starts with { or [
        if (substr(`"`trimmed'"', 1, 1) == "{" | substr(`"`trimmed'"', 1, 1) == "[") {
            di as err "fastread unsupported flow collection at line `linenum'. Rerun without fastread."
            exit 198
        }

        * Count indent
        local indent = 0
        local templine `"`line'"'
        while (substr(`"`templine'"', 1, 1) == " ") {
            local indent = `indent' + 1
            local templine = substr(`"`templine'"', 2, .)
        }

        * List item
        if (substr(`"`trimmed'"', 1, 2) == "- ") {
            local item_value = strtrim(substr(`"`trimmed'"', 3, .))
            * Sequence items that are themselves mappings are outside the
            * fast-read model: fail explicitly rather than storing junk
            * (quoted scalar items are exempt even if they contain ': ')
            mata: _yaml_seq("item_value")
            if (`_isseq') {
                di as err "fastread unsupported sequence-of-mappings item at line `linenum'. Rerun without fastread."
                exit 198
            }
            * Strip outer quotes in Mata (_yaml_q, end of this file); values are
            * never expanded into Stata expressions -- see the block below.
            mata: _yaml_q("item_value", "_yi_", 1)

            local allow_list = 1
            if (`use_listkeys') {
                local allow_list = 0
                foreach lk of local list_list {
                    if (lower("`current_field'") == "`lk'") local allow_list = 1
                }
            }
            else if (`use_fields') {
                local allow_list = 0
                foreach fk of local fields_list {
                    if (lower("`current_field'") == "`fk'") local allow_list = 1
                }
            }

            if (`allow_list' & "`current_key'" != "" & "`current_field'" != "") {
                local newobs = _N + 1
                qui set obs `newobs'
                qui replace key = "`current_key'" in `newobs'
                qui replace field = "`current_field'" in `newobs'
                mata: st_sstore(`newobs', "value", st_local("item_value"))
                qui replace list = 1 in `newobs'
                qui replace line = `linenum' in `newobs'
            }

            if (`has_pending' == 0) file read `fh' line
            continue
        }

        * Key or field line
        local colon_pos = strpos(`"`trimmed'"', ":")
        if (`colon_pos' > 0) {
            local left = strtrim(substr(`"`trimmed'"', 1, `colon_pos' - 1))
            local right = strtrim(substr(`"`trimmed'"', `colon_pos' + 1, .))

            local _rlen : length local right
            if (`_rlen' == 0) {
                * Header (key)
                if (`indent' > `current_indent') {
                    local n_levels = `n_levels' + 1
                    local indent_`n_levels' = `indent'
                }
                else if (`indent' < `current_indent') {
                    local found_level = 1
                    forvalues lv = `n_levels'(-1)1 {
                        if (`indent_`lv'' <= `indent') {
                            local found_level = `lv'
                            continue, break
                        }
                    }
                    local n_levels = `found_level'
                }

                local key_`n_levels' "`left'"
                local current_indent = `indent'
                local current_key "`key_`n_levels''"
                local current_field ""
            }
            else {
                * Field with value
                local current_field "`left'"
                local value : copy local right
                * Probe the raw value in Mata (_yaml_q, end of this file): nothing
                * below expands the value into a Stata expression.
                mata: _yaml_q("value", "_yq_", 0)
                if (`_yq_flow') {
                    di as err "fastread unsupported flow collection at line `linenum'. Rerun without fastread."
                    exit 198
                }
                if ("`blockscalars'" == "" & `_yq_blk') {
                    di as err "fastread unsupported block scalar at line `linenum'. Rerun without fastread or use blockscalars."
                    exit 198
                }
                * Optional block scalar capture
                if ("`blockscalars'" != "" & `_yq_blk') {
                    local block_indent = `indent'
                    local block_val ""
                    file read `fh' line
                    while (r(eof) == 0) {
                        local next_trim = strtrim(`"`line'"')
                        local next_indent = 0
                        local tmp `"`line'"'
                        while (substr(`"`tmp'"', 1, 1) == " ") {
                            local next_indent = `next_indent' + 1
                            local tmp = substr(`"`tmp'"', 2, .)
                        }
                        if (`next_indent' <= `block_indent') {
                            local pending_line `"`line'"'
                            local has_pending = 1
                            continue, break
                        }
                        if (`"`block_val'"' == "") {
                            local block_val = strtrim(`"`line'"')
                        }
                        else {
                            local block_val = `"`block_val'"' + char(10) + strtrim(`"`line'"')
                        }
                        file read `fh' line
                    }
                    local value `"`block_val'"'
                }
                * Strip one matching pair of outer quotes (in Mata, same reason)
                mata: _yaml_q("value", "_yq_", 1)

                local allow_field = 1
                if (`use_fields') {
                    local allow_field = 0
                    foreach fk of local fields_list {
                        if (lower("`current_field'") == "`fk'") local allow_field = 1
                    }
                }

                if (`allow_field' & "`current_key'" != "") {
                    local newobs = _N + 1
                    qui set obs `newobs'
                    qui replace key = "`current_key'" in `newobs'
                    qui replace field = "`current_field'" in `newobs'
                    mata: st_sstore(`newobs', "value", st_local("value"))
                    qui replace list = 0 in `newobs'
                    qui replace line = `linenum' in `newobs'
                }
            }
        }

        if (`has_pending' == 0) file read `fh' line
    }

    file close `fh'

    qui drop if key == ""
    qui compress

    label variable key "Top-level key"
    label variable field "Field name"
    label variable value "Field value"
    label variable list "List item flag"
    label variable line "Line number"
end

*-------------------------------------------------------------------------------
* Mata primitives, compiled when this file loads. Values are NEVER expanded
* into Stata expressions: expanding a macro re-exposes its quote characters
* to the parser, so a real catalog description such as
*     'treated if it a) is long-lasting, b) pre-treated'
* aborts with "unknown function ()" (r(133)) inside substr()/inlist()/regexm().
* macval() and sentinel prefixes do not save it; st_local() reads the macro's
* bytes without expansion. Called directly (not through a wrapper program),
* so st_local() acts on the CALLER's macros.
*-------------------------------------------------------------------------------
version 14.0
capture mata: mata drop _yaml_q()
capture mata: mata drop _yaml_seq()
capture mata: mata drop _yaml_cat()

mata:

// strip one matching pair of outer quotes (if dostrip) and classify:
//   pfx q    1 if a quote pair was removed
//   pfx n    length after any strip
//   pfx blk  value is a bare block indicator  | |- > >-
//   pfx flow value starts a flow collection   { [
//   pfx bool 1 true-like, 2 false-like, 0 neither
//   pfx null value is null or ~
void _yaml_q(string scalar macname, string scalar pfx, real scalar dostrip)
{
    string scalar v, f
    real scalar n, q

    v = st_local(macname)
    n = strlen(v)
    f = substr(v, 1, 1)
    q = (n >= 2 & f == substr(v, n, 1) & (f == char(34) | f == char(39)))
    if (q & dostrip) {
        v = substr(v, 2, n - 2)
        st_local(macname, v)
        n = strlen(v)
        f = substr(v, 1, 1)
    }
    st_local(pfx + "q",    strofreal(q & dostrip))
    st_local(pfx + "n",    strofreal(n))
    st_local(pfx + "blk",  strofreal(v == "|" | v == "|-" | v == ">" | v == ">-"))
    st_local(pfx + "flow", strofreal(f == "{" | f == "["))
    st_local(pfx + "bool", strofreal(2*(v=="false"|v=="False"|v=="FALSE"|v=="no"|v=="No"|v=="NO") + (v=="true"|v=="True"|v=="TRUE"|v=="yes"|v=="Yes"|v=="YES")))
    st_local(pfx + "null", strofreal(v == "null" | v == "~"))
}

// sets _isseq: item is an (unquoted) mapping, outside the one-scalar model
void _yaml_seq(string scalar macname)
{
    string scalar v, f

    v = st_local(macname)
    f = substr(v, 1, 1)
    st_local("_isseq", strofreal(f != char(34) & f != char(39) & regexm(v, "^[^:#]+:([ ]|$)")))
}

// a := a + " " + b   (plain-scalar continuation join)
void _yaml_cat(string scalar a, string scalar b)
{
    st_local(a, st_local(a) + " " + st_local(b))
}

end
