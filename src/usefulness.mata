mata

void Usefulness::new() {}

void Usefulness::define(class Usefulness usefulness) {
    this.useful = usefulness.useful
    this.has_wildcard = usefulness.has_wildcard
    this.any_overlap = usefulness.any_overlap
    this.arm_id = usefulness.arm_id
    this.overlaps = usefulness.overlaps
    this.differences = usefulness.differences
}

string vector Usefulness::to_string() {
    string vector str
    pointer scalar overlap
    struct LHS scalar lhs
    real scalar i
    
    if (this.useful == 0) {
        str = sprintf("Warning : Arm %f is not useful", this.arm_id)
    }
    
    if (this.has_wildcard == 1) {
        // Don't print overlaps if the arm includes wildcards
        return(str)
    }
    
    if (this.any_overlap == 1) {
        str = str, sprintf("Warning : Arm %f has overlaps", this.arm_id)
        
        for (i = 1; i <= length(*this.overlaps); i++) {
            lhs = (*this.overlaps)[i]
            overlap = lhs.pattern
            
            str = str, sprintf("    Arm %f: %s", lhs.arm_id, ::to_string(*overlap))
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
