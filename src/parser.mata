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
