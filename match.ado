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
program match
    syntax varlist, Variables(str) Body(str asis)

    tokenize `varlist'

    if ("`2'" != "") {
        exit(error(103))
    }

    local newvar "`1'"

    mata: match(`"`body'"', "`newvar'", "`variables'")
end

mata
function match(string scalar str, string scalar newvar, string scalar vars_exp) {
    class Arm vector arms, useful_arms
    class Variable vector variables
    pointer scalar t
    real scalar i, n_vars
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
	
    eval_arms(newvar, useful_arms, variables)
}
end
