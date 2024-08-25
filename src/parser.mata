mata

class Arm vector function parse_string(
        string scalar str,
        class Variable vector variables
    ) {
    pointer scalar t

    t = tokenize(str)

    return(parse_arms(t, variables))
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
        arms = arms, arm
    }

    return(arms)
}

class Arm scalar function parse_arm (
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

    check_next(t, "=>", arm_id)

    arm.value = parse_value(t)
    
    arm.has_wildcard = check_wildcard(arm.lhs.pattern)

    return(arm)
}

class Pattern scalar function parse_pattern(
    pointer t,
    class Variable scalar variable,
    real scalar arm_id
) {
    string scalar tok
    real scalar number

    tok = tokenget(t)

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
            number = st_vlsearch(variable.name, unquote(tok))
            if (number != .) {
                return(parse_number(t, number, arm_id, variable))
            }
            else {
                errprintf(
                    "Unknown label value for variable %s in arm %f: %s\n",
                    variable.name, arm_id, tok
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

class Pattern scalar function parse_number(
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

class PWild scalar function parse_wild(class Variable scalar variable) {
    class PWild scalar pwild

    pwild.define(variable)
    return(pwild)
}

class PEmpty scalar function parse_empty() {
    return(PEmpty())
}

class PConstant scalar function parse_constant(transmorphic scalar value) {
    class PConstant scalar pconstant

    pconstant.define(value)

    return(pconstant)
}

class PRange scalar function parse_range(
    pointer scalar t,
    string scalar symbole,
    real scalar min,
    real scalar arm_id,
    class Variable scalar variable
) {
    class PRange scalar prange
    string scalar next
    real scalar max, in_min, in_max
    
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

    prange.define(min, max, in_min, in_max, variable.type == "int")

    return(prange)
}

class POr scalar function parse_or(
    pointer t,
    class Variable scalar variable,
    real scalar arm_id
) {
    class POr scalar por

    do {
        por.push(parse_pattern(t, variable, arm_id))
    } while (match_next(t, "|"))

    return(por.compress())
}

class Tuple scalar function parse_tuple(
    pointer t,
    class Variable vector variables,
    real scalar arm_id
) {
    class Tuple scalar tuple
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

class POr scalar function parse_tuples(
    pointer t,
    class Variable vector variables,
    real scalar arm_id
) {
    class POr scalar por

    do {
        por.push(parse_tuple(t, variables, arm_id))
    } while (match_next(t, "|"))
    
    return(por.compress())
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
    tokenpchars(t, ("=>", ",", "~", "!~", "~!", "!!", "(", ")", "|"))
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
    return(str == "~" | str == "!~" | str == "~!" | str == "!!")
}

real scalar function check_wildcard(transmorphic scalar pattern) {
    if (eltype(pattern) == "pointer") {
        return(check_wildcard(*pattern))
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
        return(check_wildcard_por(pattern))
    }
    else if (classname(pattern) == "Tuple") {
        return(check_wildcard_tuple(pattern))
    }
}

real scalar function check_wildcard_por(class POr scalar por) {
    real scalar i
    
    for (i = 1; i <= por.len(); i++) {
        if (check_wildcard(por.get_pat(i)) == 1) {
            return(1)
        }
    }
    
    return(0)
}

real scalar function check_wildcard_tuple(class Tuple scalar tuple) {
    real scalar i
    
    for (i = 1; i <= length(tuple.patterns); i++) {
        if (check_wildcard(tuple.patterns[i]) == 1) {
            return(1)
        }
    }
    
    return(0)
}

end
