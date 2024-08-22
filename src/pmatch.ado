// pmatch command
// see "src/pmatch.mata" for the entry point in the algorithm

program pmatch
    syntax namelist(min=1 max=1), ///
        Variables(varlist min=1) Body(str asis) ///
        [NOCHECK]
    
    local check = ("`nocheck'" == "")

    mata: pmatch("`namelist'", "`variables'", `"`body'"', `check')
end

