*! version 0.0.5  17 Sep 2024

**#************************************************************ src/declare.mata

mata
mata set matastrict on

//////////////////////////////////////////////////////////////////////// Pattern

// The parent class for all patterns
class Pattern {
    virtual void define()                                                       // Define the instance members
    virtual string scalar to_string()                                           // Turns the class content in a string
    virtual void print()                                                        // Print the class content
    virtual string scalar to_expr()                                             // Turns the class content in an expression based on a variable
    virtual transmorphic scalar compress()                                      // Simplifies the class content if possible
    virtual transmorphic scalar overlap()                                       // Returns the set of common values with another pattern
    virtual real scalar includes()                                              // Check if the pattern is included in another
    virtual pointer scalar difference()                                         // Returns the set of values not included in another patterns 
}

// Empty pattern
class PEmpty extends Pattern {
    // Members
    
    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
}

// Wild card '_'
class PWild extends Pattern {
    // Members
    class POr scalar values                                                     // The union of all possible levels

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
    void push()                                                                 // Add new value to the patterns
}

// Constant
class PConstant extends Pattern {
    // Members
    transmorphic scalar value                                                   // The value (real or string)

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
    real scalar includes_pwild()                                                // Includes PWild()
    real scalar includes_pconstant()                                            // Includes PConstant()
    real scalar includes_prange()                                               // Includes PRange()
    real scalar includes_por()                                                  // Includes POr()
}

// Real or Float Range
class PRange extends Pattern {
    // Members
    real scalar min                                                             // Minimum value
    real scalar max                                                             // Maximum value
    real scalar in_min                                                          // 1 if the minimum is included, 0 otherwize
    real scalar in_max                                                          // 1 if the maximum is included, 0 otherwize
    real scalar discrete                                                        // 1 if the variable is discrete, 0 otherwize

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
    transmorphic scalar overlap_pconstant()                                     // Overlap with PConstant()
    transmorphic scalar overlap_prange()                                        // Overlap with PRange()
    transmorphic scalar overlap_por()                                           // Overlap with POr()
    pointer scalar difference_pconstant()                                       // Difference with PConstant()
    pointer scalar difference_prange()                                          // Difference with PRange()
    pointer scalar difference_por()                                             // Difference with POr()
    real scalar includes_pwild()                                                // Includes PWild()
    real scalar includes_pconstant()                                            // Includes PConstant()
    real scalar includes_prange()                                               // Includes PRange()
    real scalar includes_por()                                                  // Includes POr()
}

class PatternList extends Pattern {
    // Members
    public pointer vector patterns                                              // An array of pointers to patterns
    public real scalar capacity                                                 // Number of pre-allocated pointers
    public real scalar length                                                   // Number of patterns initiated

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()                                                                  // Initiates the instance with a capacity
    pointer scalar get()                                                        // Returns a pointer to the desired pattern
    transmorphic scalar get_pat()                                               // Return the desired pattern
    void resize()                                                               // Resize to the desired size
    void push()                                                                 // Add a pointer to the end of the patterns
    void append()                                                               // Add a vector of pointer to the end of the patterns
    void replace()                                                              // Replace the desired pattern
    void remove()                                                               // Remove the value at a given index and shift all the following ones
    void swap_remove()                                                          // Swap the value with the last one and decrement the length
    void clear()                                                                // Redefine the legnth as 0 and ignore all values
    void check_integer()                                                        // Check if the value is an integer
    void check_range()                                                          // Check if the index is in the range of the array
}

// Or pattern, which is a list of pointers to patterns
class POr extends Pattern {
    // Members
    class PatternList scalar patterns                                           // A dynamic array of patterns

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
    real scalar includes_pconstant()                                            // Includes PConstant()
    real scalar includes_default()                                              // Includes PWild(), PRange() or POr()
    real scalar len()                                                           // Get the # of patterns
    void push()                                                                 // Push a new pattern
    void append_por()                                                           // Append a new por
    pointer scalar get()                                                        // Returns a pointer to the desired pattern
    transmorphic scalar get_pat()                                               // Return the desired pattern
    void clear()                                                                // Remove all the patterns
}

class Tuple extends Pattern {
    // Members
    real scalar arm_id                                                          // The corresponding arm #
    pointer vector patterns                                                     // An array of patterns

    // Pattern methods
    void define()
    string scalar to_string()
    void print()
    string scalar to_expr()
    transmorphic scalar compress()
    transmorphic scalar overlap()
    real scalar includes()
    pointer scalar difference()
    
    // Other methods
    void new()
    transmorphic scalar overlap_tuple()                                         // Overlap with Tuple()
    transmorphic scalar overlap_por()                                           // Overlap with POr()
    pointer scalar difference_tuple()                                        
    pointer scalar difference_por()                                        
    transmorphic scalar difference_vec()                                        // Computes the difference with an array of patterns
}

/////////////////////////////////////////////////////////////////////// Variable

class Variable {
    string scalar name                                                          // Name of the variable
    string scalar stata_type                                                    // Stata type of the variable
    string scalar type                                                          // Internal type of the variable
    transmorphic rowvector levels                                               // The corresponding sorted vector of levels
    private real scalar min
    private real scalar max

    void new()
    string scalar to_string()
    void print()
    void init()                                                                 // Initialize the variable given its name
    void init_type()                                                            // Initialize the type
    void init_levels()                                                          // Initialize the levels
    void set_minmax()                                                           // Set min and max levels
    real scalar get_min()                                                       // Get minimum level
    real scalar get_max()                                                       // Get maximum level
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
    class Pattern scalar missings                                               // The missing patterns

    void new()
    string vector to_string()
    string scalar to_string_pattern()
    string vector to_string_por()
    void print()
}
end


**#******************************************************* src/pattern_list.mata

mata

// Called with PatternList(), cannot be directly called
void PatternList::new() {
    // The default capacity when created is 8
    this.patterns = J(1, 8, NULL)
    this.capacity = 8
    this.length = 0
}

void PatternList::print() {
    printf("%s", this.to_string())
}

string scalar PatternList::to_string(string scalar sep) {
    string vector strings
    class Pattern scalar pattern
    real scalar i

    strings = J(1, this.length, "")

    for (i = 1; i <= this.length; i++) {
        pattern = *this.patterns[i]
        strings[i] = pattern.to_string()
    }

    return(invtokens(strings, sep))
}

string scalar PatternList::to_expr(string scalar sep, string vector variable) {
    string vector exprs
    class Pattern scalar pattern
    real scalar i
    
    if (this.length == 0) {
        return("")
    }

    if (this.length == 1) {
        pattern = *this.patterns[1]
        return(pattern.to_expr(variable))
    }

    exprs = J(1, this.length, "")
    
    for (i = 1; i <= this.length; i++) {
        pattern = *this.patterns[i]
        exprs[i] = "(" + pattern.to_expr(variable) + ")"
    }

    return(invtokens(exprs, sep))
}

transmorphic scalar PatternList::compress() {
    class PatternList scalar new_pat
    real scalar i

    new_pat = this

    for (i = 1; i <= new_pat.length; i++) {
        if (classname(new_pat.get_pat(i)) == "PEmpty") {
            new_pat.swap_remove(i)
        }
    }

    if (new_pat.length == 0) {
        return(PEmpty())
    }
    else if (new_pat.length == 1) {
        return(new_pat.get_pat(1))
    }
    else {
        return(new_pat)
    }
}

transmorphic scalar PatternList::overlap(class Pattern scalar pattern) {
    class Pattern scalar pattern_i
    class PatternList scalar overlap
    real scalar i

    for (i = 1; i <= this.length; i ++) {
        pattern_i = this.get_pat(i)
        overlap.push(pattern_i.overlap(pattern))
    }

    return(overlap.compress())
}

pointer scalar PatternList::difference(class Pattern scalar pattern) {
    class Pattern scalar pattern_i
    class PatternList scalar differences
    real scalar i

    for (i = 1; i <= this.length; i ++) {
        pattern_i = this.get_pat(i)
        differences.append(pattern_i.difference(pattern))
    }

    return(&differences.compress())
}


// Resize the dynamic array
void PatternList::resize(real scalar new_capacity) {
    check_integer(new_capacity, "Array new capacity")

    if (new_capacity == 0) {
        errprintf("Cannot resize to a capacity of 0\n")
        exit(_error(3300))
    }
    else if (new_capacity > this.capacity) {
        // This needs to changed if the type is not a pointer
        this.patterns = this.patterns, J(1, new_capacity - this.capacity, NULL)
        this.capacity = new_capacity
    }
    else {
        this.patterns = this.patterns[1..new_capacity]
        this.capacity = new_capacity
        this.length = new_capacity
    }
}

// Add a new element at the end of the values and resize if required
void PatternList::push(pointer scalar value) {
    // Double the capacity if the dynamic is filled
    if (this.length == this.capacity) {
        this.resize(this.capacity * 2)
    }

    this.length = this.length + 1
    this.patterns[this.length] = value
}

// Add an array of new elements at the end and resize if required
void PatternList::append(pointer rowvector new_values) {
    real scalar new_capacity, new_length

    new_length = this.length + cols(new_values)

    // Increase to the right power of two if needed
    if (new_length > this.capacity) {
        new_capacity = 2^ceil(log(new_length) / log(2))
        this.resize(new_capacity)
    }

    this.patterns[this.length+1..new_length] = new_values
    this.length = new_length
}

// Replace a value at a given index
void PatternList::replace(transmorphic scalar value, real scalar index) {
    transmorphic scalar new_value
    
    check_range(index, "replace")

    if (eltype(value) == "pointer") {
        this.patterns[index] = value
    }
    else {
        new_value = value // Copy value before reference
        this.patterns[index] = &new_value
    }
    
}

// Get the pointer at a given index
pointer scalar PatternList::get(real scalar index) {
    check_range(index, "get")

    return(this.patterns[index])
}

// Get the pattern at a given index
transmorphic scalar PatternList::get_pat(real scalar index) {
    return(*this.get(index))
}

// Removes the value at a given index
void PatternList::remove(real scalar index) {
    check_range(index, "remove")

    this.patterns[index..length-1] = this.patterns[index+1..length]
    this.length = this.length - 1
}

// Swap the value at a given index with the last value and decrease the length
void PatternList::swap_remove(real scalar index) {
    check_range(index, "swap and remove")

    this.patterns[index] = this.patterns[length]
    this.length = this.length - 1
}

// Remove all the values
void PatternList::clear() {
    if (this.length == 0) {
        return
    }

    this.patterns[1..(this.length)] = J(1, this.length, NULL)

    this.length = 0
}

// Util function to check for missing, negative or float values
void PatternList::check_integer(real scalar value, string scalar message) {
    if (value == .) {
        errprintf("%s cannot be a missing value\n", message)
        exit(_error(3351))
    }

    if (value < 0) {
        errprintf("%s should be a positive integer, found %f\n", message, value)
        exit(_error(3398))
    }

    if (trunc(value) != value) {
        errprintf("%s should be an integer, found %f\n", message, value)
        exit(_error(3398))
    }
}

// Util check if the index is in range
void PatternList::check_range(real scalar index, string scalar verb) {
    check_integer(index, "Index")

    if (index == 0) {
        errprintf("Cannot %s a value at index 0\n", verb)
        exit(_error(3300))
    }
    else if (index > this.length) {
        errprintf(
            "Cannot %s a value at index %f in an array of length %f\n",
            verb, index, this.length
        )
        exit(_error(3300))
    }
}

end


**#************************************************************ src/pattern.mata

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

    for (i = 1; i <= length(this.levels); i++) {
        if (this.type == "int" | this.type == "float") {
            levels_str[i] = strofreal(this.levels[i])
        }
        else {
            levels_str[i] = this.levels[i]
        }
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
    this.min = .a
    this.max = .a
    
    this.init_type()
    if (check) {
        this.init_levels()
    }
}

void Variable::init_type() {
    string scalar var_type

    var_type = st_vartype(this.name)
    this.stata_type = var_type

    if (substr(var_type, 1, 3) == "str") {
        this.type = "string"
    }
    else if (var_type == "byte" | var_type == "int" | var_type == "long") {
        this.type = "int"
    }
    else if (var_type == "float" | var_type == "double") {
        this.type = "float"
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}

void Variable::init_levels() {
    string vector x_str
    real vector x_num
    real scalar i

    if (this.type == "string") {
        st_sview(x_str = "", ., this.name)

        this.levels = uniqrowssort(x_str)

        for (i = 1; i <= length(this.levels); i++) {
            this.levels[i] = `"""' + this.levels[i] + `"""'
        }
    }
    else if (this.type == "int") {
        st_view(x_num = ., ., this.name)

        this.levels = uniqrowsofinteger(x_num)
    }
    else if (this.type == "float") {
        this.set_minmax()
        
        this.levels = this.get_min(), this.get_max()
        
        if (hasmissing(x_num) > 0) {
            this.levels = this.levels, .
        }
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}

void Variable::set_minmax() {
    real vector x_num, minmax
    
    minmax = minmax(x_num)
    
    if (length(this.levels) == 0) {
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

end


**#************************************************************** src/tuple.mata

mata

void Tuple::new() {}

string scalar Tuple::to_string() {
    class Pattern scalar pattern
    string vector strings
    string scalar str
    real scalar i, n_pat
    
    n_pat = length(this.patterns)

    if (n_pat == 0) {
        return("Empty Tuple: Error")
    }
    
    strings = J(1, n_pat, "")
    
    for (i = 1; i <= n_pat; i++) {
        pattern = *patterns[i]
        strings[i] = pattern.to_string()
    }
    
    str = invtokens(strings, ", ")

    if (n_pat > 1) {
        str = "(" + str + ")"
    }
    
    return(str)
}

void Tuple::print() {
    displayas("text")
    printf("%s\n", this.to_string())
}

string scalar Tuple::to_expr(class Variable vector variables) {
    class Pattern scalar pattern
    string vector exprs
    real scalar i, k, n_pat

    n_pat = length(this.patterns)
    
    if (n_pat != length(variables)) {
        errprintf(
            "The tuples and variables have different sizes %f and %f",
            length(this.patterns), length(variables)
        )
        exit(_error(3300))
    }
    
    exprs = J(1, n_pat, "")

    k = 0
    for (i = 1; i <= n_pat; i++) {
        pattern = *this.patterns[i]
        pattern = pattern.compress()
        if (classname(pattern) != "PWild" & classname(pattern) != "PEmpty") {
            k++
            exprs[k] = pattern.to_expr(variables[i].name)
        }
    }
    
    if (k == 0) {
        return("1")
    }
    
    if (k > 1) {
        for (i = 1; i <= k; i++) {
            exprs[i] = "(" + exprs[i] + ")"
        }
    }
    
    return(invtokens(exprs[1..k], " & "))
}

transmorphic scalar Tuple::compress() {
    real scalar i

    for (i = 1; i <= length(this.patterns); i++) {
        this.patterns[i] = tuple_compress_i(this.patterns, i)
    }

    for (i = 1; i <= length(this.patterns); i++) {
        if (classname(*this.patterns[i]) == "PEmpty") {
            return(PEmpty())
        }
    }

    return(this)
}

pointer scalar function tuple_compress_i(pointer vector patterns, real scalar i) {
    class Pattern scalar pattern

    pattern = *patterns[i]
    return(&pattern.compress())
}

transmorphic scalar Tuple::overlap(transmorphic scalar pattern) {
    if (classname(pattern) == "Tuple") {
        return(this.overlap_tuple(pattern))
    }
    else if (classname(pattern) == "POr") {
        return(this.overlap_por(pattern))
    }
    else {
        errprintf("Unexpected pattern class: %s", classname(pattern))
        exit(_error(3260))
    }
}

real scalar Tuple::includes(class Tuple scalar tuple) {
    class Pattern scalar pattern_i
    real scalar included
    real scalar i

    check_tuples_length(this, tuple)

    included = 1

    for (i = 1; i <= length(this.patterns); i++) {
        pattern_i = *this.patterns[i]
        if (!pattern_i.includes(*tuple.patterns[i])) {
            included = 0
            break
        }
    }

    return(included)
}

void function check_tuples_length( ///
    class Tuple scalar tuple_1, ///
    class Tuple scalar tuple_2    ///
) {
    if (length(tuple_1.patterns) != length(tuple_2.patterns)) {
        errprintf(
            "The tuples different sizes %f and %f",
            length(tuple_1.patterns), length(tuple_2.patterns)
        )
        exit(_error(3300))
    }
}

transmorphic scalar Tuple::overlap_tuple(class Tuple scalar tuple) {
    class Pattern scalar pattern_i
    class Tuple scalar tuple_overlap
    real scalar i

    tuple_overlap.patterns = J(1, length(this.patterns), NULL)

    // We compute the overlap of each pattern in the tuple
    for (i = 1; i <= length(this.patterns); i++) {
        pattern_i = *this.patterns[i]
        tuple_overlap.patterns[i] = &pattern_i.overlap(*tuple.patterns[i])
    }

    return(tuple_overlap.compress())
}

transmorphic scalar Tuple::overlap_por(class POr scalar por) {
    class POr scalar por_overlap
    real scalar i
    
    // We compute the overlap for each tuple in the Or pattern
    for (i = 1; i <= por.len(); i++) {
        por_overlap.push(&this.overlap(por.get_pat(i)))
    }

    return(por_overlap.compress())
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
pointer scalar Tuple::difference(transmorphic scalar pattern) {
    if (classname(pattern) == "PEmpty") {
        return(&this)
    }
    else if (classname(pattern) == "POr") {
        return(this.difference_por(pattern))
    }
    else if (classname(pattern) != "Tuple") {
        errprintf("Unexpected pattern class %s", classname(pattern))
        exit(_error(101))
    }

    return(this.difference_tuple(pattern))
}

pointer scalar Tuple::difference_por(class POr scalar por) {
    class POr scalar por_result
    
    por_result.define(difference_list(this, por.patterns))

    return(&por_result.compress())
}

pointer scalar Tuple::difference_tuple(class Tuple scalar tuple) {
    class POr scalar res_inter, res_diff, result
    transmorphic scalar new_diff
    class Pattern scalar main_pattern, other_pattern, field_inter
    pointer vector field_diff
    class Tuple scalar new_main, new_other, new_diff_i
    class PatternList scalar pat_list
    real scalar i
    
    // Compute the field difference
    main_pattern = *this.patterns[1]
    other_pattern = *tuple.patterns[1]

    field_inter = main_pattern.overlap(other_pattern)
    field_diff = main_pattern.difference(other_pattern)

    // If there are no other fields
    if (length(this.patterns) == 1) {
        if (classname(*field_diff) != "PEmpty") {
            res_diff.push(tuple_from_patterns(field_diff))
        }
    }
    else {
        // If the fields difference is empty there is no difference part
        if (classname(*field_diff) != "PEmpty") {
            res_diff.push(tuple_from_patterns((field_diff, this.patterns[2..length(this.patterns)])))
        }

        // If the fields intersection is empty there is intersection part
        if (classname(field_inter) != "PEmpty") {
            // Build two tuples with the reaining patterns
            new_main.patterns = this.patterns[2..length(this.patterns)]

            new_other.patterns = tuple.patterns[2..length(this.patterns)]

            // Compute the difference
            new_diff = *new_main.difference(new_other)

            // If non empty, we fill the tuples
            if (classname(new_diff) == "Tuple") {
                new_diff_i = new_diff
                res_inter.push(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
            }
            else if (classname(new_diff) == "PatternList") {
                pat_list = new_diff
                for (i = 1; i <= pat_list.length; i++) {
                    new_diff_i = pat_list.get_pat(i)
                    res_inter.push(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
                }
            }
            else if (classname(new_diff) != "PEmpty") {
                errprintf("Unexpected pattern of class '%s'", classname(*new_diff))
                exit(_error(3260))
            }
        }
    }

    result.push(&res_diff)
    result.push(&res_inter)

    return(&result.compress())
}

pointer scalar function tuple_from_patterns(pointer vector patterns) {
    class Tuple scalar tuple

    tuple.patterns = patterns
    return(&tuple)
}

// To compute the difference between a tuple and a list of tuple
// We have an issue:
// 1. Compute the difference between our tuple and the first one
// 2. We obtain zero, one or more tuple corresponding to the difference
// 3. Compute the difference between each of these tuples and the second one
// 4. We obtain a new vector of differences
// 5. We repeat until we have checked all the tuples in the list
// We can stop earlier if at some point we have no difference remaining
transmorphic scalar function difference_vec( ///
    class Pattern scalar pattern,
    class Tuple vector tuples ///
) {
    class PatternList scalar differences
    transmorphic scalar new_differences
    real scalar i

    differences.push(&pattern)

    for (i = 1; i <= length(tuples); i++) {

        new_differences = *differences.difference(tuples[i])

        if (classname(new_differences) == "PEmpty") {
            return(new_differences)
        }
        else {
            differences = new_differences
        }
    }

    return(differences)
}


real scalar function is_empty_ctor(class Tuple vector tuples) {
    if (length(tuples) == 0) {
        return(1)
    }
    else if (length(tuples) == 1) {
        return(length(tuples[1].patterns) == 0)
    }
    else {
        return(0)
    }
}


                // x = (1 | 2, 1 | 2, 1 | 2)
                // y = (1, 1 | 2, 1)
                // diff_tuple(x, y)
                // 1. diff((1 | 2, 1 | 2, 1 | 2), (1, 1 | 2, 1))
                //        - overlap(1 | 2, 1)
                //        => overlap_pattern = 1
                //        - 1 | 2 - 1
                //        => diff_field = 2
                //        => not_overlap = (2, 1 | 2, 1 | 2)
                // 2. diff((1 | 2, 1 | 2), (1 | 2, 1))
                //        - overlap(1 | 2, 1 | 2)
                //        => overlap_pattern = 1 | 2
                //        - 1 | 2 - 1 | 2
                //        => diff_field = 0
                //        => not_overlap = 0
                // 3. diff((1 | 2), (1))
                //        - overlap(1 | 2, 1)
                //        => overlap_pattern = 1
                //        - 1 | 2 - 1
                //        => diff_field = 2
                //        => not_overlap = 2
                //        => remaining = 0
                //      return((2))
                // 2.
                //        => remaining_other_fields = (2)
                //        => remaining = (1 | 2, 2)
                //        return((1 | 2, 2))
                // 1.
                //        => remaining_other_fields = (1 | 2, 2)
                //        => remaining = (1, 1 | 2, 2)
                //        return((2, 1 | 2, 1 | 2), (1, 1 | 2, 2))


end


**#**************************************************************** src/arm.mata

mata

void Arm::new() {}

string scalar Arm::to_string() {
    class Pattern scalar pattern

    pattern = *this.lhs.pattern
    return(
        sprintf(
            "Arm %f: Tuple: %s / Value: %s",
            this.id, pattern.to_string(), this.value
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
    real scalar gen_first
) {
    class Arm scalar arm
    class Pattern scalar pattern
    string scalar command, condition, statement
    real scalar i, n

    n = length(arms)
    
    displayas("text")
    for (i = n; i >= 1; i--) {
        arm = arms[i]
        pattern = *arm.lhs.pattern
        
        if (i == n & gen_first) {
            command = "generate"
        }
        else {
            command = "replace"
        }
        
        if (length(variables) == 1) {
            condition = pattern.to_expr(variables[1].name)
        }
        else {
            condition = pattern.to_expr(variables)
        }
        
        if (condition == "1") {
            statement = sprintf(`"%s %s = %s"', command, varname, arm.value)
        }
        else {
            statement = sprintf(`"%s %s = %s if %s"', command, varname, arm.value, condition)
        }

        stata(statement, 1)
    }
}

end


**#************************************************************* src/parser.mata

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

    check_next(t, "=", arm_id)

    arm.value = parse_value(t)
    
    arm.has_wildcard = check_wildcard(arm.lhs.pattern)

    return(arm)
}

class Pattern scalar function parse_pattern(
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

    if (symbole == "/") {
        in_min = 1
        in_max = 1
    }
    else if (symbole == "!/") {
        in_min = 0
        in_max = 1
    }
    else if (symbole == "/!") {
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
    class Pattern scalar overlap
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
            overlap = *lhs.pattern
            
            if (classname(overlap) != "PEmpty") {
                str = str,
                    sprintf("    Arm %f: %s", lhs.arm_id, overlap.to_string())
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

    if (length(this.missings) == 0) {
        return(strings)
    }

    if (classname(this.missings) == "PEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (classname(this.missings) == "POr") {
        strings = strings, this.to_string_por(this.missings)
    }
    else {
        strings = strings, this.to_string_pattern(this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(class Pattern scalar pattern) {
    return(sprintf("    %s", pattern.to_string()))
}

string vector Match_report::to_string_por(class POr scalar por) {
    string vector strings
    real scalar i

    strings = J(1, por.len(), "")
    
    for (i = 1; i <= por.len(); i++) {
        strings[i] = this.to_string_pattern(por.get_pat(i))
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
    class Pattern scalar missings
    class Arm scalar arm
    class Arm vector useful_arms
    real scalar i

    report.usefulness = check_useful(arms)

    useful_arms = Arm(0)

    for (i = 1; i <= length(report.usefulness); i++) {
        usefulness = report.usefulness[i]
        if (usefulness.useful == 1) {
            arm = arms[i]
            arm.lhs.pattern = usefulness.differences
            useful_arms = useful_arms, arm
        }
    }

    missings = check_completeness(useful_arms, variables)
    report.missings = missings.compress()

    report.print()
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
        usefulness = is_useful(arms[i], useful_arms)
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
    transmorphic scalar tuple
    class Pattern scalar tuple_pattern, differences_pattern
    struct LHS vector overlaps
    struct LHS scalar lhs_empty
    transmorphic scalar differences
    class Usefulness scalar result
    class Arm scalar ref_arm
    real scalar i, k

    lhs_empty.pattern = &(PEmpty())

    overlaps = LHS(length(useful_arms))

    tuple = *arm.lhs.pattern
    tuple_pattern = tuple

    differences = tuple

    // If it is the first pattern, it's always useful
    if (length(useful_arms) == 0) {
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = &differences

        return(result)
    }

    // We loop over all the patterns
    for (i = 1; i <= length(useful_arms); i++) {
        // TODO: Use difference
        ref_arm = useful_arms[i]

        overlaps[i].arm_id = ref_arm.id
        overlaps[i].pattern = &tuple_pattern.overlap(*ref_arm.lhs.pattern)

        if (classname(*overlaps[i].pattern) != "PEmpty") {
            differences_pattern = differences
            differences = *differences_pattern.difference(*overlaps[i].pattern)
        }
    }

    k = 0
    for (i = 1; i <= length(overlaps); i++) {
        overlaps[i].pattern = get_and_compress(overlaps, i)
        if (classname(*overlaps[i].pattern) != "PEmpty") {
            k++
            // Copy member by member
            // Otherwise it's empty at the end of the loop
            // And it crashes when trying to access it
            overlaps[k].arm_id = overlaps[i].arm_id
            overlaps[k].pattern = overlaps[i].pattern
        }
    }

    if (k == 0) {
        // No overlap, return tuple
        result.useful = 1
        result.any_overlap = 0
        result.overlaps = &lhs_empty
        result.differences = &tuple
    }
    else {
        // Compute the remaining patterns
        //differences = difference_vec(tuple_pattern, overlaps[1..k])

        if (classname(differences) == "PEmpty") {
            // If no pattern remains, the pattern is not useful
            result.useful = 0
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = &differences
        }
        else {
            // Else return the tuple, the overlaps and the differences
            result.useful = 1
            result.any_overlap = 1
            result.overlaps = &overlaps[1..k]
            result.differences = &differences
        }
    }

    return(result)
}

function get_and_compress(struct LHS vector overlaps, i) {
    class Pattern scalar pattern_i

    pattern_i = *overlaps[i].pattern
    return(&pattern_i.compress())
}

///////////////////////////////////////////////////////////// Check completeness

class Tuple vector function check_completeness( ///
        class Arm vector arms, ///
        class Variable vector variables ///
    ) {
    class Arm scalar wild_arm
    class PWild vector pwilds
    class Tuple scalar tuple
    class Usefulness scalar usefulness
    real scalar i

    pwilds = PWild(length(variables))

    for (i = 1; i <= length(variables); i++) {
        pwilds[i].define(variables[i])
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

    usefulness = is_useful(wild_arm, arms)

    return(*usefulness.differences)
}

end


**#************************************************************* src/pmatch.mata

// Main function for the `pmatch` command
// The // bench_on() and // bench_off() functions are not used in the online code)

mata
function pmatch(
    string scalar newvar,
    string scalar vars_exp,
    string scalar body,
    real scalar check,
    real scalar gen_first
) {
    class Variable vector variables
    class Arm vector arms, useful_arms

    // bench_on("total")
    
    // bench_on("init")
    variables = init_variables(vars_exp, check)
    // bench_off("init")
    
    // bench_on("parse")
    arms = parse_string(body, variables)
    // bench_off("parse")
    
    // bench_on("check")
    if (check) {
        check_match(arms, variables)
    }
    // bench_off("check")
    
    // bench_on("eval")
    eval_arms(newvar, arms, variables, gen_first)
    // bench_off("eval")

    // bench_off("total")
}
end


**#************************************************************** src/pmatch.ado

// pmatch command
// see "src/pmatch.mata" for the entry point in the algorithm

program pmatch
    syntax namelist(min=1 max=1), ///
        Variables(varlist min=1) Body(str asis) ///
        [REPLACE NOCHECK]
    
    local check     = ("`nocheck'" == "")
    
    check_replace `namelist', `replace'
    local gen_first = ("`replace'" == "")

    mata: pmatch("`namelist'", "`variables'", `"`body'"', `check', `gen_first')
end

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

