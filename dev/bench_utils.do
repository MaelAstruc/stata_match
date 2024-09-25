// Some utils functions for the benchmarks

**#****************************************************** Extand timer functions

capture mata: mata drop bench_init() bench_summary() bench_print() bench_on() bench_off()

mata
BENCH_NAMES = (
    "base",
    "init",
    "parse",
    "check",
    "- usefulness",
    "- combine",
    "- exhaustiveness",
    "- compress",
    "- print",
    "eval",
    "total"
)

struct Bench {
    real matrix results
    string vector names
    transmorphic names_index
    real scalar iter
}

struct Bench scalar function bench_init(real scalar N) {
    struct Bench scalar bench
    real scalar k, K
    string vector names
    
    names = *findexternal("BENCH_NAMES")
    
    K = length(names)
    
    bench = Bench()
    bench.results = J(N, K, .)
    bench.names = names
    bench.names_index = asarray_create()
    bench.iter = 0
    
    for (k = 1; k <= K; k++) {
        asarray(bench.names_index, bench.names[k], k)
    }
    
    return(bench)
}

real vector bench_summary(real vector values) {
    real scalar val_total, val_N, val_min, val_mean, val_median, val_max, val_sd
    
    values = sort(values, 1)
    
    if (values[1] == .) {
    	return(J(1, 7, .))
    }
    
    val_total = sum(values)
    val_N = nonmissing(values)
    val_min = values[1]
    val_mean = mean(values)
    val_median = values[ceil(val_N / 2)]
    val_max = values[val_N]
    val_sd = sqrt(variance(values))
    
    return((val_total, val_N, val_min, val_mean, val_median, val_max, val_sd))
}

void function bench_print(struct Bench scalar bench) {
    real scalar K, n_stats, i, index
    real matrix results 
    
    K = length(bench.names)
    n_stats = 10
    
    results = J(K, n_stats, .)
    
    for (i = 1; i <= K; i++) {
        index = asarray(bench.names_index, bench.names[i])
        results[i, 1..7] = bench_summary(bench.results[., index])
    }
    
    for (i = 1; i <= K; i++) {
        results[i, n_stats - 2] = results[i, 4] / results[K, 4] * 100
        results[i, n_stats - 1] = results[i, 4] / results[1, 4] * 100
    }
    
    results[K, n_stats] = results[K, 4] - results[1, 4]
    
    printf("{txt}{hline 115}\n")
    printf("{txt}profiler report\n")
    printf(
        "{txt}%-15s     %12s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n",
        "Name",
        "Total",
        "N",
        "min",
        "mean",
        "median",
        "max",
        "sd",
        "%total",
        "%base",
        "diff"
    )
    
    for (i = 1; i <= K; i++) {
        printf(
            "{txt}  %-17s %12.3f %8.0f %8.3f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.3f\n",
            bench.names[i],
            results[i, 1],
            results[i, 2],
            results[i, 3],
            results[i, 4],
            results[i, 5],
            results[i, 6],
            results[i, 7],
            results[i, 8],
            results[i, 9],
            results[i, 10]
        )
    }
    
    printf("{txt}{hline 115}\n")
}

void function bench_on(string scalar name) {
    pointer(struct Bench) scalar bench
    real scalar index
    
    bench = findexternal("BENCH")
    
    index = asarray(bench->names_index, name)
    
    if (name == "base") {
        bench->iter = bench->iter + 1
        timer_clear()
    }
    
    timer_on(index)
}

void function bench_off(string scalar name) {
    pointer(struct Bench) scalar bench
    real scalar index
    
    bench = findexternal("BENCH")
    index = asarray(bench->names_index, name)
    
    timer_off(index)
    
    bench->results[bench->iter, index] = timer_value(index)[1]
}
end

**#******************************************************** Automate comparisons

capture program drop compare_num compare_int compare_float compare_str

// Check the time needed  with different number of observations
program compare_num
    syntax, TYPE(string) OBS(integer) LEVELS(integer) [NOCHECK NOBENCH]
    
    local n = (`levels' / 10)
    
    // Prepare data
    clear
    set obs `obs'
    gen `type' x = mod(_n, `levels') + 1
    bsample
    
    // Run base commands
    if ("`nobench'" == "") mata: bench_on("base")
    gen y_base = "d"
    forvalues i = 0/`n' {
        replace y_base = "`i'0a" if x == `i'1
        replace y_base = "`i'0b" if x == `i'2 | x == `i'3 | x == `i'4
        replace y_base = "`i'0c" if x >= `i'5 & x <= `i'9
    }
    if ("`nobench'" == "") mata: bench_off("base")
    
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
    syntax, OBS(integer) LEVELS(integer) [NOCHECK NOBENCH]

    compare_num, type("int") obs(`obs') levels(`levels') `nocheck' `nobench'
end

program compare_float
    syntax, OBS(integer) LEVELS(integer) [NOCHECK NOBENCH]

    compare_num, type("float") obs(`obs') levels(`levels') `nocheck' `nobench'
end

program compare_str
    syntax, OBS(integer) LEVELS(integer) [NOCHECK NOBENCH]
    
    local n = (`levels' / 10)
    
    // Prepare data
    clear
    set obs `obs'
    gen x = string(mod(_n, `levels') + 1)
    bsample
    
    // Run base commands
    if ("`nobench'" == "") mata: bench_on("base")
    gen y_base = "c"
    forvalues i = 0/`n' {
        replace y_base = "`i'0a" if x == "`i'1"
        replace y_base = "`i'0b" if x == "`i'2" | x == "`i'3" | x == "`i'4"
    }
    if ("`nobench'" == "") mata: bench_off("base")
    
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

**#********************************************************** Automate profiling

capture program drop profile_obs_integer profile_obs_float profile_obs_string

program profile_obs_integer
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK NOBENCH]
    
    if ("`nobench'" == "") mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        compare_int, obs(`obs') levels(`levels') `nocheck' `nobench'
    }

    if ("`nobench'" == "") mata: bench_print(BENCH)
end

program profile_obs_float
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK]
    
    if ("`nobench'" == "") mata: BENCH = bench_init(`rep')
    
    quietly: forvalues i = 1/`rep' {
        compare_float, obs(`obs') levels(`levels') `nocheck' `nobench'
    }

    if ("`nobench'" == "") mata: bench_print(BENCH)
end

program profile_obs_string
    syntax, OBS(integer) LEVELS(integer) REP(integer) [NOCHECK]
    
    if ("`nobench'" == "") mata: BENCH = bench_init(`rep')
    
    quietly forvalues i = 1/`rep' {
        compare_str, obs(`obs') levels(`levels') `nocheck' `nobench'
    }

    if ("`nobench'" == "") mata: bench_print(BENCH)
end
