mata

//////////////////////////////////////////////////////////////////// to_string()

`STRING' to_string(`T' pattern) {
    if (eltype(pattern) == "real") {
        if (pattern[1, 1] == `EMPTY_TYPE') {
            return(to_string_pempty(pattern))
        }
        else if (pattern[1, 1] == `WILD_TYPE') {
            return(to_string_pwild(pattern))
        }
        else if (pattern[1, 1] == `CONSTANT_TYPE') {
            return(to_string_pconstant(pattern))
        }
        else if (pattern[1, 1] == `RANGE_TYPE') {
            return(to_string_prange(pattern))
        }
        else if (pattern[1, 1] == `OR_TYPE') {
            return(to_string_por(pattern))
        }
    }
    else if (eltype(pattern) == "struct") {
        if (structname(pattern) == "Tuple") {
            return(to_string_tuple(pattern))
        }
        else if (structname(pattern) == "TupleOr") {
            return(to_string_tupleor(pattern))
        }
        else if (structname(pattern) == "TupleEmpty") {
            return("Empty")
        }
    }
    
    unknown_pattern(pattern)
}

//////////////////////////////////////////////////////////////////////// print()

void print(`PATTERN' pattern) {
    to_string(pattern)
}

////////////////////////////////////////////////////////////////////// to_expr()

`STRING' to_expr(`T' pattern, `VARIABLES' variable) {
    if (eltype(pattern) == "real") {
        if (pattern[1, 1] == `EMPTY_TYPE') {
            return(to_expr_pempty(pattern, variable))
        }
        else if (pattern[1, 1] == `WILD_TYPE') {
            return(to_expr_pwild(pattern, variable))
        }
        else if (pattern[1, 1] == `CONSTANT_TYPE') {
            return(to_expr_pconstant(pattern, variable))
        }
        else if (pattern[1, 1] == `RANGE_TYPE') {
            return(to_expr_prange(pattern, variable))
        }
        else if (pattern[1, 1] == `OR_TYPE') {
            return(to_expr_por(pattern, variable))
        }
    }
    else if (eltype(pattern) == "struct") {
        if (structname(pattern) == "Tuple") {
            return(to_expr_tuple(pattern, variable))
        }
        else if (structname(pattern) == "TupleOr") {
            return(to_expr_tupleor(pattern, variable))
        }
        else if (structname(pattern) == "TupleEmpty") {
            return("")
        }
    }
    unknown_pattern(pattern)
}

///////////////////////////////////////////////////////////////////// compress()

`T' compress(`T' pattern) {
    if (eltype(pattern) == "real") {
        if (pattern[1, 1] == `EMPTY_TYPE') {
            return(compress_pempty(pattern))
        }
        else if (pattern[1, 1] == `WILD_TYPE') {
            return(compress_pwild(pattern))
        }
        else if (pattern[1, 1] == `CONSTANT_TYPE') {
            return(compress_pconstant(pattern))
        }
        else if (pattern[1, 1] == `RANGE_TYPE') {
            return(compress_prange(pattern))
        }
        else if (pattern[1, 1] == `OR_TYPE') {
            return(compress_por(pattern))
        }
    }
    else if (eltype(pattern) == "struct") {
        if (structname(pattern) == "Tuple") {
            return(compress_tuple(pattern))
        }
        else if (structname(pattern) == "TupleOr") {
            return(compress_tupleor(pattern))
        }
        else if (structname(pattern) == "TupleEmpty") {
            return(pattern)
        }
    }
    unknown_pattern(pattern)
}

////////////////////////////////////////////////////////////////////// overlap()

`T' overlap(`T' pattern_1, `T' pattern_2) {
    if (eltype(pattern_1) == "real") {
        if (pattern_1[1, 1] == `EMPTY_TYPE') {
            return(overlap_pempty(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `WILD_TYPE') {
            return(overlap_pwild(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `CONSTANT_TYPE') {
            return(overlap_pconstant(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `RANGE_TYPE') {
            return(overlap_prange(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `OR_TYPE') {
            return(overlap_por(pattern_1, pattern_2))
        }
    }
    else if (eltype(pattern_1) == "struct") {
        if (structname(pattern_1) == "Tuple") {
            return(overlap_tuple(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleOr") {
            return(overlap_tupleor(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleEmpty") {
            return(pattern_1)
        }
    }
    else {
        unknown_pattern(pattern_1)
    }
}

///////////////////////////////////////////////////////////////////// includes()

`REAL' includes(`PATTERN' pattern_1, `PATTERN' pattern_2) {
    if (eltype(pattern_1) == "real") {
        if (pattern_1[1, 1] == `EMPTY_TYPE') {
            return(includes_pempty(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `WILD_TYPE') {
            return(includes_pwild(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `CONSTANT_TYPE') {
            return(includes_pconstant(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `RANGE_TYPE') {
            return(includes_prange(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `OR_TYPE') {
            return(includes_por(pattern_1, pattern_2))
        }
    }
    else if (eltype(pattern_1) == "struct") {
        if (structname(pattern_1) == "Tuple") {
            return(includes_tuple(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleOr") {
            return(includes_tupleor(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleEmpty") {
            return(1)
        }
    }
    else {
        unknown_pattern(pattern_1)
    }
}

/////////////////////////////////////////////////////////////////// difference()

`T' difference(`T' pattern_1, `T' pattern_2) {
    if (eltype(pattern_1) == "real") {
        if (pattern_1[1, 1] == `EMPTY_TYPE') {
            return(difference_pempty(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `WILD_TYPE') {
            return(difference_pwild(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `CONSTANT_TYPE') {
            return(difference_pconstant(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `RANGE_TYPE') {
            return(difference_prange(pattern_1, pattern_2))
        }
        else if (pattern_1[1, 1] == `OR_TYPE') {
            return(difference_por(pattern_1, pattern_2))
        }
    }
    else if (eltype(pattern_1) == "struct") {
        if (structname(pattern_1) == "Tuple") {
            return(difference_tuple(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleOr") {
            return(difference_tupleor(pattern_1, pattern_2))
        }
        else if (structname(pattern_1) == "TupleEmpty") {
            return(pattern_2)
        }
    }
    else {
        unknown_pattern(pattern_1)
    }
}


end
