
mata

////////////////////////////////////////////////////////////////// Main function

void function check_match(`ARMS' arms, `VARIABLES' variables) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    `POINTER' missings
    `ARM' arm
    `ARMS' useful_arms
    `REAL' i

    // bench_on("- usefulness")
    report.usefulness = check_useful(arms)
    // bench_off("- usefulness")

    useful_arms = Arm(0)

    // bench_on("- combine")
    for (i = 1; i <= length(report.usefulness); i++) {
        usefulness = report.usefulness[i]
        if (usefulness.useful == 1) {
            arm = arms[i]
            arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, arm
        }
    }
    // bench_off("- combine")

    // bench_on("- exhaustiveness")
    missings = &check_exhaustiveness(useful_arms, variables)
    // bench_off("- exhaustiveness")
    
    // bench_on("- compress")
    report.missings = &compress(*missings)
    // bench_off("- compress")

    // bench_on("- print")
    report.print()
    // bench_off("- print")
}

/////////////////////////////////////////////////////////////// Check usefulness

class Usefulness vector check_useful(`ARMS' arms) {
    `ARMS' useful_arms
    `ARM' new_arm
    class Usefulness scalar usefulness
    class Usefulness vector usefulness_vec
    `REAL' i, n_arms

    useful_arms = Arm(0)

    n_arms = length(arms)

    usefulness_vec = Usefulness(n_arms)

    // Check that each arm is useful compared to previous useful arms
    for (i = 1; i <= n_arms; i++) {
        // bench_on("  - is_useful() 1")
        usefulness = is_useful(arms[i], useful_arms)
        // bench_off("  - is_useful() 1")
        usefulness.arm_id = i
        usefulness.has_wildcard = arms[i].has_wildcard

        if (usefulness.useful == 1) {
            new_arm = arms[i]
            new_arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, new_arm
        }

        usefulness_vec[i].define(usefulness)
    }
    
    return(usefulness_vec)
}

class Usefulness scalar function is_useful(`ARM' arm, `ARMS' useful_arms) {
    `POINTER' tuple, differences, overlap_i
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    class Usefulness scalar result
    `ARM' ref_arm
    `REAL' i, k
    
    lhs_empty.pattern = &new_pempty()
    
    overlaps = LHS(length(useful_arms))
    
    tuple = arm.lhs.pattern

    differences = tuple

    // If it is the first pattern, it's always useful
    if (length(useful_arms) == 0) {
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = differences

        return(result)
    }

    k = 0
    
    // We loop over all the patterns
    for (i = 1; i <= length(useful_arms); i++) {
        // TODO: Use difference
        ref_arm = useful_arms[i]

        // bench_on("+ Overlap()")
        overlap_i = &overlap(*tuple, *ref_arm.lhs.pattern)
        // bench_off("+ Overlap()")
        
        if ((*overlap_i)[1, 1] != `EMPTY_TYPE' & structname(*overlap_i) != "TupleEmpty") {
            k++
            overlaps[k].pattern = overlap_i
            overlaps[k].arm_id = ref_arm.id
            // bench_on("+ Difference()")
            differences = &difference(*differences, *overlap_i)
            // bench_off("+ Difference()")
        }
    }
    
    if (k == 0) {
        // No overlap, return tuple
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = tuple
    }
    else {
        // Compute the remaining patterns
        //differences = difference_vec(*tuple, overlaps[1..k])
        
        // Ensure that differences are compressed to remove this
        differences = &compress(*differences)
        
        if ((*differences)[1, 1] == `EMPTY_TYPE' | structname(*differences) == "TupleEmpty") {
            // If no pattern remains, the pattern is not useful
            result.useful = 0
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = differences
        }
        else {
            // Else return the tuple, the overlaps and the differences
            result.useful = 1
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = differences
        }
    }

    return(result)
}

`T' get_and_compress(struct LHS vector overlaps, i) {
    return(&compress(*overlaps[i].pattern))
}

///////////////////////////////////////////////////////////// Check completeness

`T' check_exhaustiveness(`ARMS' arms, `VARIABLES' variables ) {
    `ARM' wild_arm
    pointer(`WILD') vector pwilds
    `TUPLE' tuple
    class Usefulness scalar usefulness
    `REAL' i
    
    pwilds = J(length(variables), 1, NULL)

    for (i = 1; i <= length(variables); i++) {
        pwilds[i] = &new_pwild(variables[i])
        (*pwilds[i])[1, 1] = `OR_TYPE'
    }

    if (length(variables) == 1) {
        wild_arm.lhs.pattern = pwilds[1]
    }
    else {
        tuple.patterns = J(1, length(variables), NULL)

        for (i = 1; i <= length(variables); i++) {
            tuple.patterns[i] = pwilds[i]
        }

        wild_arm.lhs.pattern = &tuple
    }

    // bench_on("  - is_useful() 2")
    usefulness = is_useful(wild_arm, arms)
    // bench_off("  - is_useful() 2")
    
    return(*usefulness.differences)
}

end
