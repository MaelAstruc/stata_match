mata

function match(string scalar str, string scalar newvar, string scalar vars_exp) {
    class Arm scalar arm
    class Arm vector arms, useful_arms
    class Variable vector variables
    class Pattern scalar pattern
    pointer scalar t
    real scalar i, n_vars
    string scalar command
    string vector vars_str

    // bench_on("total")
    
    t = tokeninit()
    tokenwchars(t, ",")
    tokenset(t, vars_exp)
    vars_str = strtrim(tokengetall(t))

    
    // bench_on("init")
    n_vars = length(vars_str)

    variables = Variable(n_vars)

    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i])
    }
    // bench_off("init")
    
    // bench_on("parse")
    arms = parse_string(str, variables)
    // bench_off("parse")
    
    // bench_on("check")
    useful_arms = check_match(arms, variables)
    // bench_off("check")
    
    // bench_on("eval")
    displayas("text")
    for (i = 1; i <= length(useful_arms); i++) {
        arm = useful_arms[i]
        pattern = *arm.lhs.pattern

        if (length(variables) == 1) {
            command = sprintf(
                `"replace %s = %s if %s"',
                newvar, arm.value, pattern.to_expr(variables[1].name)
            )
        }
        else {
            command = sprintf(
                `"replace %s = %s if %s"',
                newvar, arm.value, pattern.to_expr(variables)
            )
        }

        printf("%s\n", command)
        stata(command, 1)
    }
    // bench_off("eval")

    // bench_off("total")
}

end
