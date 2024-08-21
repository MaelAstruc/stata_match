// Some utils functions for the benchmarks

mata
BENCH_NAMES = ("base", "init", "parse", "check", "eval", "total")

// A copy of the pmatch function with bench functions
mata drop pmatch()
function pmatch(string scalar newvar, string scalar vars_exp, string scalar body, real scalar check) {
    class Arm vector arms, useful_arms
    class Variable vector variables
    pointer scalar t
    real scalar i, n_vars
    string vector vars_str

    bench_on("total")
    
    t = tokeninit()
    tokenwchars(t, ",")
    tokenset(t, vars_exp)
    vars_str = strtrim(tokengetall(t))

    bench_on("init")
    n_vars = length(vars_str)

    variables = Variable(n_vars)

    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i], check)
    }
    bench_off("init")
    
    bench_on("parse")
    arms = parse_string(body, variables)
    bench_off("parse")
    
    bench_on("check")
    if (check) {
        useful_arms = check_match(arms, variables)
    }
    bench_off("check")
    
    bench_on("eval")
    eval_arms(newvar, arms, variables)
    bench_off("eval")

    bench_off("total")
}
end

mata
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
    
    val_total = sum(values)
    val_N = length(values)
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
        results[i, n_stats - 1]     = results[i, 4] / results[1, 4] * 100
    }
    
    results[K, n_stats] = results[K, 4] - results[1, 4]
    
    printf("{txt}{hline}\n")
    printf("{txt}profiler report\n")
    printf(
        "{txt}  %10s   %12s %8s %8s %8s %8s %8s %8s %8s %8s %8s\n",
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
            "{txt}  %10s   %12.3f %8.0f %8.3f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.3f\n",
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
    
    printf("{txt}{hline}\n")
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
