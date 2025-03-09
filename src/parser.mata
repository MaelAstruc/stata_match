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
