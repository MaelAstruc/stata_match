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
