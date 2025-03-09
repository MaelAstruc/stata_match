mata

///////////////////////////////////////////////////////////////////// new_*()

`EMPTY' new_pempty() {
    return((`EMPTY_TYPE', 0, 0, 0))
}

`WILD' new_pwild(`VARIABLE' variable) {
    `WILD' pwild
    `CONSTANT' pconstant
    `REAL' i, n_pat, variable_type
    
    // profiler_on("new_pwild")
    
    variable_type = variable.get_type_nb()
    
    check_var_type(variable_type)
    
    n_pat = length(variable.levels)
    
    pwild = (`WILD_TYPE', n_pat, 0, variable_type) \ J(n_pat, 4, 0)
    
    if (variable.type == "string") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(i, variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "int") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "float") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "double") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else {
        errprintf(
            "Unexpected variable type for variable '%s': '%s'\n",
            variable.name, variable.stata_type
        )
        exit(_error(3256))
    }
    
    // profiler_off()
    
    return(pwild)
}

`CONSTANT' new_pconstant(`REAL' value, `REAL' variable_type) {
    check_var_type(variable_type)
    
    return((`CONSTANT_TYPE', value, value, variable_type))
}

`RANGE' new_prange(`REAL' min, `REAL' max, `REAL' variable_type) {
    check_var_type(variable_type)

    if (min == . | max == .) {
        errprintf("Range boundaries should be non-missing reals\n")
        exit(_error(3253))
    }
    
    if (variable_type == 1 | variable_type == 4) {
        if (!isint(min) | !isint(max)) {
            errprintf("Range is discrete but boundaries are not integers\n")
            exit(_error(3498))
        }
    }
    
    return((`RANGE_TYPE', min, max, variable_type))
}

`OR' new_por() {
    return((`OR_TYPE', 0, 0, 0) \ J(8, 4, 0))
}

//////////////////////////////////////////////////////////////////// to_string()

`STRING' to_string_pempty(`EMPTY' pempty) {
    return("Empty")
}

`STRING' to_string_pwild(`WILD' pwild, | `REAL' detailed) {
    if (args() == 1) {
        detailed = 0
    }
    
    if (detailed == 0) {
        return("_")
    }
    else {
        return(to_string_por(pwild))
    }
}

`STRING' to_string_pconstant(`CONSTANT' pconstant) {
    return(strofreal(pconstant[1, 2]))
}

`STRING' to_string_prange(`RANGE' prange) {
    return(strofreal(prange[1, 2]) + "/" + strofreal(prange[1, 3]))
}

`STRING' to_string_por(`OR' por) {
    `STRINGS' strings
    `REAL' i, n_pat
    
    n_pat = por[1, 2]
    
    strings = J(1, n_pat, "")
    
    for (i = 1; i <= n_pat; i++) {
        strings[i] = to_string(por[i + 1, .])
    }
    
    return(invtokens(strings, " | "))
}

////////////////////////////////////////////////////////////////////// to_expr()

`STRING' to_expr_pempty(`EMPTY' pempty, `VARIABLE' variable) {
    return("")
}

`STRING' to_expr_pwild(`WILD' pwild, `VARIABLE' variable) {
    return("1")
}

`STRING' to_expr_pconstant(`CONSTANT' pconstant, `VARIABLE' variable) {
    if (variable.type == "string") {
        return(sprintf("%s == %s", variable.name, variable.levels[pconstant[1, 2]]))
    }
    else {
        return(sprintf("%s == %21x", variable.name, pconstant[1, 2]))
    }
}

`STRING' to_expr_prange(`RANGE' prange, `VARIABLE' variable) {
    return(sprintf(
        "%s >= %21x & %s <= %21x",
        variable.name, prange[1, 2], variable.name, prange[1, 3]
    ))
}

`STRING' to_expr_por(`OR' por, `VARIABLES' variable) {
    `STRINGS' exprs
    `REAL' i, n_pat
    
    n_pat = por[1, 2]
    
    if (n_pat == 0) {
        return("")
    }
    
    if (n_pat== 1) {
        return(to_expr(por[2, .], variable))
    }

    exprs = J(1, n_pat, "")
    
    for (i = 1; i <= n_pat; i++) {
        exprs[i] = "(" + to_expr(por[i + 1, .], variable) + ")"
    }

    return(invtokens(exprs, " | "))
}

///////////////////////////////////////////////////////////////////// compress()

`PATTERN' compress_pempty(`EMPTY' pempty) {
    return(pempty)
}

`PATTERN' compress_pwild(`WILD' pwild) {
    return(pwild)
}

`PATTERN' compress_pconstant(`CONSTANT' pconstant) {
    return(pconstant)
}

`PATTERN' compress_prange(`RANGE' prange) {
    `CONSTANT' pconstant
    
    if (prange[1, 2] > prange[1, 3]) {
        return(new_pempty())
    }
    else if (prange[1, 2] == prange[1, 3]) {
        pconstant = new_pconstant(prange[1, 2], prange[1, 4])
        return(pconstant)
    }
    else {
        return(prange)
    }
}

`PATTERN' compress_por(`OR' por) {
    `OR' por_compressed
    `PATTERN' pattern_compressed
    `REAL' i, n_pat
    
    // profiler_on("compress_por")
    
    por_compressed = new_por()
    
    n_pat = por[1, 2]
    
    for (i = 1; i <= n_pat; i++) {
        pattern_compressed = compress(por[i + 1, .])
        if (pattern_compressed[1, 1] == `EMPTY_TYPE') {
            continue
        }
        else if (pattern_compressed[1, 1] == `WILD_TYPE') {
            // profiler_off()
            return(pattern_compressed)
        }
        else {
            if (!includes_por(por_compressed, pattern_compressed)) {
                push_por(por_compressed, pattern_compressed) 
            }
        }
    }
    
    // profiler_off()
    
    if (por_compressed[1, 2] == 0) {
        return(new_pempty())
    }
    else if (por_compressed[1, 2] == 1) {
        return(por_compressed[2, .])
    }
    else {
        return(por_compressed)
    }
}

////////////////////////////////////////////////////////////////////// overlap()

`PATTERN' overlap_pempty(`EMPTY' pempty, `PATTERN' pattern) {
    return(pempty)
}

`PATTERN' overlap_pwild(`WILD' pwild, `PATTERN' pattern) {
    return(pattern)
}

`PATTERN' overlap_pconstant(`CONSTANT' pconstant, `PATTERN' pattern) {
    `PATTERN' res
    
    // profiler_on("overlap_pconstant")
    
    if (includes(pattern, pconstant)) {
        res = pconstant
    }
    else {
        res = new_pempty()
    }
    
    // profiler_off()
    return(res)
}

`PATTERN' overlap_prange(`RANGE' prange, `PATTERN' pattern) {
    `PATTERN' res
    
    // profiler_on("overlap_pconstant")
    
    if (pattern[1, 1] == `EMPTY_TYPE') {
        res = new_pempty()
    }
    else if (pattern[1, 1] == `WILD_TYPE') {
        res = prange
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        res = overlap_prange_pconstant(prange, pattern)
    }
    else if (pattern[1, 1] == `RANGE_TYPE') {
        res = overlap_prange_prange(prange, pattern)
    }
    else if (pattern[1, 1] == `OR_TYPE') {
        res = overlap_por(pattern, prange)
    }
    else {
        unknown_pattern(pattern)
    }
    
    // profiler_off()
    return(res)
}

`PATTERN' overlap_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    `PATTERN' res
    
    // profiler_on("overlap_pconstant")
    
    if (includes_prange_pconstant(prange, pconstant)) {
        res = pconstant
    }
    else {
        res = new_pempty()
    }
    
    // profiler_off()
    return(res)
}

`PATTERN' overlap_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    `RANGE' inter_range
    `REAL' min, max
    `PATTERN' res
    
    // profiler_on("overlap_prange_prange")
    
    if (prange_1[1, 2] > prange_2[1, 3]) {
        // profiler_off()
        return(new_pempty())
    }
    if (prange_1[1, 3] < prange_2[1, 2]) {
        // profiler_off()
        return(new_pempty())
    }

    // Determine the minimum
    min = max((prange_1[1, 2], prange_2[1, 2]))
    max = min((prange_1[1, 3], prange_2[1, 3]))

    inter_range = new_prange(min, max, prange_1[1, 4])
    
    // Return the compressed version
    res = compress_prange(inter_range)
    
    // profiler_off()
    return(res)
}

// The outcome is compressed, but need to check if the pattern is included
// If X = 1/3 and Y = 2/4, Z = 3 and T = 2/3
// (1/3 | 2/4 | 3) & T => (2/3 | 2/3 | 3)
// If (X | Y | Z) was compressed such that no element is included in another
// (1/3 | 2/4 | 3) => (1/3 | 2/4)
// X and Y are not included in one another
// Compressing would require to merge the overlaping patterns
// (1/3 | 2/4 | 3) => 1/4
// In this case all the compressed elements are exclusive
// The overlaps of a compressed POr and a pattern would always be compressed
// This would work for tuples to
`PATTERN' overlap_por(`OR' por, `PATTERN' pattern) {
    `OR' por_overlap
    `PATTERN' overlap
    `REAL' i
    
    // profiler_on("overlap_por")
    
    por_overlap = new_por()

    for (i = 1; i <= por[1, 2]; i++) {
        overlap = overlap(por[i + 1, .], pattern)
        
        if (overlap[1, 1] == `EMPTY_TYPE') {
            continue
        }
        else if (overlap[1, 1] == `WILD_TYPE') {
            // profiler_off()
            return(overlap)
        }
        else {
            if (!includes_por(por_overlap, overlap)) {
                push_por(por_overlap, overlap)
            }
        }
    }
    
    // profiler_off()
    if (por_overlap[1, 2] == 0) {
        return(new_pempty())
    }
    if (por_overlap[1, 2] == 1) {
        return(por_overlap[2, .])
    }
    else {
        return(por_overlap)
    }
}

///////////////////////////////////////////////////////////////////// includes()

`REAL' includes_pempty(`EMPTY' pempty, `PATTERN' pattern) {
    return(pattern[1, 1] == `EMPTY_TYPE')
}

`REAL' includes_pwild(`WILD' pwild, `PATTERN' pattern) {
    return(1)
}

`REAL' includes_pconstant(`CONSTANT' pconstant, `PATTERN' pattern) {
    if (pattern[1, 1] == `EMPTY_TYPE') {
        return(1)
    }
    else if (pattern[1, 1] == `WILD_TYPE') {
        return(includes_pconstant_pwild(pconstant, pattern))
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        return(includes_pconstant_pconstant(pconstant, pattern))
    }
    else if (pattern[1, 1] == `RANGE_TYPE') {
        return(includes_pconstant_prange(pconstant, pattern))
    }
    else if (pattern[1, 1] == `OR_TYPE') {
        return(includes_pconstant_por(pconstant, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`REAL' includes_pconstant_pwild(`CONSTANT' pconstant, `WILD' pwild) {
    return(includes_pconstant_por(pconstant, pwild))
}

`REAL' includes_pconstant_pconstant(`CONSTANT' pconstant_1, `CONSTANT' pconstant_2) {
    return(pconstant_1[1, 2] == pconstant_2[1, 2])
}

`REAL' includes_pconstant_prange(`CONSTANT' pconstant, `RANGE' prange) {
    return(pconstant[1, 2] == prange[1, 2] & pconstant[1, 2] == prange[1, 3])
}

`REAL' includes_pconstant_por(`CONSTANT' pconstant, `OR' por) {
    `REAL' i
    // profiler_on("includes_pconstant_por")
    
    for (i = 1; i <= por[1, 2]; i++) {
        if (!includes_pconstant(pconstant, por[i + 1, .])) {
            // profiler_off()
            return(0)
        }
    }
    
    // profiler_off()
    return(1)
}

`REAL' includes_prange(`RANGE' prange, `PATTERN' pattern) {
    if (pattern[1, 1] == `EMPTY_TYPE') {
        return(1)
    }
    else if (pattern[1, 1] == `WILD_TYPE') {
        return(includes_prange_pwild(prange, pattern))
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        return(includes_prange_pconstant(prange, pattern))
    }
    else if (pattern[1, 1] == `RANGE_TYPE') {
        return(includes_prange_prange(prange, pattern))
    }
    else if (pattern[1, 1] == `OR_TYPE') {
        return(includes_prange_por(prange, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`REAL' includes_prange_pwild(`RANGE' prange, `WILD' pwild) {
    return(includes_prange_por(prange, pwild))
}

`REAL' includes_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    return(pconstant[1, 2] >= prange[1, 2] & pconstant[1, 2] <= prange[1, 3])
}

`REAL' includes_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    return(prange_2[1, 2] >= prange_1[1, 2] & prange_2[1, 3] <= prange_1[1, 3])
}

`REAL' includes_prange_por(`RANGE' prange, `OR' por) {
    `REAL' i
    
    // profiler_on("includes_prange_por")
    
    for (i = 1; i <= por[1, 2]; i++) {
        if (!includes_prange(prange, por[i + 1, .])) {
            // profiler_off()
            return(0)
        }
    }
    
    // profiler_off()
    return(1)
}

`REAL' includes_por(`OR' por, `PATTERN' pattern) {
    if (pattern[1, 1] == `EMPTY_TYPE') {
        return(1)
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        return(includes_por_pconstant(por, pattern))
    }
    else {
        return(includes_por_default(por, pattern))
    }
}

`REAL' includes_por_pconstant(`OR' por, `CONSTANT' pconstant) {
    `REAL' i
    
    // profiler_on("includes_por_pconstant")
    
    for (i = 1; i <= por[1, 2]; i++) {
        if (includes(por[i + 1, .], pconstant)) {
            // profiler_off()
            return(1)
        }
    }
    
    // profiler_off()
    return(0)
}

`REAL' includes_por_default(`OR' por, `PATTERN' pattern) {
    `POINTERS' difference
    `REAL' i, n_pat
    
    // profiler_on("includes_por_default")
    
    difference = difference_list(pattern, por)
    
    if (difference[1, 1] == `EMPTY_TYPE') {
        // profiler_off()
        return(1)
    }
    else if (difference[1, 1] == `OR_TYPE' & difference[1, 2] == 0) {
        // profiler_off()
        return(1)
    }
    else {
        // difference_list() removes all the empty patterns
        // So if there is anything, there are patterns not in por
        // profiler_off()
        return(0)
    }
}

/////////////////////////////////////////////////////////////////// difference()

// The result is compressed
`PATTERN' difference_pempty(`EMPTY' pempty, `PATTERN' pattern) {
    return(pempty)
}

`PATTERN' difference_pwild(`WILD' pwild, `PATTERN' pattern) {
    `PATTERN' res
    
    // profiler_on("difference_pwild")
    res = difference_por(pwild, pattern)
    
    // profiler_off()
    return(res)
}

// The result is compressed
`PATTERN' difference_pconstant(`CONSTANT' pconstant, `PATTERN' pattern) {
    `PATTERN' res
    
    // profiler_on("difference_pwild")
    
    if (includes(pattern, pconstant)) {
        res = new_pempty()
    }
    else {
        res = pconstant
    }
    
    // profiler_off()
    return(res)
}

`PATTERN' difference_prange(`RANGE' prange, `PATTERN' pattern) {
    `PATTERN' res
    
    // profiler_on("difference_prange")
    
    if (pattern[1, 1] == `EMPTY_TYPE') {
        res = prange
    }
    else if (pattern[1, 1] == `WILD_TYPE') {
        res = new_pempty()
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        res = difference_prange_pconstant(prange, pattern)
    }
    else if (pattern[1, 1] == `RANGE_TYPE') {
        res = difference_prange_prange(prange, pattern)
    }
    else if (pattern[1, 1] == `OR_TYPE') {
        res = difference_prange_por(prange, pattern)
    }
    else {
        unknown_pattern(pattern)
    }
    
    // profiler_off()
    return(res)
}

// The result is compressed
`PATTERN' difference_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    `RANGE' prange_low, prange_high
    `OR' pranges
    `PATTERN' res
    
    // profiler_on("difference_prange_pconstant")
    
    pranges = new_por()
    
    if (pconstant[1, 2] < prange[1, 2] | pconstant[1, 2] > prange[1, 3]) {
        // profiler_off()
        return(prange)
    }
    
    if (pconstant[1, 2] != prange[1, 2]) {
        prange_low = new_prange(
            prange[1, 2],
            pconstant[1, 2] - get_epsilon(pconstant[1, 2], prange[1, 4]),
            prange[1, 4]
        )
        push_por(pranges, prange_low)
    }
    
    if (pconstant[1, 2] != prange[1, 3]) {
        prange_high = new_prange(
            pconstant[1, 2] + get_epsilon(pconstant[1, 2], prange[1, 4]),
            prange[1, 3],
            prange[1, 4]
        )
        push_por(pranges, prange_high)
    }
    
    res = compress(pranges)
    
    // profiler_off()
    return(res)
}

// The result is compressed
`PATTERN' difference_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    `RANGE' prange_low, prange_high
    `OR' pranges
    `PATTERN' res
    
    // profiler_on("difference_prange_prange")
    
    pranges = new_por()
    
    if (prange_2[1, 3] < prange_1[1, 2] | prange_2[1, 2] > prange_1[1, 3]) {
        // profiler_off()
        return(prange_1)
    }
    
    // First half
    if (prange_2[1, 2] <= prange_1[1, 2]) {
        // Nothing there is no first half
    }
    else {
        prange_low = new_prange(
            prange_1[1, 2],
            prange_2[1, 2] - get_epsilon(prange_2[1, 2], prange_1[1, 4]),
            prange_1[1, 4]
        )
        push_por(pranges, prange_low)
    }
    
    // Second half
    if (prange_2[1, 3] >= prange_1[1, 3]) {
        // Nothing there is no second half
    }
    else {
        prange_high = new_prange(
            prange_2[1, 3] + get_epsilon(prange_2[1, 3], prange_1[1, 4]),
            prange_1[1, 3],
            prange_1[1, 4]
        )
        push_por(pranges, prange_high)
    }
    
    res = compress(pranges)
    
    // profiler_off()
    return(res)
}

`PATTERN' difference_prange_por(`RANGE' prange, `OR' por) {
    `OR' por_differences
    
    // profiler_on("difference_prange_por")
    
    por_differences = new_por()

    append_por(por_differences, difference_list(prange, por))
    
    // profiler_off()
    return(por_differences)
}

// The result is NOT compressed
`PATTERN' difference_por(`OR' por, `PATTERN' pattern) {
    `OR' por_differences
    `REAL' i
    
    // profiler_on("difference_por")
    por_differences = new_por()

    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= por[1, 2]; i++) {
        push_por(por_differences, difference(por[i + 1, .], pattern))
    }
    
    // profiler_off()
    if (por_differences[1, 2] == 0) {
        return(new_pempty())
    }
    else {
        return(por_differences)
    }
}

`PATTERN' difference_list(`PATTERN' pattern, `OR' por) {
    `OR' differences, new_differences
    `REAL' i, j
    
    // profiler_on("difference_list")
    differences = new_por()
    push_por(differences, pattern)

    if (por[1, 2] == 0) {
        // profiler_off()
        return(differences)
    }
    
    // Loop over all pattern in Or
    for (i = 1; i <= por[1, 2]; i++) {
        new_differences = new_por()

        // Compute the difference
        for (j = 1; j <= differences[1, 2]; j++) {
            append_por(
                new_differences,
                difference(differences[j + 1, .], por[i + 1, .])
            )
        }
        
        differences = new_differences

        if (new_differences[1, 2] == 0) {
            break
        }
    }
    
    drop_empty_patterns(differences)
    
    // profiler_off()
    return(differences)
}

void drop_empty_patterns(`OR' por) {
    `REAL' i
    
    // profiler_on("drop_empty_patterns")
    
    // TODO: matrix version
    for (i = 1; i <= por[1, 2]; i++) {
        if (por[i + 1, 1] == 0) {
            por[i + 1, .] = por[por[1, 2] + 1, .]
            por[por[1, 2] + 1, 1..3] = (0, 0, 0)
            por[1, 2] = por[1, 2] - 1
            i--
        }
    }
    
    // profiler_off()
}

////////////////////////////////////////////////////////////////////////// Utils

void push_por(`OR' por, `PATTERN' pattern) {
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
    
    if (length(por) == 0 || por[1, 2] == .) {
        por = new_por()
    }
    
    if (pattern[1, 1] == `EMPTY_TYPE') {
        // Ignore
        return
    }
    else if (pattern[1, 1] == `WILD_TYPE') {
        push_por_copy_pwild(por, pattern)
    }
    else if (pattern[1, 1] == `CONSTANT_TYPE') {
        push_por_copy_pconstant(por, pattern)
    }
    else if (pattern[1, 1] == `RANGE_TYPE') {
        push_por_copy_prange(por, pattern)
    }
    else if (pattern[1, 1] == `OR_TYPE') {
        if (pattern[1, 2] > 0) {
            append_por(por, pattern[2..(pattern[1, 2] + 1), .])
        }
    }
    else {
        unknown_pattern(pattern)
    }
}

void push_por_copy_pwild(`OR' por, `WILD' pwild) {
    por = pwild
}

void push_por_copy_pconstant(`OR' por, `CONSTANT' pconstant) {
    if (por[1, 2] == rows(por) - 1) {
        por = por \ J(rows(por) - 1, 4, 0)
    }
    
    por[1, 2] = por[1, 2] + 1
    por[por[1, 2] + 1, .] = pconstant
}

void push_por_copy_prange(`OR' por, `RANGE' prange) {
    if (por[1, 2] == rows(por) - 1) {
        por = por \ J(rows(por) - 1, 4, 0)
    }
    
    por[1, 2] = por[1, 2] + 1
    por[por[1, 2] + 1, .] = prange
}

void append_por(`OR' por, `PATTERN' patterns) {
    `REAL' i, pat_start, pat_end, n_pat, n_pat_new
    
    if (patterns[1, 1] == `OR_TYPE') {
        n_pat = patterns[1, 2]
        pat_start = 2
    }
    else {
        n_pat = rows(patterns)
        pat_start = 1
    }
    
    pat_end = pat_start + n_pat - 1
    
    if (n_pat == 0) {
        return
    }
    
    if (por[1, 2] + n_pat >= rows(por) - 1) {
        // Get the next power of 2 number of patterns
        n_pat_new = por[1, 2] + n_pat
        n_pat_new = log(n_pat_new) / log(2)
        n_pat_new = ceil(n_pat_new)
        n_pat_new = exp(n_pat_new * log(2))
        por = por \ J(n_pat_new, 4, 0)
    }
    
    por[(por[1, 2] + 2)..(por[1, 2] + n_pat + 1), .] = patterns[pat_start..pat_end, .]
    por[1, 2] = por[1, 2] + n_pat
}

end
