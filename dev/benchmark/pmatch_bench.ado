*! version   20 Sep 2024

**#************************************************************* src/pmatch.mata

// Main function for the `pmatch` command
// The bench_on() and // bench_off() functions are not used in the online code)

mata
function pmatch(
    string scalar newvar,
    string scalar vars_exp,
    string scalar body,
    real   scalar check,
    real   scalar gen_first,
    string scalar dtype
) {
    class Variable vector variables
    class Arm vector arms, useful_arms

    bench_on("total")
    
    bench_on("init")
    variables = init_variables(vars_exp, check)
    bench_off("init")
    
    bench_on("parse")
    arms = parse_string(body, variables)
    bench_off("parse")
    
    bench_on("check")
    if (check) {
        check_match(arms, variables)
    }
    bench_off("check")
    
    bench_on("eval")
    eval_arms(newvar, arms, variables, gen_first, dtype)
    bench_off("eval")

    bench_off("total")
}
end

