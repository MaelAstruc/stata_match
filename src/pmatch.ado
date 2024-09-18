// pmatch command
// see "src/pmatch.mata" for the entry point in the algorithm

program pmatch
    syntax namelist(min=1 max=2), ///
        Variables(varlist min=1) Body(str asis) ///
        [REPLACE NOCHECK]
    
    local check = ("`nocheck'" == "")
    local dtype = ""
    
    if (wordcount("`namelist'") == 2) {
        local dtype    = word("`namelist'", 1)
        local namelist = word("`namelist'", 2)
        check_dtype `dtype', `replace'
    }
    
    check_replace `namelist', `replace'
    local gen_first = ("`replace'" == "")

    mata: pmatch("`namelist'", "`variables'", `"`body'"', `check', `gen_first', "`dtype'")
end

// Util functions to check the inputs

// Check that replace is correctly used for new and existing variable names
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

// If two names are provided, check that the first is a data type
program check_dtype
    syntax namelist(min=1 max=1), [REPLACE]
    
    scalar is_dtype = 0
    
    if (inlist("`namelist'", "byte", "int", "long", "float", "double", "strL")) {
        scalar is_dtype = 1
    }
    else if (regexm("`namelist'", "^str")) {
        local str_end = regexr("`namelist'", "^str", "")
        local str_end = real("`str_end'")
        if (`str_end' == int(`str_end') & `str_end' >= 1 & `str_end' <= 2045) {
            scalar is_dtype = 1
        }
    }
    
    if (!is_dtype) {
        dis as error in smcl "{bf:`dtype'} is not a data type, too many variables specified"
        exit 103
    }
    
    if ("`replace'" != "") {
        dis as error in smcl "options {bf:data type `namelist'} and {bf:replace} may not be combined"
        exit 184
    }
end
