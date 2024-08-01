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

run "main.do"

* Global variables to keep track of the results

mata: PASSED = 0
mata: FAILED = 0
mata: ERRORS = J(1, 0, "")

////////////////////////////////////////////////////////////////////////// UTILS

* Small functions to run the tests and keep track of the results

run "./test/utils.do"

////////////////////////////////////////////////////////////////////// RUN TESTS

// TODO: run "./test/test_variables.do"
run "./test/test_patterns.do"
// TODO: run "./test/test_arm.do"
// TODO: run "./test/test_parser.do"
// TODO: run "./test/test_algorithm.do"
run "./test/test_end_to_end.do"

mata: mata drop test_*()

////////////////////////////////////////////////////////////////// PRINT RESULTS

mata: display_errors(ERRORS)
mata: printf("TEST PASSED: %f", PASSED)
mata: printf("TEST FAILED: %f", FAILED)
