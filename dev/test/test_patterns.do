/*
Do-file to test the pattern classes and methods
*/

// Representation of 0, 1, 2 and 3 in 21x format
local zero_21x  = "+0.0000000000000X-3ff"
local one_21x   = "+1.0000000000000X+000"
local two_21x   = "+1.0000000000000X+001"
local three_21x = "+1.8000000000000X+001"

local T         transmorphic     scalar
local POINTER   pointer          scalar
local POINTERS  pointer          vector
local REAL      real             scalar
local STRING    string           scalar

local PATTERN   real             matrix

local EMPTY     real             rowvector
local WILD      real             matrix
local CONSTANT  real             rowvector
local RANGE     real             rowvector
local OR        real             matrix

local EMPTY_TYPE     0
local WILD_TYPE      1
local CONSTANT_TYPE  2
local RANGE_TYPE     3
local OR_TYPE        4

local TUPLES    struct TupleOr   scalar
local TUPLE     struct Tuple     scalar

local VARIABLE  class Variable   scalar
local VARIABLES class Variable   vector

mata

////////////////////////////////////////////////////////// DEFINE TEST FUNCTIONS


//////////////////////////////////////////////////////////////////// to_string()

// PEmpty

function test_pempty_to_string() {
    `EMPTY' pempty

    pempty = new_pempty()

    test_result("Test PEmpty::to_string()", to_string(pempty), "Empty")
}

// PWild

function test_pwild_to_string() {
    `WILD' pwild
    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    test_result("Test PWild::to_string()", to_string(pwild), "_")
}

// PConstant

function test_pconstant_to_string() {
    `CONSTANT' pconstant

    pconstant = new_pconstant(1, 1)
    test_result("Test PConstant::to_string(): integer", to_string(pconstant), "1")
    
    pconstant = new_pconstant(1.1, 2)
    test_result("Test PConstant::to_string(): float", to_string(pconstant), "1.1")
    
    pconstant = new_pconstant(., 1)
    test_result("Test PConstant::to_string(): missing real", to_string(pconstant), ".")
}

// PRange

function test_prange_to_string() {
    `RANGE' prange

    prange = new_prange(1, 3, 1)
    test_result("Test PRange::to_string(): integer", to_string(prange), "1/3")
    
    prange = new_prange(1.1, 3.1, 2)
    test_result("Test PRange::to_string(): float", to_string(prange), "1.1/3.1")
    
    prange = new_prange(1.1, 3.1, 3)
    test_result("Test PRange::to_string(): double", to_string(prange), "1.1/3.1")
}

// POr

function test_por_to_string() {
    `OR' por
    `CONSTANT' pconstant
    `RANGE' prange
    
    por = new_por()
    
    test_result("Test POr::to_string(): empty", to_string(por), "")
    
    pconstant = new_pconstant(1, 1)
    por[2, .] = pconstant
    por[1, 2] = 1
    
    test_result("Test POr::to_string(): one element", to_string(por), "1")
    
    prange = new_prange(1, 3, 1)
    por[3, .] = prange
    por[1, 2] = 2
    
    test_result("Test POr::to_string(): two elements", to_string(por), "1 | 1/3")
}

// Tuple

function test_ptuple_to_string() {
    struct Tuple scalar tuple
    `CONSTANT' pconstant
    `RANGE' prange
    
    tuple = Tuple()
    
    test_result("Test Tuple::to_string(): empty", to_string(tuple), "Empty Tuple: Error")
    
    pconstant = new_pconstant(1, 1)
    
    tuple.patterns = J(1, 1, NULL)
    tuple.patterns[1] = &pconstant
    
    test_result("Test Tuple::to_string(): one element", to_string(tuple), "1")
    
    prange = new_prange(1, 3, 1)
    
    tuple.patterns = J(2, 1, NULL)
    tuple.patterns[1] = &pconstant
    tuple.patterns[2] = &prange
    test_result("Test Tuple::to_string(): two elements", to_string(tuple), "(1, 1/3)")
}

/////////////////////////////////////////////////////////////////////// define()

// PEmpty

function test_pempty_define() {
    `EMPTY' pempty

    pempty = new_pempty()

    test_result("Test PEmpty::define()", to_string(pempty), "Empty")
}

// PWild

function test_pwild_define() {
    `WILD' pwild
    `VARIABLE' variable
    `CONSTANT' pconstant_1, pconstant_2
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    test_result("Test PWild::define()", to_string_pwild(pwild, 1), "1 | 2")
}

// PConstant

function test_pconstant_define() {
    `CONSTANT' pconstant
    
    pconstant = new_pconstant(1, 1)
    test_result("Test PConstant::define(): real", to_string(pconstant), "1")
    
    pconstant = new_pconstant(., 1)
    test_result("Test PConstant::define(): missing real", to_string(pconstant), ".")
    
    pconstant = new_pconstant(.a, 1)
    test_result("Test PConstant::define(): missing real .a", to_string(pconstant), ".a")
}

// PRange

function test_prange_define() {
    `RANGE' prange
    
    prange = new_prange(1, 3, 1)
    test_result("Test PRange::define(): integer", to_string(prange), "1/3")
    
    prange = new_prange(1.1, 3.1, 2)
    test_result("Test PRange::define(): float", to_string(prange), "1.1/3.1")
    
    prange = new_prange(1.1, 3.1, 3)
    test_result("Test PRange::define(): double", to_string(prange), "1.1/3.1")
    
    /*
    TODO: test errors
       - discrete not bool
       - min / max missing
       - min > max not bool
       - min / max not int while discrete
    */
}

// POr

function test_por_define() {
    `OR' por
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    
    pconstant_1 = new_pconstant(1, 1)
    pconstant_2 = new_pconstant(2, 1)
    pconstant_3 = new_pconstant(2, 1)
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, pconstant_2)
    push_por(por, pconstant_3)
    
    test_result("Test POr::define(): base", to_string(por), "1 | 2 | 2")
}

// Tuple

/* function test_ptuple_define() {
    // TODO: write the function
}*/

///////////////////////////////////////////////////////////////////// compress()

// PEmpty

function test_pempty_compress() {
    `EMPTY' pempty
    transmorphic scalar compressed

    pempty = new_pempty()
    
    compressed = compress(pempty)

    test_result("Test PEmpty::compress()", to_string(compressed), "Empty")
}

// PWild

function test_pwild_compress() {
    `WILD' pwild
    transmorphic scalar compressed
    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    compressed = compress(pwild)

    test_result("Test PWild::compress()", to_string(compressed), "_")
}

// PConstant

function test_pconstant_compress() {
    `CONSTANT' pconstant
    transmorphic scalar compressed

    pconstant = new_pconstant(1, 1)
    
    compressed = compress(pconstant)

    test_result("Test PConstant::compress()", to_string(compressed), "1")
}

// PRange

function test_prange_compress() {
    `RANGE' prange
    transmorphic scalar compressed

    prange = new_prange(1, 3, 1)
    compressed = compress(prange)
    test_result("Test PRange::compress(): int range", to_string(compressed), "1/3")
    
    prange = new_prange(1.1, 3.1, 2)
    compressed = compress(prange)
    test_result("Test PRange::compress(): float range", to_string(compressed), "1.1/3.1")
    
    prange = new_prange(1.1, 3.1, 3)
    compressed = compress(prange)
    test_result("Test PRange::compress(): double range", to_string(compressed), "1.1/3.1")
    
    prange = new_prange(1, 1, 1)
    compressed = compress(prange)
    test_result("Test PRange::compress(): int constant", to_string(compressed), "1")
    
    prange = new_prange(1.1, 1.1, 2)
    compressed = compress(prange)
    test_result("Test PRange::compress(): float constant", to_string(compressed), "1.1")
    
    prange = new_prange(1.1, 1.1, 3)
    compressed = compress(prange)
    test_result("Test PRange::compress(): double constant", to_string(compressed), "1.1")
    
    prange = new_prange(3, 1, 1)
    compressed = compress(prange)
    test_result("Test PRange::compress(): int empty", to_string(compressed), "Empty")
    
    prange = new_prange(3.1, 1.1, 2)
    compressed = compress(prange)
    test_result("Test PRange::compress(): float empty", to_string(compressed), "Empty")
    
    prange = new_prange(3.1, 1.1, 3)
    compressed = compress(prange)
    test_result("Test PRange::compress(): double empty", to_string(compressed), "Empty")
    
}

// POr

function test_por_compress() {
    `OR' por
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    `RANGE' prange_1, prange_2
    transmorphic scalar compressed
    
    pconstant_1 = new_pconstant(1, 1)
    
    pconstant_2 = new_pconstant(2, 1)
    
    pconstant_3 = new_pconstant(2, 1)
    
    prange_1 = new_prange(1, 3, 1)
    
    prange_2 = new_prange(2, 2, 1)
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, pconstant_2)
    
    compressed = compress(por)
    test_result("Test POr::compress(): base", to_string(compressed), "1 | 2")
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, pconstant_2)
    push_por(por, pconstant_3)
    compressed = compress(por)
    test_result("Test POr::compress(): shrink", to_string(compressed), "1 | 2")
    
    por = new_por()
    push_por(por, pconstant_2)
    push_por(por, pconstant_3)
    compressed = compress(por)
    test_result("Test POr::compress(): to constant", to_string(compressed), "2")
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, prange_2)
    compressed = compress(por)
    test_result("Test POr::compress(): compress each", to_string(compressed), "1 | 2")
    
    por = new_por()
    push_por(por, prange_2)
    push_por(por, prange_2)
    compressed = compress(por)
    test_result("Test POr::compress(): empty", to_string(compressed), "2")
}

// Tuple

function test_ptuple_compress() {
    struct Tuple scalar tuple
    `OR' por
    `CONSTANT' pconstant
    `RANGE' prange_1, prange_2
    transmorphic scalar compressed
    
    pconstant = new_pconstant(1, 1)
    
    por = new_por()
    push_por(por, pconstant)
    push_por(por, pconstant)
    
    prange_1 = new_prange(2, 2, 1)
    prange_2 = new_prange(3, 1, 1)
    
    tuple = Tuple()
    
    tuple.patterns = (&pconstant, &pconstant)
    compressed = compress(tuple)
    test_result("Test Tuple::compress(): base", to_string(compressed), "(1, 1)")
    
    tuple.patterns = (&por, &prange_1)
    compressed = compress(tuple)
    test_result("Test Tuple::compress(): compress each", to_string(compressed), "(1, 2)")
    
    tuple.patterns = (&por, &prange_2)
    compressed = compress(tuple)
    test_result("Test Tuple::compress(): empty", to_string(compressed), "Empty")
}


////////////////////////////////////////////////////////////////////// overlap()

// PEmpty

function test_pempty_overlap() {
    `EMPTY' pempty
    `CONSTANT' pconstant
    pointer scalar overlap
    
    pempty = new_pempty()
    pconstant = new_pconstant(1, 1)
    
    overlap = &overlap(pempty, pconstant)

    test_result("Test PEmpty::overlap()", to_string(*overlap), "Empty")
}

// PWild

function test_pwild_overlap() {
    `WILD' pwild
    `CONSTANT' pconstant
    `RANGE' prange
    `OR' por
    pointer scalar overlap
    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    // PEmpty is covered in previous test
    
    pconstant = new_pconstant(1, 1)
    overlap = &overlap(pwild, pconstant)
    test_result("Test PWild::overlap() constant", to_string(*overlap), to_string(pconstant))
    
    prange = new_prange(0, 2, 1)
    overlap = &overlap(pwild, prange)
    test_result("Test PWild::overlap() range", to_string(*overlap), to_string(prange))
    
    por = new_por()
    push_por(por, pconstant)
    push_por(por, prange)
    overlap = &overlap(pwild, por)
    test_result("Test PWild::overlap() or", to_string(*overlap), to_string(por))
}

// PConstant

function test_pconstant_overlap() {
    `CONSTANT' pconstant, pconstant_1, pconstant_2
    `RANGE' prange_1, prange_2
    `OR' por
    pointer scalar overlap
    
    pconstant = new_pconstant(1, 1)
    
    // PEmpty is covered in previous test
    
    // Pwild is covered in previous test
    
    pconstant_1 = new_pconstant(1, 1)
    overlap = &overlap(pconstant, pconstant_1)
    test_result("Test PConstant::overlap() same constant", to_string(*overlap), "1")
    
    pconstant_2 = new_pconstant(2, 1)
    overlap = &overlap(pconstant, pconstant_2)
    test_result("Test PConstant::overlap() other constant", to_string(*overlap), "Empty")
    
    prange_1 = new_prange(0, 2, 1)
    overlap = &overlap(pconstant, prange_1)
    test_result("Test PConstant::overlap() range in", to_string(*overlap), "1")
    
    prange_2 = new_prange(2, 3, 1)
    overlap = &overlap(pconstant, prange_2)
    test_result("Test PConstant::overlap() range out", to_string(*overlap), "Empty")
    
    por = new_por()
    push_por(por, pconstant_2)
    push_por(por, prange_2)
    overlap = &overlap(pconstant, por)
    test_result("Test PConstant::overlap() or out", to_string(*overlap), "Empty")
    
    push_por(por, pconstant_1)
    overlap = &overlap(pconstant, por)
    test_result("Test PConstant::overlap() or in", to_string(*overlap), "1")
}

// PRange

function test_prange_overlap() {
    `RANGE' prange, prange_1, prange_2, prange_3, prange_4, prange_5, prange_6
    `CONSTANT' pconstant_1, pconstant_2
    `OR' por
    pointer scalar overlap
    
    prange = new_prange(0, 3, 1)
    
    // PEmpty is covered in previous test
    
    // PWild is covered in previous test
    
    // PConstant is covered in previous test
    
    prange_1 = new_prange(0, 3, 1)
    overlap = &overlap(prange, prange_1)
    test_result("Test PRange::overlap() same range", to_string(*overlap), "0/3")
    
    prange_2 = new_prange(1, 2, 1)
    overlap = &overlap(prange, prange_2)
    test_result("Test PRange::overlap() range in", to_string(*overlap), "1/2")
    
    prange_3 = new_prange(10, 20, 1)
    overlap = &overlap(prange, prange_3)
    test_result("Test PRange::overlap() range out", to_string(*overlap), "Empty")
    
    prange_4 = new_prange(-1, 1, 1)
    overlap = &overlap(prange, prange_4)
    test_result("Test PRange::overlap() low", to_string(*overlap), "0/1")
    
    prange_5 = new_prange(2, 4, 1)
    overlap = &overlap(prange, prange_5)
    test_result("Test PRange::overlap() high", to_string(*overlap), "2/3")
    
    prange = new_prange(0, 4, 3)
    pconstant_1 = new_pconstant(1, 1)
    pconstant_2 = new_pconstant(5, 1)
    prange_6 = new_prange(2, 3, 1)
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, pconstant_2)
    push_por(por, prange_6)
    overlap = &overlap(prange, por)
    test_result("Test PRange::overlap() or", to_string(*overlap), "1 | 2/3")
}

// POr

function test_por_overlap() {
    `OR' por_1, por_2
    `RANGE' prange_1, prange_2
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    pointer scalar overlap
    
    // POr 1 : (0 | 1 | 2/4)
    
    por_1 = new_por()
    
    pconstant_1 = new_pconstant(0, 1)
    pconstant_2 = new_pconstant(1, 1)
    prange_1 = new_prange(2, 4, 1)
    
    push_por(por_1, pconstant_1)
    push_por(por_1, pconstant_2)
    push_por(por_1, prange_1)
    
    // POr 2 : (10/20 | 3 | 1)
    
    por_2 = new_por()
    prange_2 = new_prange(10, 20, 1)
    pconstant_3 = new_pconstant(3, 1)
    
    push_por(por_2, prange_2)
    push_por(por_2, pconstant_3)
    push_por(por_2, pconstant_2)
    
    // Check
    // - pconstant out
    // - same pconstant
    // - pconstant in prange
    // - prange out
    // - order does not matter
    
    overlap = &overlap(por_1, por_2)
    
    test_result("Test POr::overlap() or", to_string(*overlap), "1 | 3")
}

///////////////////////////////////////////////////////////////////// includes()

// PEmpty

function test_pempty_includes() {
    `EMPTY' pempty, pempty_1
    `CONSTANT' pconstant
    real scalar included
    
    pempty = new_pempty()
    pempty_1 = new_pempty()
    
    included = includes(pempty, pempty_1)
    test_result("Test PEmpty::includes() empty", strofreal(included), "1")
    
    pconstant = new_pconstant(1, 1)
    
    included = includes(pempty, pconstant)
    test_result("Test PEmpty::includes() constant", strofreal(included), "0")
}

// PWild

function test_pwild_includes() {
    `WILD' pwild
    `EMPTY' pempty
    `CONSTANT' pconstant
    `RANGE' prange
    `OR' por
    real scalar included
    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    pempty = new_pempty()
    included = includes(pwild, pempty)
    test_result("Test PWild::includes() empty", strofreal(included), "1")
    
    pconstant = new_pconstant(1, 1)
    included = includes(pwild, pconstant)
    test_result("Test PWild::includes() constant", strofreal(included), "1")
    
    prange = new_prange(0, 2, 1)
    included = includes(pwild, prange)
    test_result("Test PWild::includes() range", strofreal(included), "1")
    
    por = new_por()
    push_por(por, pconstant)
    push_por(por, prange)
    included = includes(pwild, por)
    test_result("Test PWild::includes() or", strofreal(included), "1")
}

// PConstant

function test_pconstant_includes() {
    `CONSTANT' pconstant, pconstant_1, pconstant_2
    `EMPTY' pempty
    `RANGE' prange_1, prange_2, prange_3
    `OR' por
    pointer scalar overlap
    real scalar included
    
    pconstant = new_pconstant(1, 1)
    
    pempty = new_pempty()
    included = includes(pconstant, pempty)
    test_result("Test PConstant::includes() empty", strofreal(included), "1")
    
    // PWild is equivalent to POr on its values
    
    pconstant_1 = new_pconstant(1, 1)
    included = includes(pconstant, pconstant_1)
    test_result("Test PConstant::includes() same constant", strofreal(included), "1")
    
    pconstant_2 = new_pconstant(2, 1)
    included = includes(pconstant, pconstant_2)
    test_result("Test PConstant::includes() other constant", strofreal(included), "0")
    
    prange_1 = new_prange(1, 1, 1)
    included = includes(pconstant, prange_1)
    test_result("Test PConstant::includes() range constant", strofreal(included), "1")
    
    prange_2 = new_prange(0, 2, 1)
    included = includes(pconstant, prange_2)
    test_result("Test PConstant::includes() range in", strofreal(included), "0")
    
    prange_3 = new_prange(2, 3, 1)
    included = includes(pconstant, prange_3)
    test_result("Test PConstant::includes() range out", strofreal(included), "0")
    
    por = new_por()
    
    push_por(por, pconstant_1)
    included = includes(pconstant, por)
    test_result("Test PConstant::includes() or in", strofreal(included), "1")
    
    push_por(por, pconstant_2)
    included = includes(pconstant, por)
    test_result("Test PConstant::includes() or out", strofreal(included), "0")
}

// PRange

function test_prange_includes() {
    `RANGE' prange, prange_1, prange_2, prange_3, prange_4, prange_5
    `EMPTY' pempty
    `CONSTANT' pconstant_1, pconstant_2
    `OR' por
    pointer scalar overlap
    real scalar included
    
    prange = new_prange(0, 3, 1)
    
    pempty = new_pempty()
    included = includes(prange, pempty)
    test_result("Test PRange::includes() empty", strofreal(included), "1")
    
    pconstant_1 = new_pconstant(1, 1)
    included = includes(prange, pconstant_1)
    test_result("Test PRange::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = new_pconstant(5, 1)
    included = includes(prange, pconstant_2)
    test_result("Test PRange::includes() constant out", strofreal(included), "0")
    
    // PWild is equivalent to POr on its values
    
    prange_1 = new_prange(0, 3, 1)
    included = includes(prange, prange_1)
    test_result("Test PRange::includes() same range", strofreal(included), "1")
    
    prange_2 = new_prange(1, 2, 1)
    included = includes(prange, prange_2)
    test_result("Test PRange::includes() range in", strofreal(included), "1")
    
    prange_3 = new_prange(10, 20, 1)
    included = includes(prange, prange_3)
    test_result("Test PRange::includes() range out", strofreal(included), "0")
    
    prange_4 = new_prange(-1, 1, 1)
    included = includes(prange, prange_4)
    test_result("Test PRange::includes() low", strofreal(included), "0")
    
    prange_5 = new_prange(2, 4, 1)
    included = includes(prange, prange_5)
    test_result("Test PRange::includes() high", strofreal(included), "0")
    
    por = new_por()
    push_por(por, pconstant_1)
    included = includes(prange, por)
    test_result("Test PRange::includes() or in", strofreal(included), "1")
    
    push_por(por, pconstant_2)
    included = includes(prange, por)
    test_result("Test PRange::includes() or out", strofreal(included), "0")
}

// POr

function test_por_includes() {
    `OR' por, por_1
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    `RANGE' prange_1, prange_2, prange_3, prange_4
    real scalar included
    
    // POr : (0 | 1/4)
    
    por = new_por()
    
    pconstant_1 = new_pconstant(0, 1)
    
    prange_1 = new_prange(1, 4, 1)
    
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    included = includes(por, pconstant_1)
    test_result("Test POr::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = new_pconstant(2, 1)
    
    included = includes(por, pconstant_2)
    test_result("Test POr::includes() constant in 2", strofreal(included), "1")
    
    pconstant_3 = new_pconstant(-1, 1)
    
    included = includes(por, pconstant_3)
    test_result("Test POr::includes() constant out", strofreal(included), "0")
    
    prange_2 = new_prange(2, 3, 1)
    
    included = includes(por, prange_2)
    test_result("Test POr::includes() range in", strofreal(included), "1")
    
    prange_3 = new_prange(-3, -1, 1)
    
    included = includes(por, prange_3)
    test_result("Test POr::includes() range out", strofreal(included), "0")
    
    prange_4 = new_prange(0, 2, 1) // = (0 | 1 | 2) in (0 | 1/4)
    
    included = includes(por, prange_4)
    test_result("Test POr::includes() range in across patterns", strofreal(included), "1")
    
    por_1 = new_por()
    
    push_por(por_1, pconstant_1)
    included = includes(por, por_1)
    test_result("Test POr::includes() or in 1 element", strofreal(included), "1")
    
    push_por(por_1, prange_2)
    included = includes(por, por_1)
    test_result("Test POr::includes() or in 2 elements", strofreal(included), "1")
    
    push_por(por_1, pconstant_3)
    included = includes(por, por_1)
    test_result("Test POr::includes() or out", strofreal(included), "0")    
}

/////////////////////////////////////////////////////////////////// difference()

// PEmpty

function test_pempty_difference() {
    `EMPTY' pempty
    pointer scalar difference
    `EMPTY' pempty_1
    `WILD' pwild
    `CONSTANT' pconstant_1
    `RANGE' prange_1
    `OR' por
    
    pempty = new_pempty()
    
    // PEmpty

    pempty_1 = new_pempty()
    
    difference = difference(pempty, pempty_1)

    test_result("Test PEmpty::difference() empty", to_string(difference), "Empty")

    // PWild

    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    difference = difference(pempty, pwild)

    test_result("Test PEmpty::difference() wild", to_string(difference), "Empty")

    // PConstant

    pconstant_1 = new_pconstant(1, 1)
    
    difference = difference(pempty, pconstant_1)

    test_result("Test PEmpty::difference() constant", to_string(difference), "Empty")

    // PRange

    prange_1 = new_prange(0, 2, 1)
    
    difference = difference(pempty, prange_1)

    test_result("Test PEmpty::difference() range", to_string(difference), "Empty")

    // POr

    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    difference = difference(pempty, por)

    test_result("Test PEmpty::difference() or", to_string(difference), "Empty")
}

// PWild

function test_pwild_difference() {
    // Equivalent to POr with values
}

// PConstant

function test_pconstant_difference() {
    `CONSTANT' pconstant
    pointer scalar difference
    `EMPTY' pempty
    `WILD' pwild
    `CONSTANT' pconstant_1, pconstant_2
    `RANGE' prange_1, prange_2
    `OR' por
    
    pconstant = new_pconstant(1, 1)
    
    // PEmpty

    pempty = new_pempty()
    
    difference = difference(pconstant, pempty)

    test_result("Test PConstant::difference() empty", to_string(difference), "1")

    // PWild

    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    difference = difference(pconstant, pwild)

    test_result("Test PConstant::difference() wild", to_string(difference), "Empty")

    // PConstant

    pconstant_1 = new_pconstant(1, 1)
    
    difference = difference(pconstant, pconstant_1)

    test_result("Test PConstant::difference() constant same", to_string(difference), "Empty")

    pconstant_2 = new_pconstant(2, 1)
    
    difference = difference(pconstant ,pconstant_2)

    test_result("Test PConstant::difference() constant different", to_string(difference), "1")

    // PRange

    prange_1 = new_prange(0, 2, 1)
    
    difference = difference(pconstant, prange_1)

    test_result("Test PConstant::difference() range in", to_string(difference), "Empty")

    prange_2 = new_prange(-2, 0, 1)
    
    difference = difference(pconstant, prange_2)

    test_result("Test PConstant::difference() range out", to_string(difference), "1")

    // POr

    por = new_por()
    push_por(por, pconstant_2)
    push_por(por, prange_2)
    
    difference = difference(pconstant, por)

    test_result("Test PConstant::difference() range in", to_string(difference), "1")

    push_por(por, pconstant_1)
    
    difference = difference(pconstant, por)

    test_result("Test PConstant::difference() range out", to_string(difference), "Empty")
}

// PRange

function test_prange_difference() {
    `RANGE' prange
    pointer scalar difference
    `EMPTY' pempty
    `WILD' pwild
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    `RANGE' prange_1, prange_2, prange_3
    `OR' por
    
    prange = new_prange(0, 3, 1)
    
    // PEmpty

    pempty = new_pempty()
    
    difference = difference(prange, pempty)

    test_result("Test PRange::difference() empty", to_string(difference), "0/3")

    // PWild

    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    difference = difference(prange, pwild)

    test_result("Test PRange::difference() wild", to_string(difference), "Empty")

    // PConstant

    pconstant_1 = new_pconstant(-1, 1)
    
    difference = difference(prange, pconstant_1)

    test_result("Test PRange::difference() constant out", to_string(difference), "0/3")

    pconstant_2 = new_pconstant(2, 1)
    
    difference = difference(prange, pconstant_2)

    test_result("Test PRange::difference() constant middle", to_string(difference), "0/1 | 3")

    pconstant_3 = new_pconstant(3, 1)
    
    difference = difference(prange, pconstant_3)

    test_result("Test PRange::difference() constant boundary", to_string(difference), "0/2")

    // PRange

    prange_1 = new_prange(-2, -1, 1)
    
    difference = difference(prange, prange_1)

    test_result("Test PRange::difference() range out", to_string(difference), "0/3")
    
    prange_2 = new_prange(1, 2, 1)
    
    difference = difference(prange, prange_2)

    test_result("Test PRange::difference() range in", to_string(difference), "0 | 3")
    
    prange_3 = new_prange(0, 3, 1)
    
    difference = difference(prange, prange_3)

    test_result("Test PRange::difference() range same", to_string(difference), "Empty")
    
    // POr
    
    por = new_por()
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    difference = difference(prange, por)
    
    test_result("Test PRange::difference() or out", to_string(difference), "0/3")
    
    push_por(por, pconstant_3)
    
    difference = difference(prange, por)

    test_result("Test PRange::difference() or in 1", to_string(difference), "0/2")
    
    push_por(por, prange_2)
    
    difference = difference(prange, por)

    test_result("Test PRange::difference() or in 2", to_string(difference), "0")
}

// POr

function test_por_difference() {
    `OR' por
    pointer scalar difference
    `EMPTY' pempty
    `WILD' pwild
    `CONSTANT' pconstant_1, pconstant_2, pconstant_3
    `RANGE' prange_1, prange_2, prange_3, prange_4
    `OR' por_1
    `VARIABLE' variable
    
    por = new_por()
    
    pconstant_1 = new_pconstant(1, 1)
    prange_1 = new_prange(3, 7, 1)
    
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    // PEmpty
    
    pempty = new_pempty()
    
    difference = difference(por, pempty)

    test_result("Test POr::difference() empty", to_string(difference), "1 | 3/7")
    
    // PWild
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    difference = difference(por, pwild)

    test_result("Test POr::difference() wild", to_string(difference), "Empty")
    
    // PConstant
    
    difference = difference(por, pconstant_1)

    test_result("Test POr::difference() constant in 1", to_string(difference), "3/7")
    
    pconstant_2 = new_pconstant(5, 1)
    
    difference = difference(por, pconstant_2)

    test_result("Test POr::difference() constant in 2", to_string(difference), "1 | 3/4 | 6/7")
    
    pconstant_3 = new_pconstant(8, 1)
    
    difference = difference(por, pconstant_3)

    test_result("Test POr::difference() constant out", to_string(difference), "1 | 3/7")
    
    // PRange
    
    difference = difference(por, prange_1)

    test_result("Test POr::difference() range in", to_string(difference), "1")
    
    prange_2 = new_prange(1, 4, 1)
    
    difference = difference(por, prange_2)

    test_result("Test POr::difference() range across", to_string(difference), "5/7")
    
    prange_3 = new_prange(-5, 0, 1)
    
    difference = difference(por, prange_3)

    test_result("Test POr::difference() range out", to_string(difference), "1 | 3/7")
    
    prange_4 = new_prange(0, 8, 1)
    
    difference = difference(por, prange_4)

    test_result("Test POr::difference() ranger all", to_string(difference), "Empty")
    
    // POr
    
    por_1 = new_por()
    push_por(por_1, pconstant_3)
    push_por(por_1, prange_3)
    
    difference = difference(por, por_1)
    
    test_result("Test POr::difference() or out", to_string(difference), "1 | 3/7")
    
    push_por(por_1, pconstant_2)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or in 1", to_string(difference), "1 | 3/4 | 6/7")
    
    push_por(por_1, prange_2)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or in 2", to_string(difference), "6/7")
    
    push_por(por_1, prange_4)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or all", to_string(difference), "Empty")
}

////////////////////////////////////////////////////////////////////// to_expr()

// PEmpty

function test_pempty_to_expr() {
    `EMPTY' pempty
    `VARIABLE' variable

    variable.name = "test_var"

    pempty = new_pempty()

    test_result("Test PEmpty::to_expr()", to_expr(pempty, variable), "")
}

// PWild

function test_pwild_to_expr() {
    `WILD' pwild
    `VARIABLE' variable

    variable.name = "test_var"

    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    test_result("Test PWild::to_expr()", to_expr(pwild, variable), "1")
}

// PConstant

function test_pconstant_to_expr() {
    `CONSTANT' pconstant
    `VARIABLE' variable

    variable.name  = "test_var"
    variable.type  = "int"
    variable.check = 0
    variable.levels_len = 0

    pconstant = new_pconstant(1, 1)

    test_result("Test PConstant::to_expr() real", to_expr(pconstant, variable), "test_var == `one_21x'")

    variable.type = "string"
    pconstant = new_pconstant(variable.get_level_index(`""a""'), 1)

    test_result("Test PConstant::to_expr() string", to_expr(pconstant, variable), `"test_var == "a""')
}

// PRange

function test_prange_to_expr() {
    `RANGE' prange
    `VARIABLE' variable

    variable.name = "test_var"
    variable.type = "int"
    
    prange = new_prange(0, 2, 1)
    test_result("Test PRange::to_expr() [0, 2]", to_expr(prange, variable), "test_var >= `zero_21x' & test_var <= `two_21x'")
}

// POr

function test_por_to_expr() {
    `OR' por
    `CONSTANT' pconstant
    `RANGE' prange
    `VARIABLE' variable

    variable.name = "test_var"
    variable.type = "int"

    por = new_por()
    
    test_result("Test POr::to_expr() empty", to_expr(por, variable), "")

    pconstant = new_pconstant(1, 1)

    push_por(por, pconstant)

    test_result("Test POr::to_expr()", to_expr(por, variable), "test_var == `one_21x'")

    prange = new_prange(2, 3, 1)

    push_por(por, prange)

    test_result("Test POr::to_expr()", to_expr(por, variable), "(test_var == `one_21x') | (test_var >= `two_21x' & test_var <= `three_21x')")
}

// Tuple

function test_ptuple_to_expr() {
    struct Tuple scalar tuple_1, tuple_2
    `CONSTANT' pconstant
    `RANGE' prange
    `WILD' pwild
    `OR' por_1
    `TUPLES' tuples
    class Variable vector variables

    tuple_1 = Tuple()

    // 1

    pconstant = new_pconstant(1, 1)

    tuple_1.patterns = J(1, 1, NULL)
    tuple_1.patterns[1] = &pconstant

    variables = Variable(1)
    variables[1].name = "test_var_1"
    variables[1].type = "int"

    test_result("Test Tuple::to_expr(): one element", to_expr(tuple_1, variables), "test_var_1 == `one_21x'")

    // (1, 1/3)
     prange = new_prange(1, 3, 1)

    tuple_1.patterns = J(2, 1, NULL)
    tuple_1.patterns[1] = &pconstant
    tuple_1.patterns[2] = &prange

    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[1].type = "int"
    variables[2].name = "test_var_2"
    variables[2].type = "int"

    test_result("Test Tuple::to_expr(): two elements", to_expr(tuple_1, variables), "(test_var_1 == `one_21x') & (test_var_2 >= `one_21x' & test_var_2 <= `three_21x')")

    // (1 | 1/3, _)

    por_1 = new_por()
    push_por(por_1, pconstant)
    push_por(por_1, prange)

    `VARIABLE' variable
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = new_pwild(variable)

    tuple_1.patterns = J(2, 1, NULL)
    tuple_1.patterns[1] = &por_1
    tuple_1.patterns[2] = &pwild

    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[1].type = "int"
    variables[2].name = "test_var_2"
    variables[2].type = "int"
    
    test_result("Test Tuple::to_expr(): wildcard", to_expr(tuple_1, variables), "(test_var_1 == `one_21x') | (test_var_1 >= `one_21x' & test_var_1 <= `three_21x')")

    // (1 | 1/3, _) | (1, 1/3)
    
    tuple_2.patterns = J(2, 1, NULL) 
    tuple_2.patterns[1] = &pconstant
    tuple_2.patterns[2] = &prange
    
    tuples = new_tupleor()
    append_tupleor(tuples, &tuple_1)
    append_tupleor(tuples, &tuple_2)
    
    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[1].type = "int"
    variables[2].name = "test_var_2"
    variables[2].type = "int"
    
    test_result("Test Tuple::to_expr(): POr of tuples", to_expr(tuples, variables), "((test_var_1 == `one_21x') | (test_var_1 >= `one_21x' & test_var_1 <= `three_21x')) | ((test_var_1 == `one_21x') & (test_var_2 >= `one_21x' & test_var_2 <= `three_21x'))")
}

////////
///////////////////////////////////////////////////////////// RUN TEST FUNCTIONS


// to_string()

test_pempty_to_string()
test_pwild_to_string()
test_pconstant_to_string()
test_prange_to_string()
test_por_to_string()
test_ptuple_to_string()

// define()

test_pempty_define()
test_pwild_define()
test_pconstant_define()
test_prange_define()
test_por_define()
// test_ptuple_define()

// compress()

test_pempty_compress()
test_pwild_compress()
test_pconstant_compress()
test_prange_compress()
test_por_compress()
test_ptuple_compress()

// overlap()

test_pempty_overlap()
test_pwild_overlap()
test_pconstant_overlap()
test_prange_overlap()
test_por_overlap()
// test_ptuple_overlap()

// includes()

test_pempty_includes()
test_pwild_includes()
test_pconstant_includes()
test_prange_includes()
test_por_includes()
// test_ptuple_includes()

// difference()

test_pempty_difference()
test_pwild_difference()
test_pconstant_difference()
test_prange_difference()
test_por_difference()
// test_ptuple_difference()

// to_expr()

test_pempty_to_expr()
test_pwild_to_expr()
test_pconstant_to_expr()
test_prange_to_expr()
test_por_to_expr()
test_ptuple_to_expr()

end
