*! version 0.0.17  09 Mar 2025

**#************************************************************ src/declare.mata

//////////////////////////////////////////////////////////////////// Local types

local T              transmorphic      matrix
local POINTER        pointer           scalar
local POINTERS       pointer           vector
local REAL           real              scalar
local STRING         string            scalar
local STRINGS        string            vector

local PATTERN        real              matrix

local EMPTY          real              rowvector
local WILD           real              matrix
local CONSTANT       real              rowvector
local RANGE          real              rowvector
local OR             real              matrix

local EMPTY_TYPE     0
local WILD_TYPE      1
local CONSTANT_TYPE  2
local RANGE_TYPE     3
local OR_TYPE        4

local INT_TYPE       1
local FLOAT_TYPE     2
local DOUBLE_TYPE    3
local STRING_TYPE    4

local TUPLEEMPTY     struct TupleEmpty scalar
local TUPLEOR        struct TupleOr    scalar
local TUPLE          struct Tuple      scalar
local TUPLEWILD      struct TupleWild  scalar

local VARIABLE       class Variable    scalar
local VARIABLES      class Variable    vector

local ARM            class Arm         scalar
local ARMS           class Arm         vector

mata
mata set matastrict on

//////////////////////////////////////////////////////////////////////// Pattern

// Empty pattern
// Simple vector with 4 columns
// (0, 0, 0, 0)

// Wild card '_'
// Matrix with first row for type
// Following rows for levels patterns similar to POr
// (1, number_values, 0, 0)
// (...)

// Constant
// Simple vector with 4 columns
// (2, value, value, variable_type)

// Real or Float Range
// Simple vector with 4 columns
// (3, min, max, variable_type)

// Or pattern
// Matrix with first row for type and number of patterns
// Following rows for patterns patterns similar to POr
// (4, number_values, 0, 0)
// (...)

struct TupleEmpty { }

struct TupleWild { }

struct Tuple {
    // Members
    real scalar arm_id                                                          // The corresponding arm #
    pointer(`PATTERN') vector patterns                                          // An array of patterns
}

struct TupleOr {
    // Members
    pointer(struct Tuple vector) scalar list                                    // A dynamic array of patterns
    real scalar length
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


**#************************************************************** src/utils.mata


mata

`REAL' isbool(`REAL' x) {
    return(x == 0 | x == 1)
}

`REAL' isint(`REAL' x) {
    return(x == trunc(x))
}

void check_var_type(`REAL' variable_type) {
    if (!isint(variable_type) | variable_type < 0 | variable_type > 4) {
        errprintf(
            "Variable type number field should be 1, 2, 3 or 4: found %f\n",
            variable_type
        )
        exit(_error(3498))
    }
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

end


**#********************************************************** src/interface.mata

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


**#************************************************************ src/pattern.mata

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


**#************************************************************* src/tuples.mata

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

    // profiler_on("compress_tuple")
    
    tuple_compressed.arm_id = tuple.arm_id
    tuple_compressed.patterns = J(length(tuple.patterns), 1, NULL)
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        tuple_compressed.patterns[i] = &compress(*tuple.patterns[i])
        if ((*tuple_compressed.patterns[i])[1, 1] == `EMPTY_TYPE') {
            // profiler_off()
            return(TupleEmpty())
        }
    }

    // profiler_off()
    
    return(tuple_compressed)
}

`T' compress_tupleor(`TUPLEOR' tuples) {
    `TUPLEOR' tuples_compressed
    `POINTER' pattern_compressed
    `REAL' i
    
    // profiler_on("compress_tupleor")
    
    tuples_compressed = new_tupleor()
    
    for (i = 1; i <= tuples.length; i++) {
        pattern_compressed = &compress(*tuples.list[i])
        if (structname(*pattern_compressed) == "TupleEmpty") {
            continue
        }
        else if (structname(*pattern_compressed) == "TupleWild") {
            // profiler_off()
            return(*pattern_compressed)
        }
        else {
            if (!includes_tupleor(tuples_compressed, *pattern_compressed)) {
                push_tupleor(tuples_compressed, *pattern_compressed) 
            }
        }
    }
    
    // profiler_off()
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
    
    // profiler_on("overlap_tuple_tuple")
    
    check_tuples(tuple_1, tuple_2)
    
    tuple_overlap.patterns = J(1, length(tuple_1.patterns), NULL)

    // We compute the overlap of each pattern in the tuple
    for (i = 1; i <= length(tuple_1.patterns); i++) {
        tuple_overlap.patterns[i] = &overlap(
            *tuple_1.patterns[i],
            *tuple_2.patterns[i]
        )
        if ((*tuple_overlap.patterns[i])[1, 1] == 0) {
            // profiler_off()
            return(TupleEmpty())
        }
    }

    // profiler_off()
    return(tuple_overlap)
}

`T' overlap_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `TUPLEOR' tuples_overlap
    `REAL' i
    `T' res
    
    // profiler_on("overlap_tuple_tupleor")
    
    tuples_overlap = new_tupleor()
    
    tuples_overlap.list = J(1, length(tuples.list), NULL)
    
    for (i = 1; i <= tuples.length; i++) {
        push_tupleor(tuples_overlap, overlap_tuple_tuple(tuple, *tuples.list[i]))
    }
    
    res = compress(tuples_overlap)
    
    // profiler_off()
    return(res)
}

`T' overlap_tupleor(`TUPLEOR' tuples, `T' pattern) {
    `TUPLEOR' tuples_overlap
    `POINTER' overlap
    `REAL' i
    
    // profiler_on("overlap_tupleor")
    
    if (structname(pattern) == "TupleEmpty") {
        // profiler_off()
        return(TupleEmpty())
    }
    if (structname(pattern) == "TupleWild") {
        // profiler_off()
        return(tuples)
    }
    
    tuples_overlap = new_tupleor()

    for (i = 1; i <= tuples.length; i++) {
        overlap = &overlap(*tuples.list[i], pattern)
        if (structname(*overlap) == "TupleEmpty") {
            continue
        }
        else if (structname(*overlap) == "TupleWild") {
            // profiler_off()
            return(*overlap)
        }
        else {
            if (!includes_tupleor(tuples_overlap, *overlap)) {
                push_tupleor(tuples_overlap, *overlap)
            }
        }
    }
    
    // profiler_off()
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
    
    // profiler_on("includes_tuple_tuple")
    
    check_tuples(tuple_1, tuple_2)
    
    for (i = 1; i <= length(tuple_1.patterns); i++) {
        if (!includes(*tuple_1.patterns[i], *tuple_2.patterns[i])) {
            // profiler_off()
            return(0)
        }
    }

    // profiler_off()
    return(1)
}

`REAL' includes_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `REAL' i
    
    // profiler_on("includes_tuple_tupleor")
    
    for (i = 1; i <= tuples.length; i++) {
        if (!includes_tuple(tuple, *tuples.list[i])) {
            // profiler_off()
            return(0)
        }
    }

    // profiler_off()
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
    
    // profiler_on("includes_tuples_tuple")
    
    difference = difference_list_tupleor(tuple, tuples)
    
    n_pat = 0
    
    for (i = 1; i <= length(difference); i++) {
        if (difference[i] == NULL) break
        n_pat++
    }
    
    // profiler_off()
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
    
    // profiler_on("difference_tuple_tuple")
    
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
    
    // profiler_off()
    return(compress(result))
}

`TUPLE' tuple_from_patterns(`POINTERS' patterns) {
    `TUPLE' tuple

    tuple.patterns = patterns
    
    return(tuple)
}

`T' difference_tuple_tupleor(`TUPLE' tuple, `TUPLEOR' tuples) {
    `TUPLEOR' tuples_result
    `T' res
    
    // profiler_on("difference_tuple_tupleor")
    
    tuples_result = new_tupleor()
    
    append_tupleor(tuples_result, difference_list_tupleor(tuple, tuples))
    
    res = compress(tuples_result)
    
    // profiler_off()
    return(res)
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
    
    // profiler_on("difference_tupleor_tuple")
    
    tuples_differences = new_tupleor()
    
    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= tuples.length; i++) {
        push_tupleor(tuples_differences, difference(*tuples.list[i], tuple))
    }
    
    // profiler_off()
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
    
    // profiler_on("difference_list_tupleor")
    
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
    
    // profiler_off()
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
    
    H          = Htable()
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
    
    // profiler_on("htable_expand")
    
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
    
    
    // profiler_off()
}

transmorphic colvector htable_keys(struct Htable H) {
    return(sort(select(H.keys, H.status)', 1))
}

end


**#*********************************************************** src/variable.mata

mata
`VARIABLES' init_variables(`STRING' vars_exp, `REAL' check) {
    `VARIABLES' variables
    `POINTER'   t
    `REAL'      i, n_vars
    `STRINGS'   vars_str
    
    // profiler_on("init_variables")
    
    t = tokeninit()
    tokenset(t, vars_exp)
    
    vars_str = tokengetall(t)
    
    n_vars = length(vars_str)
    
    variables = Variable(n_vars)
    
    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i], check)
    }
    
    // profiler_off()
    
    return(variables)
}

void Variable::new() {}

`STRING' Variable::to_string() {
    string rowvector levels_str
    `STRING' res
    `REAL' i

    // profiler_on("Variable::to_string()")
    
    levels_str = J(1, length(this.levels), "")

    if (this.type == "string") {
        levels_str = this.levels'
    }
    else {
        levels_str = strofreal(this.levels)'
    }
    
    res = sprintf(
        "'%s' (%s): (%s)",
        this.name,
        this.type,
        invtokens(levels_str)
    )
    
    // profiler_off()
    
    return(res)
}

void Variable::print() {
    printf("%s", this.to_string())
}

void Variable::init(`STRING' variable, `REAL' check) {
    // profiler_on("Variable::init")
    
    this.name = variable
    this.levels_len = 0
    this.min = .a
    this.max = .a
    this.check  = check
    this.sorted = check
    
    this.init_type()
    this.init_levels()
    
    // profiler_off()
}

void Variable::init_type() {
    `STRING' var_type
    
    // profiler_on("Variable::init_type")
    
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
        // profiler_off()
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
    
    // profiler_off()
}
end

// Different functions based on the `levelsof` command
local N_MATA_SORT 2000
local N_SAMPLE    200
local N_USE_TAB   50
local N_MATA_HASH 100000

mata
void Variable::init_levels() {
    // profiler_on("Variable::init_levels")
    
    if (this.check == 0) {
        // profiler_off()
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
    
    // profiler_off()
}

void Variable::init_levels_int() {
    // profiler_on("Variable::init_levels_int")
    
    if (st_nobs() < `N_MATA_SORT') {
        this.init_levels_int_base()
    }
    if (this.should_tab()) {
        this.init_levels_tab()
    }
    else {
        this.init_levels_int_base()
    }
    
    // profiler_off()
}

void Variable::init_levels_float() {
    // profiler_on("Variable::init_levels_float")
    
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
    
    // profiler_off()
}

void Variable::init_levels_string() {
    // profiler_on("Variable::init_levels_string")
    
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
    
    // profiler_off()
}

void Variable::init_levels_int_base() {
    // profiler_on("Variable::init_levels_int_base")
    
    real colvector x
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowsofinteger(x)
    
    // profiler_off()
}

void Variable::init_levels_float_base() {
    real colvector x
    
    // profiler_on("Variable::init_levels_float_base")
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowssort(x)
    
    // profiler_off()
}

// Similar to the `levelsof` command internals
// Removed some things not needed such as the frequency
// Benchmarks in dev/benchmark/levelsof_strL.do
void Variable::init_levels_strL() {
    `STRING' n_init, indices
    real matrix cond, i, w
    
    // profiler_on("Variable::init_levels_strL")
    
    n_init = st_tempname()
    indices = st_tempname()
    
    stata("gen " + n_init + " = _n")
    stata("bysort " + this.name + ": gen " + indices + " = _n == 1")
     
    st_view(cond, ., indices)
    maxindex(cond, 1, i, w)
    
    this.levels = st_sdata(i, this.name)
    
    stata("sort " + n_init)
    
    // profiler_off()
}

void Variable::init_levels_strN() {
    string colvector x
    
    // profiler_on("Variable::init_levels_strN")
    
    st_sview(x = "", ., this.name)

    this.levels = uniqrowssort(x)
    
    // profiler_off()
}

void Variable::init_levels_tab() {
    `STRING' matname
    
    // profiler_on("Variable::init_levels_tab")
    
    matname = st_tempname()
    
    stata("quietly tab " + this.name + ", missing matrow(" + matname + ")")
    this.levels = st_matrix(matname)
    
    // profiler_off()
}

void Variable::init_levels_hash() {
    transmorphic vector x
    transmorphic scalar key
    struct Htable scalar levels
    real scalar n, h, res, i
    
    // profiler_on("Variable::init_levels_hash")

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
    
    // profiler_off()
}

real scalar Variable::should_tab() {
    `REAL'          n, s, N, S, multi
    `STRING'        state
    real colvector  x, y
    real matrix     t
    
    // profiler_on("Variable::should_tab")
    
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
        // profiler_off()
        return(0)
    }

    // Compute the number of unique values that appear only once
    s = sum(t[., 2] :== 1)
    
    // Estimate multiplicity in the sample
    multi = multiplicity(sum(t[., 2] :== 1), rows(t))
    
    // profiler_off()
    return(multi <= `N_USE_TAB')
}

void Variable::quote_levels() {
    `REAL' i
    
    // profiler_on("Variable::quote_levels")
    
    for (i = 1; i <= length(this.levels); i++) {
        this.levels[i] = `"""' + this.levels[i] + `"""'
    }
    
    // profiler_off()
}

real scalar Variable::get_level_index(transmorphic scalar level) {
    `REAL' index
    
    // profiler_on("Variable::get_level_index")
    
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
    
    // profiler_off()
    return(index)
}

real scalar binary_search(pointer(transmorphic vector) vec, `REAL' length, transmorphic scalar value) {
    `REAL' left, right, i
    transmorphic scalar val
    
    // profiler_on("binary_search")
    
    left = 1
    right = length
    
    while (left <= right) {
        i = floor((left + right) / 2)
        val = (*vec)[i]
        
        if (value == val) {
            // profiler_off()
            return(i)
        }
        else if (value < val) {
            right = i - 1
        }
        else {
            left = i + 1
        }
    }
    
    // profiler_off()
    
    return(0)
}

void Variable::set_minmax() {
    real vector x_num, minmax
    
    // profiler_on("Variable::set_minmax")
    
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
    // profiler_off()
}

real scalar Variable::get_min() {
    // profiler_on("Variable::get_min")
    
    if (this.min == .a) {
        this.set_minmax()
    }
    
    // profiler_off()
    return(this.min)
}

real scalar Variable::get_max() {
    // profiler_on("Variable::get_max")
    
    if (this.max == .a) {
        this.set_minmax()
    }
    
    // profiler_off()
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
        errprintf("Unknown variable type %s", this.type)
        exit(_error(3300))
    }
}

// We use the level indices for string variables
// If the checks are skipped, they are obtained during parsing
// In this case they are not ordered and need to be sorted afterwards
real colvector Variable::reorder_levels() {
    real vector indices, new_indices
    transmorphic matrix table
    `REAL' i, k
    
    // profiler_on("Variable::reorder_levels")
    
    if (this.type != "string" | this.check == 1) {
        // TODO: improve error
        // profiler_off()
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
    // profiler_off()
    return(table[., 2])
}
end

**#************************************************************** Levelsof utils

mata
// From levelsof functions
real scalar multiplicity(`REAL' s, `REAL' n) {
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
    `STRING' varname,
    `ARMS' arms,
    `VARIABLES' variables,
    `REAL' gen_first,
    `STRING' dtype
) {
    `ARM' arm
    `POINTER' pattern
    `STRING' command, condition, statement
    `REAL' i, n, _rc

    // profiler_on("eval_arms")
    
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
    
    // profiler_off()
}

end


**#************************************************************* src/parser.mata

mata

`ARMS' parse_string(`STRING' str, `VARIABLES' variables, `REAL' check) {
    `ARMS' arms
    `POINTER' t

    // profiler_on("parse_string")
    
    t = tokenize(str)

    arms = parse_arms(t, variables)
    
    if (check == 0) {
        reorder_levels(arms, variables)
    }
    
    // profiler_off()
    return(arms)
}

`ARMS' parse_arms(`POINTER' t, `VARIABLES' variables) {
    `ARM' arm
    `ARMS' arms
    `REAL' i

    // profiler_on("parse_arms")
    
    arms = Arm(0)
    i = 0

    while (tokenpeek(t) != "") {
        arm = parse_arm(t, ++i, variables)
        
        if (structname(*arm.lhs.pattern) == "TupleEmpty") {
            errprintf("Arm %f is considered empty\n", i)
        }
        else if (isreal(*arm.lhs.pattern) & (*arm.lhs.pattern)[1, 1] == `EMPTY_TYPE') {
            errprintf("Arm %f is considered empty\n", i)
        }
        else {
            arms = arms, arm
        }
    }

    // profiler_off()
    return(arms)
}

`ARM' parse_arm(`POINTER' t, `REAL' arm_id, `VARIABLES' variables) {
    `ARM' arm

    // profiler_on("parse_arm")
    
    arm.id = arm_id
    arm.lhs.arm_id = arm_id

    if (length(variables) == 1) {
        arm.lhs.pattern = &parse_or(t, variables[1], arm_id)
    }
    else {
        arm.lhs.pattern = &parse_tupleor(t, variables, arm_id)
    }

    check_next(t, "=", arm_id)

    arm.value = parse_value(t)
    
    arm.has_wildcard = check_wildcard(arm.lhs.pattern)

    // profiler_off()
    return(arm)
}

`PATTERN' parse_pattern(`POINTER' t, `VARIABLE' variable, `REAL' arm_id) {
    `STRING' tok, var_label
    `REAL' number
    `PATTERN' res

    // profiler_on("parse_pattern")
    
    tok = tokenget(t)

    if (variable.type == "string") {
        if (tok == "_") {
            res = parse_wild(variable)
        }
        else if (isquoted(tok)) {
            number = variable.get_level_index(tok)
            if (number == 0) {
                errprintf("Unknown level : %s\n", tok)
                res = new_pempty()
            }
            else {
                res = parse_constant(number, variable)
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
            res = parse_wild(variable)
        }
        else if (tok == "min") {
            number =  variable.get_min()
            res = parse_number(t, number, arm_id, variable)
        }
        else if (tok == "max") {
            number = variable.get_max()
            res = parse_number(t, number, arm_id, variable)
        }
        else if (isnumber(tok)) {
            number = strtoreal(tok)
            res = parse_number(t, number, arm_id, variable)
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
                res = parse_number(t, number, arm_id, variable)
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
    
    // profiler_off()
    return(res)
}

`PATTERN' parse_number(
    `POINTER' t,
    `REAL' number,
    `REAL' arm_id,
    `VARIABLE' variable
) {
    `STRING' next
    `PATTERN' res

    // profiler_on("parse_number")
    
    next = tokenpeek(t)
    
    if (israngesym(next)) {
        (void) tokenget(t)
        res = parse_range(t, next, number, arm_id, variable)
    }
    else {
        res = parse_constant(number, variable)
    }
    
    // profiler_off()
    return(res)
}

///////////////////////////////////////////////////////////////// Parse patterns

`EMPTY' parse_empty(`VARIABLE' variable) {
    return(new_pempty())
}

`WILD' parse_wild(`VARIABLE' variable) {
    return(new_pwild(variable))
}

`CONSTANT' parse_constant(`REAL' value, `VARIABLE' variable) {
    return(new_pconstant(value, variable.get_type_nb()))
}

`RANGE' parse_range(
    `POINTER' t,
    `STRING' symbole,
    `REAL' min,
    `REAL' arm_id,
    `VARIABLE' variable
) {
    `RANGE' prange
    `STRING' next
    `REAL' max, epsilon, var_type
    
    // profiler_on("parse_range")
    
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
    
    var_type = variable.get_type_nb()
    
    if (symbole == "/") {
    }
    else if (symbole == "!/") {
        min = min + get_epsilon(min, var_type)
    }
    else if (symbole == "/!") {
        max = max - get_epsilon(max, var_type)
    }
    else if (symbole == "!!") {
        min = min + get_epsilon(min, var_type)
        max = max - get_epsilon(max, var_type)
    }
    else {
        errprintf("Unexpected symbole: %s\n", symbole)
        exit(_error(3498))
    }

    // profiler_off()
    return(new_prange(min, max, var_type))
}

// We to shift the epsilon depending on the precision of x in base 2
`REAL' get_epsilon(`REAL' x, `REAL' type_nb) {
    `REAL' epsilon, epsilon0, x_log2, epsilon_log2, epsilon0_log2
    
    // We define epsilon and epsilon0 depending on the type
    //    epsilon  is the smallest 'e' such that x != x + e
    //    epsilon0 is the smallest 'e' such that 0 != 0 + e
    
    if (type_nb == 1 | type_nb == 4) {
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
        errprintf("Expected a variable type 1, 2, 3 or 4, found %f", type_nb)
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

`OR' parse_or(`POINTER' t, `VARIABLE' variable, `REAL' arm_id) {
    `OR' por
    `PATTERN' pat

    // profiler_on("parse_or")
    
    por = new_por()
    
    do {
        pat = parse_pattern(t, variable, arm_id)
        
        if (pat[1, 1] == `WILD_TYPE') {
            // profiler_off()
            return(pat)
        }
        else {
            push_por(por, pat)
        }
    } while (match_next(t, "|"))

    por = compress_por(por)
    
    // profiler_off()
    return(por)
}

`TUPLE' parse_tuple(`POINTER' t, `VARIABLES' variables, `REAL' arm_id) {
    `TUPLE' tuple
    `REAL' i

    // profiler_on("parse_tuple")
    
    tuple.patterns = J(1, length(variables), NULL)

    i = 0
    
    if (tokenpeek(t) == "_") {
        // profiler_off()
        return(TupleWild())
    }
    
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

    // profiler_off()
    return(tuple)
}

`TUPLEOR' parse_tupleor(`POINTER' t, `VARIABLES' variables, `REAL' arm_id) {
    `TUPLEOR' tuples
    
    // profiler_on("parse_tupleor")
    
    tuples = new_tupleor()

    do {
        push_tupleor(tuples, parse_tuple(t, variables, arm_id))
    } while (match_next(t, "|"))
    
    tuples = compress_tupleor(tuples)
    
    // profiler_off()
    return(tuples)
}

//////////////////////////////////////////////////////////////////// Parse Value

`STRING' parse_value(`POINTER' t) {
    return(consume(t, ","))
}

////////////////////////////////////////////////////////////////////////// Utils

`POINTER' tokenize(`STRING' str) {
    `POINTER' t
    
    t = tokeninitstata()
    tokenpchars(t, ("=", ",", "/", "!/", "/!", "!!", "(", ")", "|"))
    tokenset(t, str)
    
    return(t)
}

`STRING' consume(`POINTER' t, `STRING' str) {
    `STRING' tok, inside, value

    // profiler_on("consume")
    
    value = ""
    while (tokenpeek(t) != str & tokenpeek(t) != "") {
        tok = tokenget(t)
        if (tok == "(") {
            inside = consume(t, ")") + ")"
        }
        value = value + tok + inside
    }
    (void) tokenget(t)
    
    // profiler_off()
    return(value)
}

`REAL' match_next(`POINTER' t, `STRING' str) {
    `STRING' next
    
    next = tokenpeek(t)
    
    if (next == str) {
        (void) tokenget(t)
        return(1)
    }
    else {
        return(0)
    }
}

void check_next(`POINTER' t, `STRING' str, `REAL' arm_id) {
    `STRING' next

    next = tokenget(t)
    
    if (next != str) {
        errprintf("Expect '%s' in arm %f, found: '%s'\n", str, arm_id, next)
        exit(_error(3499))
    }
}

`REAL' isnumber(`STRING' str) {
    return(str == "." | strtoreal(str) != .)
}

`REAL' isquoted(`STRING' str) {
    return(strmatch(str, `""*""'))
}

`STRING' unquote(`STRING' str) {
    return(ustrregexra(str, `"(^"|"$)"', ""))
}

`REAL' israngesym(`STRING' str) {
    return(str == "/" | str == "!/" | str == "/!" | str == "!!")
}

`REAL' check_wildcard(`T' pattern) {
    if (eltype(pattern) == "pointer") {
        return(check_wildcard(*pattern))
    }
    else if (eltype(pattern) == "real") {
        if (pattern[1, 1] == `EMPTY_TYPE') {
            return(0)
        }
        else if (pattern[1, 1] == `WILD_TYPE') {
            return(1)
        }
        else if (pattern[1, 1] == `CONSTANT_TYPE') {
            return(0)
        }
        else if (pattern[1, 1] == `RANGE_TYPE') {
            return(0)
        }
        else if (pattern[1, 1] == `OR_TYPE') {
            return(check_wildcard_por(pattern))
        }
    }
    else if (eltype(pattern) == "struct") {
        if (structname(pattern) == "Tuple") {
            return(check_wildcard_tuple(pattern))
        }
        else if (structname(pattern) == "TupleEmpty") {
            return(0)
        }
        else if (structname(pattern) == "TupleWild") {
            return(1)
        }
        else if (structname(pattern) == "TupleOr") {
            return(check_wildcard_tupleor(pattern))
        }
    }
    
    // If no early return
    unknown_pattern(pattern)
}

`REAL' check_wildcard_por(`OR' por) {
    `REAL' i
    
    // profiler_on("check_wildcard_por")
    
    for (i = 1; i <= por[1, 2]; i++) {
        if (check_wildcard(por[i + 1, 1]) == 1) {
            // profiler_off()
            return(1)
        }
    }
    
    // profiler_off()
    return(0)
}

`REAL' check_wildcard_tuple(`TUPLE' tuple) {
    `REAL' i
    
    // profiler_on("check_wildcard_tuple")
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        if (check_wildcard(*tuple.patterns[i]) == 1) {
            // profiler_off()
            return(1)
        }
    }
    
    // profiler_off()
    return(0)
}

`REAL' check_wildcard_tupleor(`TUPLEOR' tuples) {
    `REAL' i
    
    // profiler_on("check_wildcard_tuplepor")
    
    for (i = 1; i <= tuples.length; i++) {
        if (check_wildcard(*tuples.list[i]) == 1) {
            // profiler_off()
            return(1)
        }
    }
    
    // profiler_off()
    return(0)
}

void reorder_levels(`ARMS' arms, `VARIABLES' variables) {
    `REAL' i
    pointer(real colvector) vector tables
    
    // profiler_on("reorder_levels")
    
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
    
    // profiler_off()
}

void reindex_levels_arms(
    `ARMS' arms,
    pointer(real colvector) vector tables
) {
    `REAL' i
    
    // profiler_on("reindex_levels_arms")
    
    // Get a list of vector to recast indices
    for (i = 1; i <= length(arms); i++) {
        reindex_levels_arm(arms[i], tables)
    }
    
    // profiler_off()
}

void reindex_levels_arm(
    `ARM' arm,
    pointer(real colvector) vector tables
) {
    // profiler_on("reindex_levels_arm")
    
    reindex_levels_pattern(*arm.lhs.pattern, 1, tables)
    
    // profiler_off()
}

void reindex_levels_pattern(
    `T' pattern,
    `REAL' index,
    pointer(real colvector) vector tables
) {
    // profiler_on("reindex_levels_pattern")
    
    if (eltype(pattern) == "real") {
        if (pattern[1, 1] == `EMPTY_TYPE') {
            // Nothing
        }
        else if (pattern[index, 1] == `WILD_TYPE') {
            reindex_levels_pwild(pattern, index, tables)
        }
        else if (pattern[index, 1] == `CONSTANT_TYPE') {
            reindex_levels_pconstant(pattern, index, tables)
        }
        else if (pattern[index, 1] == `RANGE_TYPE') {
            reindex_levels_prange(pattern, index, tables)
        }
        else if (pattern[index, 1] == `OR_TYPE') {
            reindex_levels_por(pattern, index, tables)
        }
        else {
            unknown_pattern(pattern)
        }
    }
    else if (eltype(pattern) == "struct") {
        if (structname(pattern) == "Tuple") {
            reindex_levels_tuple(pattern, tables)
        }
        else if (structname(pattern) == "TupleEmpty") {
            // Nothing
        }
        else if (structname(pattern) == "TupleWild") {
            // TODO: Implement it
            // reindex_levels_tuplewild(pattern, tables)
            errprintf("Wild card for tuples is not implemented yet")
            exit(9999)
        }
        else if (structname(pattern) == "TupleOr") {
            reindex_levels_tupleor(pattern, tables)
        }
        else {
            unknown_pattern(pattern)
        }
    }
    else {
        unknown_pattern(pattern)
    }
    
    // profiler_off()
}

void reindex_levels_pwild(
    `PATTERN' pwild,
    `REAL' index,
    pointer(real colvector) vector tables
) {
    // profiler_on("reindex_levels_pwild")
    
    // Rebuild the wild pattern
    
    pwild = (`WILD_TYPE' \ J(length(*tables), 1, `CONSTANT_TYPE')) ,
            (length(*tables) \ *tables),
            (0 \ *tables),
            J(length(*tables) + 1, 1, pwild[1, 4])
    
    // profiler_off()
}

void reindex_levels_pconstant(
    `PATTERN' pconstant,
    `REAL' index,
    pointer(real colvector) scalar tables
) {
    `REAL' value
    
    // profiler_on("reindex_levels_pconstant")
    
    if (tables != NULL) {
        value = (*tables)[pconstant[index, 2]]
        pconstant[index, 2] = value
        pconstant[index, 3] = value
    }
    
    // profiler_off()
}

void reindex_levels_prange(
    `PATTERN' prange,
    `REAL' index,
    pointer(real colvector) scalar tables
) {
    // profiler_on("reindex_levels_prange")
    
    if (tables != NULL) {
        prange[index, 2] = (*tables)[prange[index, 2]]
        prange[index, 3] = (*tables)[prange[index, 3]]
    }
    
    // profiler_off()
}

void reindex_levels_por(
    `PATTERN' por,
    `REAL' index,
    pointer(real colvector) vector tables
) {
    `REAL' i
    
    // profiler_on("reindex_levels_por")
    
    for (i = 1; i <= por[1, 2]; i++) {
        reindex_levels_pattern(por, i + 1, tables)
    }
    
    // profiler_off()
}

void reindex_levels_tuple(
    `TUPLE' tuple,
    pointer(real colvector) vector tables
) {
    `REAL' i
    
    // profiler_on("reindex_levels_tuple")
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        if (tables[i] != NULL) {
            reindex_levels_pattern(*tuple.patterns[i], 1, tables[i])
        }
    }
    
    // profiler_off()
}

void reindex_levels_tupleor(
    `TUPLEOR' tuples,
    pointer(real colvector) vector tables
) {
    `REAL' i
    
    // profiler_on("reindex_levels_tupleor")
    
    for (i = 1; i <= tuples.length; i++) {
        reindex_levels_pattern(*tuples.list[i], 1, tables)
    }
    
    // profiler_off()
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
            
            str = str, sprintf("    Arm %f: %s", lhs.arm_id, ::to_string(*overlap))
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

    if ((*this.missings)[1, 1] == `EMPTY_TYPE' | structname(*this.missings) == "TupleEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (eltype(*this.missings) == "real") {
        if ((*this.missings)[1, 1] == `OR_TYPE') {
            strings = strings, to_string_por(*this.missings)
        }
        else {
            strings = strings, to_string_pattern((*this.missings)[1, .])
        }
    }
    else {
        strings = strings, to_string_pattern(*this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(`T' pattern) {
    return(sprintf("    %s", ::to_string(pattern)))
}

string vector Match_report::to_string_por(`POR' por) {
    string vector strings
    `REAL' i, n_pat
    
    n_pat = por[1, 2]

    strings = J(1, n_pat, "")

    for (i = 1; i <= n_pat; i++) {
        strings[i] = this.to_string_pattern(por[i + 1, .])
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

void function check_match(`ARMS' arms, `VARIABLES' variables) {
    class Match_report scalar report
    class Usefulness scalar usefulness
    `POINTER' missings
    `ARM' arm
    `ARMS' useful_arms
    `REAL' i

    // profiler_on("check_match")
    
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
    
    // profiler_off()
}

/////////////////////////////////////////////////////////////// Check usefulness

class Usefulness vector check_useful(`ARMS' arms) {
    `ARMS' useful_arms
    `ARM' new_arm
    class Usefulness scalar usefulness
    class Usefulness vector usefulness_vec
    `REAL' i, n_arms

    // profiler_on("check_useful")
    
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
    
    // profiler_off()
    return(usefulness_vec)
}

class Usefulness scalar function is_useful(`ARM' arm, `ARMS' useful_arms) {
    `POINTER' tuple, differences, overlap_i
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    class Usefulness scalar result
    `ARM' ref_arm
    `REAL' i, k
    
    // profiler_on("is_useful")
    
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

        // profiler_off()
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
        
        if ((*overlap_i)[1, 1] != `EMPTY_TYPE' & structname(*overlap_i) != "TupleEmpty") {
            k++
            overlaps[k].pattern = overlap_i
            overlaps[k].arm_id = ref_arm.id
            bench_on("+ Difference()")
            differences = &difference(*differences, *overlap_i)
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

    // profiler_off()
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

    bench_on("  - is_useful() 2")
    usefulness = is_useful(wild_arm, arms)
    bench_off("  - is_useful() 2")
    
    // profiler_off()
    return(*usefulness.differences)
}

end


**#************************************************************* src/pmatch.mata

// Main function for the `pmatch` command
// The bench_on() and // bench_off() functions are not used in the online code)

mata
void pmatch(
    `STRING' newvar,
    `STRING' vars_exp,
    `STRING' body,
    `REAL'   check,
    `REAL'   gen_first,
    `STRING' dtype
) {
    `VARIABLES' variables
    `ARMS' arms, useful_arms

    // profiler_on("pmatch")
    
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
    
    // profiler_off()
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

