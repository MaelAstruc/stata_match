mata

//#********************************************************************** SET-UP

mata clear
mata set matastrict on

timer_clear()

struct mystruct {
    real scalar n1, n2
}

// Create pointers to unique structs
// Otherwise, in a loop all the pointers point to the same struct
pointer(struct mystruct) function gen_struct_ptr() {
    struct mystruct temp_struct
    
    temp_struct = mystruct()
    return(&temp_struct)
}

//#******************************************************* ACCESS AND MODIFY ONE

// Just loop
function test_1(real scalar n) {
    struct mystruct scalar struct_1
    real scalar i

    timer_on(1)
    for (i = 0; i < n; i = i + 1) {
    }
    timer_off(1)
    
    stata("mata: mata memory")
}

// Assign in a struct
function test_2(real scalar n) {
    struct mystruct scalar struct_1
    real scalar i

    timer_on(2)
    for (i = 0; i < n; i = i + 1) {
        struct_1.n1 = i
    }
    timer_off(2)
    
    stata("mata: mata memory")
}

// Assign in a vector
function test_3(real scalar n) {
    real vector vec_1
    real scalar i
    
    vec_1 = J(2, 1, .)
    
    timer_on(3)
    for (i = 0; i < n; i = i + 1) {
        vec_1[1] = i
    }
    timer_off(3)
    
    stata("mata: mata memory")
}

// Assign string in a vector
function test_4(real scalar n) {
    string vector vec_1
    real scalar i
    
    vec_1 = J(2, 1, "")
    
    timer_on(4)
    for (i = 0; i < n; i = i + 1) {
        vec_1[1] = "1"
    }
    timer_off(4)
    
    stata("mata: mata memory")
}

// Assign string in a vector with a call to str of real
function test_5(real scalar n) {
    string vector vec_1
    real scalar i
    
    vec_1 = J(2, 1, "")
    
    timer_on(5)
    for (i = 0; i < n; i = i + 1) {
        vec_1[1] = strofreal(i)
    }
    timer_off(5)
    
    stata("mata: mata memory")
}

//#*************************************************** ACCESS AND MODIFY VECTORS

// Vector of structs
function test_11(real scalar n) {
    struct mystruct vector struct_1
    real scalar i

    timer_on(10)
    
    timer_on(11)
    struct_1 = mystruct(n)
    timer_off(11)
    
    timer_on(12)
    for (i = 1; i <= n; i = i + 1) {
        struct_1[i].n1 = i
    }
    timer_off(12)
    
    timer_off(10)
    
    stata("mata: mata memory")
}

// Vector of pointers to vectors
function test_12(real scalar n) {
    pointer(struct mystruct) vector vec_ptr
    real scalar i
    
    timer_on(20)
    
    timer_on(21)
    vec_ptr = J(n, 1, NULL)
    for (i = 1; i <= n; i = i + 1) {
        vec_ptr[i] = gen_struct_ptr()
    }
    timer_off(21)
    
    timer_on(22)
    for (i = 1; i <= n; i = i + 1) {
        (*vec_ptr[i]).n1 = i
    }
    timer_off(22)

    timer_off(20)
    
    stata("mata: mata memory")
}

// Vector of pointers to vectors
function test_13(real scalar n) {
    pointer(real vector) vector vec_ptr
    real scalar i
    
    timer_on(30)
    
    timer_on(31)
    vec_ptr = J(n, 1, NULL)
    for (i = 1; i <= n; i = i + 1) {
        vec_ptr[i] = &J(2, 1, .)
    }
    timer_off(31)
    
    timer_on(32)
    for (i = 1; i <= n; i = i + 1) {
        (*vec_ptr[i])[1] = i
    }
    timer_off(32)
    
    timer_off(30)
    
    stata("mata: mata memory")
}

// Flatten the vector
function test_14(real scalar n) {
    real vector vec_1
    real scalar i
    
    timer_on(40)
    
    timer_on(41)
    vec_1 = J(2 * n, 1, .)
    timer_off(41)
    
    timer_on(42)
    for (i = 1; i <= n; i = i + 1) {
        vec_1[i * 2] = i
    }
    timer_off(42)
    
    timer_off(40)
    
    stata("mata: mata memory")
}

// Flatten the vector of strings
function test_15(real scalar n) {
    string vector vec_1
    real scalar i
    
    timer_on(50)
    
    timer_on(51)
    vec_1 = J(2 * n, 1, "")
    timer_off(51)
    
    timer_on(52)
    for (i = 1; i <= n; i = i + 1) {
        vec_1[i * 2] = "1"
    }
    timer_off(52)
    
    timer_off(50)
    
    stata("mata: mata memory")
}

//#**************************************************************** POLYMORPHISM

/*
The first version uses classes, methods and inheritance
The second step is removing inheritance by using structs
The last possibility is to use vectors
  - a vector of with a first value that indicates the type
  - the other fields that correspond to the type
  ? the different types need different size
    -> given the type we know the loayout of the vector 
    - in OR patterns we can use a flatten vector
    - the issue with custom size patterns is that we cannot jump to the nth one
    - also we cannot remove a pattern by swapping it to last place
*/

// Test with Constant, Range and Or patterns and to_string() method

// OOP style

class Pattern {
    virtual string scalar to_string()
    virtual transmorphic overlap()
}

class PEmpty extends Pattern {
    virtual string scalar to_string()
    virtual transmorphic overlap()
}

class PConstant extends Pattern {
    real scalar value
    
    virtual string scalar to_string()
    virtual transmorphic overlap()
}

class PRange extends Pattern {
    real scalar min, max, type_nb
    
    virtual string scalar to_string()
    virtual transmorphic overlap()
    transmorphic scalar compress()
}

class POr extends Pattern {
    pointer vector patterns
    real scalar length, capacity

    virtual string scalar to_string()
    virtual transmorphic overlap()
}

pointer function gen_class_ptr(i) {
    class PConstant scalar temp_constant
    class PRange scalar temp_range
    
    if (mod(i, 2) == 0) {
        temp_constant = PConstant()
        temp_constant.value = 1
        return(&temp_constant)
    } else {
        temp_range = PRange()
        temp_range.min = 0
        temp_range.max = 2
        temp_range.type_nb = 1
        return(&temp_range)
    }
}

////// to_string()

string scalar PEmpty::to_string() {
    return("Empty")
}

string scalar PConstant::to_string() {
    return(strofreal(this.value))
}

string scalar PRange::to_string() {
    return(strofreal(this.min) + "/" + strofreal(this.max))
}

string scalar POr::to_string() {
    class Pattern scalar pattern
    string vector str_vec
    real scalar i

    if (this.length == 0) {
        return("")
    }

    str_vec = J(1, this.length, "")
    
    for (i = 1; i <= this.length; i++) {
        pattern = *this.patterns[i]
        str_vec[i] = pattern.to_string()
    }

    return(invtokens(str_vec, " | "))
}

////// overlap()

transmorphic PEmpty::overlap(transmorphic scalar pattern) {
    return(this)
}

transmorphic PConstant::overlap(transmorphic scalar pattern) {
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por

    if (classname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (classname(pattern) == "PConstant") {
        pconstant = pattern
        
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

transmorphic scalar PRange::compress() {
    class PConstant scalar pconstant

    // The range can also be empty or a constant
    if (this.min > this.max) {
        return(PEmpty())
    }
    else if (this.min == this.max) {
        pconstant.value = this.min
        return(pconstant)
    }
    else {
        return(this)
    }
}

transmorphic PRange::overlap(transmorphic scalar pattern) {
    class PRange scalar inter_range
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    
    if (classname(pattern) == "PEmpty") {
        return(PEmpty())
    }
    else if (classname(pattern) == "PWild") {
        return(this)
    }
    else if (classname(pattern) == "PConstant") {
        pconstant = pattern
        if (pconstant.value >= this.min & pconstant.value <= this.max) {
            return(pconstant)
        }
        else {
            return(PEmpty())
        }
    }
    else if (classname(pattern) == "PRange") {
        prange = pattern
        
        if (this.min > prange.max) return(PEmpty())
        if (this.max < prange.min) return(PEmpty())

        inter_range.type_nb = this.type_nb

        // Determine the minimum
        if (this.min >= prange.min) {
            inter_range.min = this.min
        }
        else {
            inter_range.min = prange.min
        }

        // Determine the maximum
        if (this.max <= prange.max) {
            inter_range.max = this.max
        }
        else {
            inter_range.max = prange.max
        }

        // Return the compressed version
        return(inter_range.compress())
    }
    else if (classname(pattern) == "POr") {
        por = pattern
        return(por.overlap(this))
    }
}

transmorphic POr::overlap(class Pattern scalar pattern) {
    class POr scalar por
    real scalar i
    real scalar check_includes

    por = POr()
    por.patterns = J(8, 1, NULL)
    por.capacity = 8
    por.length = 0

    for (i = 1; i <= this.length; i++) {
        por.length = por.length + 1
        
        if (por.length > por.capacity) {
            por.patterns = por.patterns \ J(por.capacity, 1, NULL)
            por.capacity = por.capacity * 2
        }
        
        por.patterns[por.length] = &por_overlap(this, i, pattern)
    }

    if (por.length == 0) {
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
    pattern_i = *por.patterns[i]
    return(pattern_i.overlap(pattern))
}

///////////////////////////////////////////////////////////////// Vector version

real matrix function gen_vec(real scalar n) {
    real matrix por
    real scalar i

    por = J(n + 1, 4, .)
    por[1, 1] = 4
    por[1, 2] = 0
    
    for (i = 2; i <= n + 1; i++) {
        if (mod(i, 2) == 0) {
            por[i, 1] = 2
            por[i, 2] = 1
        }
        else {
            por[i, 1] = 3
            por[i, 2] = 0
            por[i, 3] = 2
            por[i, 4] = 1
        }
    }
    
    por[1, 2] = n
    
    return(por)
}

///// to_string()

string scalar to_string_vec_pconstant(pointer(real matrix) pattern, real scalar index) {
    return(strofreal((*pattern)[index, 2]))
}

string scalar to_string_vec_prange(pointer(real matrix) pattern, real scalar index) {
    real scalar min, max, in_min, in_max
    string scalar sym
    
    min = (*pattern)[index, 2]
    max = (*pattern)[index, 3]
    
    return(strofreal(min) + "/" + strofreal(max))
}

string scalar to_string_vec_por(pointer(real matrix) pattern, real scalar index) {
    string vector str_vec
    real scalar n_pat, i
    
    n_pat = (*pattern)[index, 2]
    
    if (n_pat == 0) {
        return("")
    }
    else {
        str_vec = J(1, n_pat, "")
        
        for (i = 1; i <= n_pat; i++) {
            str_vec[i] = to_string_vec(pattern, index + i)
        }
        
        return(invtokens(str_vec, " | "))
    }
}

string scalar to_string_vec(pointer(real matrix) pattern, real scalar index) {
    real scalar type_pat
    
    type_pat = (*pattern)[index, 1]
    
    if (type_pat == 1) {
        return("Empty")
    }
    else if (type_pat == 2) {
        return(to_string_vec_pconstant(pattern, index))
    }
    else if (type_pat == 3) {
        return(to_string_vec_prange(pattern, index))
    }
    else if (type_pat == 4) {
        return(to_string_vec_por(pattern, index))
    }
    else {
        exit(99999)
    }
}

///// overlap()

function overlap_vec_pconstant(pointer(real matrix) scalar overlap, pointer(real matrix) scalar pattern, real scalar index, pointer(real matrix) scalar other_patterns, real scalar other_index) {
    real scalar type_pat
    real scalar value
    real scalar overlap_end
    
    value = (*pattern)[index, 2]
    
    type_pat = (*other_patterns)[other_index, 1]
    
    if (type_pat == 1) {
        // Empty, nothing to do
    }
    else if (type_pat == 2) {
        
        overlap_end = (*overlap)[1, 2]
        
        if (value == (*other_patterns)[other_index, 2]) {
            overlap_end++
            (*overlap)[1, 2] = overlap_end
            (*overlap)[overlap_end, 1] = 1
            (*overlap)[overlap_end, 2] = value
        }
    }
    else if (type_pat == 3) {
        overlap_vec_prange(overlap, other_patterns, other_index, pattern, index)
    }
    else if (type_pat == 4) {
        overlap_vec_por(overlap, other_patterns, other_index, pattern, index)
    }
    else {
        exit(99999)
    }
}

function prange_vec_compress(pointer(real matrix) scalar prange, real scalar index) {
    // The range can also be empty or a constant
    if ((*prange)[index, 2] > (*prange)[index, 3]) {
        (*prange)[index, 1] = 1
        (*prange)[index, 2] = .
        (*prange)[index, 3] = .
        (*prange)[index, 4] = .
    }
    else if ((*prange)[index, 2] == (*prange)[index, 3]) {
        (*prange)[index, 1] = 2
        (*prange)[index, 3] = .
        (*prange)[index, 4] = .
    }
    else {
        // no change
    }
}

function overlap_vec_prange(pointer(real matrix) scalar overlap, pointer(real matrix) scalar pattern, real scalar index, pointer(real matrix) scalar other_pattern, real scalar other_index) {
    real scalar min, max, new_min, new_max, type_nb
    real scalar other_min, other_max, other_in_min, other_in_max
    real scalar type_pat
    real scalar value, above_min, below_max
    real scalar overlap_end
    real vector inter_range
    
    type_pat = (*other_pattern)[other_index, 1]
    
    min      = (*pattern)[index, 2]
    max      = (*pattern)[index, 3]
    type_nb  = (*pattern)[index, 4]
    
    overlap_end = (*overlap)[1, 2]
    
    if (type_pat == 1) {
        // Nothing to do
    }
    else if (type_pat == 2) {
        value = (*other_pattern)[other_index, 2]

        // The constant is above the minimum
        above_min = value >= min
        below_max = value <= max
                    
        if (above_min & below_max) {
            overlap_end++
            (*overlap)[overlap_end, 1] = 2
            (*overlap)[overlap_end, 2] = value
            (*overlap)[1, 2] = overlap_end
        }
    }
    else if (type_pat == 3) {            
        other_min    = (*other_pattern)[other_index, 2]
        other_max    = (*other_pattern)[other_index, 3]
        
        new_min = max((min, other_min))
        new_max = min((max, other_max))
        
        if (new_min > new_max) return

        overlap_end++
        
        // Modify overlap depending on result
        if (new_min == new_max) {
            (*overlap)[overlap_end, 1] = 2
            (*overlap)[overlap_end, 2] = new_min
        }
        else {
            (*overlap)[overlap_end, 1] = 3
            (*overlap)[overlap_end, 2] = new_min
            (*overlap)[overlap_end, 3] = new_max
            (*overlap)[overlap_end, 4] = type_nb
        }
    }
    else if (type_pat == 4) {
        overlap_vec_por(overlap, other_pattern, other_index, pattern, index)
    }
    else {
        exit(99999)
    }
}

function overlap_vec_por(pointer(real matrix) scalar overlap, pointer(real matrix) scalar pattern, real scalar index, pointer(real matrix) scalar other_patterns, real scalar other_index) {
    real scalar check_includes
    real scalar n_pat, i, k
    
    n_pat = (*pattern)[index, 2]
    
    if (n_pat == 0) {
        // nothing
        return
    }
    else {
        for (i = 1; i <= n_pat; i++) {
            overlap_vec(overlap, pattern, index + i, other_patterns, other_index)
        }
    }
}

function overlap_vec(pointer(real matrix) scalar overlap, pointer(real matrix) scalar pattern, real scalar index, pointer(real matrix) scalar other_patterns, real scalar other_index) {
    real scalar type_pat

    type_pat = (*pattern)[index, 1]
    
    if (type_pat == 1) {
    }
    else if (type_pat == 2) {
        overlap_vec_pconstant(overlap, pattern, index, other_patterns, other_index)
    }
    else if (type_pat == 3) {
        overlap_vec_prange(overlap, pattern, index, other_patterns, other_index)
    }
    else if (type_pat == 4) {
        overlap_vec_por(overlap, pattern, index, other_patterns, other_index)
    }
    else {
        exit(99999)
    }
}

////// Tests

// to_string()

function test_21(real scalar n) {
    class POr scalar por
    string scalar _
    real scalar i
    
    timer_on(60)
    
    timer_on(61)
    por = POr()
    por.patterns = J(n, 1, NULL)
    por.capacity = n
    por.length = 0
    
    for (i = 1; i <= n; i = i + 1) {
        por.patterns[i] = gen_class_ptr(i)
    }
    por.length = n
    timer_off(61)
    
    timer_on(62)
    _ = por.to_string()
    timer_off(62)
    
    timer_off(60)
    
    stata("mata: mata memory")
}

function test_22(real scalar n) {
    real matrix por
    string scalar _
    
    timer_on(70)
    
    timer_on(71)
    por = gen_vec(n)
    timer_off(71)

    timer_on(72)
    _ = to_string_vec(&por, 1)
    timer_off(72)

    timer_off(70)
    
    stata("mata: mata memory")
}

// overlap()

function test_23(real scalar n) {
    class POr scalar por
    class PConstant scalar pconstant
    class POr scalar result
    real scalar i
    
    timer_on(80)
    
    timer_on(81)
    por = POr()
    por.patterns = J(n, 1, NULL)
    por.capacity = n
    
    for (i = 1; i <= n; i = i + 1) {
        por.patterns[i] = gen_class_ptr(i)
    }
    
    por.length = n
    
    pconstant = PConstant()
    pconstant.value = 2
    timer_off(81)
    
    timer_on(82)
    result = por.overlap(pconstant)
    // result.to_string()
    timer_off(82)
    
    timer_off(80)
    
    stata("mata: mata memory")
}

function test_24(real scalar n) {
    real matrix por, overlap
    real matrix pconstant
    
    timer_on(90)
    
    timer_on(91)
    por = gen_vec(n)
    
    pconstant = J(1, 4, .)
    pconstant[1, 1] = 2
    pconstant[1, 2] = 2
    timer_off(91)

    timer_on(92)
    overlap = J(n + 1, 4, .)
    overlap[1, 1] = 4
    overlap[1, 2] = 2
    
    overlap_vec(&overlap, &por, 1, &pconstant, 1)
    // to_string_vec(&overlap, 1)
    timer_off(92)

    timer_off(90)
    
    stata("mata: mata memory")
}

//#********************************************************************* RESULTS

/*
Two points:
    - Speed performance
    - Memory performance
        - same autoloaded functions
        - same defined functions
        - we look at matrices and scalars + overhead
*/

N = 10^7

// functions(N) // time | mat & scal + overhead
test_1(N) //  .503s | 121 + 1,904
test_2(N) //  .617s | 121 + 1,904
test_3(N) //  .639s |  97 + 1,736
test_4(N) // 1.487s |  98 + 1,736
test_5(N) // 4.766s | 104 + 1,736

// We can indeed measure the overhead to the modifications
// There is no clear difference between modifying a struct and a vector
// Modifying a string vector is at least x2 slower
// Including a call to strofreal() is slow, it matters in benchmarks

// Structs have a larger memory overhead

N = 10^6

test_11(N) // 2.876 = 2.623 + .253 | 40,000,081 + 168,001,736
test_12(N) // 5.410 = 5.090 + .320 | 48,000,081 + 224,001,736
test_13(N) //  .765 =  .610 + .155 | 24,000,081 +  56,001,736
test_14(N) //  .104 =  .002 + .102 | 16,000,081 +       1,736
test_15(N) //  .259 =  .006 + .253 | 17,000,081 +       1,736

// A vector of struct is slow
// A vector of pointers to structs is slow
//  - probably because we need another function call to create pointer
//  - might be necessary if there a different structs
// A vector of pointers to vectors is faster
// A flatten vector is the fastest
// A flatten vector of strings is still fast

// Flatten vectors are really memory efficient compared to structs
//  - it uses less matrices and scalars
//  - there is far less overhead compared to structs

// Using flatten vectors should
//  - divide memory usage by 2
//  - improve speed by almost x3 for reals
//  - improve speed by at least x2 for strings

N = 10^6

test_21(N) // 7.348 = 5.139 + 2.209 | 85,000,078 + 280,001,960
test_22(N) // 2.377 =  .308 + 2.069 | 53,000,070 +       1,904

// Doing a more concrete example with to_string()
// In terms of memory
//   - vectors have much less overhead
//   - it scales linearly
// In terms of speed
//   - vectors are faster because the initial allocation is faster
//   - classes seem limited by memory
//     -> N = 10^3 =>     .006 =   .002 +   .004
//     -> N = 10^4 =>     .060 =   .037 +   .023
//     -> N = 10^5 =>     .536 =   .326 +   .210
//     -> N = 10^6 =>    7.348 =  5.139 +  2.209
//     -> N = 10^7 =>  139.298 = 60.885 + 78.413
//   - vectors scale linearly
//     -> N = 10^3 =>     .003 =   .001 +   .002
//     -> N = 10^4 =>     .025 =   .004 +   .021
//     -> N = 10^5 =>     .248 =   .032 +   .216
//     -> N = 10^6  =>   2.377 =   .308 +  2.069
//     -> N = 10^7 =>   27.790 =  3.676 + 24.114
// => In my case 10^7 does not make sense, but still good to know

N = 10^6

test_23(N) // 6.198 = 2.395 + 3.803 | 100,388,817 + 336,003,304
test_24(N) // 2.310 =  .298 + 2.012 | 115,108,961 +       2,688

// Trying with overlap()
// In terms of memory
//   - it requires more memory for matrices and scalars
//   - the vectors are still more efficient with less overhead
//   - x3/x4 less memory
// In terms of speed
//   - vectors passed through pointers are faster than classes
//   - x3/x4 faster
// The memory limit impacts the classes for N = 10^7
//     -> classes =>  156.615 =  37.568 + 119.047
//     -> vectors =>   24.915 =   3.111 +  21.804

/*
 80.       6.32 /        1 =      6.32
 81.       2.22 /        1 =     2.217
 82.        4.1 /        1 =     4.103
 90.       1.93 /        1 =     1.927
 91.       .245 /        1 =      .245
 92.       1.68 /        1 =     1.682

*/

timer()

/*
CONCLUSION

These benchmarks suggest that moving from classes to vectors would improve speed and memory efficiency.

Regarding maintainability, the classes are easier to handle than the vectors with a header indicating the type. If I need to change something in the types, I will need to check all the parts of the code without better checks. Also, the question regarding the string variables remains.

However, with vectors I avoid strange issues that I have when using pointers to store different classes in a vector. Most notably when performing operations in a loop, where I shot me feet many times.

For the string variable issue I have two ideas right now:
    - create string vectors for string variables
      -> I can copy and paste the code
      -> The different vectors are stored in vectors of pointers
      -> Certainly a performance cost for the algorithm
    - store the strings in a sorted vector and use the index
      -> I need to replace in the parsing and evaluating steps
      -> I can reuse the same code for the algorithm
      -> No performance cost on the algorithm
      -> Probably a performance cost on the other steps
      -> Might be reusable when adding the labeled values
*/

end
