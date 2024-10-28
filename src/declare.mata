mata
mata set matastrict on

//////////////////////////////////////////////////////////////////////// Pattern

// Empty pattern
struct PEmpty { }

// Wild card '_'
struct PWild {
    // Members
    struct POr scalar values                                                     // The union of all possible levels                                                            // Add new value to the patterns
}

// Constant
struct PConstant {
    real scalar value                                                           // The value (real or string index)
}

// Real or Float Range
struct PRange {
    real scalar min                                                             // Minimum value
    real scalar max                                                             // Maximum value
    real scalar type_nb                                                         // 1 int, 2 float, 3 double
}

// Or pattern, which is a list of pointers to patterns
struct POr {
    // Members
    pointer vector patterns                                           // A dynamic array of patterns
    real scalar length
}

struct Tuple {
    // Members
    real scalar arm_id                                                          // The corresponding arm #
    pointer vector patterns                                                     // An array of patterns
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
