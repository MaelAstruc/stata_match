mata

class Arm vector function parse_string( ///
        string scalar str, ///
        class Variable vector variables ///
    ) {
    pointer scalar t

    t = tokenize(str)

    return(parse_arms(&t, variables))
}

class Arm vector function parse_arms ( ///
        pointer t, ///
        class Variable vector variables ///
) {
    class Arm scalar arm
    class Arm vector arms
    real scalar i

    arms = Arm(0)
    i = 0

    while (tokenpeek(*t) != "") {
        arm = parse_arm(t, ++i, variables)
        arms = arms, arm
    }

    return(arms)
}

class Arm scalar function parse_arm ( ///
        pointer t, ///
        real scalar arm_id,
        class Variable vector variables ///
    ) {
    class Arm scalar arm

    arm     = Arm()
    arm.id = arm_id
    arm.lhs.arm_id = arm_id

    if (length(variables) == 1) {
        arm.lhs.pattern = &parse_or(t, variables, arm_id)
    }
    else {
        arm.lhs.pattern = &parse_tuples(t, variables, arm_id)
    }

    check_next(t, "=>", arm_id)

    arm.value = parse_value(t)
    
    arm.has_wildcard = check_wildcard(arm.lhs.pattern)

    return(arm)
}

class Pattern scalar function parse_pattern( ///
    pointer t, ///
    class Variable vector variables, ///
    real scalar arm_id ///
) {
    class Variable scalar variable
    string scalar tok, next, _
    real scalar number

    if (tokenpeek(*t) == "(") {
        return(parse_tuple(t, variables, arm_id))
    }
    else {
        variable = variables[1]
    }

    tok = tokenget(*t)

    if (variable.type == "string") {
        if (tok == "_") {
            return(parse_wild(variable))
        }
        else if (isquoted(tok)) {
            return(parse_constant(tok))
        }
        else {
            errprintf(
                "Expected a quoted string for variable %s in arm %f, found: %s\n",
                variable.name, arm_id, tok
            )
            exit(_error(3254))
        }
    }
    else if (variable.type == "int" | variable.type == "float") {
        if (tok == "_") {
            return(parse_wild(variable))
        }
        else if (tok == "min") {
            number = min(variable.levels)
            return(parse_number(t, number, arm_id, variable))
        }
        else if (tok == "max") {
            number = max(variable.levels)
            return(parse_number(t, number, arm_id, variable))
        }
        else if (isnumber(tok)) {
            number = strtoreal(tok)
            return(parse_number(t, number, arm_id, variable))
        }
        else {
            errprintf(
                "Expected a number for variable %s in arm %f, found: %s\n",
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

class Pattern scalar function parse_number( ///
    pointer t, ///
    real scalar number, ///
    real scalar arm_id,
    class Variable scalar variable ///
) {
    string scalar _, next

    next = tokenpeek(*t)
    if (israngesym(next)) {
        _ = tokenget(*t)
        return(parse_range(t, next, number, arm_id, variable))
    }
    else {
        return(parse_constant(number))
    }
}

///////////////////////////////////////////////////////////////// Parse patterns

class PWild scalar function parse_wild(class Variable scalar variable) {
    class PWild scalar pwild

    pwild = PWild()
    pwild.define(variable)
    return(pwild)
}

class PEmpty scalar function parse_empty() {
    return(PEmpty())
}

class PConstant scalar function parse_constant(transmorphic scalar value) {
    class PConstant scalar pconstant

    pconstant = PConstant()
    pconstant.define(value)

    return(pconstant)
}

class PRange scalar function parse_range( ///
    pointer scalar t, ///
    string scalar symbole, ///
    real scalar min, ///
    real scalar arm_id, ///
    class Variable scalar variable ///
) {
    class PRange scalar prange
    string scalar next, _
    real scalar number, max, in_min, in_max, precision
    
    next = tokenget(*t)
    
    if (next == "max") {
        max = max(variable.levels)
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

    if (symbole == "~") {
        in_min = 1
        in_max = 1
    }
    else if (symbole == "!~") {
        in_min = 0
        in_max = 1
    }
    else if (symbole == "~!") {
        in_min = 1
        in_max = 0
    }
    else if (symbole == "!!") {
        in_min = 0
        in_max = 0
    }
    else {
        "Unexpected symbole: " + symbole
    }

    prange = PRange()
    prange.define(min, max, in_min, in_max, variable.type == "int")

    return(prange)
}

class POr scalar function parse_or( ///
    pointer t, ///
    class Variable vector variables, ///
    real scalar arm_id ///
) {
    class POr scalar por
    real scalar check_includes

    check_includes = 1

    por = POr()
    por.insert(&parse_pattern(t, variables, arm_id), check_includes)

    while (match_next(t, "|")) {
        por.insert(&parse_pattern(t, variables, arm_id), check_includes)
    }

    return(por)
}

class Tuple scalar function parse_tuple( ///
    pointer t, ///
    class Variable vector variables, ///
    real scalar arm_id ///
) {
    class Tuple scalar tuple
    real scalar i

    tuple = Tuple()
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

class POr scalar function parse_tuples( ///
    pointer t, ///
    class Variable vector variables, ///
    real scalar arm_id ///
) {
    class POr scalar por
    real scalar check_includes

    check_includes = 1

    por = POr()
    por.insert(&parse_tuple(t, variables, arm_id), check_includes)

    while (match_next(t, "|")) {
        por.insert(&parse_tuple(t, variables, arm_id), check_includes)
    }

    return(por)
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
    tokenpchars(t, ("=>", ",", "~", "!~", "~!", "!!", "(", ")"))
    tokenset(t, str)
    
    return(t)
}

string scalar function consume(pointer t, string scalar str) {
    pointer scalar _
    string scalar tok, inside, value

    value = ""
    while (tokenpeek(*t) != str & tokenpeek(*t) != "") {
        tok = tokenget(*t)
        if (tok == "(") {
            inside = consume(t, ")") + ")"
        }
        value = value + tok + inside
    }
    _ = tokenget(*t)
    return(value)
}

real scalar function match_next(pointer t, string scalar str) {
    string scalar next, _

    next = tokenpeek(*t)
    
    if (next == str) {
        _ = tokenget(*t)
        return(1)
    }
    else {
        return(0)
    }
}

void function check_next(pointer t, string scalar str, real scalar arm_id) {
    string scalar next

    next = tokenget(*t)
    
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

real scalar function israngesym(str) {
    return(str == "~" | str == "!~" | str == "~!" | str == "!!")
}

real scalar function check_wildcard(transmorphic scalar pattern) {
    transmorphic scalar pattern_copy
    class POr scalar por
    class Tuple scalar tuple
    real scalar i
    
    if (eltype(pattern) == "pointer") {
        pattern_copy = *pattern
        return(check_wildcard(pattern_copy))
    }
    else if (classname(pattern) == "PEmpty") {
        return(0)
    }
    else if (classname(pattern) == "PWild") {
        return(1)
    }
    else if (classname(pattern) == "PConstant") {
        return(0)
    }
    else if (classname(pattern) == "PRange") {
        return(0)
    }
    else if (classname(pattern) == "POr") {
        por = pattern
        
        for (i = 1; i <= por.len(); i++) {
            if (check_wildcard(por.patterns.get_pat(i)) == 1) {
                return(1)
            }
        }
        return(0)
    }
    else if (classname(pattern) == "Tuple") {
        tuple = pattern
        for (i = 1; i <= length(tuple.patterns); i++) {
            if (check_wildcard(tuple.patterns[i]) == 1) {
                return(1)
            }
        }
        return(0)
    }
}

end
