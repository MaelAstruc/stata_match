/////////////////////////////// MAIN TEST DO-FILE //////////////////////////////

/*
The purpose of this do-file is to run all the tests and report the results.

These tests include:
    - Unit-tests on the core of the algorithm: to assert that each component
        produces the expected result
    - End-to-end test to assert that the whole command works

These tests help me check that everything works as expected and continue to work
as I add new features.
*/

///////////////////////////////////////////////////////////////////////// SET-UP

* Set up environment

clear all

mata
mata clear
mata set matastrict on
mata set matalnum off
end

* Charge the package

do "match.ado"

* Global variables to keep track of the results

mata: TOTAL  = 0
mata: PASSED = 0
mata: FAILED = 0
mata: ERRORS = J(1, 0, "")

////////////////////////////////////////////////////////////////////////// UTILS

* Small functions to run the tests and keep track of the results

run "dev/test/test_utils.do"

//////////////////////////////////////////////////////////////////////////// LOG

capture log close
log using "dev/logs/test.log", replace

////////////////////////////////////////////////////////////////////// RUN TESTS

// TODO: run "dev/test/test_variables.do"
run "dev/test/test_patterns.do"
// TODO: run "dev/test/test_arm.do"
// TODO: run "dev/test/test_parser.do"
// TODO: run "dev/test/test_algorithm.do"
run "dev/test/test_end_to_end.do"

mata: mata drop test_*()

////////////////////////////////////////////////////////////////// PRINT RESULTS

mata: display_errors(ERRORS)
mata: printf("TEST TOTAL : %4.0f", TOTAL)
mata: printf("TEST PASSED: %4.0f", PASSED)
mata: printf("TEST FAILED: %4.0f", FAILED)

log close