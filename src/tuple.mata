mata

void Tuple::new() {}

string scalar Tuple::to_string() {
    class Pattern scalar pattern
    string vector strings
    string scalar str
    real scalar i, n_pat
    
    n_pat = length(this.patterns)

    if (n_pat == 0) {
        return("Empty Tuple: Error")
    }
    
    strings = J(1, n_pat, "")
    
    for (i = 1; i <= n_pat; i++) {
        pattern = *patterns[i]
        strings[i] = pattern.to_string()
    }
    
    str = invtokens(strings, ", ")

    if (n_pat > 1) {
        str = "(" + str + ")"
    }
    
    return(str)
}

void Tuple::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

string scalar Tuple::to_expr(class Variable vector variables) {
    class Pattern scalar pattern
    string vector exprs
    real scalar i, k, n_pat

    n_pat = length(this.patterns)
    
    if (n_pat != length(variables)) {
        errprintf(
            "The tuples and variables have different sizes %f and %f",
            length(this.patterns), length(variables)
        )
        exit(_error(3300))
    }
    
    exprs = J(1, n_pat, "")

    k = 0
    for (i = 1; i <= n_pat; i++) {
        pattern = *this.patterns[i]
        pattern = pattern.compress()
        if (classname(pattern) != "PWild" & classname(pattern) != "PEmpty") {
            k++
            exprs[k] = pattern.to_expr(variables[i])
        }
    }
    
    if (k == 0) {
        return("1")
    }
    
    if (k > 1) {
        for (i = 1; i <= k; i++) {
            exprs[i] = "(" + exprs[i] + ")"
        }
    }
    
    return(invtokens(exprs[1..k], " & "))
}

transmorphic scalar Tuple::compress() {
    real scalar i

    for (i = 1; i <= length(this.patterns); i++) {
        this.patterns[i] = tuple_compress_i(this.patterns, i)
    }

    for (i = 1; i <= length(this.patterns); i++) {
        if (classname(*this.patterns[i]) == "PEmpty") {
            return(PEmpty())
        }
    }

    return(this)
}

pointer scalar function tuple_compress_i(pointer vector patterns, real scalar i) {
    class Pattern scalar pattern

    pattern = *patterns[i]
    return(&pattern.compress())
}

transmorphic scalar Tuple::overlap(transmorphic scalar pattern) {
    if (classname(pattern) == "Tuple") {
        return(this.overlap_tuple(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.overlap_por(pattern))
    }
    else {
        errprintf("Unexpected pattern class: %s", classname(pattern))
        exit(_error(3260))
    }
}

real scalar Tuple::includes(class Tuple scalar tuple) {
    class Pattern scalar pattern_i
    real scalar included
    real scalar i

    check_tuples_length(this, tuple)

    included = 1

    for (i = 1; i <= length(this.patterns); i++) {
        pattern_i = *this.patterns[i]
        if (!pattern_i.includes(*tuple.patterns[i])) {
            included = 0
            break
        }
    }

    return(included)
}

void function check_tuples_length( ///
    class Tuple scalar tuple_1, ///
    class Tuple scalar tuple_2    ///
) {
    if (length(tuple_1.patterns) != length(tuple_2.patterns)) {
        errprintf(
            "The tuples different sizes %f and %f",
            length(tuple_1.patterns), length(tuple_2.patterns)
        )
        exit(_error(3300))
    }
}

transmorphic scalar Tuple::overlap_tuple(class Tuple scalar tuple) {
    class Pattern scalar pattern_i
    class Tuple scalar tuple_overlap
    real scalar i

    tuple_overlap.patterns = J(1, length(this.patterns), NULL)

    // We compute the overlap of each pattern in the tuple
    for (i = 1; i <= length(this.patterns); i++) {
        pattern_i = *this.patterns[i]
        tuple_overlap.patterns[i] = &pattern_i.overlap(*tuple.patterns[i])
    }

    return(tuple_overlap.compress())
}

transmorphic scalar Tuple::overlap_por(class POr scalar por) {
    class POr scalar por_overlap
    real scalar i
    
    // We compute the overlap for each tuple in the Or pattern
    for (i = 1; i <= por.len(); i++) {
        por_overlap.push(&this.overlap(por.get_pat(i)))
    }

    return(por_overlap.compress())
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
pointer scalar Tuple::difference(transmorphic scalar pattern) {
    if (classname(pattern) == "PEmpty") {
        return(&this)
    }
    else if (classname(pattern) == "POr") {
        return(this.difference_por(pattern))
    }
    else if (classname(pattern) != "Tuple") {
        errprintf("Unexpected pattern class %s", classname(pattern))
        exit(_error(101))
    }

    return(this.difference_tuple(pattern))
}

pointer scalar Tuple::difference_por(class POr scalar por) {
    class POr scalar por_result
    
    por_result.define(difference_list(this, por.patterns))

    return(&por_result.compress())
}

pointer scalar Tuple::difference_tuple(class Tuple scalar tuple) {
    class POr scalar res_inter, res_diff, result
    transmorphic scalar new_diff
    class Pattern scalar main_pattern, other_pattern, field_inter
    pointer vector field_diff
    class Tuple scalar new_main, new_other, new_diff_i
    class PatternList scalar pat_list
    real scalar i
    
    // Compute the field difference
    main_pattern = *this.patterns[1]
    other_pattern = *tuple.patterns[1]

    field_inter = main_pattern.overlap(other_pattern)
    field_diff = main_pattern.difference(other_pattern)

    // If there are no other fields
    if (length(this.patterns) == 1) {
        if (classname(*field_diff) != "PEmpty") {
            res_diff.push(tuple_from_patterns(field_diff))
        }
    }
    else {
        // If the fields difference is empty there is no difference part
        if (classname(*field_diff) != "PEmpty") {
            res_diff.push(tuple_from_patterns((field_diff, this.patterns[2..length(this.patterns)])))
        }

        // If the fields intersection is empty there is intersection part
        if (classname(field_inter) != "PEmpty") {
            // Build two tuples with the reaining patterns
            new_main.patterns = this.patterns[2..length(this.patterns)]

            new_other.patterns = tuple.patterns[2..length(this.patterns)]

            // Compute the difference
            new_diff = *new_main.difference(new_other)

            // If non empty, we fill the tuples
            if (classname(new_diff) == "Tuple") {
                new_diff_i = new_diff
                res_inter.push(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
            }
            else if (classname(new_diff) == "PatternList") {
                pat_list = new_diff
                for (i = 1; i <= pat_list.length; i++) {
                    new_diff_i = pat_list.get_pat(i)
                    res_inter.push(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
                }
            }
            else if (classname(new_diff) != "PEmpty") {
                errprintf("Unexpected pattern of class '%s'", classname(*new_diff))
                exit(_error(3260))
            }
        }
    }

    result.push(&res_diff)
    result.push(&res_inter)

    return(&result.compress())
}

pointer scalar function tuple_from_patterns(pointer vector patterns) {
    class Tuple scalar tuple

    tuple.patterns = patterns
    return(&tuple)
}

// To compute the difference between a tuple and a list of tuple
// We have an issue:
// 1. Compute the difference between our tuple and the first one
// 2. We obtain zero, one or more tuple corresponding to the difference
// 3. Compute the difference between each of these tuples and the second one
// 4. We obtain a new vector of differences
// 5. We repeat until we have checked all the tuples in the list
// We can stop earlier if at some point we have no difference remaining
transmorphic scalar function difference_vec( ///
    class Pattern scalar pattern,
    class Tuple vector tuples ///
) {
    class PatternList scalar differences
    transmorphic scalar new_differences
    real scalar i

    differences.push(&pattern)

    for (i = 1; i <= length(tuples); i++) {

        new_differences = *differences.difference(tuples[i])

        if (classname(new_differences) == "PEmpty") {
            return(new_differences)
        }
        else {
            differences = new_differences
        }
    }

    return(differences)
}


real scalar function is_empty_ctor(class Tuple vector tuples) {
    if (length(tuples) == 0) {
        return(1)
    }
    else if (length(tuples) == 1) {
        return(length(tuples[1].patterns) == 0)
    }
    else {
        return(0)
    }
}


                // x = (1 | 2, 1 | 2, 1 | 2)
                // y = (1, 1 | 2, 1)
                // diff_tuple(x, y)
                // 1. diff((1 | 2, 1 | 2, 1 | 2), (1, 1 | 2, 1))
                //        - overlap(1 | 2, 1)
                //        => overlap_pattern = 1
                //        - 1 | 2 - 1
                //        => diff_field = 2
                //        => not_overlap = (2, 1 | 2, 1 | 2)
                // 2. diff((1 | 2, 1 | 2), (1 | 2, 1))
                //        - overlap(1 | 2, 1 | 2)
                //        => overlap_pattern = 1 | 2
                //        - 1 | 2 - 1 | 2
                //        => diff_field = 0
                //        => not_overlap = 0
                // 3. diff((1 | 2), (1))
                //        - overlap(1 | 2, 1)
                //        => overlap_pattern = 1
                //        - 1 | 2 - 1
                //        => diff_field = 2
                //        => not_overlap = 2
                //        => remaining = 0
                //      return((2))
                // 2.
                //        => remaining_other_fields = (2)
                //        => remaining = (1 | 2, 2)
                //        return((1 | 2, 2))
                // 1.
                //        => remaining_other_fields = (1 | 2, 2)
                //        => remaining = (1, 1 | 2, 2)
                //        return((2, 1 | 2, 1 | 2), (1, 1 | 2, 2))


end
