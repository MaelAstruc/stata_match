**#****************************************************************************

clear all

run "dev/main_utils.do"
run "dev/profiler/pmatch_profiler.ado"

capture log close
log using "dev/logs/profile.log", replace

mata: PROFILER = new_profiler()

bench_obs_integer, obs(100000)     levels(500) rep(1) nobench

dis "`c(current_time)'"

mata: profiler_print(PROFILER, 10)

dis "`c(current_time)'"

mata: profiler_summarize(PROFILER)

dis "`c(current_time)'"

mata: profiler_graph(PROFILER, 10)
graph export "dev/logs/profile.png", replace

log close