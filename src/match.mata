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

    t = tokeninit()
    tokenwchars(t, ",")
    tokenset(t, vars_exp)
    vars_str = strtrim(tokengetall(t))

    n_vars = length(vars_str)

    variables = Variable(n_vars)

    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i])
    }

    arms = parse_string(str, variables)

    useful_arms = check_match(arms, variables)

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
        stata(command)
    }

}

end
