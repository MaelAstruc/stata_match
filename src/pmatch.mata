// Main function for the `pmatch` command
// The // bench_on() and // bench_off() functions are not used in the online code)

mata
void pmatch(
    `STRING' newvar,
    `STRING' vars_exp,
    `STRING' body,
    `REAL'   check,
    `REAL'   gen_first,
    `STRING' dtype
) {
    `VARIABLES' variables
    `ARMS' arms, useful_arms

    // profiler_on("pmatch")
    
    // bench_on("total")
    
    // bench_on("init")
    variables = init_variables(vars_exp, check)
    // bench_off("init")
    
    // bench_on("parse")
    arms = parse_string(body, variables, check)
    // bench_off("parse")
    
    // bench_on("check")
    if (check) {
        check_match(arms, variables)
    }
    // bench_off("check")
    
    // bench_on("eval")
    eval_arms(newvar, arms, variables, gen_first, dtype)
    // bench_off("eval")

    // bench_off("total")
    
    // profiler_off()
}
end
