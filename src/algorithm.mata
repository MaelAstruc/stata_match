
mata

////////////////////////////////////////////////////////////////// Main function

class UsefulnessResult {
    `POINTER' usefulness_vec
    `POINTER' covered
}


void function check_match(`ARMS' arms, `VARIABLES' variables) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    class UsefulnessResult scalar usefulness_result
    `POINTER' missings, covered
    `ARM' arm
    `ARMS' useful_arms
    `REAL' i

    // profiler_on("check_match")
    
    // bench_on("- usefulness")
    usefulness_result = check_useful(arms)
    report.usefulness = *usefulness_result.usefulness_vec
    covered = usefulness_result.covered
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
    missings = &check_exhaustiveness(useful_arms, variables, covered)
    // bench_off("- exhaustiveness")
    
    // bench_on("- compress")
    report.missings = &compress(*missings)
    // bench_off("- compress")

    // bench_on("- print")
    report.print()
    // bench_off("- print")
    
    // profiler_off()
}

/////////////////////////////////////////////////////////////// Check usefulness

class UsefulnessResult scalar check_useful(`ARMS' arms) {
    `ARMS' useful_arms
    `ARM' new_arm
    class Usefulness scalar usefulness
    class Usefulness vector usefulness_vec
    class UsefulnessResult scalar usefulness_result
    `REAL' i, n_arms
    `POINTER' covered

    // profiler_on("check_useful")
    
    useful_arms = Arm(0)

    n_arms = length(arms)

    usefulness_vec = Usefulness(n_arms)
    
    covered = empty_like(arms[1])

    // Check that each arm is useful compared to previous useful arms
    for (i = 1; i <= n_arms; i++) {
        // bench_on("  - is_useful() 1")
        usefulness = is_useful(arms[i], useful_arms, covered)
        // bench_off("  - is_useful() 1")
        usefulness.arm_id = i
        usefulness.has_wildcard = arms[i].has_wildcard

        if (usefulness.useful == 1) {
            new_arm = arms[i]
            new_arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, new_arm
        }

        usefulness_vec[i].define(usefulness)
        
        covered = combine(covered, arms[i].lhs.pattern)
    }
    
    usefulness_result.usefulness_vec = &usefulness_vec
    usefulness_result.covered = covered
    
    // profiler_off()
    return(usefulness_result)
}

`POINTER' empty_like(`ARM' arm) {
    if (eltype(*arm.lhs.pattern) == "struct") {
        return(&(new_tupleor()))
    }
    else {
        return(&(new_por()))
    }
}

`POINTER' combine(`POINTER' covered, `POINTER' pattern) {
    if (eltype(*pattern) == "struct") {
        push_tupleor(*covered, *pattern)
        return(&compress_tupleor(*covered, 0))
    }
    else {
        push_por(*covered, *pattern)
        return(&compress_por(*covered, 0))
    }
}

class Usefulness scalar function is_useful(
    `ARM' arm,
    `ARMS' useful_arms,
    `POINTER' covered
) {
    `POINTER' tuple, differences, overlap_all, overlap_i
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    class Usefulness scalar result
    `ARM' ref_arm
    `REAL' i, k
    
    // profiler_on("is_useful")
    
    lhs_empty.pattern = &new_pempty()
    
    overlaps = LHS(length(useful_arms))
    
    tuple = arm.lhs.pattern

    // If it is the first pattern, it's always useful
    if (length(useful_arms) == 0) {
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = tuple

        // profiler_off()
        return(result)
    }
    
    // Compute the total overlap
    // bench_on("+ Overlap() all")
    overlap_all = &overlap(*tuple, *covered)
    // bench_off("+ Overlap() all")

    // Early exist if no overalp
    if ((*overlap_all)[1, 1] == `EMPTY_TYPE' | structname(*overlap_all) == "TupleEmpty") {
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = tuple

        // profiler_off()
        return(result)
    }
    
    k = 0

    // We loop over all the patterns to find the overlaps
    for (i = 1; i <= length(useful_arms); i++) {
        ref_arm = useful_arms[i]

        // bench_on("+ Overlap() i")
        overlap_i = &overlap(*tuple, *ref_arm.lhs.pattern)
        // bench_off("+ Overlap() i")
        
        if ((*overlap_i)[1, 1] != `EMPTY_TYPE' & structname(*overlap_i) != "TupleEmpty") {
            k++
            overlaps[k].pattern = overlap_i
            overlaps[k].arm_id = ref_arm.id
        }
    }
    
    // bench_on("+ Difference()")
    differences = &difference(*tuple, *overlap_all)
    // bench_off("+ Difference()")

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

    // profiler_off()
    return(result)
}

`T' get_and_compress(struct LHS vector overlaps, i) {
    return(&compress(*overlaps[i].pattern))
}

///////////////////////////////////////////////////////////// Check completeness

`T' check_exhaustiveness(`ARMS' arms, `VARIABLES' variables, `POINTER' covered) {
    `ARM' wild_arm
    pointer(`WILD') vector pwilds
    `TUPLE' tuple
    class Usefulness scalar usefulness
    `REAL' i
    
    // profiler_on("check_exhaustiveness")
    
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
    usefulness = is_useful(wild_arm, arms, covered)
    // bench_off("  - is_useful() 2")
    
    // profiler_off()
    return(*usefulness.differences)
}

end
