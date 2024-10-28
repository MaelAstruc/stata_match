local T         transmorphic     scalar
local POINTER   pointer          scalar
local POINTERS  pointer          vector
local REAL      real             scalar
local STRING    string           scalar

local EMPTY     struct PEmpty    scalar
local WILD      struct PWild     scalar
local CONSTANT  struct PConstant scalar
local RANGE     struct PRange    scalar
local OR        struct POr       scalar
local TUPLE     struct Tuple     scalar

local VARIABLE  class Variable   scalar
local VARIABLES class Variable   vector

mata

///////////////////////////////////////////////////////////////////// define_*()

void define_pempty(`EMPTY' pempty) {
}

void define_pwild(`WILD' pwild, `VARIABLE' variable) {
    `CONSTANT' pconstant
    `REAL' i
    
    init_por(pwild.values)
    
    if (length(variable.levels) == 0) {
        push_por(pwild.values, PEmpty())
        return
    }
    
    if (variable.type == "string") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            define_pconstant(pconstant, i)
            push_por(pwild.values, pconstant)
        }
    }
    else if (variable.type == "int") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            define_pconstant(pconstant, variable.levels[i])
            push_por(pwild.values, pconstant)
        }
    }
    else if (variable.type == "float") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            define_pconstant(pconstant, variable.levels[i])
            push_por(pwild.values, pconstant)
        }
    }
    else if (variable.type == "double") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            define_pconstant(pconstant, variable.levels[i])
            push_por(pwild.values, pconstant)
        }
    }
    else {
        errprintf(
            "Unexpected variable type for variable '%s': '%s'\n",
            variable.name, variable.stata_type
        )
        exit(_error(3256))
    }
}

void define_pconstant(`CONSTANT' pconstant, `REAL' value) {
    pconstant.value = value
}

void define_prange(`RANGE' prange, `REAL' min, `REAL' max, `REAL' type_nb) {
    if (isint(type_nb) & type_nb >= 1 & type_nb <= 3) {
        prange.type_nb = type_nb
    }
    else {
        errprintf("Range type number field should be 1, 2 or 3\n")
        exit(_error(3498))
    }

    if (min == . | max == .) {
        errprintf("Range boundaries should be non-missing reals\n")
        exit(_error(3253))
    }
    
    /*if (min > max) {
        errprintf("Range minimum (%s) should be smaller than its maximum (%s)\n", min, max)
        exit(_error(3498))
    }*/
    
    if (prange.type_nb == 1) {
        if (!isint(min) | !isint(max)) {
            errprintf("Range is discrete but boundaries are not integers\n")
            exit(_error(3498))
        }
    }
    
    prange.min = min
    prange.max = max
}

void define_por(`OR' por, `POINTERS' patterns) {
    init_por(por)
    append(por, patterns)
}

//////////////////////////////////////////////////////////////////// to_string()

`STRING' to_string(`T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(to_string_pempty(pattern))
    }
    else if (structname(pattern) == "PWild") {
        return(to_string_pwild(pattern))
    }
    else if (structname(pattern) == "PConstant") {
        return(to_string_pconstant(pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(to_string_prange(pattern))
    }
    else if (structname(pattern) == "POr") {
        return(to_string_por(pattern))
    }
    else if (structname(pattern) == "Tuple") {
        return(to_string_tuple(pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

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
        return(to_string_por(pwild.values))
    }
}

`STRING' to_string_pconstant(`CONSTANT' pconstant) {
    return(strofreal(pconstant.value))
}

`STRING' to_string_prange(`RANGE' prange) {
    return(strofreal(prange.min) + "/" + strofreal(prange.max))
}

`STRING' to_string_por(`OR' por) {
    string vector strings
    `REAL' i

    strings = J(1, por.length, "")

    for (i = 1; i <= por.length; i++) {
        strings[i] = to_string(*por.patterns[i])
    }

    return(invtokens(strings, " | "))
}

`STRING' to_string_tuple(`TUPLE' tuple) {
    string vector strings
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


//////////////////////////////////////////////////////////////////////// print()

void print(`T' pattern) {
    to_string(pattern)
}

////////////////////////////////////////////////////////////////////// to_expr()

`STRING' to_expr(`T' pattern, `VARIABLES' variable) {
    if (structname(pattern) == "PEmpty") {
        return(to_expr_pempty(pattern, variable))
    }
    else if (structname(pattern) == "PWild") {
        return(to_expr_pwild(pattern, variable))
    }
    else if (structname(pattern) == "PConstant") {
        return(to_expr_pconstant(pattern, variable))
    }
    else if (structname(pattern) == "PRange") {
        return(to_expr_prange(pattern, variable))
    }
    else if (structname(pattern) == "POr") {
        return(to_expr_por(pattern, variable))
    }
    else if (structname(pattern) == "Tuple") {
        return(to_expr_tuple(pattern, variable))
    }
    else {
        unknown_pattern(pattern)
    }
}

`STRING' to_expr_pempty(`EMPTY' pempty, `VARIABLE' variable) {
    return("")
}

`STRING' to_expr_pwild(`WILD' pwild, `VARIABLE' variable) {
    return("1")
}

`STRING' to_expr_pconstant(`CONSTANT' pconstant, `VARIABLE' variable) {
    if (variable.type == "string") {
        return(sprintf("%s == %s", variable.name, variable.levels[pconstant.value]))
    }
    else {
        return(sprintf("%s == %21x", variable.name, pconstant.value))
    }
}

`STRING' to_expr_prange(`RANGE' prange, `VARIABLE' variable) {
    return(sprintf(
        "%s >= %21x & %s <= %21x",
        variable.name, prange.min, variable.name, prange.max
    ))
}

`STRING' to_expr_por(`OR' por, `VARIABLES' variable) {
    string vector exprs
    `REAL' i
    
    assert(!missing(por.length))
    
    if (por.length == 0) {
        return("")
    }
    
    if (por.length == 1) {
        return(to_expr(*por.patterns[1], variable))
    }

    exprs = J(1, por.length, "")
    
    for (i = 1; i <= por.length; i++) {
        exprs[i] = "(" + to_expr(*por.patterns[i], variable) + ")"
    }

    return(invtokens(exprs, " | "))
}

`STRING' to_expr_tuple(`TUPLE' tuple, `VARIABLES' variables) {
    `POINTER' pattern
    string vector exprs
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
        pattern = &compress(*tuple.patterns[i])
        if (structname(*pattern) != "PWild" & structname(*pattern) != "PEmpty") {
            k++
            exprs[k] = to_expr(*pattern, variables[i])
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

///////////////////////////////////////////////////////////////////// compress()

`T' compress(`T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(compress_pempty(pattern))
    }
    else if (structname(pattern) == "PWild") {
        return(compress_pwild(pattern))
    }
    else if (structname(pattern) == "PConstant") {
        return(compress_pconstant(pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(compress_prange(pattern))
    }
    else if (structname(pattern) == "POr") {
        return(compress_por(pattern))
    }
    else if (structname(pattern) == "Tuple") {
        return(compress_tuple(pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`T' compress_pempty(`EMPTY' pempty) {
    return(pempty)
}

`T' compress_pwild(`WILD' pwild) {
    return(pwild)
}

`T' compress_pconstant(`CONSTANT' pconstant) {
    return(pconstant)
}

`T' compress_prange(`RANGE' prange) {
    `CONSTANT' pconstant
    
    if (prange.min > prange.max) {
        return(PEmpty())
    }
    else if (prange.min == prange.max) {
        pconstant.value = prange.min
        return(pconstant)
    }
    else {
        return(prange)
    }
}

`T' compress_por(`OR' por) {
    `OR' por_compressed
    `POINTER' pattern_compressed
    `REAL' i
    
    init_por(por_compressed)
    
    for (i = 1; i <= por.length; i++) {
        pattern_compressed = &compress(*por.patterns[i])
        if (structname(*pattern_compressed) == "PEmpty") {
            continue
        }
        else if (structname(*pattern_compressed) == "PWild") {
            return(*pattern_compressed)
        }
        else {
            if (!includes_por(por_compressed, *pattern_compressed)) {
                push_por(por_compressed, *pattern_compressed) 
            }
        }
    }
    
    if (por_compressed.length == 0) {
        return(PEmpty())
    }
    if (por_compressed.length == 1) {
        return(*por_compressed.patterns[1])
    }
    else {
        return(por_compressed)
    }
}

`T' compress_tuple(`TUPLE' tuple) {
    `TUPLE' tuple_compressed
    `REAL' i

    tuple_compressed.arm_id = tuple.arm_id
    tuple_compressed.patterns = J(length(tuple.patterns), 1, NULL)
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        tuple_compressed.patterns[i] = &compress(*tuple.patterns[i])
        if (structname(*tuple_compressed.patterns[i]) == "PEmpty") {
            return(PEmpty())
        }
    }

    return(tuple_compressed)
}

////////////////////////////////////////////////////////////////////// overlap()

`T' overlap(`T' pattern_1, `T' pattern_2) {
    if (structname(pattern_1) == "PEmpty") {
        return(overlap_pempty(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PWild") {
        return(overlap_pwild(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PConstant") {
        return(overlap_pconstant(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PRange") {
        return(overlap_prange(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "POr") {
        return(overlap_por(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "Tuple") {
        return(overlap_tuple(pattern_1, pattern_2))
    }
    else {
        unknown_pattern(pattern_1)
    }
}

`T' overlap_pempty(`EMPTY' pempty, `T' pattern) {
    return(pempty)
}

`T' overlap_pwild(`WILD' pwild, `T' pattern) {
    return(pattern)
}

`T' overlap_pconstant(`CONSTANT' pconstant, `T' pattern) {
    if (includes(pattern, pconstant)) {
        return(pconstant)
    }
    else {
        return(PEmpty())
    }
}

`T' overlap_prange(`RANGE' prange, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (structname(pattern) == "PWild") {
        return(prange)
    }
    else if (structname(pattern) == "PConstant") {
        return(overlap_prange_pconstant(prange, pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(overlap_prange_prange(prange, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(overlap_por(pattern, prange))
    }
    else {
        unknown_pattern(pattern)
    }
}

`T' overlap_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    if (includes_prange_pconstant(prange, pconstant)) {
        return(pconstant)
    }
    else {
        return(PEmpty())
    }
}

`T' overlap_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    `RANGE' inter_range
    
    if (prange_1.min > prange_2.max) return(PEmpty())
    if (prange_1.max < prange_2.min) return(PEmpty())

    inter_range.type_nb = prange_2.type_nb

    // Determine the minimum
    inter_range.min = max((prange_1.min, prange_2.min))
    inter_range.max = min((prange_1.max, prange_2.max))

    // Return the compressed version
    return(compress_prange(inter_range))
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
`T' overlap_por(`OR' por, `T' pattern) {
    `OR' por_overlap
    `POINTER' overlap
    `REAL' i
    
    init_por(por_overlap)

    for (i = 1; i <= por.length; i++) {
        overlap = &overlap(*por.patterns[i], pattern)
        if (structname(*overlap) == "PEmpty") {
            continue
        }
        else if (structname(*overlap) == "PWild") {
            return(*overlap)
        }
        else {
            if (!includes_por(por_overlap, *overlap)) {
                push_por(por_overlap, *overlap)
            }
        }
    }
    
    if (por_overlap.length == 0) {
        return(PEmpty())
    }
    if (por_overlap.length == 1) {
        return(*por_overlap.patterns[1])
    }
    else {
        return(por_overlap)
    }
}

`T' overlap_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (structname(pattern) == "PWild") {
        return(tuple)
    }
    else if (structname(pattern) == "Tuple") {
        return(overlap_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(overlap_tuple_por(tuple, pattern))
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
        if (structname(*tuple_overlap.patterns[i]) == "PEmpty") {
            return(PEmpty())
        }
    }

    return(tuple_overlap)
}

`T' overlap_tuple_por(`TUPLE' tuple, `OR' por) {
    `OR' por_overlap
    `REAL' i
    
    init_por(por_overlap)
    
    por_overlap.patterns = J(1, length(por.patterns), NULL)
    
    for (i = 1; i <= por.length; i++) {
        push_por(por_overlap, overlap_tuple_tuple(tuple, *por.patterns[i]))
    }
    
    return(compress(por_overlap))
}

///////////////////////////////////////////////////////////////////// includes()

`REAL' includes(`T' pattern_1, `T' pattern_2) {
    if (structname(pattern_1) == "PEmpty") {
        return(includes_pempty(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PWild") {
        return(includes_pwild(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PConstant") {
        return(includes_pconstant(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PRange") {
        return(includes_prange(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "POr") {
        return(includes_por(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "Tuple") {
        return(includes_tuple(pattern_1, pattern_2))
    }
    else {
        unknown_pattern(pattern_1)
    }
}

`REAL' includes_pempty(`EMPTY' pempty, `T' pattern) {
    return(structname(pattern) == "PEmpty")
}

`REAL' includes_pwild(`WILD' pwild, `T' pattern) {
    return(1)
}

`REAL' includes_pconstant(`CONSTANT' pconstant, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(1)
    }
    else if (structname(pattern) == "PWild") {
        return(includes_pconstant_pwild(pconstant, pattern))
    }
    else if (structname(pattern) == "PConstant") {
        return(includes_pconstant_pconstant(pconstant, pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(includes_pconstant_prange(pconstant, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(includes_pconstant_por(pconstant, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`REAL' includes_pconstant_pwild(`CONSTANT' pconstant, `WILD' pwild) {
    return(includes_pconstant_por(pconstant, pwild.values))
}

`REAL' includes_pconstant_pconstant(`CONSTANT' pconstant_1, `CONSTANT' pconstant_2) {
    return(pconstant_1.value == pconstant_2.value)
}

`REAL' includes_pconstant_prange(`CONSTANT' pconstant, `RANGE' prange) {
    return(pconstant.value == prange.min & pconstant.value == prange.max)
}

`REAL' includes_pconstant_por(`CONSTANT' pconstant, `OR' por) {
    `REAL' i
    
    for (i = 1; i <= por.length; i++) {
        if (!includes_pconstant(pconstant, *por.patterns[i])) {
            return(0)
        }
    }
    
    return(1)
}

`REAL' includes_prange(`RANGE' prange, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(1)
    }
    else if (structname(pattern) == "PWild") {
        return(includes_prange_pwild(prange, pattern))
    }
    else if (structname(pattern) == "PConstant") {
        return(includes_prange_pconstant(prange, pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(includes_prange_prange(prange, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(includes_prange_por(prange, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

`REAL' includes_prange_pwild(`RANGE' prange, `WILD' pwild) {
    return(includes_prange_por(prange, pwild.values))
}

`REAL' includes_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    return(pconstant.value >= prange.min & pconstant.value <= prange.max)
}

`REAL' includes_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    return(prange_2.min >= prange_1.min & prange_2.max <= prange_1.max)
}

`REAL' includes_prange_por(`RANGE' prange, `OR' por) {
    `REAL' i
    
    for (i = 1; i <= por.length; i++) {
        if (!includes_prange(prange, *por.patterns[i])) {
            return(0)
        }
    }
    
    return(1)
}

`REAL' includes_por(`OR' por, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(1)
    }
    else if (structname(pattern) == "PConstant") {
        return(includes_por_pconstant(por, pattern))
    }
    else {
        return(includes_por_default(por, pattern))
    }
}

`REAL' includes_por_pconstant(`OR' por, `CONSTANT' pconstant) {
    `REAL' i
    
    for (i = 1; i <= por.length; i++) {
        if (includes(*por.patterns[i], pconstant)) {
            return(1)
        }
    }
    
    return(0)
}

`REAL' includes_por_default(`OR' por, `T' pattern) {
    `POINTERS' difference
    `REAL' i, n_pat
    
    difference = difference_list(pattern, por)
    
    n_pat = 0
    
    for (i = 1; i <= length(difference); i++) {
        if (difference[i] == NULL) break
        n_pat++
    }
    
    if (n_pat == 0) {
        return(1)
    }
    else {
        // difference_list() removes all the empty patterns
        // So if there is anything, there are patterns of pattern not in por
        return(0)
    }
}

`REAL' includes_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(1)
    }
    if (structname(pattern) == "PWild") {
        // TODO: loop over all wildcards
        return(0)
    }
    else if (structname(pattern) == "Tuple") {
        return(includes_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(includes_tuple_por(tuple, pattern))
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

`REAL' includes_tuple_por(`TUPLE' tuple, `OR' por) {
    `REAL' i
    
    for (i = 1; i <= por.length; i++) {
        if (!includes_tuple(tuple, *por.patterns[i])) {
            return(0)
        }
    }

    return(1)
}

/////////////////////////////////////////////////////////////////// difference()

`POINTER' difference(`T' pattern_1, `T' pattern_2) {
    if (structname(pattern_1) == "PEmpty") {
        return(difference_pempty(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PWild") {
        return(difference_pwild(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PConstant") {
        return(difference_pconstant(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "PRange") {
        return(difference_prange(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "POr") {
        return(difference_por(pattern_1, pattern_2))
    }
    else if (structname(pattern_1) == "Tuple") {
        return(difference_tuple(pattern_1, pattern_2))
    }
    else {
        unknown_pattern(pattern_1)
    }
}

// The result is compressed
`POINTER' difference_pempty(`EMPTY' pempty, `T' pattern) {
    return(&pempty)
}

`POINTER' difference_pwild(`WILD' pwild, `T' pattern) {
    return(difference_por(pwild.values, pattern))
}

// The result is compressed
`POINTER' difference_pconstant(`CONSTANT' pconstant, `T' pattern) {
    if (includes(pattern, pconstant)) {
        return(&(PEmpty()))
    }
    else {
        return(&pconstant)
    }
}

`POINTER' difference_prange(`RANGE' prange, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(&prange)
    }
    else if (structname(pattern) == "PWild") {
        return(&(PEmpty()))
    }
    else if (structname(pattern) == "PConstant") {
        return(difference_prange_pconstant(prange, pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(difference_prange_prange(prange, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(difference_prange_por(prange, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

// The result is compressed
`POINTER' difference_prange_pconstant(`RANGE' prange, `CONSTANT' pconstant) {
    `RANGE' prange_low, prange_high
    `OR' pranges
    
    init_por(pranges)
    
    if (pconstant.value < prange.min | pconstant.value > prange.max) {
        return(&prange)
    }
    
    if (pconstant.value != prange.min) {
        prange_low.min = prange.min
        prange_low.max = pconstant.value - get_epsilon(pconstant.value, prange.type_nb)
        prange_low.type_nb = prange.type_nb
        push_por(pranges, prange_low)
    }
    
    if (pconstant.value != prange.max) {
        prange_high.min = pconstant.value + get_epsilon(pconstant.value, prange.type_nb)
        prange_high.max = prange.max
        prange_high.type_nb = prange.type_nb
        push_por(pranges, prange_high)
    }
    
    return(&compress(pranges))
}

// The result is compressed
`POINTER' difference_prange_prange(`RANGE' prange_1, `RANGE' prange_2) {
    `RANGE' prange_low, prange_high
    `OR' pranges
    
    init_por(pranges)
    
    if (prange_2.max < prange_1.min | prange_2.min > prange_1.max) {
        return(&prange_1)
    }
    
    // First half
    if (prange_2.min <= prange_1.min) {
        // Nothing there is no first half
    }
    else {
        prange_low.min = prange_1.min
        prange_low.max = prange_2.min - get_epsilon(prange_2.min, prange_1.type_nb)
        prange_low.type_nb = prange_1.type_nb
        push_por(pranges, prange_low)
    }
    
    // Second half
    if (prange_2.max >= prange_1.max) {
        // Nothing there is no second half
    }
    else {
        prange_high.min = prange_2.max + get_epsilon(prange_2.max, prange_1.type_nb)
        prange_high.max = prange_1.max
        prange_high.type_nb = prange_1.type_nb
        push_por(pranges, prange_high)
    }
    
    return(&compress(pranges))
}

`POINTER' difference_prange_por(`RANGE' prange, `OR' por) {
    `OR' por_differences
    
    init_por(por_differences)

    append(por_differences, difference_list(prange, por))
    
    return(&por_differences)
}

// The result is NOT compressed
`POINTER' difference_por(`OR' por, `T' pattern) {
    `OR' por_differences
    `REAL' i
    
    init_por(por_differences)

    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= por.length; i++) {
        push_por(por_differences, *difference(*por.patterns[i], pattern))
    }
    
    if (por_differences.length == 0) {
        return(&(PEmpty()))
    }
    else {
        return(&por_differences)
    }
}

`POINTER' difference_tuple(`TUPLE' tuple, `T' pattern) {
    if (structname(pattern) == "PEmpty") {
        return(&tuple)
    }
    if (structname(pattern) == "PWild") {
        return(&(PEmpty()))
    }
    else if (structname(pattern) == "Tuple") {
        return(difference_tuple_tuple(tuple, pattern))
    }
    else if (structname(pattern) == "POr") {
        return(difference_tuple_por(tuple, pattern))
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
`POINTER' difference_tuple_tuple(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    `OR' res_inter, res_diff, result, por
    `POINTER' new_diff, main_pattern, other_pattern, field_inter
    `POINTERS' field_diff
    `TUPLE' new_main, new_other, new_diff_i
    `REAL' i
    
    check_tuples(tuple_1, tuple_2)
    
    init_por(res_inter)
    init_por(res_diff)
    init_por(result)
    init_por(por)
    
    // Compute the field difference
    main_pattern = tuple_1.patterns[1]
    other_pattern = tuple_2.patterns[1]

    field_inter = &overlap(*main_pattern, *other_pattern)
    field_diff = difference(*main_pattern, *other_pattern)

    // If there are no other fields
    if (length(tuple_1.patterns) == 1) {
        if (structname(*field_diff) != "PEmpty") {
            push_por(
                res_diff,
                tuple_from_patterns(field_diff)
            )
        }
    }
    else {
        // If the fields difference is empty there is no difference part
        if (structname(*field_diff) != "PEmpty") {
            push_por(
                res_diff,
                tuple_from_patterns((
                    field_diff,
                    tuple_1.patterns[2..length(tuple_1.patterns)]
                ))
            )
        }

        // If the fields intersection is empty there is intersection part
        if (structname(*field_inter) != "PEmpty") {
            // Build two tuples with the reaining patterns
            new_main.patterns = tuple_1.patterns[2..length(tuple_1.patterns)]
            new_other.patterns = tuple_2.patterns[2..length(tuple_2.patterns)]

            // Compute the difference
            new_diff = difference(new_main, new_other)

            // If non empty, we fill the tuples
            if (eltype(*new_diff) != "struct") {
                exit(420)
            }
            if (structname(*new_diff) == "Tuple") {
                new_diff_i = *new_diff
                push_por(
                    res_inter,
                    tuple_from_patterns((
                        field_inter, 
                        new_diff_i.patterns
                    ))
                )
            }
            else if (structname(*new_diff) == "POr") {
                por = *new_diff
                for (i = 1; i <= por.length; i++) {
                    new_diff_i = *por.patterns[i]
                    push_por(
                        res_inter,
                        tuple_from_patterns((
                            field_inter,
                            new_diff_i.patterns
                        ))
                    )
                }
            }
            else if (structname(*new_diff) != "PEmpty") {
                unknown_pattern(*new_diff)
            }
        }
    }
    
    push_por(result, res_inter)
    push_por(result, res_diff)

    return(&compress(result))
}

`TUPLE' tuple_from_patterns(`POINTERS' patterns) {
    `TUPLE' tuple

    tuple.patterns = patterns
    
    return(tuple)
}

`POINTER' difference_tuple_por(`TUPLE' tuple, `OR' por) {
    `OR' por_result
    
    init_por(por_result)
    
    append(por_result, difference_list(tuple, por))

    return(&compress(por_result))
}

`POINTERS' difference_list(`T' pattern, `OR' por) {
    `OR' differences, new_differences
    `REAL' i, j
    
    init_por(differences)
    
    push_por(differences, pattern)

    // Loop over all pattern in Or
    for (i = 1; i <= por.length; i++) {
        init_por(new_differences)

        // Compute the difference
        for (j = 1; j <= differences.length; j++) {
            append(
                new_differences,
                difference(*differences.patterns[j], *por.patterns[i])
            )
        }

        if (new_differences.length == 0) {
            break
        }
        
        // if we don't precise ".patterns" it creates a new instance
        differences.patterns = new_differences.patterns
        differences.length = new_differences.length
    }

    drop_empty_patterns(differences)
    
    return(differences.patterns)
}

void drop_empty_patterns(`OR' por) {
    `REAL' i
    
    for (i = 1; i <= por.length; i++) {
        if (structname(*por.patterns[i]) == "PEmpty") {
            por.patterns[i] = por.patterns[por.length]
            por.patterns[por.length] = NULL
            por.length = por.length - 1
            i--
        }
    }
}

////////////////////////////////////////////////////////////////////////// Utils

`REAL' function isbool(`REAL' x) {
    return(x == 0 | x == 1)
}

`REAL' function isint(`REAL' x) {
    return(x == trunc(x))
}

`STRING' type_details(object) {
    `STRING' eltype, orgtype
    
    eltype = eltype(object)
    orgtype = orgtype(object)
    
    if (eltype == "pointer" & orgtype == "scalar") {
        eltype = eltype + "(" + type_details(*object) + ")"
    }
    else if (eltype == "struct") {
        eltype = eltype + " " + structname(object)
    }
    else if (eltype == "classname") {
        eltype = eltype + " " + classname(object)
    }
    
    return(eltype + " " + orgtype)
}

void unknown_pattern(`T' pattern) {
    errprintf(
        "Unknown pattern of type: %s\n",
        type_details(pattern)
    )
    exit(_error(3250))
}

void check_tuples(`TUPLE' tuple_1, `TUPLE' tuple_2) {
    if (length(tuple_1.patterns) != length(tuple_2.patterns)) {
        errprintf(
            "Different number of patter in tuples: %f != %f\n",
            length(tuple_1.patterns), length(tuple_2.patterns)
        )
        exit(_error(3200))
    }
}

void init_por(`OR' por) {
    por.length = 0
    por.patterns = J(1, 8, NULL)
}

void push_por(`OR' por, `T' pattern) {
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
    if (por.length == .) {
        init_por(por)
    }
    
    if (structname(pattern) == "PEmpty") {
        // Ignore
        return
    }
    else if (structname(pattern) == "PWild") {
        return(push_por_copy_pwild(por, pattern))
    }
    else if (structname(pattern) == "PConstant") {
        return(push_por_copy_pconstant(por, pattern))
    }
    else if (structname(pattern) == "PRange") {
        return(push_por_copy_prange(por, pattern))
    }
    else if (structname(pattern) == "POr") {
        append_por(por, pattern)
    }
    else if (structname(pattern) == "Tuple") {
        return(push_por_copy_tuple(por, pattern))
    }
    else {
        unknown_pattern(pattern)
    }
}

void push_por_copy_pwild(`OR' por, `WILD' pwild) {
    `WILD' wild_copy
    
    wild_copy = pwild
    
    por.patterns = &wild_copy, J(1, 7, NULL)
    por.length = 1
}

void push_por_copy_pconstant(`OR' por, `CONSTANT' pconstant) {
    `CONSTANT' pconstant_copy
    
    if (por.length == 1) {
        if (structname(*por.patterns[1]) == "PWild") {
            return
        }
    }
    
    if (por.length == length(por.patterns)) {
        por.patterns = por.patterns, J(1, length(por.patterns), NULL)
    }
    
    pconstant_copy = pconstant
    
    por.length = por.length + 1
    por.patterns[por.length] = &pconstant_copy
}

void push_por_copy_prange(`OR' por, `RANGE' prange) {
    `RANGE' prange_copy
    
    if (por.length == 1) {
        if (structname(*por.patterns[1]) == "PWild") {
            return
        }
    }
    
    if (por.length == length(por.patterns)) {
        por.patterns = por.patterns, J(1, length(por.patterns), NULL)
    }
    
    prange_copy = prange
    
    por.length = por.length + 1
    por.patterns[por.length] = &prange_copy
}

void push_por_copy_tuple(`OR' por, `TUPLE' tuple) {
    `TUPLE' tuple_copy
    
    if (por.length == 1) {
        if (structname(*por.patterns[1]) == "PWild") {
            return
        }
    }
    
    if (por.length == length(por.patterns)) {
        por.patterns = por.patterns, J(1, length(por.patterns), NULL)
    }
    
    tuple_copy = tuple
    
    por.length = por.length + 1
    por.patterns[por.length] = &tuple_copy
}

void append(`OR' por, `POINTERS' patterns) {
    `REAL' i, n_pat, n_pat_new
    
    if (por.length == .) {
        init_por(por)
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
    
    if (por.length + n_pat >= length(por.patterns)) {
        // Get the next power of 2 number of patterns
        n_pat_new = por.length + n_pat
        n_pat_new = log(n_pat_new) / log(2)
        n_pat_new = ceil(n_pat_new)
        n_pat_new = exp(n_pat_new * log(2))
        por.patterns = por.patterns, J(1, n_pat_new, NULL)
    }
    
    por.patterns[(por.length + 1)..(por.length + n_pat)] = patterns[1..n_pat]
    por.length = por.length + n_pat
}

void append_por(`OR' por_1, `OR' por_2) {
    if (por_2.length == 0) {
        return
    }
    else {
        append(por_1, por_2.patterns[1..por_2.length])
    }
}

end
