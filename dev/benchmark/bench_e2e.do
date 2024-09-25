/*
Benchmark the match function and compare to performance of base commands
*/

clear all

run "dev/main_utils.do"
run "dev/benchmark/pmatch_bench.ado"

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

profile_obs_integer, obs(1000)     levels(1000) rep(1)
profile_obs_integer, obs(10000)    levels(1000) rep(1)
profile_obs_integer, obs(100000)   levels(1000) rep(1)
profile_obs_integer, obs(1000000)  levels(1000) rep(1)
profile_obs_integer, obs(10000000) levels(1000) rep(1)

profile_obs_float,   obs(1000)     levels(1000) rep(1)
profile_obs_float,   obs(10000)    levels(1000) rep(1)
profile_obs_float,   obs(100000)   levels(1000) rep(1)
profile_obs_float,   obs(1000000)  levels(1000) rep(1)
profile_obs_float,   obs(10000000) levels(1000) rep(1)

profile_obs_string,  obs(1000)     levels(1000) rep(1)
profile_obs_string,  obs(10000)    levels(1000) rep(1)
profile_obs_string,  obs(100000)   levels(1000) rep(1)
profile_obs_string,  obs(1000000)  levels(1000) rep(1)
profile_obs_string,  obs(10000000) levels(1000) rep(1)


////////////////////////////////////////////////////// Benchmarks without checks

profile_obs_integer, obs(1000)     levels(10) rep(1000) nocheck
profile_obs_integer, obs(10000)    levels(10) rep(1000) nocheck
profile_obs_integer, obs(100000)   levels(10) rep(100)  nocheck
profile_obs_integer, obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_integer, obs(10000000) levels(10) rep(1)    nocheck

profile_obs_float,   obs(1000)     levels(10) rep(1000) nocheck
profile_obs_float,   obs(10000)    levels(10) rep(1000) nocheck
profile_obs_float,   obs(100000)   levels(10) rep(100)  nocheck
profile_obs_float,   obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_float,   obs(10000000) levels(10) rep(1)    nocheck
 
profile_obs_string,  obs(1000)     levels(10) rep(1000) nocheck
profile_obs_string,  obs(10000)    levels(10) rep(1000) nocheck
profile_obs_string,  obs(100000)   levels(10) rep(100)  nocheck
profile_obs_string,  obs(1000000)  levels(10) rep(10)   nocheck
profile_obs_string,  obs(10000000) levels(10) rep(1)    nocheck

log close
