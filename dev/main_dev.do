/*
Main file for development
Tests the code and runs benchmarks
*/

clear all

**#********************************************************************** Locals

local pkg_version    = "0.0.10"
local distrib_date   = "24 Sep 2024"
local stata_version  = "`c(version)'"
local date_fmt       = string(date("`distrib_date'", "DMY"), "%tdDD/NN/CCYY")
local pwd            = ustrregexra("`c(pwd)'", "\\", "/") + "/"

mata
    files = (
        "src/declare.mata",
        "src/pattern_list.mata",
        "src/pattern.mata",
        "src/htable.mata",
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

**#******************************************** Change directory to project root

if (regexm("`pwd'", "/stata_match/.*$")) {
	local pwd = regexr("`pwd'", "/stata_match/.*$", "") + "/stata_match"
	cd `pwd'
}
else {
	dis as error "Invalid working directory"
	exit 170
}

**#**************************************************************** Charge utils

do "dev/main_utils.do"

**#*************************************************************** Build package

// Remove tabs from files in "src"

mata: rm_tabs_dir("src")
mata: rm_tabs_dir("dev/benchmark")
mata: rm_tabs_dir("dev/test")

// Build main files

mata: combine_files(files, "pkg/pmatch.ado", st_local("pkg_version"), st_local("distrib_date"), 0)
mata: write_pkg("pkg/pmatch.pkg", st_local("distrib_date"))
mata: write_sthlp_dir("docs", "pkg", st_local("pkg_version"), st_local("distrib_date"))

// Translate all .sthlp help files to pdf

sthlp2pdf_dir "pkg"

**#*********************************************************** Reinstall command

capture net uninstall pmatch
net install pmatch, from("`c(pwd)'/pkg")

**#******************************************************************* Run tests

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

**#************************************************************** Run benchmarks

do "dev/benchmark/class_count.do"
do "dev/benchmark/bench_e2e.do"
