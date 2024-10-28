*! version 0.0.15  06 Oct 2024

**#************************************************************ src/declare.mata

mata
mata set matastrict on

//////////////////////////////////////////////////////////////////////// Pattern

// Empty pattern
struct PEmpty { }

// Wild card '_'
struct PWild {
    // Members
    struct POr scalar values                                                     // The union of all possible levels                                                            // Add new value to the patterns
}

// Constant
struct PConstant {
    real scalar value                                                           // The value (real or string index)
}

// Real or Float Range
struct PRange {
    real scalar min                                                             // Minimum value
    real scalar max                                                             // Maximum value
    real scalar type_nb                                                         // 1 int, 2 float, 3 double
}

// Or pattern, which is a list of pointers to patterns
struct POr {
    // Members
    pointer vector patterns                                           // A dynamic array of patterns
    real scalar length
}

struct Tuple {
    // Members
    real scalar arm_id                                                          // The corresponding arm #
    pointer vector patterns                                                     // An array of patterns
}

/////////////////////////////////////////////////////////////////////// Variable

class Variable {
    string scalar name                                                          // Name of the variable
    string scalar stata_type                                                    // Stata type of the variable
    string scalar type                                                          // Internal type of the variable
    transmorphic colvector levels                                               // The corresponding sorted vector of levels
    real scalar levels_len                                                      // Number of levels
    private real scalar min
    private real scalar max
    real scalar check                                                           // Is the variable checked
    real scalar sorted                                                          // Are the levels sorted
    
    void new()
    string scalar to_string()
    void print()
    void init()                                                                 // Initialize the variable given its name
    void init_type()                                                            // Initialize the type
    void init_levels()                                                          // Initialize the levels
    void init_levels_int()
    void init_levels_float()
    void init_levels_string()
    void init_levels_int_base()
    void init_levels_float_base()
    void init_levels_strL()
    void init_levels_strN()
    void init_levels_tab()
    void init_levels_hash()
    real scalar should_tab()
    void quote_levels()
    real scalar get_level_index()                                               // Retrieve index of level
    void set_minmax()                                                           // Set min and max levels
    real scalar get_min()                                                       // Get minimum level
    real scalar get_max()                                                       // Get maximum level
    real scalar get_type_nb()                                                   // Get type number
    real colvector reorder_levels()
}

///////////////////////////////////////////////////////////////////// Hash Table

struct Htable {
    real         scalar    capacity
    real         scalar    N
    transmorphic scalar    dkey
    transmorphic rowvector keys
    real         rowvector status
}
//////////////////////////////////////////////////////////////////////////// Arm

// The condition part of the Arm
struct LHS {
    real scalar arm_id                                                          // The arm #
    pointer scalar pattern                                                      // The corresponding patterns
}

class Arm {
    struct LHS scalar lhs                                                       // The patterns
    string scalar value                                                         // The value to replace if the condition is met
    real scalar id                                                              // The arm #
    real scalar has_wildcard                                                    // 1 if the patterns include a wildcard, 0 otherwize

    void new()
    string scalar to_string()
    void print()
}

///////////////////////////////////////////////////////////////////// Usefulness

// The result after checking if an arm is useful
class Usefulness {
    real scalar useful                                                          // 1 if the pattern is useful, 0 otherwize
    real scalar has_wildcard                                                    // 1 if the arm includes wild_cards, 0 otherwize
    real scalar any_overlap                                                     // 1 if there are any overlap, 0 otherwize
    real scalar arm_id                                                          // The arm #
    pointer scalar overlaps                                                     // The overlaps
    pointer scalar differences                                                  // The differences

    void define()
    string vector to_string()
    void print()
    void new()
}

// The result of all the checks
class Match_report {
    class Usefulness vector usefulness                                          // The usefulness of each arm
    pointer scalar missings                                                     // The missing patterns

    void new()
    string vector to_string()
    string scalar to_string_pattern()
    string vector to_string_por()
    void print()
}
end


**#************************************************************ src/pattern.mata

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


**#************************************************************* src/htable.mata


**#***************************************************** Hash table struct utils

/*
Simple Hash Table with string keys and no values
Only the necessary parts for getting the levels in Variable() class methods
*/

local CAPACITY = 100
local RATIO    = 2

mata
struct Htable scalar htable_create(transmorphic scalar default_key, |real scalar capacity) {
    struct Htable H
    
    if (args() == 1) {
        capacity = `CAPACITY'
    }
    
    H = Htable()
    H.capacity = capacity
    H.N        = 0
    H.dkey     = default_key 
    H.keys     = J(1, capacity, default_key)
    H.status   = J(1, capacity, 0)
    
    return(H)
}

void htable_add_at(struct Htable H, transmorphic scalar key, real scalar h) {
    (void) H.N++
    H.keys[h]   = key
    H.status[h] = 1
    
    if (H.N * `RATIO' >= H.capacity) {
        htable_expand(H)
    }
}

real scalar htable_newloc_dup(struct Htable H, transmorphic scalar key, real scalar h) {
    // Will exit the loop because never at full capacity
    while (1) {
        if (H.status[h]) {
            if (H.keys[h] == key) {
                return(0)
            }
            h++
        }
        else {
            return(h)
        }
        
        if (h > H.capacity) {
            h = 1
        }
    }
}

void htable_expand(struct Htable H) {
    struct Htable scalar newH
    real scalar h, res, i
    transmorphic scalar key
    
    newH = htable_create(H.dkey, H.capacity * `RATIO')
    
    for (i = 1; i <= H.capacity; i++) {
        if (H.status[i]) {
            key = H.keys[i]

            h = hash1(key, newH.capacity)

            if (newH.status[h]) {
                res = htable_newloc_dup(newH, key, h)
            }
            else {
                res = h
            }

            if (res) {
                (void) newH.N++
                newH.keys[res] = key
                newH.status[res] = 1
            }
        }
    }
    
    swap(H, newH)
}

transmorphic colvector htable_keys(struct Htable H) {
    return(sort(select(H.keys, H.status)', 1))
}
end


**#*********************************************************** src/variable.mata

mata
class Variable vector function init_variables(string scalar vars_exp, real scalar check) {
    class Variable vector variables
    pointer scalar t
    real scalar i, n_vars
    string vector vars_str
    
    t = tokeninit()
    tokenset(t, vars_exp)
    
    vars_str = tokengetall(t)
    
    n_vars = length(vars_str)
    
    variables = Variable(n_vars)
    
    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i], check)
    }
    
    return(variables)
}

void Variable::new() {}

string scalar Variable::to_string() {
    string rowvector levels_str
    real scalar i

    levels_str = J(1, length(this.levels), "")

    if (this.type == "string") {
        levels_str = this.levels'
    }
    else {
        levels_str = strofreal(this.levels)'
    }
    
    return(
        sprintf(
            "'%s' (%s): (%s)",
            this.name,
            this.type,
            invtokens(levels_str)
        )
    )
}

void Variable::print() {
    printf("%s", this.to_string())
}

void Variable::init(string scalar variable, real scalar check) {
    this.name = variable
    this.levels_len = 0
    this.min = .a
    this.max = .a
    this.check  = check
    this.sorted = check
    
    this.init_type()
    this.init_levels()
}

void Variable::init_type() {
    string scalar var_type

    var_type = st_vartype(this.name)
    this.stata_type = var_type

    if (var_type == "byte" | var_type == "int" | var_type == "long") {
        this.type = "int"
    }
    else if (var_type == "float") {
        this.type = "float"
    }
    else if (var_type == "double") {
        this.type = "double"
    }
    else if (substr(var_type, 1, 3) == "str") {
        this.type = "string"
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}
end

// Different functions based on the `levelsof` command
local N_MATA_SORT 2000
local N_SAMPLE    200
local N_USE_TAB   50
local N_MATA_HASH 100000

mata
void Variable::init_levels() {
    if (this.check == 0) {
        return
    }
    
    if (this.type == "int") {
        this.init_levels_int()
    }
    else if (this.type == "float" | this.type == "double") {
        this.init_levels_float()
    }
    else if (this.type == "string") {
        this.init_levels_string()
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
    
    this.levels_len = length(this.levels)
}

void Variable::init_levels_int() {
    if (st_nobs() < `N_MATA_SORT') {
        this.init_levels_int_base()
    }
    if (this.should_tab()) {
        this.init_levels_tab()
    }
    else {
        this.init_levels_int_base()
    }
}

void Variable::init_levels_float() {
    if (st_nobs() < `N_MATA_SORT') {
        this.init_levels_float_base()
    }
    if (this.should_tab()) {
        this.init_levels_tab()
    }
    if (st_nobs() > `N_MATA_HASH') {
        this.init_levels_hash()
    }
    else {
        this.init_levels_float_base()
    }
}

void Variable::init_levels_string() {
    if (this.stata_type == "strL") {
        this.init_levels_strL()
    }
    else if (st_nobs() > `N_MATA_HASH') {
        this.init_levels_hash()
    }
    else {
        this.init_levels_strN()
    }
    
    this.quote_levels()
}

void Variable::init_levels_int_base() {
    real colvector x
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowsofinteger(x)
}

void Variable::init_levels_float_base() {
    real colvector x
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowssort(x)
}

// Similar to the `levelsof` command internals
// Removed some things not needed such as the frequency
// Benchmarks in dev/benchmark/levelsof_strL.do
void Variable::init_levels_strL() {
    string scalar n_init, indices
    real matrix cond, i, w
    
    n_init = st_tempname()
    indices = st_tempname()
    
    stata("gen " + n_init + " = _n")
    stata("bysort " + this.name + ": gen " + indices + " = _n == 1")
     
    st_view(cond, ., indices)
    maxindex(cond, 1, i, w)
    
    this.levels = st_sdata(i, this.name)
    
    stata("sort " + n_init)
}

void Variable::init_levels_strN() {
    string colvector x
    
    st_sview(x = "", ., this.name)

    this.levels = uniqrowssort(x)
}

void Variable::init_levels_tab() {
    string scalar matname
    
    matname = st_tempname()
    
    stata("quietly tab " + this.name + ", missing matrow(" + matname + ")")
    this.levels = st_matrix(matname)
}

void Variable::init_levels_hash() {
    transmorphic vector x
    transmorphic scalar key
    struct Htable scalar levels
    real scalar n, h, res, i

    if (this.type == "string") {
        st_sview(x="", ., this.name)
        levels = htable_create("")
    }
    else {
        st_view(x=., ., this.name)
        levels = htable_create(.)
    }
    
    n = length(x)

    for (i = 1; i <= n; i++) {
        key = x[i]

        h = hash1(key, levels.capacity)

        if (levels.status[h]) {
            res = htable_newloc_dup(levels, key, h)
        }
        else {
            res = h
        }

        if (res) {
            (void) levels.N++
            levels.keys[res] = key
            levels.status[res] = 1

            if (levels.N * 2 >= levels.capacity) {
                htable_expand(levels)
            }
        }
    }

    this.levels = htable_keys(levels)
}

real scalar Variable::should_tab() {
    real scalar     n, s, N, S, multi
    string scalar   state
    real colvector  x, y
    real matrix     t
    
    // Create a view
    st_view(x, ., this.name)

    // Take a random sample of x
    state = rngstate()
    rseed(987654321)
    y = srswor(x, `N_SAMPLE')
    rngstate(state)

    // Compute the number of unique levels in sample
    t = uniqrows(y, 1)
    n = rows(t)

    // If too many unique values in sample, return
    if (n >= `N_USE_TAB') {
        return(0)
    }

    // Compute the number of unique values that appear only once
    s = sum(t[., 2] :== 1)
    
    // Estimate multiplicity in the sample
    multi = multiplicity(sum(t[., 2] :== 1), rows(t))
    return(multi <= `N_USE_TAB')
}

void Variable::quote_levels() {
    real scalar i
    
    for (i = 1; i <= length(this.levels); i++) {
        this.levels[i] = `"""' + this.levels[i] + `"""'
    }
}

real scalar Variable::get_level_index(transmorphic scalar level) {
    real scalar index
    
    if (this.sorted == 1) {
        index = binary_search(&this.levels, this.levels_len, level)
    }
    else {
        if (this.levels_len == 0) {
            this.levels = J(64, 1, missingof(level))
        }
        
        if (this.levels_len == length(this.levels)) {
            this.levels = this.levels \ J(length(this.levels), 1, missingof(level))
        }
        
        this.levels_len = this.levels_len + 1
        this.levels[this.levels_len] = level
        index = this.levels_len
    }
    
    return(index)
}

real scalar function binary_search(pointer(transmorphic vector) vec, real scalar length, transmorphic scalar value) {
    real scalar left, right, i
    transmorphic scalar val
    
    left = 1
    right = length
    
    while (left <= right) {
        i = floor((left + right) / 2)
        val = (*vec)[i]
        
        if (value == val) {
            return(i)
        }
        else if (value < val) {
            right = i - 1
        }
        else {
            left = i + 1
        }
    }
    
    return(0)
}

void Variable::set_minmax() {
    real vector x_num, minmax
    
    minmax = minmax(x_num)
    
    if (this.check == 0) {
        st_view(x_num = ., ., this.name)
        minmax = minmax(x_num)
    }
    else {
        minmax = minmax(this.levels)
    }
    
    this.min = minmax[1]
    this.max = minmax[2]
}

real scalar Variable::get_min() {
    if (this.min == .a) {
        this.set_minmax()
    }
    
    return(this.min)
}

real scalar Variable::get_max() {
    if (this.max == .a) {
        this.set_minmax()
    }
    
    return(this.max)
}

real scalar Variable::get_type_nb() {
    if (this.type == "int") {
        return(1)
    }
    else if (this.type == "float") {
        return(2)
    }
    else if (this.type == "double") {
        return(3)
    }
    else if (this.type == "string") {
        return(4)
    }
    else {
        // TODO: improve error
        exit(1)
    }
}

// We use the level indices for string variables
// If the checks are skipped, they are obtained during parsing
// In this case they are not ordered and need to be sorted afterwards
real colvector Variable::reorder_levels() {
    real vector indices, new_indices
    transmorphic matrix table
    real scalar i, k
    
    if (this.type != "string" | this.check == 1) {
        // TODO: improve error
        exit(1)
    }
    
    indices = (1..this.levels_len)'
    
    // Keep track of original order
    table = (this.levels[1..this.levels_len], strofreal(indices))
    
    // Sort levels
    table = sort(table, 1)
    
    // Handle duplicate levels
    new_indices = J(this.levels_len, 1, 1)
    k = 1
    for (i = 2; i <= this.levels_len; i++) {
        if (table[i, 1] != table[i - 1, 1]) {
            k++
        }
        new_indices[i] = k
    }
    
    // Update Variable
    this.levels = uniqrowssort(table[., 1])
    this.sorted = 1
    
    // Add new position of levels
    table = (strtoreal(table[., 2]), new_indices)
    
    // Reorganize based on original order
    table = sort(table, 1)
    
    // Return a vector of new indices
    return(table[., 2])
}
end

**#************************************************************** Levelsof utils

mata
// From levelsof functions
real scalar multiplicity(real scalar s, real scalar n) {
        return(1/(1 - (s/n)^(1/(n - 1))))
}
end


**#**************************************************************** src/arm.mata

mata

void Arm::new() {}

string scalar Arm::to_string() {
    return(
        sprintf(
            "Arm %f: Tuple: %s / Value: %s",
            this.id, ::to_string(*this.lhs.pattern), this.value
        )
    )
}

void Arm::print() {
    displayas("text")
    printf("%s", this.to_string())
}

void function eval_arms(
    string scalar varname,
    class Arm vector arms,
    class Variable vector variables,
    real   scalar gen_first,
    string scalar dtype
) {
    class Arm scalar arm
    pointer scalar pattern
    string scalar command, condition, statement
    real scalar i, n, _rc

    n = length(arms)
    
    displayas("text")
    for (i = n; i >= 1; i--) {
        arm = arms[i]
        pattern = arm.lhs.pattern
        
        if (i == n & gen_first) {
            if (dtype != "") {
                command = "generate " + dtype
            }
            else {
                command = "generate"
            }
        }
        else {
            command = "replace"
        }
        
        if (length(variables) == 1) {
            condition = to_expr(*pattern, variables[1])
        }
        else {
            condition = to_expr(*pattern, variables)
        }
        
        if (condition == "1") {
            statement = sprintf(`"%s %s = %s"', command, varname, arm.value)
        }
        else {
            statement = sprintf(`"%s %s = %s if %s"', command, varname, arm.value, condition)
        }

        _rc = _stata(statement, 1)
        
        if (_rc) {
            errprintf("Stata encountered an error when evaluating arm %f\n", i)
            exit(error(_rc))
        }
    }
}

end


**#************************************************************* src/parser.mata

mata

class Arm vector function parse_string(
        string scalar str,
        class Variable vector variables,
        real scalar check
) {
    class Arm vector arms
    pointer scalar t

    t = tokenize(str)

    arms = parse_arms(t, variables)
    
    if (check == 0) {
        reorder_levels(arms, variables)
    }
    
    return(arms)
}

class Arm vector function parse_arms (
        pointer t,
        class Variable vector variables
) {
    class Arm scalar arm
    class Arm vector arms
    real scalar i

    arms = Arm(0)
    i = 0

    while (tokenpeek(t) != "") {
        arm = parse_arm(t, ++i, variables)
        if (structname(*arm.lhs.pattern) == "PEmpty") {
            errprintf("Arm %f is considered empty\n", i)
        }
        else {
            arms = arms, arm
        }
    }

    return(arms)
}

class Arm scalar function parse_arm(
        pointer t,
        real scalar arm_id,
        class Variable vector variables
    ) {
    class Arm scalar arm

    arm.id = arm_id
    arm.lhs.arm_id = arm_id

    if (length(variables) == 1) {
        arm.lhs.pattern = &parse_or(t, variables[1], arm_id)
    }
    else {
        arm.lhs.pattern = &parse_tuples(t, variables, arm_id)
    }

    check_next(t, "=", arm_id)

    arm.value = parse_value(t)
    
    arm.has_wildcard = check_wildcard(arm.lhs.pattern)

    return(arm)
}

transmorphic scalar function parse_pattern(
    pointer t,
    class Variable scalar variable,
    real scalar arm_id
) {
    string scalar tok, var_label
    real scalar number

    tok = tokenget(t)

    if (variable.type == "string") {
        if (tok == "_") {
            return(parse_wild(variable))
        }
        else if (isquoted(tok)) {
            number = variable.get_level_index(tok)
            if (number == 0) {
                errprintf("Unknown level : %s\n", tok)
                return(PEmpty())
            }
            else {
                return(parse_constant(number))
            }
        }
        else {
            errprintf(
                "Expected a quoted string for variable %s in arm %f, found: %s\n",
                variable.name, arm_id, tok
            )
            exit(_error(3254))
        }
    }
    else if (variable.type == "int" | variable.type == "float" | variable.type == "double") {
        if (tok == "_") {
            return(parse_wild(variable))
        }
        else if (tok == "min") {
            number =  variable.get_min()
            return(parse_number(t, number, arm_id, variable))
        }
        else if (tok == "max") {
            number = variable.get_max()
            return(parse_number(t, number, arm_id, variable))
        }
        else if (isnumber(tok)) {
            number = strtoreal(tok)
            return(parse_number(t, number, arm_id, variable))
        }
        else if (isquoted(tok)) {
            var_label = st_varvaluelabel(variable.name)
            
            if (var_label == "") {
                errprintf(
                    "No label value defined for variable %s, unexpected label in arm %f, found: %s\n",
                    variable.name, arm_id, tok
                )
                exit(_error(180))
            }
            
            number = st_vlsearch(var_label, unquote(tok))
            if (number != .) {
                return(parse_number(t, number, arm_id, variable))
            }
            else {
                errprintf(
                    "Unknown label value for variable %s and value label %s in arm %f: %s\n",
                    variable.name, var_label, arm_id, tok
                )
                exit(_error(180))
            }
        }
        else {
            errprintf(
                "Expected a number or a quoted value label for variable %s in arm %f, found: %s\n",
                variable.name, arm_id, tok
            )
            exit(_error(3253))
        }
    }
    else {
        errprintf(
            "Unexpected type for variable %s in arm %f: %s\n",
            variable.name, arm_id, variable.type
        )
        exit(_error(3250))
    }
}

transmorphic scalar function parse_number(
    pointer t,
    real scalar number,
    real scalar arm_id,
    class Variable scalar variable
) {
    string scalar next

    next = tokenpeek(t)
    if (israngesym(next)) {
        (void) tokenget(t)
        return(parse_range(t, next, number, arm_id, variable))
    }
    else {
        return(parse_constant(number))
    }
}

///////////////////////////////////////////////////////////////// Parse patterns

struct PWild scalar function parse_wild(class Variable scalar variable) {
    struct PWild scalar pwild
    define_pwild(pwild, variable)
    return(pwild)
}

struct PEmpty scalar function parse_empty() {
    return(PEmpty())
}

struct PConstant scalar function parse_constant(transmorphic scalar value) {
    class PConstant scalar pconstant
    define_pconstant(pconstant, value)
    return(pconstant)
}

struct PRange scalar function parse_range(
    pointer scalar t,
    string scalar symbole,
    real scalar min,
    real scalar arm_id,
    class Variable scalar variable
) {
    struct PRange scalar prange
    string scalar next
    real scalar max, epsilon
    
    next = tokenget(t)
    
    if (next == "max") {
        max = variable.get_max()
    }
    else  {
        max = strtoreal(next)
        if (max == .) {
            errprintf(
                "Error in range pattern in arm %f: expected a number or max, found %s\n",
                arm_id, next
            )
            exit(_error(3498))
        }
    }
    
    if (symbole == "/") {
    }
    else if (symbole == "!/") {
        min = min + get_epsilon(min, variable.get_type_nb())
    }
    else if (symbole == "/!") {
        max = max - get_epsilon(max, variable.get_type_nb())
    }
    else if (symbole == "!!") {
        min = min + get_epsilon(min, variable.get_type_nb())
        max = max - get_epsilon(max, variable.get_type_nb())
    }
    else {
        "Unexpected symbole: " + symbole
    }

    define_prange(prange, min, max, variable.get_type_nb())

    return(prange)
}

// We to shift the epsilon depending on the precision of x in base 2
real scalar get_epsilon(real scalar x, real scalar type_nb) {
    real scalar epsilon, epsilon0, x_log2, epsilon_log2, epsilon0_log2
    
    // We define epsilon and epsilon0 depending on the type
    //    epsilon  is the smallest 'e' such that x != x + e
    //    epsilon0 is the smallest 'e' such that 0 != 0 + e
    
    if (type_nb == 1) {
        return(1)
    }
    else if (type_nb == 2) {
        epsilon = 1.0000000000000X-017
        epsilon0 = 1.0000000000000X-07f
    }
    else if (type_nb == 3) {
        epsilon = 1.0000000000000X-034
        epsilon0 = 1.0000000000000X-3fe
    }
    else {
        // TODO: improve error
        errprintf("Expected a variable type 1, 2 or 3, found %f", type_nb)
        exit(_error(3250))
    }
    
    x_log2 = log(abs(x)) / log(2)
    epsilon_log2 = log(abs(epsilon)) / log(2)
    epsilon0_log2 = log(abs(epsilon0)) / log(2)

    if (x_log2 <  epsilon0_log2 - epsilon_log2) {
        // x is too close to zero, the epsilon will always be the minimum one
        return(epsilon0)
    }
    else {
        // epsilon needs to be shifted based on x value in base 2
        return(epsilon * exp(floor(x_log2) * log(2)))
    }
}

struct POr scalar function parse_or(
    pointer t,
    class Variable scalar variable,
    real scalar arm_id
) {
    struct POr scalar por

    init_por(por)
    
    do {
        push_por(por, parse_pattern(t, variable, arm_id))
    } while (match_next(t, "|"))

    return(compress_por(por))
}

struct Tuple scalar function parse_tuple(
    pointer t,
    class Variable vector variables,
    real scalar arm_id
) {
    struct Tuple scalar tuple
    real scalar i

    tuple.patterns = J(1, length(variables), NULL)

    i = 0
    
    check_next(t, "(", arm_id)

    do {
        i++
        if (i > length(variables)) {
            errprintf(
                "Too many patterns in arm %f: expected %f, found %f\n",
                arm_id, length(variables), i
            )
            exit(_error(3300))
        }
        
        tuple.patterns[i] = &parse_or(t, variables[i], arm_id)
    } while (match_next(t, ","))

    check_next(t, ")", arm_id)

    if (i != length(variables)) {
        errprintf(
            "Too few patterns in arm %f: expected %f, found %s\n",
            arm_id, length(variables), i
        )
        exit(_error(3300))
    }

    return(tuple)
}

struct POr scalar function parse_tuples(
    pointer t,
    class Variable vector variables,
    real scalar arm_id
) {
    struct POr scalar por
    
    init_por(por)

    do {
        push_por(por, parse_tuple(t, variables, arm_id))
    } while (match_next(t, "|"))
    
    return(compress_por(por))
}

//////////////////////////////////////////////////////////////////// Parse Value

string scalar function parse_value(pointer t) {
    string scalar value

    value = consume(t, ",")
    return(value)
}

////////////////////////////////////////////////////////////////////////// Utils

pointer scalar function tokenize(string scalar str) {
    pointer scalar t
    
    t = tokeninitstata()
    tokenpchars(t, ("=", ",", "/", "!/", "/!", "!!", "(", ")", "|"))
    tokenset(t, str)
    
    return(t)
}

string scalar function consume(pointer t, string scalar str) {
    string scalar tok, inside, value

    value = ""
    while (tokenpeek(t) != str & tokenpeek(t) != "") {
        tok = tokenget(t)
        if (tok == "(") {
            inside = consume(t, ")") + ")"
        }
        value = value + tok + inside
    }
    (void) tokenget(t)
    return(value)
}

real scalar function match_next(pointer t, string scalar str) {
    string scalar next
    
    next = tokenpeek(t)
    
    if (next == str) {
        (void) tokenget(t)
        return(1)
    }
    else {
        return(0)
    }
}

void function check_next(pointer t, string scalar str, real scalar arm_id) {
    string scalar next

    next = tokenget(t)
    
    if (next != str) {
        errprintf("Expect '%s' in arm %f, found: '%s'\n", str, arm_id, next)
        exit(_error(3499))
    }
}

real scalar function isnumber(string scalar str) {
    return(str == "." | strtoreal(str) != .)
}

real scalar function isquoted(string scalar str) {
    return(strmatch(str, `""*""'))
}

string scalar function unquote(string scalar str) {
    return(ustrregexra(str, `"(^"|"$)"', ""))
}

real scalar function israngesym(str) {
    return(str == "/" | str == "!/" | str == "/!" | str == "!!")
}

real scalar function check_wildcard(transmorphic scalar pattern) {
    if (eltype(pattern) == "pointer") {
        return(check_wildcard(*pattern))
    }
    else if (structname(pattern) == "PEmpty") {
        return(0)
    }
    else if (structname(pattern) == "PWild") {
        return(1)
    }
    else if (structname(pattern) == "PConstant") {
        return(0)
    }
    else if (structname(pattern) == "PRange") {
        return(0)
    }
    else if (structname(pattern) == "POr") {
        return(check_wildcard_por(pattern))
    }
    else if (structname(pattern) == "Tuple") {
        return(check_wildcard_tuple(pattern))
    }
    else {
        // From pattern.mata
        unknown_pattern(pattern)
    }
}

real scalar function check_wildcard_por(struct POr scalar por) {
    real scalar i
    
    for (i = 1; i <= por.length; i++) {
        if (check_wildcard(*por.patterns[i]) == 1) {
            return(1)
        }
    }
    
    return(0)
}

real scalar function check_wildcard_tuple(struct Tuple scalar tuple) {
    real scalar i
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        if (check_wildcard(*tuple.patterns[i]) == 1) {
            return(1)
        }
    }
    
    return(0)
}

void function reorder_levels(
    class Arm vector arms,
    class Variable vector variables
) {
    real scalar i
    pointer(real colvector) vector tables
    
    tables = J(1, length(variables), NULL)
    
    // Get a list of vector to recast indices
    for (i = 1; i <= length(variables); i++) {
        if (variables[i].type == "string") {
            tables[i] = &variables[i].reorder_levels()
        }
    }
    
    if (tables != J(1, length(variables), NULL)) {
        reindex_levels_arms(arms, tables)
    }
}

void function reindex_levels_arms(
    class Arm vector arms,
    pointer(real colvector) vector tables
) {
    real scalar i
    
    // Get a list of vector to recast indices
    for (i = 1; i < length(arms); i++) {
        reindex_levels_arm(arms[i], tables)
    }
}

void function reindex_levels_arm(
    class Arm scalar arm,
    pointer(real colvector) vector tables
) {
    reindex_levels_pattern(*arm.lhs.pattern, tables)
}

void function reindex_levels_pattern(
    transmorphic scalar pattern,
    pointer(real colvector) vector tables
) {
    if (structname(pattern) == "PEmpty") {
        // Nothing
    }
    else if (structname(pattern) == "PWild") {
        reindex_levels_pwild(pattern, tables)
    }
    else if (structname(pattern) == "PConstant") {
        reindex_levels_pconstant(pattern, tables)
    }
    else if (structname(pattern) == "PRange") {
        reindex_levels_prange(pattern, tables)
    }
    else if (structname(pattern) == "POr") {
        reindex_levels_por(pattern, tables)
    }
    else if (structname(pattern) == "Tuple") {
        reindex_levels_tuple(pattern, tables)
    }
    else {
        // TODO: improve error
        unknown_pattern(pattern)
    }
}

void function reindex_levels_pwild(
    struct PWild scalar pwild,
    pointer(real colvector) vector tables
) {
    reindex_levels_por(pwild.values, tables)
}

void function reindex_levels_pconstant(
    struct PConstant scalar pconstant,
    pointer(real colvector) scalar tables
) {
    if (tables != NULL) {
        pconstant.value = (*tables)[pconstant.value]
    }
}

void function reindex_levels_prange(
    struct PRange scalar prange,
    pointer(real colvector) scalar tables
) {
    if (tables != NULL) {
        prange.min = (*tables)[prange.min]
        prange.max = (*tables)[prange.max]
    }
}

void function reindex_levels_por(
    struct POr scalar por,
    pointer(real colvector) vector tables
) {
    real scalar i
    
    for (i = 1; i <= por.length; i++) {
        reindex_levels_pattern(*por.patterns[i], tables)
    }
}

void function reindex_levels_tuple(
    struct Tuple scalar tuple,
    pointer(real colvector) vector tables
) {
    real scalar i
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        if (tables[i] != NULL) {
            reindex_levels_pattern(tuple.patterns[i], tables[i])
        }
    }
}
end


**#********************************************************* src/usefulness.mata

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
            
            if (structname(*overlap) != "PEmpty") {
                str = str,
                    sprintf("    Arm %f: %s", lhs.arm_id, ::to_string(*overlap))
            }
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


**#******************************************************* src/match_report.mata

mata

void Match_report::new() {}

string vector Match_report::to_string() {
    class Usefulness scalar usefulness
    string vector strings
    real scalar i
    
    strings = J(1, 0, "")

    for (i = 1; i <= length(this.usefulness); i++) {
        usefulness = this.usefulness[i]
        strings = strings, usefulness.to_string()
    }

    if (length(*this.missings) == 0) {
        return(strings)
    }

    if (structname(*this.missings) == "PEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (structname(*this.missings) == "POr") {
        strings = strings, to_string_por(*this.missings)
    }
    else {
        strings = strings, to_string_pattern(*this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(transmorphic scalar pattern) {
    return(sprintf("    %s", ::to_string(pattern)))
}

string vector Match_report::to_string_por(struct POr scalar por) {
    string vector strings
    real scalar i

    strings = J(1, por.length, "")
    
    for (i = 1; i <= por.length; i++) {
        strings[i] = this.to_string_pattern(*por.patterns[i])
    }
    
    return(strings)
}

void Match_report::print() {
    string vector strings
    real scalar i

    strings = this.to_string()

    displayas("error")
    for (i = 1; i <= length(strings); i++) {
        printf("    %s\n", strings[i])
    }
}

end


**#********************************************************** src/algorithm.mata

mata

////////////////////////////////////////////////////////////////// Main function

void function check_match( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    pointer scalar missings
    class Arm scalar arm
    class Arm vector useful_arms
    real scalar i

    bench_on("- usefulness")
    report.usefulness = check_useful(arms)
    bench_off("- usefulness")

    useful_arms = Arm(0)

    bench_on("- combine")
    for (i = 1; i <= length(report.usefulness); i++) {
        usefulness = report.usefulness[i]
        if (usefulness.useful == 1) {
            arm = arms[i]
            arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, arm
        }
    }
    bench_off("- combine")

    bench_on("- exhaustiveness")
    missings = &check_exhaustiveness(useful_arms, variables)
    bench_off("- exhaustiveness")
    
    bench_on("- compress")
    report.missings = &compress(*missings)
    bench_off("- compress")

    bench_on("- print")
    report.print()
    bench_off("- print")
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
        bench_on("  - is_useful() 1")
        usefulness = is_useful(arms[i], useful_arms)
        bench_off("  - is_useful() 1")
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
    pointer scalar tuple, differences
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    class Usefulness scalar result
    class Arm scalar ref_arm
    pointer scalar overlap_i
    real scalar i, k

    lhs_empty.pattern = &(PEmpty())

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

        bench_on("+ Overlap()")
        overlap_i = &overlap(*tuple, *ref_arm.lhs.pattern)
        bench_off("+ Overlap()")
        
        if (structname(*overlap_i) != "PEmpty") {
            k++
            overlaps[k].pattern = overlap_i
            overlaps[k].arm_id = ref_arm.id
            bench_on("+ Difference()")
            differences = difference(*differences, *overlap_i)
            bench_off("+ Difference()")
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
        
        if (structname(*differences) == "PEmpty") {
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

function get_and_compress(struct LHS vector overlaps, i) {
    return(&compress(*overlaps[i].pattern))
}

///////////////////////////////////////////////////////////// Check completeness

class Tuple vector function check_exhaustiveness( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Arm scalar wild_arm
    struct PWild vector pwilds
    struct Tuple scalar tuple
    class Usefulness scalar usefulness
    real scalar i

    pwilds = PWild(length(variables))

    for (i = 1; i <= length(variables); i++) {
        define_pwild(pwilds[i], variables[i])
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

    bench_on("  - is_useful() 2")
    usefulness = is_useful(wild_arm, arms)
    bench_off("  - is_useful() 2")

    return(*usefulness.differences)
}

end


**#************************************************************* src/pmatch.mata

// Main function for the `pmatch` command
// The bench_on() and // bench_off() functions are not used in the online code)

mata
function pmatch(
    string scalar newvar,
    string scalar vars_exp,
    string scalar body,
    real   scalar check,
    real   scalar gen_first,
    string scalar dtype
) {
    class Variable vector variables
    class Arm vector arms, useful_arms

    bench_on("total")
    
    bench_on("init")
    variables = init_variables(vars_exp, check)
    bench_off("init")
    
    bench_on("parse")
    arms = parse_string(body, variables, check)
    bench_off("parse")
    
    bench_on("check")
    if (check) {
        check_match(arms, variables)
    }
    bench_off("check")
    
    bench_on("eval")
    eval_arms(newvar, arms, variables, gen_first, dtype)
    bench_off("eval")

    bench_off("total")
}
end


**#************************************************************** src/pmatch.ado

// pmatch command
// see "src/pmatch.mata" for the entry point in the algorithm

program pmatch
    syntax namelist(min=1 max=2), ///
        Variables(varlist min=1) Body(str asis) ///
        [REPLACE NOCHECK]
    
    local check = ("`nocheck'" == "")
    local dtype = ""
    
    if (wordcount("`namelist'") == 2) {
        local dtype    = word("`namelist'", 1)
        local namelist = word("`namelist'", 2)
        check_dtype `dtype', `replace'
    }
    
    check_replace `namelist', `replace'
    local gen_first = ("`replace'" == "")

    mata: pmatch("`namelist'", "`variables'", `"`body'"', `check', `gen_first', "`dtype'")
end

// Util functions to check the inputs

// Check that replace is correctly used for new and existing variable names
program check_replace
    syntax namelist(min=1 max=1), [REPLACE]
    
    local gen_first = ("`replace'" == "")
    
    if (`gen_first') {
        capture confirm new variable `namelist'
        
        if (_rc == 110) {
            dis as error in smcl "variable {bf:`namelist'} already defined, use the 'replace' option to overwrite it"
            exit 110
        }
        else if (_rc != 0) {
            // Should be covered by the syntax command
            exit _rc
        }
    }
    else {
        capture confirm variable `namelist'
        
        if (_rc == 111) {
            dis as error in smcl "variable {bf:`namelist'} not found, option 'replace' cannot be used"
            exit 111
        }
        else if (_rc != 0) {
            // Should be covered by the syntax command
            exit _rc
        }
    }
end

// If two names are provided, check that the first is a data type
program check_dtype
    syntax namelist(min=1 max=1), [REPLACE]
    
    scalar is_dtype = 0
    
    if (inlist("`namelist'", "byte", "int", "long", "float", "double", "strL")) {
        scalar is_dtype = 1
    }
    else if (regexm("`namelist'", "^str")) {
        local str_end = regexr("`namelist'", "^str", "")
        local str_end = real("`str_end'")
        if (`str_end' == int(`str_end') & `str_end' >= 1 & `str_end' <= 2045) {
            scalar is_dtype = 1
        }
    }
    
    if (!is_dtype) {
        dis as error in smcl "{bf:`dtype'} is not a data type, too many variables specified"
        exit 103
    }
    
    if ("`replace'" != "") {
        dis as error in smcl "options {bf:data type `namelist'} and {bf:replace} may not be combined"
        exit 184
    }
end

