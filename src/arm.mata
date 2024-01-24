mata

string scalar Arm::to_string() {
    class Pattern scalar pattern

    pattern = *this.lhs.pattern
    return(
        sprintf(
            "Arm %f: Tuple: %s  /  Value: %s\n",
            this.id, pattern.to_string(), this.value
        )
    )
}

void Arm::print() {
    displayas("text")
    printf("%s", this.to_string())
}

end
