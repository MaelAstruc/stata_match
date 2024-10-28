/*
Do-file to test the pattern classes and methods
*/

// Representation of 0, 1, 2 and 3 in 21x format
local zero_21x  = "+0.0000000000000X-3ff"
local one_21x   = "+1.0000000000000X+000"
local two_21x   = "+1.0000000000000X+001"
local three_21x = "+1.8000000000000X+001"

mata

////////////////////////////////////////////////////////// DEFINE TEST FUNCTIONS


//////////////////////////////////////////////////////////////////// to_string()

// PEmpty

function test_pempty_to_string() {
    struct PEmpty scalar pempty

    pempty = PEmpty()

    test_result("Test PEmpty::to_string()", to_string(pempty), "Empty")
}

// PWild

function test_pwild_to_string() {
    struct PWild scalar pwild

    pwild = PWild()

    test_result("Test PWild::to_string()", to_string(pwild), "_")
}

// PConstant

function test_pconstant_to_string() {
    struct PConstant scalar pconstant

    pconstant = PConstant()
    
    pconstant.value = 1
    test_result("Test PConstant::to_string(): integer", to_string(pconstant), "1")
    
    pconstant.value = 1.1
    test_result("Test PConstant::to_string(): float", to_string(pconstant), "1.1")
    
    pconstant.value = .
    test_result("Test PConstant::to_string(): missing real", to_string(pconstant), ".")
}

// PRange

function test_prange_to_string() {
    struct PRange scalar prange

    prange = PRange()
    
    prange.min = 1
    prange.max = 3
    prange.type_nb = 1
    
    test_result("Test PRange::to_string(): integer", to_string(prange), "1/3")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.type_nb = 2
    
    test_result("Test PRange::to_string(): float", to_string(prange), "1.1/3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.type_nb = 3
    
    test_result("Test PRange::to_string(): double", to_string(prange), "1.1/3.1")
}

// POr

function test_por_to_string() {
    struct POr scalar por
    struct PConstant scalar pconstant
    struct PRange scalar prange
    
    por = POr()
    
    init_por(por)
    
    test_result("Test POr::to_string(): empty", to_string(por), "")
    
    pconstant = PConstant()
    pconstant.value = 1
    
    por.patterns[1] = &pconstant
    por.length = 1
    
    test_result("Test POr::to_string(): one element", to_string(por), "1")
    
    prange = PRange()
    
    prange.min = 1
    prange.max = 3
    prange.type_nb = 1
    
    por.patterns[2] = &prange
    por.length = 2
    
    test_result("Test POr::to_string(): two elements", to_string(por), "1 | 1/3")
}

// Tuple

function test_ptuple_to_string() {
    struct Tuple scalar tuple
    struct PConstant scalar pconstant
    struct PRange scalar prange
    
    tuple = Tuple()
    
    test_result("Test Tuple::to_string(): empty", to_string(tuple), "Empty Tuple: Error")
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    tuple.patterns = J(1, 1, NULL)
    tuple.patterns[1] = &pconstant
    
    test_result("Test Tuple::to_string(): one element", to_string(tuple), "1")
    
    prange = PRange()
    prange.min = 1
    prange.max = 3
    prange.type_nb = 1
    
    tuple.patterns = J(2, 1, NULL)
    tuple.patterns[1] = &pconstant
    tuple.patterns[2] = &prange
    test_result("Test Tuple::to_string(): two elements", to_string(tuple), "(1, 1/3)")
}

/////////////////////////////////////////////////////////////////////// define()

// PEmpty

function test_pempty_define() {
    struct PEmpty scalar pempty

    pempty = PEmpty()
    define_pempty(pempty)

    test_result("Test PEmpty::define()", to_string(pempty), "Empty")
}

// PWild

function test_pwild_define() {
    struct PWild scalar pwild
    class Variable scalar variable
    struct PConstant scalar pconstant_1, pconstant_2
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = PWild()
    define_pwild(pwild, variable)

    test_result("Test PWild::define()", to_string_pwild(pwild, 1), "1 | 2")
}

// PConstant

function test_pconstant_define() {
    struct PConstant scalar pconstant
    
    pconstant = PConstant()
    
    define_pconstant(pconstant, 1)
    test_result("Test PConstant::define(): real", to_string(pconstant), "1")
    
    define_pconstant(pconstant, .)
    test_result("Test PConstant::define(): missing real", to_string(pconstant), ".")
    
    define_pconstant(pconstant, .a)
    test_result("Test PConstant::define(): missing real .a", to_string(pconstant), ".a")
}

// PRange

function test_prange_define() {
    struct PRange scalar prange
    
    prange = PRange()
    
    define_prange(prange, 1, 3, 1)
    test_result("Test PRange::define(): integer", to_string(prange), "1/3")
    
    define_prange(prange, 1.1, 3.1, 2)
    test_result("Test PRange::define(): float", to_string(prange), "1.1/3.1")
    
    define_prange(prange, 1.1, 3.1, 3)
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
    struct POr scalar por
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    
    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, 2)
    
    por = POr()
    define_por(por, (&pconstant_1, &pconstant_2, &pconstant_3))
    
    test_result("Test POr::define(): base", to_string(por), "1 | 2 | 2")
}

// Tuple

/* function test_ptuple_define() {
    // TODO: write the function
}*/

///////////////////////////////////////////////////////////////////// compress()

// PEmpty

function test_pempty_compress() {
    struct PEmpty scalar pempty
    pointer scalar compressed

    pempty = PEmpty()
    
    compressed = &compress(pempty)

    test_result("Test PEmpty::compress()", to_string(*compressed), "Empty")
}

// PWild

function test_pwild_compress() {
    struct PWild scalar pwild
    pointer scalar compressed

    pwild = PWild()
    
    compressed = &compress(pwild)

    test_result("Test PWild::compress()", to_string(*compressed), "_")
}

// PConstant

function test_pconstant_compress() {
    struct PConstant scalar pconstant
    pointer scalar compressed

    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    compressed = &compress(pconstant)

    test_result("Test PConstant::compress()", to_string(*compressed), "1")
}

// PRange

function test_prange_compress() {
    struct PRange scalar prange
    pointer scalar compressed

    prange = PRange()
    
    define_prange(prange, 1, 3, 1)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): int range", to_string(*compressed), "1/3")
    
    define_prange(prange, 1.1, 3.1, 2)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): float range", to_string(*compressed), "1.1/3.1")
    
    define_prange(prange, 1.1, 3.1, 3)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): double range", to_string(*compressed), "1.1/3.1")
    
    define_prange(prange, 1, 1, 1)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): int constant", to_string(*compressed), "1")
    
    define_prange(prange, 1.1, 1.1, 2)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): float constant", to_string(*compressed), "1.1")
    
    define_prange(prange, 1.1, 1.1, 3)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): double constant", to_string(*compressed), "1.1")
    
    define_prange(prange, 3, 1, 1)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): int empty", to_string(*compressed), "Empty")
    
    define_prange(prange, 3.1, 1.1, 2)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): float empty", to_string(*compressed), "Empty")
    
    define_prange(prange, 3.1, 1.1, 3)
    compressed = &compress(prange)
    test_result("Test PRange::compress(): double empty", to_string(*compressed), "Empty")
    
}

// POr

function test_por_compress() {
    struct POr scalar por
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    struct PRange scalar prange_1, prange_2
    pointer scalar compressed
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    
    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, 2)
    
    prange_1 = PRange()
    define_prange(prange_1, 1, 3, 1)
    
    prange_2 = PRange()
    define_prange(prange_2, 2, 2, 1)
    
    por = POr()
    define_por(por, (&pconstant_1, &pconstant_2))
    compressed = &compress(por)
    test_result("Test POr::compress(): base", to_string(*compressed), "1 | 2")
    
    por = POr()
    define_por(por, (&pconstant_1, &pconstant_2, &pconstant_3))
    compressed = &compress(por)
    test_result("Test POr::compress(): shrink", to_string(*compressed), "1 | 2")
    
    por = POr()
    define_por(por, (&pconstant_2, &pconstant_3))
    compressed = &compress(por)
    test_result("Test POr::compress(): to constant", to_string(*compressed), "2")
    
    por = POr()
    define_por(por, (&pconstant_1, &prange_2))
    compressed = &compress(por)
    test_result("Test POr::compress(): compress each", to_string(*compressed), "1 | 2")
    
    por = POr()
    define_por(por, (&prange_2, &prange_2))
    compressed = &compress(por)
    test_result("Test POr::compress(): empty", to_string(*compressed), "2")
}

// Tuple

function test_ptuple_compress() {
    struct Tuple scalar tuple
    struct POr scalar por
    struct PConstant scalar pconstant
    struct PRange scalar prange_1, prange_2
    pointer scalar compressed
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    por = POr()
    define_por(por, (&pconstant, &pconstant))
    
    prange_1 = PRange()
    define_prange(prange_1, 2, 2, 1)
    
    prange_2 = PRange()
    define_prange(prange_2, 3, 1, 1)
    
    tuple = Tuple()
    
    tuple.patterns = (&pconstant, &pconstant)
    compressed = &compress(tuple)
    test_result("Test Tuple::compress(): base", to_string(*compressed), "(1, 1)")
    
    tuple.patterns = (&por, &prange_1)
    compressed = &compress(tuple)
    test_result("Test Tuple::compress(): compress each", to_string(*compressed), "(1, 2)")
    
    tuple.patterns = (&por, &prange_2)
    compressed = &compress(tuple)
    test_result("Test Tuple::compress(): empty", to_string(*compressed), "Empty")
}


////////////////////////////////////////////////////////////////////// overlap()

// PEmpty

function test_pempty_overlap() {
    struct PEmpty scalar pempty
    struct PConstant scalar pconstant
    pointer scalar overlap
    
    pempty = PEmpty()
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    overlap = &overlap(pempty, pconstant)

    test_result("Test PEmpty::overlap()", to_string(*overlap), "Empty")
}

// PWild

function test_pwild_overlap() {
    struct PWild scalar pwild
    struct PConstant scalar pconstant
    struct PRange scalar prange
    struct POr scalar por
    pointer scalar overlap
    
    pwild = PWild()
    
    // PEmpty is covered in previous test
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    overlap = &overlap(pwild, pconstant)
    test_result("Test PWild::overlap() constant", to_string(*overlap), to_string(pconstant))
    
    prange = PRange()
    define_prange(prange, 0, 2, 1)
    overlap = &overlap(pwild, prange)
    test_result("Test PWild::overlap() range", to_string(*overlap), to_string(prange))
    
    por = POr()
    push_por(por, pconstant)
    push_por(por, prange)
    overlap = &overlap(pwild, por)
    test_result("Test PWild::overlap() or", to_string(*overlap), to_string(por))
}

// PConstant

function test_pconstant_overlap() {
    struct PConstant scalar pconstant, pconstant_1, pconstant_2
    struct PRange scalar prange_1, prange_2
    struct POr scalar por
    pointer scalar overlap
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    // PEmpty is covered in previous test
    
    // Pwild is covered in previous test
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    overlap = &overlap(pconstant, pconstant_1)
    test_result("Test PConstant::overlap() same constant", to_string(*overlap), "1")
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    overlap = &overlap(pconstant, pconstant_2)
    test_result("Test PConstant::overlap() other constant", to_string(*overlap), "Empty")
    
    prange_1 = PRange()
    define_prange(prange_1, 0, 2, 1)
    overlap = &overlap(pconstant, prange_1)
    test_result("Test PConstant::overlap() range in", to_string(*overlap), "1")
    
    prange_2 = PRange()
    define_prange(prange_2, 2, 3, 1)
    overlap = &overlap(pconstant, prange_2)
    test_result("Test PConstant::overlap() range out", to_string(*overlap), "Empty")
    
    por = POr()
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
    struct PRange scalar prange, prange_1, prange_2, prange_3, prange_4, prange_5, prange_6
    struct PConstant scalar pconstant_1, pconstant_2
    struct POr scalar por
    pointer scalar overlap
    
    prange = PRange()
    define_prange(prange, 0, 3, 1)
    
    // PEmpty is covered in previous test
    
    // PWild is covered in previous test
    
    // PConstant is covered in previous test
    
    prange_1 = PRange()
    define_prange(prange_1, 0, 3, 1)
    overlap = &overlap(prange, prange_1)
    test_result("Test PRange::overlap() same range", to_string(*overlap), "0/3")
    
    prange_2 = PRange()
    define_prange(prange_2, 1, 2, 1)
    overlap = &overlap(prange, prange_2)
    test_result("Test PRange::overlap() range in", to_string(*overlap), "1/2")
    
    prange_3 = PRange()
    define_prange(prange_3, 10, 20, 1)
    overlap = &overlap(prange, prange_3)
    test_result("Test PRange::overlap() range out", to_string(*overlap), "Empty")
    
    prange_4 = PRange()
    define_prange(prange_4, -1, 1, 1)
    overlap = &overlap(prange, prange_4)
    test_result("Test PRange::overlap() low", to_string(*overlap), "0/1")
    
    prange_5 = PRange()
    define_prange(prange_5, 2, 4, 1)
    overlap = &overlap(prange, prange_5)
    test_result("Test PRange::overlap() high", to_string(*overlap), "2/3")
    
    prange = PRange()
    define_prange(prange, 0, 4, 3)
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 5)
    
    prange_6 = PRange()
    define_prange(prange_6, 2, 3, 1)
    
    por = POr()
    push_por(por, pconstant_1)
    push_por(por, pconstant_2)
    push_por(por, prange_6)
    overlap = &overlap(prange, por)
    test_result("Test PRange::overlap() or", to_string(*overlap), "1 | 2/3")
}

// POr

function test_por_overlap() {
    struct POr scalar por_1, por_2
    struct PRange scalar prange_1, prange_2
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    pointer scalar overlap
    
    // POr 1 : (0 | 1 | 2/4)
    
    por_1 = POr()
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 0)
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 1)
    
    prange_1 = PRange()
    define_prange(prange_1, 2, 4, 1)
    
    push_por(por_1, pconstant_1)
    push_por(por_1, pconstant_2)
    push_por(por_1, prange_1)
    
    // POr 2 : (10/20 | 3 | 1)
    
    por_2 = POr()
    
    prange_2 = PRange()
    define_prange(prange_2, 10, 20, 1)
    
    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, 3)
    
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
    struct PEmpty scalar pempty, pempty_1
    struct PConstant scalar pconstant
    real scalar included
    
    pempty = PEmpty()
    
    pempty_1 = PEmpty()
    
    included = includes(pempty, pempty_1)
    test_result("Test PEmpty::includes() empty", strofreal(included), "1")
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    included = includes(pempty, pconstant)
    test_result("Test PEmpty::includes() constant", strofreal(included), "0")
}

// PWild

function test_pwild_includes() {
    struct PWild scalar pwild
    struct PEmpty scalar pempty
    struct PConstant scalar pconstant
    struct PRange scalar prange
    struct POr scalar por
    real scalar included
    
    pwild = PWild()
    
    pempty = PEmpty()
    included = includes(pwild, pempty)
    test_result("Test PWild::includes() empty", strofreal(included), "1")
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    included = includes(pwild, pconstant)
    test_result("Test PWild::includes() constant", strofreal(included), "1")
    
    prange = PRange()
    define_prange(prange, 0, 2, 1)
    included = includes(pwild, prange)
    test_result("Test PWild::includes() range", strofreal(included), "1")
    
    por = POr()
    push_por(por, pconstant)
    push_por(por, prange)
    included = includes(pwild, por)
    test_result("Test PWild::includes() or", strofreal(included), "1")
}

// PConstant

function test_pconstant_includes() {
    struct PConstant scalar pconstant, pconstant_1, pconstant_2
    struct PEmpty scalar pempty
    struct PRange scalar prange_1, prange_2, prange_3
    struct POr scalar por
    pointer scalar overlap
    real scalar included
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    pempty = PEmpty()
    included = includes(pconstant, pempty)
    test_result("Test PConstant::includes() empty", strofreal(included), "1")
    
    // PWild is equivalent to POr on its values
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    included = includes(pconstant, pconstant_1)
    test_result("Test PConstant::includes() same constant", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    included = includes(pconstant, pconstant_2)
    test_result("Test PConstant::includes() other constant", strofreal(included), "0")
    
    prange_1 = PRange()
    define_prange(prange_1, 1, 1, 1)
    included = includes(pconstant, prange_1)
    test_result("Test PConstant::includes() range constant", strofreal(included), "1")
    
    prange_2 = PRange()
    define_prange(prange_2, 0, 2, 1)
    included = includes(pconstant, prange_2)
    test_result("Test PConstant::includes() range in", strofreal(included), "0")
    
    prange_3 = PRange()
    define_prange(prange_3, 2, 3, 1)
    included = includes(pconstant, prange_3)
    test_result("Test PConstant::includes() range out", strofreal(included), "0")
    
    por = POr()
    
    push_por(por, pconstant_1)
    included = includes(pconstant, por)
    test_result("Test PConstant::includes() or in", strofreal(included), "1")
    
    push_por(por, pconstant_2)
    included = includes(pconstant, por)
    test_result("Test PConstant::includes() or out", strofreal(included), "0")
}

// PRange

function test_prange_includes() {
    struct PRange scalar prange, prange_1, prange_2, prange_3, prange_4, prange_5
    struct PEmpty scalar pempty
    struct PConstant scalar pconstant_1, pconstant_2
    struct POr scalar por
    pointer scalar overlap
    real scalar included
    
    prange = PRange()
    define_prange(prange, 0, 3, 1)
    
    pempty = PEmpty()
    included = includes(prange, pempty)
    test_result("Test PRange::includes() empty", strofreal(included), "1")
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    included = includes(prange, pconstant_1)
    test_result("Test PRange::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 5)
    included = includes(prange, pconstant_2)
    test_result("Test PRange::includes() constant out", strofreal(included), "0")
    
    // PWild is equivalent to POr on its values
    
    prange_1 = PRange()
    define_prange(prange_1, 0, 3, 1)
    included = includes(prange, prange_1)
    test_result("Test PRange::includes() same range", strofreal(included), "1")
    
    prange_2 = PRange()
    define_prange(prange_2, 1, 2, 1)
    included = includes(prange, prange_2)
    test_result("Test PRange::includes() range in", strofreal(included), "1")
    
    prange_3 = PRange()
    define_prange(prange_3, 10, 20, 1)
    included = includes(prange, prange_3)
    test_result("Test PRange::includes() range out", strofreal(included), "0")
    
    prange_4 = PRange()
    define_prange(prange_4, -1, 1, 1)
    included = includes(prange, prange_4)
    test_result("Test PRange::includes() low", strofreal(included), "0")
    
    prange_5 = PRange()
    define_prange(prange_5, 2, 4, 1)
    included = includes(prange, prange_5)
    test_result("Test PRange::includes() high", strofreal(included), "0")
    
    por = POr()
    push_por(por, pconstant_1)
    included = includes(prange, por)
    test_result("Test PRange::includes() or in", strofreal(included), "1")
    
    push_por(por, pconstant_2)
    included = includes(prange, por)
    test_result("Test PRange::includes() or out", strofreal(included), "0")
}

// POr

function test_por_includes() {
    struct POr scalar por, por_1
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    struct PRange scalar prange_1, prange_2, prange_3, prange_4
    real scalar included
    
    // POr : (0 | 1/4)
    
    por = POr()
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 0)
    
    prange_1 = PRange()
    define_prange(prange_1, 1, 4, 1)
    
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    included = includes(por, pconstant_1)
    test_result("Test POr::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    
    included = includes(por, pconstant_2)
    test_result("Test POr::includes() constant in 2", strofreal(included), "1")
    
    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, -1)
    
    included = includes(por, pconstant_3)
    test_result("Test POr::includes() constant out", strofreal(included), "0")
    
    prange_2 = PRange()
    define_prange(prange_2, 2, 3, 1)
    
    included = includes(por, prange_2)
    test_result("Test POr::includes() range in", strofreal(included), "1")
    
    prange_3 = PRange()
    define_prange(prange_3, -3, -1, 1)
    
    included = includes(por, prange_3)
    test_result("Test POr::includes() range out", strofreal(included), "0")
    
    prange_4 = PRange()
    define_prange(prange_4, 0, 2, 1) // = (0 | 1 | 2) in (0 | 1/4)
    
    included = includes(por, prange_4)
    test_result("Test POr::includes() range in across patterns", strofreal(included), "1")
    
    por_1 = POr()
    
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
    struct PEmpty scalar pempty
    pointer scalar difference
    struct PEmpty scalar pempty_1
    struct PWild scalar pwild
    struct PConstant scalar pconstant_1
    struct PRange scalar prange_1
    struct POr scalar por
    
    pempty = PEmpty()
    
    // PEmpty

    pempty_1 = PEmpty()
    
    difference = difference(pempty, pempty_1)

    test_result("Test PEmpty::difference() empty", to_string(*difference), "Empty")

    // PWild

    pwild = PWild()
    
    difference = difference(pempty, pwild)

    test_result("Test PEmpty::difference() wild", to_string(*difference), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    difference = difference(pempty, pconstant_1)

    test_result("Test PEmpty::difference() constant", to_string(*difference), "Empty")

    // PRange

    prange_1 = PRange()
    define_prange(prange_1, 0, 2, 1)
    
    difference = difference(pempty, prange_1)

    test_result("Test PEmpty::difference() range", to_string(*difference), "Empty")

    // POr

    por = POr()
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    difference = difference(pempty, por)

    test_result("Test PEmpty::difference() or", to_string(*difference), "Empty")
}

// PWild

function test_pwild_difference() {
    // Equivalent to POr with values
}

// PConstant

function test_pconstant_difference() {
    struct PConstant scalar pconstant
    pointer scalar difference
    struct PEmpty scalar pempty
    struct PWild scalar pwild
    struct PConstant scalar pconstant_1, pconstant_2
    struct PRange scalar prange_1, prange_2
    struct POr scalar por
    
    pconstant = PConstant()
    define_pconstant(pconstant, 1)
    
    // PEmpty

    pempty = PEmpty()
    
    difference = difference(pconstant, pempty)

    test_result("Test PConstant::difference() empty", to_string(*difference), "1")

    // PWild

    pwild = PWild()
    
    difference = difference(pconstant, pwild)

    test_result("Test PConstant::difference() wild", to_string(*difference), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    difference = difference(pconstant, pconstant_1)

    test_result("Test PConstant::difference() constant same", to_string(*difference), "Empty")

    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    
    difference = difference(pconstant ,pconstant_2)

    test_result("Test PConstant::difference() constant different", to_string(*difference), "1")

    // PRange

    prange_1 = PRange()
    define_prange(prange_1, 0, 2, 1)
    
    difference = difference(pconstant, prange_1)

    test_result("Test PConstant::difference() range in", to_string(*difference), "Empty")

    prange_2 = PRange()
    define_prange(prange_2, -2, 0, 1)
    
    difference = difference(pconstant, prange_2)

    test_result("Test PConstant::difference() range out", to_string(*difference), "1")

    // POr

    por = POr()
    push_por(por, pconstant_2)
    push_por(por, prange_2)
    
    difference = difference(pconstant, por)

    test_result("Test PConstant::difference() range in", to_string(*difference), "1")

    push_por(por, pconstant_1)
    
    difference = difference(pconstant, por)

    test_result("Test PConstant::difference() range out", to_string(*difference), "Empty")
}

// PRange

function test_prange_difference() {
    struct PRange scalar prange
    pointer scalar difference
    struct PEmpty scalar pempty
    struct PWild scalar pwild
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    struct PRange scalar prange_1, prange_2, prange_3
    struct POr scalar por
    
    prange = PRange()
    define_prange(prange, 0, 3, 1)
    
    // PEmpty

    pempty = PEmpty()
    
    difference = difference(prange, pempty)

    test_result("Test PRange::difference() empty", to_string(*difference), "0/3")

    // PWild

    pwild = PWild()
    
    difference = difference(prange, pwild)

    test_result("Test PRange::difference() wild", to_string(*difference), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, -1)
    
    difference = difference(prange, pconstant_1)

    test_result("Test PRange::difference() constant out", to_string(*difference), "0/3")

    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 2)
    
    difference = difference(prange, pconstant_2)

    test_result("Test PRange::difference() constant middle", to_string(*difference), "0/1 | 3")

    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, 3)
    
    difference = difference(prange, pconstant_3)

    test_result("Test PRange::difference() constant boundary", to_string(*difference), "0/2")

    // PRange

    prange_1 = PRange()
    define_prange(prange_1, -2, -1, 1)
    
    difference = difference(prange, prange_1)

    test_result("Test PRange::difference() range out", to_string(*difference), "0/3")
    
    prange_2 = PRange()
    define_prange(prange_2, 1, 2, 1)
    
    difference = difference(prange, prange_2)

    test_result("Test PRange::difference() range in", to_string(*difference), "0 | 3")
    
    prange_3 = PRange()
    define_prange(prange_3, 0, 3, 1)
    
    difference = difference(prange, prange_3)

    test_result("Test PRange::difference() range same", to_string(*difference), "Empty")
    
    // POr
    
    por = POr()
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    difference = difference(prange, por)

    test_result("Test PRange::difference() or out", to_string(*difference), "0/3")
    
    push_por(por, pconstant_3)
    
    difference = difference(prange, por)

    test_result("Test PRange::difference() or in 1", to_string(*difference), "0/2")
    
    push_por(por, prange_2)
    
    difference = difference(prange, por)

    test_result("Test PRange::difference() or in 2", to_string(*difference), "0")
}

// POr

function test_por_difference() {
    struct POr scalar por
    pointer scalar difference
    struct PEmpty scalar pempty
    struct PWild scalar pwild
    struct PConstant scalar pconstant_1, pconstant_2, pconstant_3
    struct PRange scalar prange_1, prange_2, prange_3, prange_4
    struct POr scalar por_1
    
    por = POr()
    
    pconstant_1 = PConstant()
    define_pconstant(pconstant_1, 1)
    
    prange_1 = PRange()
    define_prange(prange_1, 3, 7, 1)
    
    push_por(por, pconstant_1)
    push_por(por, prange_1)
    
    // PEmpty
    
    pempty = PEmpty()
    
    difference = difference(por, pempty)

    test_result("Test POr::difference() empty", to_string(*difference), "1 | 3/7")
    
    // PWild
    
    pwild = PWild()
    
    difference = difference(por, pwild)

    test_result("Test POr::difference() wild", to_string(*difference), "Empty")
    
    // PConstant
    
    difference = difference(por, pconstant_1)

    test_result("Test POr::difference() constant in 1", to_string(*difference), "3/7")
    
    pconstant_2 = PConstant()
    define_pconstant(pconstant_2, 5)
    
    difference = difference(por, pconstant_2)

    test_result("Test POr::difference() constant in 2", to_string(*difference), "1 | 3/4 | 6/7")
    
    pconstant_3 = PConstant()
    define_pconstant(pconstant_3, 8)
    
    difference = difference(por, pconstant_3)

    test_result("Test POr::difference() constant out", to_string(*difference), "1 | 3/7")
    
    // PRange
    
    difference = difference(por, prange_1)

    test_result("Test POr::difference() range in", to_string(*difference), "1")
    
    prange_2 = PRange()
    define_prange(prange_2, 1, 4, 1)
    
    difference = difference(por, prange_2)

    test_result("Test POr::difference() range across", to_string(*difference), "5/7")
    
    prange_3 = PRange()
    define_prange(prange_3, -5, 0, 1)
    
    difference = difference(por, prange_3)

    test_result("Test POr::difference() range out", to_string(*difference), "1 | 3/7")
    
    prange_4 = PRange()
    define_prange(prange_4, 0, 8, 1)
    
    difference = difference(por, prange_4)

    test_result("Test POr::difference() ranger all", to_string(*difference), "Empty")
    
    // POr
    
    por_1 = POr()
    push_por(por_1, pconstant_3)
    push_por(por_1, prange_3)
    
    difference = difference(por, por_1)
    
    test_result("Test POr::difference() or out", to_string(*difference), "1 | 3/7")
    
    push_por(por_1, pconstant_2)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or in 1", to_string(*difference), "1 | 3/4 | 6/7")
    
    push_por(por_1, prange_2)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or in 2", to_string(*difference), "6/7")
    
    push_por(por_1, prange_4)
    
    difference = difference(por, por_1)

    test_result("Test POr::difference() or all", to_string(*difference), "Empty")
}

////////////////////////////////////////////////////////////////////// to_expr()

// PEmpty

function test_pempty_to_expr() {
    struct PEmpty scalar pempty
    class Variable scalar variable

    variable.name = "test_var"

    pempty = PEmpty()

    test_result("Test PEmpty::to_expr()", to_expr(pempty, variable), "")
}

// PWild

function test_pwild_to_expr() {
    struct PWild scalar pwild
    class Variable scalar variable

    variable.name = "test_var"

    pwild = PWild()

    test_result("Test PWild::to_expr()", to_expr(pwild, variable), "1")
}

// PConstant

function test_pconstant_to_expr() {
    struct PConstant scalar pconstant
    class Variable scalar variable

    variable.name  = "test_var"
    variable.type  = "int"
    variable.check = 0
    variable.levels_len = 0

    pconstant = PConstant()
    pconstant.value = 1

    test_result("Test PConstant::to_expr() real", to_expr(pconstant, variable), "test_var == `one_21x'")

    variable.type = "string"
    pconstant.value = variable.get_level_index(`""a""')

    test_result("Test PConstant::to_expr() string", to_expr(pconstant, variable), `"test_var == "a""')
}

// PRange

function test_prange_to_expr() {
    struct PRange scalar prange
    class Variable scalar variable

    variable.name = "test_var"
    variable.type = "int"
    
    prange = PRange()

    define_prange(prange, 0, 2, 1)
    test_result("Test PRange::to_expr() [0, 2]", to_expr(prange, variable), "test_var >= `zero_21x' & test_var <= `two_21x'")
}

// POr

function test_por_to_expr() {
    struct POr scalar por
    struct PConstant scalar pconstant
    struct PRange scalar prange
    class Variable scalar variable

    variable.name = "test_var"
    variable.type = "int"

    por = POr()
    init_por(por)

    test_result("Test POr::to_expr() empty", to_expr(por, variable), "")

    pconstant = PConstant()
    pconstant.value = 1

    push_por(por, pconstant)

    test_result("Test POr::to_expr()", to_expr(por, variable), "test_var == `one_21x'")

    prange = PRange()
    define_prange(prange, 2, 3, 1)

    push_por(por, prange)

    test_result("Test POr::to_expr()", to_expr(por, variable), "(test_var == `one_21x') | (test_var >= `two_21x' & test_var <= `three_21x')")
}

// Tuple

function test_ptuple_to_expr() {
    struct Tuple scalar tuple_1, tuple_2
    struct PConstant scalar pconstant
    struct PRange scalar prange
    struct PWild scalar pwild
    struct POr scalar por_1, por_2
    class Variable vector variables

    tuple_1 = Tuple()

    // 1

    pconstant = PConstant()
    define_pconstant(pconstant, 1)

    tuple_1.patterns = J(1, 1, NULL)
    tuple_1.patterns[1] = &pconstant

    variables = Variable(1)
    variables[1].name = "test_var_1"
    variables[1].type = "int"

    test_result("Test Tuple::to_expr(): one element", to_expr(tuple_1, variables), "test_var_1 == `one_21x'")

    // (1, 1/3)
 
    prange = PRange()
    prange.min = 1
    prange.max = 3
    prange.type_nb = 1

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

    por_1 = POr()
    push_por(por_1, pconstant)
    push_por(por_1, prange)

    pwild = PWild()

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
    
    por_2 = POr()
    push_por(por_2, tuple_1)
    push_por(por_2, tuple_2)
    
    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[1].type = "int"
    variables[2].name = "test_var_2"
    variables[2].type = "int"
    
    test_result("Test Tuple::to_expr(): POr of tuples", to_expr(por_2, variables), "((test_var_1 == `one_21x') | (test_var_1 >= `one_21x' & test_var_1 <= `three_21x')) | ((test_var_1 == `one_21x') & (test_var_2 >= `one_21x' & test_var_2 <= `three_21x'))")
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
