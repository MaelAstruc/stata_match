/*
Main file for development
Tests the code and runs benchmarks
*/

clear all

// Clean up space

do "dev/dev_utils.do"

* Remove tabs from files in "src"
mata: rm_tabs_dir("src")
mata: rm_tabs_dir("dev/benchmark")
mata: rm_tabs_dir("dev/test")

* Translate all .sthlp help files to pdf
sthlp2pdf_dir "docs"

// Run tests

do "dev/test/test.do"
mata: exit_if_errors()

// Run benchmarks

do "dev/benchmark/class_count.do"
do "dev/benchmark/bench_e2e.do"
