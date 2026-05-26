/*
Main file for development
Tests the code and runs benchmarks
*/

clear all

**#******************************************************** Check computer state

// Run Stata as high-priority
shell powershell -Command "(Get-Process -Name 'stataMP-64').PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High"

// Wait for computer to use less that 5% of processor
shell powershell -Command "while ((Get-Counter).CounterSamples.CookedValue[1] -gt 0.05) {Start-Sleep -Seconds 1}"

**#********************************************************************** Locals

local pkg_version    = "1.0.0"
local distrib_date   = "26 May 2026"
local stata_version  = "`c(version)'"
local date_fmt       = string(date("`distrib_date'", "DMY"), "%tdDD/NN/CCYY")
local pwd            = ustrregexra("`c(pwd)'", "\\", "/") + "/"

mata
    files = (
        "src/declare.mata",
        "src/utils.mata",
        "src/interface.mata",
        "src/pattern.mata",
        "src/tuples.mata",
        "src/htable.mata",
        "src/variable.mata",
        "src/arm.mata",
        "src/parser.mata",
        "src/usefulness.mata",
        "src/match_report.mata",
        "src/algorithm.mata",
        "src/patmatch.mata",
        "src/patmatch.ado"
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

mata: combine_files(files, "pkg/patmatch.ado", st_local("pkg_version"), st_local("distrib_date"), "")
mata: combine_files(files, "dev/benchmark/patmatch_bench.ado", st_local("pkg_version"), st_local("distrib_date"), "bench")
mata: combine_files(files, "dev/profiler/patmatch_profiler.ado", st_local("pkg_version"), st_local("distrib_date"), "profiler")
mata: write_pkg("pkg/patmatch.pkg", st_local("distrib_date"))
mata: write_sthlp_dir("docs", "pkg", st_local("pkg_version"), st_local("distrib_date"))

// Translate all .sthlp help files to pdf

sthlp2pdf_dir "pkg"

**#*********************************************************** Reinstall command

capture net uninstall patmatch
net install patmatch, replace from("`c(pwd)'/pkg")

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

// shell powershell -Command "(Start-Process 'C:/Users/malsouder/Documents/Stata 17/StataMP-64.exe' -ArgumentList '/e do C:/Users/malsouder/Documents/Projets/stata_match/dev/benchmark/bench_e2e.do' -PassThru).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High"

**#*************************************************************** Run profilers

do "dev/profiler/profile_end_to_end.do"
