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
	class Arm vector useful_arms,
	class Variable vector variables
) {
    class Arm scalar arm
    class Pattern scalar pattern
	string scalar command
	real scalar i
	
	
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
}

end
