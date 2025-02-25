mata

// Empty and TupleEmpty patterns needs a scalar for the type
// Constant and Ranger patterns need a vector for the type and the values
// Wildcard and Or patterns need a matrix to store the other patterns
// Tuple and TupleWild patterns need 3 dimensions to store the previous patterns
// TupleOr need 4 dimensions to store multiple Tuple patterns

// Mata goes up to 2 dimensions with matrices
// 3 dimensions are done by storing pointers to matrices
// 4 dimensions with vectors of pointers to matrices
// ...

// We need to create separate data structures for the larger dimensions

// This could be avoided if we could store pointers as reals in the matrices
// From there we could access the other matrices
// Then we wouldn't need to TupleEmpty, TupleWild and TupleOr

// TupleOr with 2 columns would be like:
// (      OrType,  length)
// (TuplePointer, pointer) -> (     TupleType, length)
//                            (PatternPointer,      .) -> (ConstantType,  value)
//                            (PatternPointer,      .) -> (      OrType, length)
//                                                        (ConstantType,  value)

// But we cannot mix reals and pointers
// So I create yet another file for data structures

///////////////////////////////////////////////////////////////////////// new()

`TUPLEOR' new_tupleor() {
    `TUPLEOR' tuples
    
    tuples = TupleOr()
    tuples.length = 0
    tuples.list = J(1, 8, NULL)
    
    return(tuples)
}

//////////////////////////////////////////////////////////////////// to_string()

`STRING' to_string_tuple(`TUPLE' tuple) {
    `STRINGS' strings
    `REAL' i, n_pat
    
    n_pat = length(tuple.patterns)
    
    if (n_pat == 0) {
        return("Empty Tuple: Error")
    }
    
    strings = J(1, n_pat, "")
    
    for (i = 1; i <= n_pat; i++) {
        strings[i] = to_string(*tuple.patterns[i])
    }
    
    if (n_pat == 1) {
        return(invtokens(strings, ", "))
    }
    else {
        return("(" + invtokens(strings, ", ") + ")")
    }
}

`STRING' to_string_tupleor(`TUPLEOR' tuples) {
    `STRINGS' strings
    `REAL' i

    strings = J(1, tuples.length, "")

    for (i = 1; i <= tuples.length; i++) {
        strings[i] = to_string_tuple(*tuples.list[i])
    }

    return(invtokens(strings, " | "))
}


////////////////////////////////////////////////////////////////////// to_expr()

`STRING' to_expr_tuple(`TUPLE' tuple, `VARIABLES' variables) {
    `POINTER' pattern
    `STRINGS' exprs
    `REAL' i, k, n_pat

    n_pat = length(tuple.patterns)
    
    if (n_pat != length(variables)) {
        errprintf(
            "The tuples and variables have different sizes %f and %f",
            n_pat, length(variables)
        )
        exit(_error(3300))
    }
    
    exprs = J(1, n_pat, "")

    k = 0
    for (i = 1; i <= n_pat; i++) {
        pattern = compress(*tuple.patterns[i])
        if (pattern[1, 1] != `EMPTY_TYPE' & pattern[1, 1] != `WILD_TYPE') {
            k++
            exprs[k] = to_expr(pattern, variables[i])
        }
    }
    
    if (k == 0) {
        return("1")
    }
    
    // Add parentheses if there is more than 1 condition
    if (k > 1) {
        for (i = 1; i <= k; i++) {
            exprs[i] = "(" + exprs[i] + ")"
        }
    }
    
    return(invtokens(exprs[1..k], " & "))
}

`STRING' to_expr_tupleor(`TUPLEOR' tuples, `VARIABLES' variable) {
    `STRINGS' exprs
    `REAL' i
    
    assert(!missing(tuples.length))
    
    if (tuples.length == 0) {
        return("")
    }
    
    if (tuples.length == 1) {
        return(to_expr(tuples.list[1], variable))
    }

    exprs = J(1, tuples.length, "")
    
    for (i = 1; i <= tuples.length; i++) {
        exprs[i] = "(" + to_expr_tuple(*tuples.list[i], variable) + ")"
    }

    return(invtokens(exprs, " | "))
}

///////////////////////////////////////////////////////////////////// compress()

`T' compress_tuple(`TUPLE' tuple) {
    `TUPLE' tuple_compressed
    `REAL' i

    tuple_compressed.arm_id = tuple.arm_id
    tuple_compressed.patterns = J(length(tuple.patterns), 1, NULL)
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        tuple_compressed.patterns[i] = &compress(*tuple.patterns[i])
        if ((*tuple_compressed.patterns[i])[1, 1] == `EMPTY_TYPE') {
            return(TupleEmpty())
        }
    }

    return(tuple_compressed)
}

`T' compress_tupleor(`TUPLEOR' tuples) {
    `TUPLEOR' tuples_compressed
    `POINTER' pattern_compressed
    `REAL' i
    
    tuples_compressed = new_tupleor()
    
    for (i = 1; i <= tuples.length; i++) {
        pattern_compressed = &compress(*tuples.list[i])
        if (structname(*pattern_compressed) == "TupleEmpty") {
            continue
        }
        else if (structname(*pattern_compressed) == "TupleWild") {
            return(*pattern_compressed)
        }
        else {
            if (!includes_tupleor(tuples_compressed, *pattern_compressed)) {
                push_tupleor(tuples_compressed, *pattern_compressed) 
            }
        }
    }
    
    if (tuples_compressed.length == 0) {
        return(TupleEmpty())
    }
    if (tuples_compressed.length == 1) {
        return(*tuples_compressed.list[1])
    }
    else {
        return(tuples_compressed)
    }
}

////////////////////////////////////////////////////////////////////// overlap()

// The outcome is compressed, but need to check if the pattern is included
// If X = 1/3 and Y = 2/4, Z = 3 and T = 2/3
// (1/3 | 2/4 | 3) & T => (2/3 | 2/3 | 3)
// If (X | Y | Z) was compressed such that no element is included in another
// (1/3 | 2/4 | 3) => (1/3 | 2/4)
// X and Y are not included in one another
// Compressing would require to merge the overlaping patterns
// (1/3 | 2/4 | 3) => 1/4
// In this case all the compressed elements are exclusive
// The overlaps of a compressed tuples and a pattern would always be compressed
// This would work for tuples too

`T' overlap_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "TupleEmpty") {
        return(TupleEmpty())
    }
    else if (structname(pattern) == "TupleWild") {
        return(tuple)
    }
    else if (structname(pattern) == "Tuple") {
        return(overlap_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "TupleOr") {
        return(overlap_tuple_tupleor(tuple, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`T' overlap_tuple_tuple(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    `TUPLE' tuple_overlap
    `REAL' i
    
    check_tuples(tuple_1, tuple_2)
    
    tuple_overlap.patterns = J(1, length(tuple_1.patterns), NULL)

    // We compute the overlap of each pattern in the tuple
    for (i = 1; i <= length(tuple_1.patterns); i++) {
        tuple_overlap.patterns[i] = &overlap(
            *tuple_1.patterns[i],
            *tuple_2.patterns[i]
        )
        if ((*tuple_overlap.patterns[i])[1, 1] == 0) {
            return(TupleEmpty())
        }
    }

    return(tuple_overlap)
}

`T' overlap_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `TUPLEOR' tuples_overlap
    `REAL' i
    
    tuples_overlap = new_tupleor()
    
    tuples_overlap.list = J(1, length(tuples.list), NULL)
    
    for (i = 1; i <= tuples.length; i++) {
        push_tupleor(tuples_overlap, overlap_tuple_tuple(tuple, *tuples.list[i]))
    }
    
    return(compress(tuples_overlap))
}

`T' overlap_tupleor(`TUPLEOR' tuples, `T' pattern) {
    `TUPLEOR' tuples_overlap
    `POINTER' overlap
    `REAL' i
    
    if (structname(pattern) == "TupleEmpty") {
        return(TupleEmpty())
    }
    if (structname(pattern) == "TupleWild") {
        return(tuples)
    }
    
    tuples_overlap = new_tupleor()

    for (i = 1; i <= tuples.length; i++) {
        overlap = &overlap(*tuples.list[i], pattern)
        if (structname(*overlap) == "TupleEmpty") {
            continue
        }
        else if (structname(*overlap) == "TupleWild") {
            return(*overlap)
        }
        else {
            if (!includes_tupleor(tuples_overlap, *overlap)) {
                push_tupleor(tuples_overlap, *overlap)
            }
        }
    }
    
    if (tuples_overlap.length == 0) {
        return(TupleEmpty())
    }
    if (tuples_overlap.length == 1) {
        return(*tuples_overlap.list[1])
    }
    else {
        return(tuples_overlap)
    }
}

///////////////////////////////////////////////////////////////////// includes()

`REAL' includes_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "TupleEmpty") {
        return(1)
    }
    if (structname(pattern) == "TupleWild") {
        // TODO: loop over all wildcards
            
        errprintf("TupleWild is not implemented yet, please come back latter")
        exit(_error(3000))
        
        return(0)
    }
    else if (structname(pattern) == "Tuple") {
        return(includes_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "TupleOr") {
        return(includes_tuple_tupleor(tuple, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`REAL' includes_tuple_tuple(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    `REAL' i
    
    check_tuples(tuple_1, tuple_2)
    
    for (i = 1; i <= length(tuple_1.patterns); i++) {
        if (!includes(*tuple_1.patterns[i], *tuple_2.patterns[i])) {
            return(0)
        }
    }

    return(1)
}

`REAL' includes_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `REAL' i
    
    for (i = 1; i <= tuples.length; i++) {
        if (!includes_tuple(tuple, *tuples.list[i])) {
            return(0)
        }
    }

    return(1)
}

`REAL' includes_tupleor(`TUPLEOR' tuples, `T' pattern) {
    if (structname(pattern) == "TupleEmpty") {
        return(1)
    }
    else if (structname(pattern) == "TupleWild") {
        // TODO: fix latter with real implementation of TupleWild
            
        errprintf("TupleWild is not implemented yet, please come back latter")
        exit(_error(3000))
        
        return(0)
    }
    else {
        return(includes_tuples_tuple(tuples, pattern))
    }
}

`REAL' includes_tuples_tuple(`TUPLEOR' tuples, `TUPLE' tuple) {
    `POINTERS' difference
    `REAL' i, n_pat
    
    difference = difference_list_tupleor(tuple, tuples)
    
    n_pat = 0
    
    for (i = 1; i <= length(difference); i++) {
        if (difference[i] == NULL) break
        n_pat++
    }
    
    if (n_pat == 0) {
        return(1)
    }
    else {
        // difference_list_tupleor() removes all the empty patterns
        // So if there is anything, there are patterns of pattern not in tuples
        return(0)
    }
}

/////////////////////////////////////////////////////////////////// difference()

`T' difference_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "TupleEmpty") {
        return(tuple)
    }
    if (structname(pattern) == "TupleWild") {
        return((TupleEmpty()))
    }
    else if (structname(pattern) == "Tuple") {
        return(difference_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "TupleOr") {
        return(difference_tuple_tupleor(tuple, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

/*
For two patterns of size n: (p_1, ...p_n) and (q_1, ..., q_n), we compute the
difference recursively. For the first patterns p_1 and q_1 we compute the
intersection inter_1, a pattern and the difference diff_1, a vectors of
patterns.

If n = 1, the difference is equal to diff_1.

If n == 2, the difference is composed of two parts:
    1. (diff_1, p_2), the combinaision of all the patterns in diff_n-1 with the pattern_n.
    2. (inter_1, diff_2), the combinaison of inter_n-1 with all the patterns in diff_n if diff_n is non-empty.

We recursively compute the difference between two tuples:
    1. We compute the interesection and the difference between two fields
    2. If they are the last fields, we return the difference
    3. Else we enter the recursive parts
        3.1 If

We then compute the difference between the remaining fields
(p_2, ..., p_n) and (q_2, ..., q_n).

For the a field n, the difference is equal to diff_n. For a field (n-1),

We recursively build the difference of all the fields up to the first one.
*/
`T' difference_tuple_tuple(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    `TUPLEOR' res_inter, res_diff, result, tuples
    `POINTER' new_diff, main_pattern, other_pattern, field_inter
    `POINTERS' field_diff
    `TUPLE' new_main, new_other, new_diff_i
    `REAL' i
    
    check_tuples(tuple_1, tuple_2)
    
    res_inter = new_tupleor()
    res_diff = new_tupleor()
    result = new_tupleor()
    tuples = new_tupleor()
    
    // Compute the field difference
    main_pattern = tuple_1.patterns[1]
    other_pattern = tuple_2.patterns[1]

    field_inter = &overlap(*main_pattern, *other_pattern)
    field_diff = difference(*main_pattern, *other_pattern)

    // If there are no other fields
    if (length(tuple_1.patterns) == 1) {
        if (field_diff[1, 1] != 0) {
            push_tupleor(
                res_diff,
                tuple_from_patterns(&field_diff)
            )
        }
    }
    else {
        // If the fields difference is empty there is no difference part
        if (field_diff[1, 1] != 0) {
            push_tupleor(
                res_diff,
                tuple_from_patterns((
                    &field_diff,
                    tuple_1.patterns[2..length(tuple_1.patterns)]
                ))
            )
        }

        // If the fields intersection is empty there is intersection part
        if ((*field_inter)[1, 1] != 0) {
            // Build two tuples with the reaining patterns
            new_main.patterns = tuple_1.patterns[2..length(tuple_1.patterns)]
            new_other.patterns = tuple_2.patterns[2..length(tuple_2.patterns)]

            // Compute the difference
            new_diff = &difference(new_main, new_other)

            // If non empty, we fill the tuples
            if (structname(*new_diff) == "Tuple") {
                new_diff_i = *new_diff
                push_tupleor(
                    res_inter,
                    tuple_from_patterns((
                        field_inter, 
                        new_diff_i.patterns
                    ))
                )
            }
            else if (structname(*new_diff) == "TupleOr") {
                tuples = *new_diff
                for (i = 1; i <= tuples.length; i++) {
                    new_diff_i = *tuples.list[i]
                    push_tupleor(
                        res_inter,
                        tuple_from_patterns((
                            field_inter,
                            new_diff_i.patterns
                        ))
                    )
                }
            }
            else if (structname(*new_diff) != "TupleEmpty") {
                unknown_pattern(*new_diff)
            }
        }
    }
    
    push_tupleor(result, res_inter)
    push_tupleor(result, res_diff)

    return(compress(result))
}

`TUPLE' tuple_from_patterns(`POINTERS' patterns) {
    `TUPLE' tuple

    tuple.patterns = patterns
    
    return(tuple)
}

`T' difference_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `TUPLEOR' tuples_result
    
    tuples_result = new_tupleor()
    
    append_tupleor(tuples_result, difference_list_tupleor(tuple, tuples))
    
    return(compress(tuples_result))
}

// The result is NOT compressed
`POINTER' difference_tupleor(`TUPLEOR' tuples, `T' pattern) {
    if (structname(pattern) == "TupleEmpty") {
        return(tuples)
    }
    if (structname(pattern) == "TupleWild") {
        return((TupleEmpty()))
    }
    else if (structname(pattern) == "Tuple") {
        return(difference_tupleor_tuple(tuples, pattern))
    }
    else if (structname(pattern) == "TupleOr") {
        return(difference_tupleor_tuple(tuples, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`POINTER' difference_tupleor_tuple(`TUPLEOR' tuples, `T' tuple) {
    `TUPLEOR' tuples_differences
    `REAL' i
    
    tuples_differences = new_tupleor()
    
    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= tuples.length; i++) {
        push_tupleor(tuples_differences, difference(*tuples.list[i], tuple))
    }
    
    if (tuples_differences.length == 0) {
        return((TupleEmpty()))
    }
    else {
        return(tuples_differences)
    }
}


`POINTERS' difference_list_tupleor(`T' pattern, `TUPLEOR' tuples) {
    `TUPLEOR' differences, new_differences
    `REAL' i, j
    
    differences = new_tupleor()
    
    push_tupleor(differences, pattern)

    // Loop over all pattern in Or
    for (i = 1; i <= tuples.length; i++) {
        new_differences = new_tupleor()

        // Compute the difference
        for (j = 1; j <= differences.length; j++) {
            push_tupleor(
                new_differences,
                difference(*differences.list[j], *tuples.list[i])
            )
        }

        // if we don't precise ".list" it creates a new instance
        differences.list = new_differences.list
        differences.length = new_differences.length
        
        if (new_differences.length == 0) {
            break
        }
    }
    
    return(differences.list)
}

////////////////////////////////////////////////////////////////////////// Utils

void check_tuples(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    if (length(tuple_1.patterns) != length(tuple_2.patterns)) {
        errprintf(
            "Different number of patter in tuples: %f != %f\n",
            length(tuple_1.patterns), length(tuple_2.patterns)
        )
        exit(_error(3200))
    }
}

void push_tupleor(`TUPLEOR' tuples, `T' pattern) {
    // New fun :
    // - with ref we create a ref to pattern
    // - in a loop creates pattern takes the last value of the loop
    // - we end up with all values equal to the last
    // - we need to copy the value before creating the ref
    // - for this we create a new variable to force the hard copy
    // - we don't know the type of pattern/struct
    // - we cannot use transmorphic because it drops the structname
    // - we need to create one variable per pattern type
    // - to avoid creating all object every time, this is done within functions
    
    // Ideally we should drop this but there might be bugs latter
    if (tuples.length == .) {
        tuples = new_tupleor()
    }
    
    if (structname(pattern) == "TupleEmpty") {
        // Ignore
        return
    }
    else if (structname(pattern) == "TupleWild") {
        return(push_tuples_copy_pwild(tuples, pattern))
    }
    else if (structname(pattern) == "TupleOr") {
        append_tupleor_tupleor(tuples, pattern)
    }
    else if (structname(pattern) == "Tuple") {
        return(push_tuples_copy_tuple(tuples, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

void push_tuples_copy_pwild(`TUPLEOR' tuples, `TUPLEWILD' tuplewild) {
    struct TupleWild scalar wild_copy
    
    errprintf("TupleWild is not implemented yet, please come back latter")
    exit(_error(3000))
    
    wild_copy = tuplewild
    
    tuples.list = &wild_copy, J(1, 7, NULL)
    tuples.length = 1
}

void push_tuples_copy_tuple(`TUPLEOR' tuples, `TUPLE' tuple) {
    `TUPLE' tuple_copy
    
    if (tuples.length == 1) {
        if (structname(*tuples.list[1]) == "TupleWild") {
            return
        }
    }
    
    if (tuples.length == length(tuples.list)) {
        tuples.list = tuples.list, J(1, length(tuples.list), NULL)
    }
    
    tuple_copy = tuple
    
    tuples.length = tuples.length + 1
    tuples.list[tuples.length] = &tuple_copy
}

void append_tupleor(`TUPLEOR' tuples, `POINTERS' patterns) {
    `REAL' i, n_pat, n_pat_new
    
    if (tuples.length == .) {
        tuples = new_tupleor()
    }
    
    n_pat = 0
    
    for (i = 1; i <= length(patterns); i++) {
        if (patterns[i] == NULL) {
            break
        }
        n_pat++
    }
    
    if (n_pat == 0) {
        return
    }
    
    if (tuples.length + n_pat >= length(tuples.list)) {
        // Get the next power of 2 number of patterns
        n_pat_new = tuples.length + n_pat
        n_pat_new = log(n_pat_new) / log(2)
        n_pat_new = ceil(n_pat_new)
        n_pat_new = exp(n_pat_new * log(2))
        tuples.list = tuples.list, J(1, n_pat_new, NULL)
    }
    
    tuples.list[(tuples.length + 1)..(tuples.length + n_pat)] = patterns[1..n_pat]
    tuples.length = tuples.length + n_pat
}

void append_tupleor_tupleor(`TUPLEOR' tuples_1, `TUPLEOR' tuples_2) {
    if (tuples_2.length == 0) {
        return
    }
    else {
        append_tupleor(tuples_1, tuples_2.list[1..tuples_2.length])
    }
}

end
