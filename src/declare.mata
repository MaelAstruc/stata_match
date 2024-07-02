mata

mata clear

//////////////////////////////////////////////////////////////////////// Pattern

// The parent class for all patterns
class Pattern {
    virtual void define(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
}

// Empty pattern
class PEmpty extends Pattern {
    virtual void define(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
}

// Wild card '_'
class PWild extends Pattern {
    pointer scalar values

    virtual void define(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
    pointer scalar get_values()
}

// Constant
class PConstant extends Pattern {
    transmorphic scalar value

    virtual void define(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
}

// Real or Float Range
class PRange extends Pattern {
    real scalar min, max, in_min, in_max, discrete

    virtual void define(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
}

class PatternList extends Pattern {
    public pointer vector patterns
    public real scalar capacity // Number of pre-allocated pointers
    public real scalar length // Number of patterns initiated

    virtual void print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()

    void new()
    string scalar to_string_ln()

    pointer scalar last(), pop(), get()
    transmorphic scalar get_pat()

    void resize()
    void push(), push_value(), append()
    void replace(), remove(), swap_remove()
    void trim(), clear()

    void check_integer(), check_range(), check_empty()
}

// Or pattern, which is a list of pointers to patterns
class POr extends Pattern {
    class PatternList scalar patterns

    virtual void define(), insert(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    virtual real scalar includes()
    real scalar len()
}

class Tuple extends Pattern {
    real scalar arm_id
    pointer vector patterns

    virtual void define(), insert(), print()
    virtual string scalar to_string(), to_expr()
    virtual transmorphic overlap()
    virtual transmorphic scalar compress()
    virtual pointer scalar difference()
    transmorphic scalar difference_vec()
    real scalar includes()
}

/////////////////////////////////////////////////////////////////////// Variable

class Variable {
    string scalar name
    string scalar type
    string scalar stata_type
    class POr scalar values

    string scalar to_string()
    void print(), init(), init_type(), init_values()
}

//////////////////////////////////////////////////////////////////////////// Arm

struct LHS {
    real scalar arm_id
    pointer scalar pattern
}

class Arm {
    struct LHS scalar lhs
    string scalar value
    real scalar id

    string scalar to_string()
    void print()
}

///////////////////////////////////////////////////////////////////// Usefulness


class Usefulness {
    real scalar useful // 1 if the pattern is useful, 0 if not
    real scalar any_overlap
    pointer scalar tuple
    real scalar arm_id
    pointer scalar overlaps
    pointer scalar differences

    string vector to_string()
    void print(), define()
}

end
