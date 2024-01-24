mata

class Arm vector function parse_string( ///
		string scalar str, ///
		class Variable vector variables ///
	) {
	pointer scalar t    
	
	t = tokeninitstata()
	tokenpchars(t, ("=>", ",", "~", "!~", "~!", "!!", "(", ")"))
	tokenset(t, str)

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
	class Tuple scalar tuple
	pointer scalar _
	real scalar i
	
	arm	 = Arm()
	arm.id = arm_id
	arm.lhs.arm_id = arm_id
	
	arm.lhs.pattern = &parse_or(t, variables, arm_id)
	
	check_next(t, "=>")
	
	arm.value = parse_value(t)
	
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
		else if (israngesym(tok)) {
			return(parse_range(t, tok, ., variable))
		}
		else if (isnumber(tok)) {
			number = strtoreal(tok)
			next = tokenpeek(*t)
			if (israngesym(next)) {
				_ = tokenget(*t)
				return(parse_range(t, next, number, variable))
			}
			else {
				return(parse_constant(number))
			}
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

///////////////////////////////////////////////////////////////// Parse patterns

class PWild scalar function parse_wild(class Variable scalar variable) {
	class PWild scalar pwild
	
	pwild = PWild()
	pwild.values = &variable.values
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
	class Variable scalar variable
) {
	class PRange scalar prange
	string scalar next, _
	real scalar number, max, in_min, in_max
	
	stata(sprintf("quietly summarize %s", variable.name))
	stata("local minimum = r(min)")
	stata("local maximum = r(max)")
	
	if (min == .) {
	    min = strtoreal(st_local("minimum"))
	}
	
	next = tokenpeek(*t)
	number = strtoreal(next)
	if (number != .) {
		_ = tokenget(*t)
		max = number
	}
	else {
		max = strtoreal(st_local("maximum"))
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
	string scalar _
	
	check_includes = 1
	
	por = POr()
	por.insert(&parse_pattern(t, variables, arm_id), check_includes)
	
	while (tokenpeek(*t) == "|") {
		_ = tokenget(*t)
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
	string scalar _
	real scalar i
	
	tuple = Tuple()
	tuple.patterns = J(1, length(variables), NULL)
	
	i = 0
	
	do {
		i++
		if (i > length(variables)) {
			errprintf(
				"Too many patterns in arm %f: expected %f, found %f\n",
				arm_id, length(variables), i
			)
			exit(_error(3300))
		}
		_ = tokenget(*t)
		tuple.patterns[i] = &parse_or(t, variables[i], arm_id)
	} while (tokenpeek(*t) == ",")
	
	check_next(t, ")")
	
	if (i != length(variables)) {
		errprintf(
			"Too few patterns in arm %f: expected %f, found %s\n",
			arm_id, length(variables), i
		)
		exit(_error(3300))
	}
	
	return(tuple)
}

//////////////////////////////////////////////////////////////////// Parse Value

string scalar function parse_value(pointer t) {
    string scalar value
	
	value = consume(t, ",")
	return(value)
}

////////////////////////////////////////////////////////////////////////// Utils

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

void function check_next(pointer t, string scalar str) {
    string scalar next
	
	next = tokenget(*t)
	if (next != str) {
		errprintf("Expect '%s', found: '%s'\n", str, next)
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

end
