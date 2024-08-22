mata

void Arm::new() {}

string scalar Arm::to_string() {
    class Pattern scalar pattern

    pattern = *this.lhs.pattern
    return(
        sprintf(
            "Arm %f: Tuple: %s / Value: %s",
            this.id, pattern.to_string(), this.value
        )
    )
}

void Arm::print() {
    displayas("text")
    printf("%s", this.to_string())
}

void function eval_arms(
    string scalar varname,
    class Arm vector arms,
    class Variable vector variables
) {
    class Arm scalar arm
    class Pattern scalar pattern
    string scalar command, condition, statement
    real scalar i, n

    n = length(arms)
    
    displayas("text")
    for (i = n; i >= 1; i--) {
        arm = arms[i]
        pattern = *arm.lhs.pattern
        
        if (i == n & _st_varindex(varname) == .) {
            command = "generate"
        }
        else {
            command = "replace"
        }
        
        if (length(variables) == 1) {
            condition = pattern.to_expr(variables[1].name)
        }
        else {
            condition = pattern.to_expr(variables)
        }
        
        if (condition == "1") {
            statement = sprintf(`"%s %s = %s"', command, varname, arm.value)
        }
        else {
            statement = sprintf(`"%s %s = %s if %s"', command, varname, arm.value, condition)
        }

        stata(statement, 1)
    }
}

end
