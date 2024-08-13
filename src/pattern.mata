mata

///////////////////////////////////////////////////////////////////////// PEmpty

void PEmpty::new() {}

void PEmpty::define() { 
    // Does nothing, it's empty
}

string scalar PEmpty::to_string() {
    return("Empty")
}

string scalar PEmpty::to_expr(string scalar variable) {
    return("")
}

void PEmpty::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic scalar PEmpty::compress() {
    return(this)
}

transmorphic PEmpty::overlap(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(this)
}

real scalar PEmpty::includes(transmorphic scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else {
        return(0)
    }
}

pointer scalar PEmpty::difference(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(&this)
}

////////////////////////////////////////////////////////////////////////// PWild

void PWild::new() {}

void PWild::define(class Variable scalar variable) { 
    real scalar check_includes
    real vector x_num, levels_int
    class PRange scalar prange
    class PConstant scalar pconstant
    real scalar i, min, max, n_miss, precision

    // All the levels are unique by definition
    check_includes = 0

    // TODO: improve depending on syntax and adapt to other types

    if (variable.type == "string") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            pconstant.value = variable.levels[i]
            this.values.insert(pconstant, check_includes)
        }
    }
    else if (variable.type == "int") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant = PConstant()
            pconstant.value = variable.levels[i]
            this.values.insert(pconstant, check_includes)
        }
    }
    else if (variable.type == "float") {
        prange = PRange()
        prange.define(variable.levels[1], variable.levels[2], 1, 1, 0)
        this.values.insert(&prange, check_includes)

        if (length(variable.levels) == 3) {
            pconstant = PConstant()
            pconstant.define(.)
            this.values.insert(&pconstant, check_includes)
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

string scalar PWild::to_string(| real scalar all) {
    
    if (args() == 0) {
        return("_")
    }
    else if (this.values.len() == 0) {
        return("")
    }
    else {
        return(this.values.to_string())
    }
}

void PWild::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic scalar PWild::compress() {
    return(this)
}

string scalar PWild::to_expr(string scalar variable) {
    return("1==1")
}

transmorphic PWild::overlap(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(pattern)
}

real scalar PWild::includes(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(1)
}

pointer scalar PWild::difference(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(this.values.difference(pattern))
}

////////////////////////////////////////////////////////////////////// PConstant

void PConstant::new() {}

void PConstant::define(transmorphic scalar value) {
    if (isreal(value) | isstring(value)) {
        this.value = value
    }
    else {
        errprintf("Constant pattern value should be real or string")
        error(_error(3254))
    }
}

string scalar PConstant::to_string() {
    if (isstring(this.value)) {
        return(this.value)
    }
    else if (isreal(this.value)) {
        return(strofreal(this.value))
    }
    else {
        errprintf("Constant pattern value should be real or string")
        error(_error(3254))
    }
}

string scalar PConstant::to_expr(string scalar variable) {
    if (isreal(this.value)) {
        return(sprintf("%s == %21x", variable, this.value))
    }
    else {
        return(sprintf("%s == %s", variable, this.value))
    }
}

void PConstant::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic scalar PConstant::compress() {
    return(this)
}

transmorphic PConstant::overlap(transmorphic scalar pattern) {
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por

    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (classname(pattern) == "PWild") {
        return(pattern)
    }
    else if (classname(pattern) == "PConstant") {
        pconstant = pattern
        if (eltype(this.value) != eltype(pconstant.value)) {
            errprintf(
                "The two constant must have the same type: %s / %s\n",
                eltype(this.value) != eltype(pconstant.value)
            )
            exit(_error(3250))
        }
        if (this.value == pconstant.value) {
            return(pconstant)
        }
        else {
            return(PEmpty())
        }
    }
    else if (classname(pattern) == "PRange") {
        prange = pattern
        return(prange.overlap(this))
    }
    else if (classname(pattern) == "POr") {
        por = pattern
        return(por.overlap(this))
    }
}

real scalar PConstant::includes(transmorphic scalar pattern) {
    class PWild scalar pwild
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    real scalar i

    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else if (classname(pattern) == "PWild") {
        pwild = pattern
        this.includes(pwild.values)
    }
    else if (classname(pattern) == "PConstant") {
        pconstant = pattern
        return(this.value == pconstant.value)
    }
    else if (classname(pattern) == "PRange") {
        prange = pattern
        return(
            this.value == prange.min
            & prange.in_min == 1
            & this.value == prange.max
            & prange.in_max == 1
        )
    }
    else if (classname(pattern) == "POr") {
        por = pattern
        for (i = 1; i <= por.len(); i++) {
            if (!this.includes(*por.patterns.get(i))) {
                return(0)
            }
        }
        return(1)
    }
}

pointer scalar PConstant::difference(class Pattern scalar pattern) {
    // For the constant there is one value
    // Hence, we either return it or return nothing
    class PEmpty scalar pempty

    if (pattern.includes(this)) {
        pempty = PEmpty()
        return(&pempty)
    }
    else {
        return(&this)
    }
}

///////////////////////////////////////////////////////////////////////// PRange

void PRange::new() {}

void PRange::define( ///
        real scalar min, ///
        real scalar max, ///
        real scalar in_min, ///
        real scalar in_max, ///
        real scalar discrete ///
) {
    if (isbool(discrete)) {
        this.discrete = discrete
    }
    else {
        errprintf("Range discrete field should be 0 or 1\n")
        exit(_error(3498))
    }

    if (isbool(in_min) & isbool(in_max)) {
        this.in_min = in_min
        this.in_max = in_max
    }
    else {
        errprintf("Range pattern min and max inclusion should be 0 or 1\n")
        exit(_error(3498))
    }
    
    if (min == . | max == .) {
        errprintf("Range boundaries should be non-missing reals\n")
        exit(_error(3253))
    }
    
    // TODO: Decide where to check it in rest of code
    // if (min > max) {
    //     errprintf("Range minimum (%s) should be smaller than its maximum (%s)\n", min, max)
    //     exit(_error(3498))
    // }
    
    if (this.discrete == 1) {
        if (!isint(min) | !isint(max)) {
            errprintf("Range is discrete but boundaries are not integers\n")
            exit(_error(3498))
        }
    }
    
    this.min = min
    this.max = max
}

string scalar PRange::to_string() {
    string scalar sym

    if (in_min == 0 & in_max == 0) sym = "!!"
    if (in_min == 0 & in_max == 1) sym = "!~"
    if (in_min == 1 & in_max == 0) sym = "~!"
    if (in_min == 1 & in_max == 1) sym = "~"

    return(sprintf("%f%s%f", this.min, sym, this.max))
}

transmorphic scalar PRange::compress() {
    class PConstant scalar pconstant

    // Move boundaries if the range is discrete and they are not included
    if (this.discrete == 1) {
        if (this.in_min == 0) {
            this.min = this.min + 1
            this.in_min = 1
        }
        if (this.in_max == 0) {
            this.max = this.max - 1
            this.in_max = 1
        }
    }

    // The range can also be empty or a constant
    if (this.min > this.max) {
        return(PEmpty())
    }
    else if (this.min == this.max) {
        if (this.in_min & this.in_max) {
            pconstant = PConstant()
            pconstant.define(this.min)
            return(pconstant)
        }
        else {
            return(PEmpty())
        }
    }
    else {
        return(this)
    }
}

string scalar PRange::to_expr(string scalar variable) {
    string scalar min_sym, max_sym

    if (this.in_min == 1) {
        min_sym = ">="
    }
    else {
        min_sym = ">"
    }

    if (this.in_max == 1) {
        max_sym = "<="
    }
    else {
        max_sym = "<"
    }

    return(sprintf(
        "%s %s %21x & %s %s %21x",
        variable, min_sym, this.min, variable, max_sym, this.max
    ))
}

void PRange::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic PRange::overlap(transmorphic scalar pattern) {
    real scalar above_min, below_max
    class PEmpty scalar pempty
    class PRange scalar prange, inter_range
    class POr scalar por

    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (classname(pattern) == "PWild") {
        return(this)
    }
    else if (classname(pattern) == "PConstant") {
        if (this.includes(pattern)) {
            return(pattern)
        }
        else {
            return(PEmpty())
        }
    }
    else if (classname(pattern) == "PRange") {
        prange = pattern
        pempty = PEmpty()

        if (this.min > prange.max) return(pempty)
        if (this.max < prange.min) return(pempty)

        inter_range = PRange()

        inter_range.discrete = this.discrete

        // Determine the minimum
        if (this.min > prange.min) {
            inter_range.min = this.min
            inter_range.in_min = this.in_min
        }
        else if (this.min == prange.min) {
            inter_range.min = this.min
            inter_range.in_min = this.in_min && prange.in_min
        }
        else {
            inter_range.min = prange.min
            inter_range.in_min = prange.in_min
        }

        // Determine the maximum
        if (this.max < prange.max) {
            inter_range.max = this.max
            inter_range.in_max = this.in_max
        }
        else if (this.max == prange.max) {
            inter_range.max = this.max
            inter_range.in_max = this.in_max && prange.in_max
        }
        else {
            inter_range.max = prange.max
            inter_range.in_max = prange.in_max
        }

        // Return the compressed version
        return(inter_range.compress())
    }
    else if (classname(pattern) == "POr") {
        por = pattern
        return(por.overlap(this))
    }
}

real scalar PRange::includes(transmorphic scalar pattern) {
    class PWild scalar pwild
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    real scalar above_min, below_max, value
    real scalar i

    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else if (classname(pattern) == "PWild") {
        pwild = pattern
        return(this.includes(pwild.values))
    }
    else if (classname(pattern) == "PConstant") {
        pconstant = pattern

        value = pconstant.value

        // The constant is above the minimum
        above_min = value > this.min | (value == this.min & this.in_min)
        below_max = value < this.max | (value == this.max & this.in_max)

        return(above_min & below_max)
    }
    else if (classname(pattern) == "PRange") {
        prange = pattern

        // The other min value is above the minimum
        above_min = prange.min > this.min |
            (prange.min == this.min & this.in_min == 1) |
            (prange.min == this.min & this.in_min == 0 & prange.in_min == 0)

        // The other max value is below the maximum
        below_max = prange.max < this.max |
            (prange.max == this.max & this.in_max == 1) |
            (prange.max == this.max & this.in_max == 0 & prange.in_max == 0)

        return(above_min & below_max)
    }
    else if (classname(pattern) == "POr") {
        por = pattern

        for (i = 1; i <= por.len(); i++) {
            if (!this.includes(*por.patterns.get(i))) {
                return(0)
            }
        }
        return(1)
    }
}

pointer scalar PRange::difference(transmorphic scalar pattern) {
    transmorphic scalar overlap
    pointer vector differences, new_differences
    class PEmpty scalar pempty
    class PConstant scalar pconstant, pconstant_min, pconstant_max
    class PRange scalar prange
    class POr scalar por, result
    class PRange scalar prange_1, prange_2
    real scalar i, j, new_in_min, new_in_max

    check_pattern(pattern)

    //overlap = this.overlap(pattern)
    overlap = pattern

    if (classname(overlap) == "PEmpty") {
        return(&this)
    }
    else if (classname(overlap) == "PWild") {
        pempty = PEmpty()
        return(&pempty)
    }
    else if (classname(overlap) == "PConstant") {
        pconstant = overlap

        if (pconstant.value < this.min | pconstant.value > this.max) {
            return(&this)
        }
        
        result = POr()
        
        if (pconstant.value != this.min) {
            prange_1 = PRange()
            prange_1.define(this.min, pconstant.value, this.in_min, 0, this.discrete)
            result.insert(&prange_1)
        }
        
        if (pconstant.value != this.max) {
            prange_2 = PRange()
            prange_2.define(pconstant.value, this.max, 0, this.in_max, this.discrete)
            result.insert(&prange_2)
        }
        
        return(&result.compress())
    }
    else if (classname(overlap) == "PRange") {
        prange = overlap

        if (prange.max < this.min | prange.min > this.max) {
            return(&this)
        }
        
        result = POr()
        
        // First half
        if (prange.min < this.min) {
            // Nothing there is no first half
        }
        if (prange.min == this.min) {
            // Only possible value: the min if included in this but not in other
            if (this.in_min & !prange.in_min) {
                pconstant_min = PConstant()
                pconstant_min.define(this.min)
                result.insert(&pconstant_min)
            }
        }
        else {
            if (prange.min == this.max) {
                new_in_max = this.in_max & !prange.in_min
            }
            else {
                new_in_max = !prange.in_min
            }
            
            prange_1 = PRange()
            prange_1.define(this.min, prange.min, this.in_min, new_in_max, this.discrete)
            result.insert(&prange_1)
        }
        
        // Second half
        if (prange.max > this.max) {
            // Nothing there is no second half
        }
        if (prange.max == this.max) {
            // Only possible value: the max if included in this but not in other
            if (this.in_max & !prange.in_max) {
                pconstant_max = PConstant()
                pconstant_max.define(this.max)
                result.insert(&pconstant_max)
            }
        }
        else {
            if (prange.max == this.min) {
                new_in_min = this.in_min & !prange.in_max
            }
            else {
                new_in_min = !prange.in_max
            }
            
            prange_2 = PRange()
            prange_2.define(prange.max, this.max, new_in_min, this.in_max, this.discrete)
            result.insert(&prange_2)
        }
        
        return(&result.compress())
    }
    else if (classname(overlap) == "POr") {
        por = overlap

        result = POr()
        result.define(difference_list(this, por.patterns))

        return(&result)
    }
}

//////////////////////////////////////////////////////////////////////////// POr

void POr::new() {}

real scalar POr::len() {
    return(this.patterns.length)
}

void POr::define(pointer vector patterns, | real scalar check_includes) {
    real scalar i

    if (args() == 1) {
        check_includes = 0
    }

    this.patterns.clear()

    for (i = 1; i <= length(patterns); i++) {
        this.insert(patterns[i], check_includes)
    }
}

void POr::insert(transmorphic scalar pattern, | real scalar check_includes) {
    class POr scalar por
    transmorphic scalar pattern_copy
    pointer scalar pattern_ref
    real scalar i
    
    pattern_copy = pattern // To avoid bad references

    if (eltype(pattern) != "pointer") {
        pattern_ref = &pattern_copy
    }
    else {
        pattern_ref = pattern_copy
    }
    
    check_pattern(*pattern_ref)

    if (args() == 1) {
        check_includes = 0
    }

    if (classname(*pattern_ref) == "PEmpty") {
        // Ignore
    }
    else if (classname(*pattern_ref) == "POr") {
        // Flatten the Or pattern
        por = *pattern_ref
        for (i = 1; i <= por.len(); i++) {
            this.insert(por.patterns.get(i), check_includes)
        }
    }
    else {
        if (check_includes) {
            if (this.includes(*pattern_ref) == 0) {
                this.patterns.push(pattern_ref)
            }
        }
        else {
            this.patterns.push(pattern_ref)
        }
    }
}

transmorphic scalar POr::compress() {
    class POr scalar por
    class Pattern scalar pattern, new_pattern
    real scalar i

    for (i = 1; i <= this.len(); i++) {
        pattern = this.patterns.get_pat(i)
        new_pattern = pattern.compress()
        if (classname(new_pattern) == "PEmpty") {
            continue
        }
        else if (classname(new_pattern) == "PWild") {
            return(new_pattern)
        }
        else {
            por.insert(new_pattern, 1) 
        }
    }

    if (por.len() == 0) {
        return(PEmpty())
    }
    if (por.len() == 1) {
        return(por.patterns.get_pat(1))
    }
    else {
        return(por)
    }
}

string scalar POr::to_string() {
    class Pattern scalar pattern
    string vector str
    real scalar i

    str = J(1, this.len(), "")
    
    for (i = 1; i <= this.len(); i++) {
        pattern = this.patterns.get_pat(i)
        str[i] = pattern.to_string()
    }

    return(invtokens(str, " | "))
}

string scalar POr::to_expr(string vector variable) {
    class Pattern scalar pattern
    string scalar expr
    string vector exprs
    real scalar i

    exprs = J(1, this.len(), "")
    
    for (i = 1; i <= this.len(); i++) {
        pattern = this.patterns.get_pat(i)
        if (this.len() > 1) {
            exprs[i] = "(" + pattern.to_expr(variable) + ")"
        }
        else {
            exprs[i] = pattern.to_expr(variable)
        }
    }
    
    return(invtokens(exprs, " | "))
}

void POr::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic POr::overlap(class Pattern scalar pattern) {
    class POr scalar por
    real scalar i
    real scalar check_includes

    por = POr()

    for (i = 1; i <= this.len(); i++) {
        por.insert(&por_overlap(this, i, pattern), 1)
    }

    if (por.len() == 0) {
        por = PEmpty()
    }

    return(por)
}

transmorphic function por_overlap( ///
    class POr scalar por, ///
    real scalar i, ///
    class Pattern scalar pattern ///
) {
    class Pattern scalar pattern_i
    // We need to declare a new variable to call overlap on the ith pattern
    // Because patterns[i] is transmorphic and does not have the method
    // In a loop, a pointer to this variable always return the last value
    // We need to create this variable in a new scope
    pattern_i = por.patterns.get_pat(i)
    return(pattern_i.overlap(pattern))
}

real scalar POr::includes(transmorphic scalar pattern) {
    class Pattern scalar in_pattern, pattern_i
    class PWild scalar pwild
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    transmorphic scalar new_pattern
    pointer vector difference
    real scalar i

    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else {
        difference = difference_list(pattern, this.patterns)
    
        if (length(difference) > 1) {
            return(0)
        }
        else if (classname(*difference[1]) == "PEmpty") {
            return(1)
        }
        else {
            return(0)
        }
    }
}

pointer scalar POr::difference(transmorphic scalar pattern) {
    class PEmpty scalar pempty
    class POr scalar differences
    real scalar i

    differences = POr()
    
    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= this.len(); i++) {
        differences.insert(por_difference(this, i, pattern))
    }
    
    if (differences.len() == 0) {
        pempty = PEmpty()
        return(&pempty)
    }
    else {
        return(&differences)
    }
}

transmorphic function por_difference( ///
    class POr scalar por, ///
    real scalar i, ///
    class Pattern scalar pattern ///
) {
    class Pattern scalar pattern_i

    pattern_i = por.patterns.get_pat(i)
    return(pattern_i.difference(pattern))
}

////////////////////////////////////////////////////////////////////////// Utils

real scalar function isbool(real scalar x) {
    return(x == 0 | x == 1)
}

real scalar function isint(real scalar x) {
    return(x == trunc(x))
}

real scalar function ispattern(transmorphic x) {
    return(
        classname(x) == "Pattern" ||
            classname(x) == "PEmpty" ||
            classname(x) == "PWild" ||
            classname(x) == "PConstant" ||
            classname(x) == "PRange" ||
            classname(x) == "POr" ||
            classname(x) == "Tuple"
    )
}

function check_pattern(transmorphic scalar pattern) {
    if (eltype(pattern) != "class") {
        exit(error(3260))
    }

    if (!ispattern(pattern)) {
        errprintf("Unknown pattern of class '%s'", classname(pattern))
        exit(_error(3260))
    }
}

pointer vector function drop_empty_pattern(pointer vector patterns) {
    pointer vector patterns_clean
    class Pattern scalar pempty
    real scalar i, j

    if (length(patterns) == 1) {
        return(patterns)
    }

    patterns_clean = J(1, length(patterns), NULL)

    j = 0

    for (i = 1; i <= length(patterns); i++) {
        if (patterns[i] != NULL) {
            if (classname(*patterns[i]) != "PEmpty") {
                j++
                patterns_clean[j] = patterns[i]
            }
        }
    }

    if (j == 0) {
        pempty = PEmpty()
        return(&pempty)
    }
    else {
        return(patterns_clean[1..j])
    }
}

// Compute the difference between a pattern and a list of patterns
pointer vector difference_list(class Pattern scalar pattern, class PatternList scalar pat_list) {
    class PatternList scalar differences, new_differences
    class Pattern scalar pattern_i, difference_j
    real scalar i, j
    
    differences = PatternList()
    differences.push(&pattern)

    // Loop over all pattern in Or
    for (i = 1; i <= pat_list.length; i++) {
        new_differences = PatternList()
        pattern_i = pat_list.get_pat(i)

        // Compute the difference
        for (j = 1; j <= length(differences); j++) {
            difference_j = differences.get_pat(j)
            new_differences.append(difference_j.difference(pattern_i))
        }

        if (new_differences.length == 0) {
            break
        }

        differences = new_differences
    }

    return(drop_empty_pattern(differences.patterns))
}

end
