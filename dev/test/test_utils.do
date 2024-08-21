/*
Util functions to run the tests and keep track of the results

*/

capture mata: mata drop test_result()
capture: program drop test_variables

mata

/*
A simple function to concatenate and display errors
*/
function display_errors(string rowvector errors) {
    string scalar str
    real scalar i, n

    if (length(errors) == 0) {
        return
    }

    str = "{err}" + errors[1]

    n = length(errors)

    for (i = 2; i <= n; i = i + 1) {
        str = str + "\n" + errors[i]
    }

    printf(str)
}

/*
Wrapper function to compare two results in string format and keep track of the
number of tests that passed or failed and the corresponding errors.
*/
function test_result(string scalar test_name, string scalar result, string scalar expected) {
    pointer(real scalar) TOTAL, PASSED, FAILED
    pointer(string scalar) ERRORS
    string scalar new_error
    
    TOTAL = findexternal("TOTAL")
    *TOTAL = *TOTAL + 1
    
    if (result == expected) {
        "TESTING PASSED"
    
        PASSED = findexternal("PASSED")
        *PASSED = *PASSED + 1
    }
    else {
        "TESTING FAILED"
    
        FAILED = findexternal("FAILED")
        *FAILED = *FAILED + 1

        ERRORS = findexternal("ERRORS")

        new_error = sprintf(
            "'%s':\n\tExpected '%s'\n\tFound    '%s'",
            test_name,
            expected,
            result
        )
        
        *ERRORS = *ERRORS, new_error
    }
}

void function exit_if_errors() {
    real scalar FAILED
    
    FAILED = *findexternal("FAILED")
    
    if (FAILED > 0) {
        exit(1)
    }
}
end

program test_variables
    syntax, EXPected(varname) RESult(varname) TESTname(string)
    
    quietly: count if `expected' != `result'
    
    mata {
        TOTAL = TOTAL + 1
        
        if (`r(N)' == 0) {
            PASSED = PASSED + 1
        }
        else {
            FAILED = FAILED + 1

            testname = st_local("testname")
            new_error = sprintf("%s\n\t%f differences", testname, `r(N)')

            ERRORS = ERRORS, new_error
        }
    }
end
