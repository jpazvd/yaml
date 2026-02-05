*******************************************************************************
* _yaml_pop_parents
*! v 1.5.0   04Feb2026               by Joao Pedro Azevedo (UNICEF)
* Helper program to manage parent stack based on indentation
*******************************************************************************

program define _yaml_pop_parents, sclass
    syntax, indent(integer) parent_stack(string) indent_stack(string)
    
    * Pop indent levels that are >= current indent
    local new_indent_stack ""
    local new_parent_stack ""
    local count = 0
    
    foreach i of local indent_stack {
        if (`i' < `indent') {
            local new_indent_stack "`new_indent_stack' `i'"
            local count = `count' + 1
        }
    }
    
    * Rebuild parent stack (simplified - just keep last parent at lower indent)
    if (`count' <= 1) {
        local new_parent_stack ""
    }
    else {
        * Keep parent stack but trim to match indent level
        local nwords : word count `parent_stack'
        if (`nwords' > 0) {
            local pos = 0
            forvalues j = 1/`=length("`parent_stack'")' {
                if (substr("`parent_stack'", `j', 1) == "_") {
                    local pos = `j'
                }
            }
            if (`pos' > 0 & `count' <= 2) {
                local new_parent_stack = substr("`parent_stack'", 1, `pos' - 1)
            }
            else {
                local new_parent_stack "`parent_stack'"
            }
        }
    }
    
    sreturn local indent_stack "`new_indent_stack'"
    sreturn local parent_stack "`new_parent_stack'"
end
