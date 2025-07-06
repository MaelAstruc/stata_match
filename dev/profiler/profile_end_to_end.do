**#****************************************************************************

clear all

run "dev/main_utils.do"
run "dev/profiler/pmatch_profiler.ado"

capture log close
log using "dev/logs/profile.log", replace

// Profile 100 000 integers with 1000 levels

mata: PROFILER = new_profiler()
mata: calibrate_profiler(PROFILER)

bench_obs_integer, obs(100000)     levels(1000) rep(1) nobench

dis "`c(current_time)'"

mata: profiler_print(PROFILER, 10)

dis "`c(current_time)'"

mata: profiler_summarize(PROFILER)

dis "`c(current_time)'"

mata: profiler_graph(PROFILER, 10)
graph export "dev/logs/profile.png", replace

// Profile 100 000 floats with 1000 levels

mata: PROFILER = new_profiler()
mata: calibrate_profiler(PROFILER)
bench_obs_float,   obs(10000000) levels(1000) rep(1) nobench
mata: profiler_print(PROFILER, 10)
mata: profiler_summarize(PROFILER)
mata: profiler_graph(PROFILER, 1)

// Profile 100 000 strings with 1000 levels

mata: PROFILER = new_profiler()
mata: calibrate_profiler(PROFILER)
bench_obs_string,  obs(1000000)  levels(1000) rep(1) nobench
mata: profiler_print(PROFILER, 10)
mata: profiler_summarize(PROFILER)
mata: profiler_graph(PROFILER, 1)


graph export "dev/logs/profile.png", replace

log close