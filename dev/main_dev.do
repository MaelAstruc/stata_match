/*
Main file for development
Tests the code and runs benchmarks
*/

clear all

local stata_version = `c(version)'
local pmatch_version = "0.0.4"

mata
    files = (
        "src/declare.mata",
        "src/pattern_list.mata",
        "src/pattern.mata",
        "src/variable.mata",
        "src/tuple.mata",
        "src/arm.mata",
        "src/parser.mata",
        "src/usefulness.mata",
        "src/match_report.mata",
        "src/algorithm.mata",
        "src/pmatch.mata",
        "src/pmatch.ado"
    )
end

// Clean up space

do "dev/dev_utils.do"

* Remove tabs from files in "src"
mata: rm_tabs_dir("src")
mata: rm_tabs_dir("dev/benchmark")
mata: rm_tabs_dir("dev/test")

* Translate all .sthlp help files to pdf
sthlp2pdf_dir "docs"

// Build main file

mata: combine_files(files, "pkg/pmatch.ado", "`pmatch_version'", 0)

// Reinstall command

capture net uninstall pmatch
net install pmatch, from("`c(pwd)'/pkg")

// Run tests

local add_log = ""

forvalues test_version = 8/`stata_version' {
    version `test_version'
    
    if (`test_version' == `stata_version') {
        local add_log = "add_log"
    }
    
    do "dev/test/test.do" `add_log'

    mata: exit_if_errors()
}

version `stata_version'

// Run benchmarks

do "dev/benchmark/class_count.do"
do "dev/benchmark/bench_e2e.do"
