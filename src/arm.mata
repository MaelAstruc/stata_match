mata

void Arm::new() {}

string scalar Arm::to_string() {
    return(
        sprintf(
            "Arm %f: Tuple: %s / Value: %s",
            this.id, ::to_string(*this.lhs.pattern), this.value
        )
    )
}

void Arm::print() {
    displayas("text")
    printf("%s", this.to_string())
}

void function eval_arms(
    `STRING' varname,
    `ARMS' arms,
    `VARIABLES' variables,
    `REAL' gen_first,
    `STRING' dtype
) {
    `ARM' arm
    `POINTER' pattern
    `STRING' command, condition, statement
    `REAL' i, n, _rc

    n = length(arms)
    
    displayas("text")
    for (i = n; i >= 1; i--) {
        arm = arms[i]
        pattern = arm.lhs.pattern
        
        if (i == n & gen_first) {
            if (dtype != "") {
                command = "generate " + dtype
            }
            else {
                command = "generate"
            }
        }
        else {
            command = "replace"
        }
        
        if (length(variables) == 1) {
            condition = to_expr(*pattern, variables[1])
        }
        else {
            condition = to_expr(*pattern, variables)
        }
        
        if (condition == "1") {
            statement = sprintf(`"%s %s = %s"', command, varname, arm.value)
        }
        else {
            statement = sprintf(`"%s %s = %s if %s"', command, varname, arm.value, condition)
        }

        _rc = _stata(statement, 1)
        
        if (_rc) {
            errprintf("Stata encountered an error when evaluating arm %f\n", i)
            exit(error(_rc))
        }
    }
}

end
