mata

/*
# Definition

We have a dataset X containing N variables. We K variables V_1, ..., V_K, each
defined with a universe of levels O(V_k) distributed over the observations. For
a variable V containing L levels O(V) = {v_1, ..., v_L}, the levels are unique
and ordered: in the following explanations, for all v_i, v_j, such that i < j,
v_i < v_j.

Given the set of levels O(V), we can define different patterns p_i, ..., p_j
that represent combinations of levels and that can be understood as sets:

Empty      {}                  empty set
Wildcard   O(V)                set containing the universe of levels
Constant   {v}                 set containing a unique level of V
Range      {v_i, ..., v_j}     set containing all the values between v_i and v_j
Or         p_i U ... U p_j     set containing the union of patterns

These patterns and the underlying levels can correspond to different individuals
in the dataset X. X(p) is the sample of X that have values of V included in the
pattern p.

Given multiple variables V_1, ..., V_k, we can consider the intersection of the
patterns p(V_1), ..., p(V_k) as:

Tuple      P(V_1) & ... & P(V_k)   set containing the intersection

With t the a tuple defined over V_1, ..., V_k and t(X) is the sample of X that
has values of V_1, ..., V_k included in the corresponding patterns
p(V_1), ..., p(V_k).

With these notations we can cover all possible combinations of levels across
the variables of the dataset X.

# Classes

For the details about the classes, check the 'src/declare.mata' file.

# Methods

These classes have common methods

define :
    Used to define the instance's members
    arguments : depends on the class
    returns :   void
to_string :
    Used to transform the class content in a string
    arguments : none
    returns :   string scalar
print :
    Used to print the string content
    arguments : none
    returns :   void
to_expr :
    Used to transform the pattern in an expression
    arguments : the corresponding variable (or variables for tuples)
    returns :   string scalar
compress :
    Used to simplify the pattern
    arguments : none
    returns :   a pattern
overlap :
    Used to compute the set of levels in common with another pattern
    arguments : a pattern
    returns :   a pattern
includes :
    Used to check if the pattern includes another
    arguments : a pattern
    returns :   1 if the pattern is included, 0 other otherwise
difference :
    Used to compute the set of levels not included in another pattern
    arguments : another pattern
    returns :   a pointer to apattern
*/

///////////////////////////////////////////////////////////////////////// PEmpty

/*
Empty pattern

An empty set of levels {}

define :
    Nothing, the set is empty
    arguments : none
    returns :   void
to_string :
    'Empty', to know it's there
    arguments : none
    returns :   string scalar 'Empty'
print :
    'Empty'
    arguments : none
    returns :   void
to_expr :
    Nothing "", it's empty
    arguments : the corresponding variable
    returns :   string scalar ""
compress :
    Nothing, it's already empty
    arguments : none
    returns :   PEmpty
overlap :
    Nothing, it contains nothing
    arguments : a pattern
    returns :   PEmpty
includes :
    The empty set includes itself
    arguments : a pattern
    returns :   1 if PEmpty, 0 other otherwise
difference :
    Nothing, it contains nothing
    arguments : another pattern
    returns :   &PEmpty()
*/

void PEmpty::new() {}

void PEmpty::define() { 
    // Does nothing, it's empty
}

string scalar PEmpty::to_string() {
    return("Empty")
}

void PEmpty::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

string scalar PEmpty::to_expr(string scalar variable) {
    return("")
}

transmorphic scalar PEmpty::compress() {
    return(this)
}

transmorphic scalar PEmpty::overlap(class Pattern scalar pattern) {
    check_pattern(pattern)

    return(this)
}

real scalar PEmpty::includes(transmorphic scalar pattern) {
    check_pattern(pattern)
    
    return(classname(pattern) == "PEmpty")
}

pointer scalar PEmpty::difference(transmorphic scalar pattern) {
    check_pattern(pattern)

    return(&this)
}

////////////////////////////////////////////////////////////////////////// PWild

/*
Wildcard pattern

A set containing the universe of the levels O(V) for a variable V

define :
    Takes a variable and define a Pattern covering its universe
        - for integers : a union of all the levels as Constant patterns
        - for float : a range from the min to the max, plus missing value if any
        - for strings : a union of all the levels as Constant patterns
    arguments : a variable
    returns :   void
to_string :
    Either '_' or the underlying patterns if argument all is provided
    arguments : optional real scalar all
    returns :   string scalar
print :
    prints the result of to_string()
    arguments : optional real scalar all
    returns :   void
to_expr :
    '1==1', it's always true
    arguments : the corresponding variable
    returns :   string scalar "1==1"
compress :
    Nothing, it's the universe of levels, that are all unique
    arguments : none
    returns :   itself
overlap :
    It overlaps with all the patterns, assuming that the user provides included patterns
    arguments : a pattern
    returns :   the provided pattern
includes :
    It includes everything
    arguments : a pattern
    returns :   1
difference :
    The difference between the underlying pattern and the provided pattern
    arguments : another pattern
    returns :   a pointer to a pattern
*/

void PWild::new() {}

void PWild::define(class Variable scalar variable) { 
    class PRange scalar prange
    class PConstant scalar pconstant
    real scalar i

    if (length(variable.levels) == 0) {
        this.push(PEmpty())
        return
    }

    if (variable.type == "string") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant.define(variable.levels[i])
            this.push(pconstant)
        }
    }
    else if (variable.type == "int") {
        for (i = 1; i <= length(variable.levels); i++) {
            pconstant.define(variable.levels[i])
            this.push(pconstant)
        }
    }
    else if (variable.type == "float") {
        prange.define(variable.levels[1], variable.levels[2], 1, 1, 0)
        this.push(prange)

        if (length(variable.levels) == 3) {
            pconstant.define(.)
            this.push(pconstant)
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
    else if (all == 0) {
        return("_")
    }
    else if (this.values.len() == 0) {
        return("")
    }
    else {
        return(this.values.to_string())
    }
}

void PWild::print(| real scalar all) {
    if (args() == 0) {
        all = 0
    }
    
    displayas("text")
    printf("%s\n", this.to_string(all))
}

string scalar PWild::to_expr(string scalar variable) {
    return("1")
}

transmorphic scalar PWild::compress() {
    return(this)
}

transmorphic scalar PWild::overlap(class Pattern scalar pattern) {
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

void PWild::push(transmorphic scalar pattern) {
    this.values.push(pattern)
}

////////////////////////////////////////////////////////////////////// PConstant

/*
Constant pattern

A set containing a unique level of variable V

define :
    Takes a value and assing it to its member
    arguments : a value (real or string)
    returns :   void
to_string :
    Transforms the value to string (%g format if its a real)
    arguments : nothing
    returns :   string scalar
print :
    Prints the result of to_string()
    arguments : nothing
    returns :   void
to_expr :
    A string of an expression checking if the variable is equal to the value. 
    Uses %21x format for real to be sure that it uses the exact value.
    arguments : the corresponding variable
    returns :   string scalar "V == value"
compress :
    Nothing, it's a unique value
    arguments : none
    returns :   itself
overlap :
    Returns the set of values in common with other another pattern. It returns
    itself if the other pattern includes it, an Empty pattern otherwise.
    arguments : a pattern
    returns :   itself or PEmpty()
includes :
    Different conditions depending on the pattern
        - It always includes the Empty pattern
        - It includes the Wildcard pattern if it includes its values
        - It includes the Range pattern if it's equal to its min and max and
          they are included in the range
        - It includes the Or pattern if it includes all its patterns
    arguments : a pattern
    returns :   real scalar 0 or 1
difference :
    The difference of the Constant pattern with another pattern is the set of
    levels in the Constant pattern that are not included in the other pattern.
    Given that the constant pattern includes one level, it can be either itself
    if the other pattern does not include this level or the Empty pattern
    otherwise.
    arguments : another pattern
    returns :   a pointer to itself or PEmpty()
*/

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

transmorphic scalar PConstant::overlap(class Pattern scalar pattern) {
    check_pattern(pattern)

    if (pattern.includes(this)) {
        return(this)
    }
    else {
        return(PEmpty())
    }
}

real scalar PConstant::includes(transmorphic scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else if (classname(pattern) == "PWild") {
        return(this.includes_pwild(pattern))
    }
    else if (classname(pattern) == "PConstant") {
        return(this.includes_pconstant(pattern))
    }
    else if (classname(pattern) == "PRange") {
        return(this.includes_prange(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.includes_por(pattern))
    }
}

real scalar PConstant::includes_pwild(class PWild scalar pwild) {
    return(this.includes(pwild.values))
}

real scalar PConstant::includes_pconstant(class PConstant scalar pconstant) {
    return(this.value == pconstant.value)
}

real scalar PConstant::includes_prange(class PRange scalar prange) {
    return(
        this.value == prange.min
        & prange.in_min == 1
        & this.value == prange.max
        & prange.in_max == 1
    )
}

real scalar PConstant::includes_por(class POr scalar por) {
    real scalar i
    
    for (i = 1; i <= por.len(); i++) {
        if (!this.includes(por.get_pat(i))) {
            return(0)
        }
    }
    return(1)
}

pointer scalar PConstant::difference(class Pattern scalar pattern) {
    // For the constant there is one value
    // Hence, we either return it or return nothing

    if (pattern.includes(this)) {
        return(&(PEmpty()))
    }
    else {
        return(&this)
    }
}

///////////////////////////////////////////////////////////////////////// PRange

/*
Range pattern

A set containing all the levels of variable V between a minimum and a maximum

define :
    Takes a minimum, a maximum, a bool if the minimum is included, a bool if the
    maximum is included and a bool if the variable is discrete
    arguments : five real scalars
    returns :   void
to_string :
    The min, the max and a symbol depending on their inclusion in the range.
    The symbol can be:
        - /   if min and max are included
        - !/  if min is excluded and max included
        - /!  if min is included and max excluded
        - !!  if min and max are excluded
    arguments : nothing
    returns :   string scalar "'min''sym''max'" 
print :
    Prints the result of to_string()
    arguments : nothing
    returns :   void
to_expr :
    A string of an expression checking if the variable is above the minimum and
    below the maximum. The inequality sign are defined depending on the
    inclusion members. The minimum and maximum use the %21x format to be sure
    that it uses the exact value.
    arguments : the corresponding variable
    returns :   string scalar "V >(=) min & V <(=) max"
compress :
    - If the variable is discrete and the min(max) is not included, we increase
        (decrease) the min(max) and mark it included
    - If the min is larger than the max the Range pattern is empty
    - If the min is equal to the max and one of them is not included, it's empty
    - If the min is equal to the max and both of them are included, it returns
        a Constant pattern
    - Otherwise it returns the itself with the modifications
    arguments : none
    returns :   itself, PEmpty() or PConstant()
overlap :
    Different conditions depending on the pattern
        - Empty pattern : the empty pattern
        - Wildcard pattern : itself
        - Constant pattern : the pattern if it includes it, empty otherwise
        - PRange pattern :
            - if the min is above the other max, it's empty
            - if the max is below the other min, it's empty
            - min = max(min, other min)
            - max = min(max, other max)
            - inclusion is taken from the corresponding pattern
            - the result can be either a Range, a Constant or an Empty pattern
        - POr pattern : it's the union of the overlap with each pattern
    arguments : a pattern
    returns :   PEmpty(), PConstant(), PRange() or POr()
includes :
    Different conditions depending on the pattern
        - It always includes the Empty pattern
        - It includes the Wildcard pattern if it includes its values
        - It includes the Range pattern if its min is smaller and its max is
            larger than the other, given their respective inclusion
        - It includes the Or pattern if it includes all its patterns
    arguments : a pattern
    returns :   real scalar 0 or 1
difference :
    Different conditions depending on the pattern
        - Returns itself with the Empty pattern
        - Returns an Empty pattern with a Wildcard patter
        - With a constant pattern
            - if it includes it, it's splitten in two ranges
            - otherwise it returns itself
        - With a range pattern it is either
            - empty if the other range covers it
            - a single range if the other range covers a side of it
            - splitten in two if the other range covers the middle of it
            - itself if the other range is below or above
        - With a Or pattern
            - it's the difference with each sub-pattern
            - comparing the resulting difference with the following sub-patterns
    arguments : another pattern
    returns :   a pointer to a pattern
*/

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
    if (in_min == 0 & in_max == 1) sym = "!/"
    if (in_min == 1 & in_max == 0) sym = "/!"
    if (in_min == 1 & in_max == 1) sym = "/"

    return(sprintf("%f%s%f", this.min, sym, this.max))
}

void PRange::print() {
    displayas("text")
    printf("%s\n", this.to_string())
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

transmorphic scalar PRange::overlap(class Pattern scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (classname(pattern) == "PWild") {
        return(this)
    }
    else if (classname(pattern) == "PConstant") {
        return(this.overlap_pconstant(pattern))
    }
    else if (classname(pattern) == "PRange") {
        return(this.overlap_prange(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.overlap_por(pattern))
    }
}

real scalar PRange::includes(transmorphic scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    else if (classname(pattern) == "PWild") {
        return(this.includes_pwild(pattern))
    }
    else if (classname(pattern) == "PConstant") {
        return(this.includes_pconstant(pattern))
    }
    else if (classname(pattern) == "PRange") {
        return(this.includes_prange(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.includes_por(pattern))
    }
}

pointer scalar PRange::difference(transmorphic scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(&this)
    }
    else if (classname(pattern) == "PWild") {
        return(&(PEmpty()))
    }
    else if (classname(pattern) == "PConstant") {
        return(this.difference_pconstant(pattern))
    }
    else if (classname(pattern) == "PRange") {
        return(this.difference_prange(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.difference_por(pattern))
    }
}

transmorphic scalar PRange::overlap_pconstant(class PConstant scalar pconstant) {
    if (this.includes(pconstant)) {
        return(pconstant)
    }
    else {
        return(PEmpty())
    }
}

transmorphic scalar PRange::overlap_prange(class PRange scalar prange) {
    class PRange scalar inter_range
    
    if (this.min > prange.max) return(PEmpty())
    if (this.max < prange.min) return(PEmpty())

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

transmorphic scalar PRange::overlap_por(class POr scalar por) {
    return(por.overlap(this))
}

real scalar PRange::includes_pwild(class PWild scalar pwild) {
    return(this.includes(pwild.values))
}

real scalar PRange::includes_pconstant(class PConstant scalar pconstant) {
    real scalar above_min, below_max, value
    
    value = pconstant.value

    // The constant is above the minimum
    above_min = value > this.min | (value == this.min & this.in_min)
    below_max = value < this.max | (value == this.max & this.in_max)

    return(above_min & below_max)
}

real scalar PRange::includes_prange(class PRange scalar prange) {
    real scalar above_min, below_max
    
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

real scalar PRange::includes_por(class POr scalar por) {
    real scalar i
    
    for (i = 1; i <= por.len(); i++) {
        if (!this.includes(por.get_pat(i))) {
            return(0)
        }
    }
    return(1)
}

pointer scalar PRange::difference_pconstant(class PConstant scalar pconstant) {
    class PRange scalar prange_1, prange_2
    class POr scalar pranges
    
    if (pconstant.value < this.min | pconstant.value > this.max) {
        return(&this)
    }
    
    if (pconstant.value != this.min) {
        prange_1.define(this.min, pconstant.value, this.in_min, 0, this.discrete)
        pranges.push(&prange_1)
    }
    
    if (pconstant.value != this.max) {
        prange_2.define(pconstant.value, this.max, 0, this.in_max, this.discrete)
        pranges.push(&prange_2)
    }
    
    return(&pranges.compress())
}

pointer scalar PRange::difference_prange(class PRange scalar prange) {
    class PRange scalar prange_1, prange_2
    class PConstant scalar pconstant_min, pconstant_max
    class POr scalar result
    real scalar new_in_min, new_in_max
    
    if (prange.max < this.min | prange.min > this.max) {
        return(&this)
    }
    
    // First half
    if (prange.min < this.min) {
        // Nothing there is no first half
    }
    if (prange.min == this.min) {
        // Only possible value: the min if included in this but not in other
        if (this.in_min & !prange.in_min) {
            pconstant_min.define(this.min)
            result.push(&pconstant_min)
        }
    }
    else {
        if (prange.min == this.max) {
            new_in_max = this.in_max & !prange.in_min
        }
        else {
            new_in_max = !prange.in_min
        }
        
        prange_1.define(this.min, prange.min, this.in_min, new_in_max, this.discrete)
        result.push(&prange_1)
    }
    
    // Second half
    if (prange.max > this.max) {
        // Nothing there is no second half
    }
    if (prange.max == this.max) {
        // Only possible value: the max if included in this but not in other
        if (this.in_max & !prange.in_max) {
            pconstant_max.define(this.max)
            result.push(&pconstant_max)
        }
    }
    else {
        if (prange.max == this.min) {
            new_in_min = this.in_min & !prange.in_max
        }
        else {
            new_in_min = !prange.in_max
        }
        
        prange_2.define(prange.max, this.max, new_in_min, this.in_max, this.discrete)
        result.push(&prange_2)
    }
    
    return(&result.compress())
}

pointer scalar PRange::difference_por(class POr scalar por) {
    class POr scalar result
    
    result.define(difference_list(this, por.patterns))
    
    return(&result)
}

//////////////////////////////////////////////////////////////////////////// POr

/*
POr pattern

A set containing the union of multiple patterns

define :
    Takes a vector of pointers and push it to its dynamic array
    arguments : a vector of pointers to patterns
    returns :   void
to_string :
    The string version of its patterns separated by " | "
    arguments : nothing
    returns :   string scalar "p_i | ... | p_j" 
print :
    Prints the result of to_string()
    arguments : nothing
    returns :   void
to_expr :
    The union of the expressions of its patterns
    arguments : the corresponding variable
    returns :   string scalar "p_i | ... | p_j"
compress :
    - Compress all its patterns
    - Add them to a new Or pattern if they are not empty
    - Return an Empty pattern if the Or pattern has no pattern
    - Return a unique pattern if the Or pattern has only one pattern
    - Return the Or pattern otherwise
    arguments : none
    returns :   PEmpty(), PConstant(), PRange() or POr()
overlap :
    The overlap of a Or pattern with another pattern is the union of its
    patterns' overlap with the other pattern
    arguments : a pattern
    returns :   PEmpty(), PConstant(), PRange() or POr()
includes :
    A Or pattern includes another pattern if, taken together, its pattern
    include the other pattern. For this we can compute the difference between
    each of its patterns with the remaining the previous differences and check
    if the final pattern is empty. If it is, it means that all the levels of the
    pattern have been found in the Or pattern and it includes it. Otherwise, it
    means that some levels are not included in the Or pattern and it does not.
    arguments : a pattern
    returns :   real scalar 0 or 1
difference :
    The difference between a Or pattern and another pattern is the union of the
    difference between each of its patterns and the other pattern?
    arguments : another pattern
    returns :   a pointer to a pattern
*/

void POr::new() {}

void POr::define(pointer vector patterns) {
    real scalar i

    this.clear()

    for (i = 1; i <= length(patterns); i++) {
        this.push(patterns[i])
    }
}

transmorphic scalar POr::compress() {
    class POr scalar por
    class Pattern scalar pattern
    real scalar i

    // TODO: Replace in place
    
    for (i = 1; i <= this.len(); i++) {
        pattern = this.get_pat(i)
        pattern = pattern.compress()
        if (classname(pattern) == "PEmpty") {
            continue
        }
        else if (classname(pattern) == "PWild") {
            return(pattern)
        }
        else {
            if (!por.includes(pattern)) {
                por.push(pattern) 
            }
        }
    }
    
    if (por.len() == 0) {
        return(PEmpty())
    }
    if (por.len() == 1) {
        return(por.get_pat(1))
    }
    else {
        return(por)
    }
}

string scalar POr::to_string() {
    return(this.patterns.to_string(" | "))
}

string scalar POr::to_expr(string vector variable) {
    class Pattern scalar pattern
    string vector exprs
    real scalar i
    
    return(this.patterns.to_expr(" | ", variable))
}

void POr::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

transmorphic scalar POr::overlap(class Pattern scalar pattern) {
    class POr scalar por
    class Pattern scalar pattern_i
    real scalar i

    for (i = 1; i <= this.len(); i++) {
        pattern_i = this.get_pat(i)
        por.push(pattern_i.overlap(pattern))
    }
    
    return(por.compress())
}

real scalar POr::includes(transmorphic scalar pattern) {
    check_pattern(pattern)

    if (classname(pattern) == "PEmpty") {
        return(1)
    }
    if (classname(pattern) == "PConstant") {
        return(this.includes_pconstant(pattern))
    }
    else {
        return(this.includes_default(pattern))
    }
}

pointer scalar POr::difference(transmorphic scalar pattern) {
    class POr scalar differences
    class Pattern scalar pattern_i
    real scalar i

    // Loop over all patterns in Or and compute the difference
    for (i = 1; i <= this.len(); i++) {
        pattern_i = this.get_pat(i)
        differences.push(*pattern_i.difference(pattern))
    }
    
    if (differences.len() == 0) {
        return(&(PEmpty()))
    }
    else {
        return(&differences)
    }
}

real scalar POr::includes_pconstant(class PConstant scalar pconstant) {
    class Pattern scalar pattern_i
    real scalar i
    
    for (i = 1; i <= this.len(); i++) {
        pattern_i = this.get_pat(i)
        if (pattern_i.includes(pconstant)) {
            return(1)
        }
    }
    
    return(0)
}

real scalar POr::includes_default(transmorphic scalar pattern) {
    pointer vector difference
    
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

real scalar POr::len() {
    return(this.patterns.length)
}

void POr::push(transmorphic scalar pattern) {
    transmorphic scalar pattern_copy
    pointer scalar pattern_ref
    
    pattern_copy = pattern // To avoid bad references

    if (eltype(pattern) != "pointer") {
        pattern_ref = &pattern_copy
    }
    else {
        pattern_ref = pattern_copy
    }
    
    check_pattern(*pattern_ref)

    if (classname(*pattern_ref) == "PEmpty") {
        // Ignore
    }
    else if (classname(*pattern_ref) == "POr") {
        // Flatten the Or pattern
        this.append_por(*pattern_ref)
    }
    else {
        this.patterns.push(pattern_ref)
    }
}

void POr::append_por(class POr scalar por) {
    real scalar i
    
    for (i = 1; i <= por.len(); i++) {
        this.push(por.get(i))
    }
}

pointer scalar POr::get(real scalar index) {
    return(this.patterns.get(index))
}

transmorphic scalar POr::get_pat(real scalar index) {
    return(this.patterns.get_pat(index))
}

void POr::clear() {
    this.patterns.clear()
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

void function check_pattern(transmorphic scalar pattern) {
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
    real scalar i, j

    if (length(patterns) == 1) {
        return(patterns)
    }

    // TODO: do in place
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
        return(&(PEmpty()))
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
    
    differences.push(&pattern)

    // Loop over all pattern in Or
    for (i = 1; i <= pat_list.length; i++) {
        new_differences.clear()
        pattern_i = pat_list.get_pat(i)

        // Compute the difference
        for (j = 1; j <= length(differences); j++) {
            difference_j = differences.get_pat(j)
            new_differences.append(difference_j.difference(pattern_i))
        }

        if (new_differences.length == 0) {
            break
        }
        
        // if we don't precise ".patterns" it creates a new instance
        differences.patterns = new_differences.patterns
    }

    return(drop_empty_pattern(differences.patterns))
}

end
