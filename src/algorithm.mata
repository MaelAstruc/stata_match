mata

class Match_report {
    class Usefulness vector usefulness
    transmorphic scalar missings

    string vector to_string()
    void print()
}

string vector Match_report::to_string() {
    class POr scalar por
    class Tuple scalar missing
    class Usefulness scalar usefulness
    string vector strings
    real scalar i

    for (i = 1; i <= length(this.usefulness); i++) {
        usefulness = this.usefulness[i]
        strings = strings, usefulness.to_string()
    }

    if (length(this.missings) == 0) {
        return(strings)
    }

    if (classname(this.missings) == "PEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing values"

    if (classname(this.missings) == "POr") {
        por = this.missings
        for (i = 1; i <= por.patterns.length; i++) {
            missing = por.patterns.get_pat(i)
            strings = strings, sprintf("\t%s", missing.to_string())
        }
    }
    else {
        missing = this.missings
        strings = strings, sprintf("\t%s", missing.to_string())
    }

    return(strings)
}

void Match_report::print() {
    string vector strings
    real scalar i

    strings = this.to_string()

    displayas("error")
    for (i = 1; i <= length(strings); i++) {
        printf("\t%s\n", strings[i])
    }
}


////////////////////////////////////////////////////////////////// Main function

class Arm vector function check_match( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    class Pattern scalar missings
    class Arm scalar arm
    class Arm vector useful_arms
    class POr scalar por
    real scalar i

    report = Match_report()

    report.usefulness = check_useful(arms)

    useful_arms = Arm(0)

    for (i = 1; i <= length(report.usefulness); i++) {
        usefulness = report.usefulness[i]
        if (usefulness.useful == 1) {
            arm = arms[i]
            arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, arm
        }
    }

    missings = check_completeness(useful_arms, variables)
    report.missings = missings.compress()

    report.print()

    return(useful_arms)
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
        usefulness = is_useful(arms[i], useful_arms)
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

function is_useful(class Arm scalar arm, class Arm vector useful_arms) {
    transmorphic scalar tuple
    class Pattern scalar tuple_overlap, tuple_pattern, differences_pattern
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    transmorphic scalar differences
    class Usefulness scalar result
    class Arm scalar ref_arm
    class PEmpty scalar pempty
    real scalar i, j, k, no_empty

    result = Usefulness()
    pempty = PEmpty()

    lhs_empty = LHS()
    lhs_empty.pattern = &pempty

    overlaps = LHS(length(useful_arms))

    tuple = *arm.lhs.pattern
    tuple_pattern = tuple

    differences = tuple

    // If it is the first pattern, it's always useful
    if (length(useful_arms) == 0) {
        result.useful = 1
        result.any_overlap = 0
        result.tuple = &tuple
        result.overlaps = &lhs_empty
        result.differences = &differences

        return(result)
    }

    // We loop over all the patterns
    for (i = 1; i <= length(useful_arms); i++) {
        // TODO: Use difference
        ref_arm = useful_arms[i]

        overlaps[i].arm_id = ref_arm.id
        overlaps[i].pattern = &tuple_pattern.overlap(*ref_arm.lhs.pattern)

        if (classname(*overlaps[i].pattern) != "PEmpty") {
            differences_pattern = differences
            differences = *differences_pattern.difference(*overlaps[i].pattern)
        }
    }

    k = 0
    for (i = 1; i <= length(overlaps); i++) {
        overlaps[i].pattern = get_and_compress(overlaps, i)
        if (classname(*overlaps[i].pattern) != "PEmpty") {
            k++
            overlaps[k] = overlaps[i]
        }
    }

    if (k == 0) {
        // No overlap, return tuple
        result.useful = 1
        result.any_overlap = 0
        result.tuple = &tuple
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
            result.tuple = &tuple
            result.overlaps = &overlaps[1..k]
            result.differences = &differences
        }
        else {
            // Else return the tuple, the overlaps and the differences
            result.useful = 1
            result.any_overlap = 1
            result.tuple = &tuple
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

class Tuple vector function check_completeness( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Arm scalar wild_arm
    class PWild vector pwilds
    class Tuple scalar tuple
    class Usefulness scalar usefulness
    real scalar i

    wild_arm = Arm()

    pwilds = PWild(length(variables))

    for (i = 1; i <= length(variables); i++) {
        pwilds[i].define(variables[i])
    }

    if (length(variables) == 1) {
        wild_arm.lhs.pattern = &pwilds[1].values
    }
    else {
        tuple = Tuple()
        tuple.patterns = J(1, length(variables), NULL)

        for (i = 1; i <= length(variables); i++) {
            tuple.patterns[i] = &pwilds[i].values
        }

        wild_arm.lhs.pattern = &tuple
    }

    usefulness = is_useful(wild_arm, arms)

    return(*usefulness.differences)
}

end
