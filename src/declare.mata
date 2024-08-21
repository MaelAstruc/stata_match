mata

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
