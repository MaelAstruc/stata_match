mata

////////////////////////////////////////////////////////////////// Main function

void function check_match( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    class Pattern scalar missings
    class Arm scalar arm
    class Arm vector useful_arms
    real scalar i

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
    missings = check_exhaustiveness(useful_arms, variables)
    // bench_off("- exhaustiveness")
    
    // bench_on("- compress")
    report.missings = missings.compress()
    // bench_off("- compress")

    // bench_on("- print")
    report.print()
    // bench_off("- print")
}

/////////////////////////////////////////////////////////////// Check usefulness

function check_useful(class Arm vector arms) {
    class Arm vector useful_arms
    class Arm scalar new_arm
    class Usefulness scalar usefulness
    class Usefulness vector usefulness_vec
    real scalar i, n_arms

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

class Usefulness scalar function is_useful(class Arm scalar arm, class Arm vector useful_arms) {
    transmorphic scalar tuple
    class Pattern scalar tuple_pattern, differences_pattern
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    transmorphic scalar differences
    class Usefulness scalar result
    class Arm scalar ref_arm
    pointer scalar overlap_i
    real scalar i, k

    lhs_empty.pattern = &(PEmpty())

    overlaps = LHS(length(useful_arms))

    tuple = *arm.lhs.pattern
    tuple_pattern = tuple

    differences = tuple

    // If it is the first pattern, it's always useful
    if (length(useful_arms) == 0) {
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = &differences

        return(result)
    }

    k = 0
    // We loop over all the patterns
    for (i = 1; i <= length(useful_arms); i++) {
        // TODO: Use difference
        ref_arm = useful_arms[i]

        // bench_on("+ Overlap()")
        overlap_i = &tuple_pattern.overlap(*ref_arm.lhs.pattern)
        // bench_off("+ Overlap()")
        
        if (classname(*overlap_i) != "PEmpty") {
            k++
            overlaps[k].pattern = overlap_i
            overlaps[k].arm_id = ref_arm.id
            differences_pattern = differences
            // bench_on("+ Difference()")
            differences = *differences_pattern.difference(*overlap_i)
            // bench_off("+ Difference()")
        }
    }
    
    if (k == 0) {
        // No overlap, return tuple
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = &tuple
    }
    else {
        // Compute the remaining patterns
        //differences = difference_vec(tuple_pattern, overlaps[1..k])

        if (classname(differences) == "PEmpty") {
            // If no pattern remains, the pattern is not useful
            result.useful = 0
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = &differences
        }
        else {
            // Else return the tuple, the overlaps and the differences
            result.useful = 1
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = &differences
        }
    }

    return(result)
}

function get_and_compress(struct LHS vector overlaps, i) {
    class Pattern scalar pattern_i

    pattern_i = *overlaps[i].pattern
    
    return(&pattern_i.compress())
}

///////////////////////////////////////////////////////////// Check completeness

class Tuple vector function check_exhaustiveness( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Arm scalar wild_arm
    class PWild vector pwilds
    class Tuple scalar tuple
    class Usefulness scalar usefulness
    real scalar i

    pwilds = PWild(length(variables))

    for (i = 1; i <= length(variables); i++) {
        pwilds[i].define(variables[i])
    }

    if (length(variables) == 1) {
        wild_arm.lhs.pattern = &pwilds[1].values
    }
    else {
        tuple.patterns = J(1, length(variables), NULL)

        for (i = 1; i <= length(variables); i++) {
            tuple.patterns[i] = &pwilds[i].values
        }

        wild_arm.lhs.pattern = &tuple
    }

    // bench_on("  - is_useful() 2")
    usefulness = is_useful(wild_arm, arms)
    // bench_off("  - is_useful() 2")

    return(*usefulness.differences)
}

end
