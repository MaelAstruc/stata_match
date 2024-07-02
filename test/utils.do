/*
Util functions to run the tests and keep track of the results

*/

capture mata: mata drop test_result()
capture: program drop test_variables

mata

/*
Wrapper function to compare two results in string format and keep track of the
number of tests that passed or failed and the corresponding errors.
*/
function test_result(string scalar test_name, string scalar result, string scalar expected) {
    string scalar new_error, all_errors
    real scalar passed, failed
    
    if (result == expected) {
        "TESTING PASSED"
    
        passed = st_global("PASSED")
        passed = strtoreal(passed)
        
        st_global("PASSED", strofreal(passed + 1))
    }
    else {
        "TESTING FAILED"
    
        new_error = sprintf(
            "'%s':\n\tExpected '%s'\n\tFound '%s'",
            test_name,
            expected,
            result
        )
        
        all_errors = st_global("ERRORS")
        
        failed = st_global("FAILED")
        failed = strtoreal(failed)

        if (failed > 0) {
            all_errors = sprintf("%s\n", all_errors)
        }
        
        all_errors = sprintf("%s%s", all_errors, new_error)
        
        st_global("ERRORS", all_errors)
        
        st_global("FAILED", strofreal(strtoreal(failed) + 1))
    }
}

end

program test_variables
    syntax, EXPected(varname) RESult(varname) TESTname(string)
    
    quietly: count if `expected' != `result'
    
    if (`r(N)' == 0) {
        global PASSED = $PASSED + 1
    }
    else {
        local new_error = "`testname':\n\t`r(N)' difference"
        
        if ($FAILED > 0) {
            global ERRORS = "$ERRORS\n"
        }
        
        global ERRORS = `"$ERRORS`new_error'"'
        
        global FAILED = $FAILED + 1
    }
end
