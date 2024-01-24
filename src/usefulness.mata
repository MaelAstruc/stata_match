mata

void Usefulness::define(class Usefulness usefulness) {
    this.useful = usefulness.useful
    this.any_overlap = usefulness.any_overlap
    this.tuple = usefulness.tuple
    this.arm_id = usefulness.arm_id
    this.overlaps = usefulness.overlaps
    this.differences = usefulness.differences
}

string vector Usefulness::to_string() {
    string vector str
    class Pattern scalar overlap
    struct LHS scalar lhs
    real scalar i

    if (this.useful == 0) {
        str = sprintf("Warning : Arm %f is not useful", this.arm_id)
    }

    if (this.any_overlap == 1) {
        str = str, sprintf("Warning : Arm %f has overlaps", this.arm_id)
        for (i = 1; i <= length(*this.overlaps); i++) {
            lhs = (*this.overlaps)[i]
            overlap = *lhs.pattern
            if (classname(overlap) != "PEmpty") {
                str = str,
                    sprintf("\tArm %f: %s", lhs.arm_id, overlap.to_string())
            }
        }
    }
    return(str)
}

void Usefulness::print() {
    string vector str
    real scalar i

    str = this.to_string()

    if (length(str) == 0) {
        return
    }

    for (i = 1; i <= length(str); i++) {
        printf("%s\n", str[i])
    }
}
end
