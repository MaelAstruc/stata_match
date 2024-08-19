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
    string scalar newvar,
    class Arm vector arms,
    class Variable vector variables
) {
    class Arm scalar arm
    class Pattern scalar pattern
    string scalar condition, command
    real scalar i
    
    displayas("text")
    for (i = length(arms); i >= 1; i--) {
        arm = arms[i]
        pattern = *arm.lhs.pattern
        
        if (length(variables) == 1) {
            condition = pattern.to_expr(variables[1].name)
        }
        else {
            condition = pattern.to_expr(variables)
        }
        
        if (condition == "1") {
            command = sprintf(`"replace %s = %s"', newvar, arm.value)
        }
        else {
            command = sprintf(`"replace %s = %s if %s"', newvar, arm.value, condition)
        }

        printf("%s\n", command)
        stata(command, 1)
    }
}

end
