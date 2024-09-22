/*
Benchmark the match function and compare to performance of base commands
*/

clear all

run "dev/dev_utils.do"
run "dev/benchmark/bench_utils.mata"
run "pkg/pmatch.ado"
mata: combine_files("src/pmatch.mata", "dev/benchmark/pmatch_bench.ado", "`version'", "`distrib_date'", 1)
mata: mata drop pmatch()
do "dev/benchmark/pmatch_bench.ado"

// Check the time needed  with different number of observations
program compare_num
    syntax, TYPE(string) OBS(integer) LEVELS(integer) [NOCHECK]
    
    local n = (`levels' / 10)
    
    // Prepare data
    clear
    set obs `obs'
    gen `type' x = mod(_n, `levels') + 1
    bsample
    
    // Run base commands
    mata: bench_on("base")
    gen y_base = "d"
    forvalues i = 0/`n' {
        replace y_base = "`i'0a" if x == `i'1
        replace y_base = "`i'0b" if x == `i'2 | x == `i'3 | x == `i'4
        replace y_base = "`i'0c" if x >= `i'5 & x <= `i'9
    }
    mata: bench_off("base")
    
    // Build pmatch command
    local command `"pmatch y, v(x) b("'
    forvalues i = 0/`n' {
        local command `"`command' `i'1 = "`i'0a","'
        local command `"`command' `i'2 | `i'3 | `i'4 = "`i'0b","'
        local command `"`command' `i'5/`i'9  = "`i'0c","'
    }
    local command `"`command' _ = "d")"'
    local command `"`command' `nocheck'"'
    
    // Run pmatch command
    `command'
    
    assert y_base == y
end

program compare_int
    syntax, OBS(integer) LEVELS(integer) [NOCHECK]

    compare_num, type("int") obs(`obs') levels(`levels') `nocheck'
end

program compare_float
    syntax, OBS(integer) LEVELS(integer) [NOCHECK]

    compare_num, type("float") obs(`obs') levels(`levels') `nocheck'
end

program compare_str
    syntax, OBS(integer) LEVELS(integer) [NOCHECK]
    
    local n = (`levels' / 10)
    
    // Prepare data
    clear
    set obs `obs'
    gen x = string(mod(_n, `levels') + 1)
    bsample
    
    // Run base commands
    mata: bench_on("base")
    gen y_base = "c"
    forvalues i = 0/`n' {
        replace y_base = "`i'0a" if x == "`i'1"
        replace y_base = "`i'0b" if x == "`i'2" | x == "`i'3" | x == "`i'4"
    }
    mata: bench_off("base")
    
    // Build pmatch command
    local command `"pmatch y, v(x) b("'
    forvalues i = 0/`n' {
        local command `"`command' "`i'1" = "`i'0a","'
        local command `"`command' "`i'2" | "`i'3" | "`i'4" = "`i'0b","'
    }
    local command `"`command' _ = "c")"'
    local command `"`command' `nocheck'"'
    
    // Run pmatch command
    `command'
    
    assert y_base == y
end

program profile_obs_integer
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        compare_int, obs(`obs') levels(`levels') `nocheck'
    }

    mata: bench_print(BENCH)
end

program profile_obs_float
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        compare_float, obs(`obs') levels(`levels') `nocheck'
    }

    mata: bench_print(BENCH)
end

program profile_obs_string
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly forvalues i = 1/`rep' {
        compare_str, obs(`obs') levels(`levels') `nocheck'
    }

    mata: bench_print(BENCH)
end

capture log close
log using "dev/logs/bench_e2e.log", replace

///////////////////////////////////////////////////////// Benchmarks with checks

// 10 levels

profile_obs_integer, obs(1000)     levels(10) rep(1000)
profile_obs_integer, obs(10000)    levels(10) rep(1000)
profile_obs_integer, obs(100000)   levels(10) rep(100)
profile_obs_integer, obs(1000000)  levels(10) rep(10)
profile_obs_integer, obs(10000000) levels(10) rep(1)

profile_obs_float,   obs(1000)     levels(10) rep(1000)
profile_obs_float,   obs(10000)    levels(10) rep(1000)
profile_obs_float,   obs(100000)   levels(10) rep(100)
profile_obs_float,   obs(1000000)  levels(10) rep(10)
profile_obs_float,   obs(10000000) levels(10) rep(1)

profile_obs_string,  obs(1000)     levels(10) rep(1000)
profile_obs_string,  obs(10000)    levels(10) rep(1000)
profile_obs_string,  obs(100000)   levels(10) rep(100)
profile_obs_string,  obs(1000000)  levels(10) rep(10)
profile_obs_string,  obs(10000000) levels(10) rep(1)

// 100 levels

profile_obs_integer, obs(1000)     levels(100) rep(100)
profile_obs_integer, obs(10000)    levels(100) rep(100)
profile_obs_integer, obs(100000)   levels(100) rep(10)
profile_obs_integer, obs(1000000)  levels(100) rep(1)
profile_obs_integer, obs(10000000) levels(100) rep(1)

profile_obs_float,   obs(1000)     levels(100) rep(100)
profile_obs_float,   obs(10000)    levels(100) rep(100)
profile_obs_float,   obs(100000)   levels(100) rep(10)
profile_obs_float,   obs(1000000)  levels(100) rep(1)
profile_obs_float,   obs(10000000) levels(100) rep(1)

profile_obs_string,  obs(1000)     levels(100) rep(100)
profile_obs_string,  obs(10000)    levels(100) rep(100)
profile_obs_string,  obs(100000)   levels(100) rep(10)
profile_obs_string,  obs(1000000)  levels(100) rep(1)
profile_obs_string,  obs(10000000) levels(100) rep(1)

// 1000 levels


profile_obs_integer, obs(1000)     levels(1000) rep(10)
profile_obs_integer, obs(10000)    levels(1000) rep(10)
profile_obs_integer, obs(100000)   levels(1000) rep(1)
profile_obs_integer, obs(1000000)  levels(1000) rep(1)
profile_obs_integer, obs(10000000) levels(1000) rep(1)

profile_obs_float,   obs(1000)     levels(1000) rep(10)
profile_obs_float,   obs(10000)    levels(1000) rep(10)
profile_obs_float,   obs(100000)   levels(1000) rep(1)
profile_obs_float,   obs(1000000)  levels(1000) rep(1)
profile_obs_float,   obs(10000000) levels(1000) rep(1)

profile_obs_string,  obs(1000)     levels(1000) rep(10)
profile_obs_string,  obs(10000)    levels(1000) rep(10)
profile_obs_string,  obs(100000)   levels(1000) rep(1)
profile_obs_string,  obs(1000000)  levels(1000) rep(1)
profile_obs_string,  obs(10000000) levels(1000) rep(1)


////////////////////////////////////////////////////// Benchmarks without checks

profile_obs_integer, obs(1000)     levels(10) rep(1000) nocheck
profile_obs_integer, obs(10000)    levels(10) rep(1000) nocheck
profile_obs_integer, obs(100000)   levels(10) rep(100)  nocheck
profile_obs_integer, obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_integer, obs(10000000) levels(10) rep(1)   nocheck

profile_obs_float,   obs(1000)     levels(10) rep(1000) nocheck
profile_obs_float,   obs(10000)    levels(10) rep(1000) nocheck
profile_obs_float,   obs(100000)   levels(10) rep(100)  nocheck
profile_obs_float,   obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_float,   obs(10000000) levels(10) rep(1)   nocheck
 
profile_obs_string,  obs(1000)     levels(10) rep(1000) nocheck
profile_obs_string,  obs(10000)    levels(10) rep(1000) nocheck
profile_obs_string,  obs(100000)   levels(10) rep(100)  nocheck
profile_obs_string,  obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_string,  obs(10000000) levels(10) rep(1)   nocheck

log close
