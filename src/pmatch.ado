// pmatch command
// see "src/pmatch.mata" for the entry point in the algorithm

program pmatch
    syntax namelist(min=1 max=1), ///
        Variables(varlist min=1) Body(str asis) ///
        [REPLACE NOCHECK]
    
    local check     = ("`nocheck'" == "")
    
    check_replace `namelist', `replace'
    local gen_first = ("`replace'" == "")

    mata: pmatch("`namelist'", "`variables'", `"`body'"', `check', `gen_first')
end

program check_replace
    syntax namelist(min=1 max=1), [REPLACE]
    
    local gen_first = ("`replace'" == "")
    
    if (`gen_first') {
        capture confirm new variable `namelist'
        
        if (_rc == 110) {
            dis as error in smcl "variable {bf:`namelist'} already defined, use the 'replace' option to overwrite it"
            exit 110
        }
        else if (_rc != 0) {
            // Should be covered by the syntax command
            exit _rc
        }
    }
    else {
        capture confirm variable `namelist'
        
        if (_rc == 111) {
            dis as error in smcl "variable {bf:`namelist'} not found, option 'replace' cannot be used"
            exit 111
        }
        else if (_rc != 0) {
            // Should be covered by the syntax command
            exit _rc
        }
    }
end
