// Main do-file used to combine the other ones stored in the 'src' directory.

run "src/declare.mata"
run "src/pattern_list.mata"
run "src/pattern.mata"
run "src/variable.mata"
run "src/tuple.mata"
run "src/arm.mata"
run "src/parser.mata"
run "src/usefulness.mata"
run "src/match_report.mata"
run "src/algorithm.mata"

capture program drop match
program pmatch
    syntax namelist(min=1 max=1), Variables(varlist min=1) Body(str asis)

    mata: pmatch("`namelist'", "`variables'", `"`body'"')
end

mata
function pmatch(string scalar newvar, string scalar vars_exp, string scalar body) {
    class Arm vector arms, useful_arms
    class Variable vector variables
    pointer scalar t
    real scalar i, n_vars
    string vector vars_str

    t = tokeninit()
    tokenset(t, vars_exp)
    vars_str = tokengetall(t)
    
    n_vars = length(vars_str)

    variables = Variable(n_vars)

    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i])
    }
    
    arms = parse_string(body, variables)
    
    useful_arms = check_match(arms, variables)
    
    eval_arms(newvar, arms, variables)
}
end

