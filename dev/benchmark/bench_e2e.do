/*
Benchmark the match function and compare to performance of base commands
*/

clear all

run "dev/dev_utils.do"
run "dev/benchmark/bench_utils.mata"
run "pkg/pmatch.ado"
mata: combine_files("src/pmatch.mata", "dev/benchmark/pmatch_bench.ado", "`version'", 1)
mata: mata drop pmatch()
do "dev/benchmark/pmatch_bench.ado"

// Check the time needed  with different number of observations

program profile_obs_integer
    syntax, OBS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        clear
        set obs `obs'
        
        gen int x = runiform(0, 15) + 1 // [1, 15]
        
        mata: bench_on("base")
        gen y_base = "d"
        replace y_base = "a" if x == 1
        replace y_base = "b" if x == 2 | x == 3 | x == 4
        replace y_base = "c" if x >= 5 & x <= 9
        mata: bench_off("base")

        pmatch y, v(x) b(    ///
            1         => "a",  ///
            2 | 3 | 4 => "b",  ///
            5~9       => "c",  ///
            _         => "d"   ///
        ) `nocheck'
        
        assert y_base == y
    }

    mata: bench_print(BENCH)
end

program profile_obs_float
    syntax, OBS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        clear
        set obs `obs'
        
        gen float x = floor(runiform(0, 15) + 1) // [1, 15]
        
        mata: bench_on("base")
        gen y_base = "d"
        replace y_base = "a" if x == 1
        replace y_base = "b" if x == 2 | x == 3 | x == 4
        replace y_base = "c" if x >= 5 & x <= 9
        mata: bench_off("base")

        pmatch y, v(x) b(    ///
            1         => "a",  ///
            2 | 3 | 4 => "b",  ///
            5~9       => "c",  ///
            _         => "d"   ///
        ) `nocheck'
        
        assert y_base == y
    }

    mata: bench_print(BENCH)
end

program profile_obs_string
    syntax, OBS(integer) REP(integer) [NOCHECK]
    
    mata: BENCH = bench_init(`rep')
    
    quietly forvalues i = 1/`rep' {
        clear
        set obs `obs'
        
        // Only to 10 because there is no range here
        gen str x = string(floor(runiform(0, 10) + 1)) // [1, 10]
        
        mata: bench_on("base")
        gen y_base = "c"
        replace y_base = "a" if x == "1"
        replace y_base = "b" if x == "2" | x == "3" | x == "4"
        mata: bench_off("base")

        pmatch y, v(x) b(    ///
            "1"             => "a",  ///
            "2" | "3" | "4" => "b",  ///
            _               => "c"   ///
        ) `nocheck'
        
        assert y_base == y
    }

    mata: bench_print(BENCH)
end

capture log close
log using "dev/logs/bench_e2e.log", replace

dis "`c(current_date)'"
dis "`c(current_time)'"

///////////////////////////////////////////////////////// Benchmarks with checks

profile_obs_integer, obs(1000)     rep(1000)
profile_obs_integer, obs(10000)    rep(1000)
profile_obs_integer, obs(100000)   rep(100)
profile_obs_integer, obs(1000000)  rep(10)
profile_obs_integer, obs(10000000) rep(1)

profile_obs_float,   obs(1000)     rep(1000)
profile_obs_float,   obs(10000)    rep(1000)
profile_obs_float,   obs(100000)   rep(100)
profile_obs_float,   obs(1000000)  rep(10)
profile_obs_float,   obs(10000000) rep(1)

profile_obs_string,  obs(1000)     rep(1000)
profile_obs_string,  obs(10000)    rep(1000)
profile_obs_string,  obs(100000)   rep(100)
profile_obs_string,  obs(1000000)  rep(10)
profile_obs_string,  obs(10000000) rep(1)

////////////////////////////////////////////////////// Benchmarks without checks

profile_obs_integer, obs(1000)     rep(1000) nocheck
profile_obs_integer, obs(10000)    rep(1000) nocheck
profile_obs_integer, obs(100000)   rep(100)  nocheck
profile_obs_integer, obs(1000000)  rep(10)   nocheck
profile_obs_integer, obs(10000000) rep(1)   nocheck

profile_obs_float,   obs(1000)     rep(1000) nocheck
profile_obs_float,   obs(10000)    rep(1000) nocheck
profile_obs_float,   obs(100000)   rep(100)  nocheck
profile_obs_float,   obs(1000000)  rep(10)   nocheck
profile_obs_float,   obs(10000000) rep(1)   nocheck
 
profile_obs_string,  obs(1000)     rep(1000) nocheck
profile_obs_string,  obs(10000)    rep(1000) nocheck
profile_obs_string,  obs(100000)   rep(100)  nocheck
profile_obs_string,  obs(1000000)  rep(10)   nocheck
profile_obs_string,  obs(10000000) rep(1)   nocheck

log close
