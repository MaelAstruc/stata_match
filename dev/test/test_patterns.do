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
    class PEmpty scalar pempty

    pempty = PEmpty()

    test_result("Test PEmpty::to_string()", pempty.to_string(), "Empty")
}

// PWild

function test_pwild_to_string() {
    class PWild scalar pwild

    pwild = PWild()

    test_result("Test PWild::to_string()", pwild.to_string(), "_")
}

// PConstant

function test_pconstant_to_string() {
    class PConstant scalar pconstant

    pconstant = PConstant()
    
    pconstant.value = 1
    test_result("Test PConstant::to_string(): integer", pconstant.to_string(), "1")
    
    pconstant.value = 1.1
    test_result("Test PConstant::to_string(): float", pconstant.to_string(), "1.1")
    
    pconstant.value = .
    test_result("Test PConstant::to_string(): missing real", pconstant.to_string(), ".")
    
    pconstant.value = "a"
    test_result("Test PConstant::to_string(): string", pconstant.to_string(), "a")
    
    pconstant.value = ""
    test_result("Test PConstant::to_string(): missing string", pconstant.to_string(), "")
}

// PRange

function test_prange_to_string() {
    class PRange scalar prange

    prange = PRange()
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 1
    
    test_result("Test PRange::to_string(): integer range closed", prange.to_string(), "1/3")
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 0
    prange.in_max = 1
    prange.discrete = 1
    
    test_result("Test PRange::to_string(): integer range open min closed max", prange.to_string(), "1!/3")
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 0
    prange.discrete = 1
    
    test_result("Test PRange::to_string(): integer range closed min open max", prange.to_string(), "1/!3")
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 0
    prange.in_max = 0
    prange.discrete = 1
    
    test_result("Test PRange::to_string(); integer range open", prange.to_string(), "1!!3")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range closed", prange.to_string(), "1.1/3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 0
    prange.in_max = 1
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range open min closed max", prange.to_string(), "1.1!/3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 1
    prange.in_max = 0
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range closed min open max", prange.to_string(), "1.1/!3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 0
    prange.in_max = 0
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range open", prange.to_string(), "1.1!!3.1")
}

// POr

function test_por_to_string() {
    class POr scalar por
    class PConstant scalar pconstant
    class PRange scalar prange
    
    por = POr()
    
    test_result("Test POr::to_string(): empty", por.to_string(), "")
    
    pconstant = PConstant()
    pconstant.value = 1
    
    por.patterns.patterns[1] = &pconstant
    por.patterns.length = 1
    
    test_result("Test POr::to_string(): one element", por.to_string(), "1")
    
    prange = PRange()
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 1
    
    por.patterns.patterns[2] = &prange
    por.patterns.length = 2
    
    test_result("Test POr::to_string(): two elements", por.to_string(), "1 | 1/3")
}

// Tuple

function test_ptuple_to_string() {
    class Tuple scalar tuple
    class PConstant scalar pconstant
    class PRange scalar prange
    
    tuple = Tuple()
    
    test_result("Test Tuple::to_string(): empty", tuple.to_string(), "Empty Tuple: Error")
    
    pconstant = PConstant()
    pconstant.define(1)
    
    tuple.patterns = J(1, 1, NULL)
    tuple.patterns[1] = &pconstant
    
    test_result("Test Tuple::to_string(): one element", tuple.to_string(), "1")
    
    prange = PRange()
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 1
    
    tuple.patterns = J(2, 1, NULL)
    tuple.patterns[1] = &pconstant
    tuple.patterns[2] = &prange
    test_result("Test Tuple::to_string(): two elements", tuple.to_string(), "(1, 1/3)")
}

/////////////////////////////////////////////////////////////////////// define()

// PEmpty

function test_pempty_define() {
    class PEmpty scalar pempty

    pempty = PEmpty()
    pempty.define()

    test_result("Test PEmpty::define()", pempty.to_string(), "Empty")
}

// PWild

function test_pwild_define() {
    class PWild scalar pwild
    class Variable scalar variable
    class PConstant scalar pconstant_1, pconstant_2
    
    variable = Variable()
    variable.name = "test_var"
    variable.type = "int"
    variable.levels = 1, 2
    
    pwild = PWild()
    pwild.define(variable)

    test_result("Test PWild::define()", pwild.to_string(1), "1 | 2")
}

// PConstant

function test_pconstant_define() {
    class PConstant scalar pconstant
    
    pconstant = PConstant()
    
    pconstant.define(1)
    test_result("Test PConstant::define(): real", pconstant.to_string(), "1")
    
    pconstant.define(.)
    test_result("Test PConstant::define(): missing real", pconstant.to_string(), ".")
    
    pconstant.define("a")
    test_result("Test PConstant::define(): string", pconstant.to_string(), "a")
    
    pconstant.define("")
    test_result("Test PConstant::define(): missing string", pconstant.to_string(), "")
    
    // TODO: test error with non real or string value
}

// PRange

function test_prange_define() {
    class PRange scalar prange
    
    prange = PRange()
    
    prange.define(1, 3, 1, 1, 1)
    test_result("Test PRange::define(): integer range closed", prange.to_string(), "1/3")
    
    prange.define(1, 3, 0, 1, 1)
    test_result("Test PRange::define(): integer range open min closed max", prange.to_string(), "1!/3")
    
    prange.define(1, 3, 1, 0, 1)
    test_result("Test PRange::define(): integer range closed min open max", prange.to_string(), "1/!3")
    
    prange.define(1, 3, 0, 0, 1)
    test_result("Test PRange::define(); integer range open", prange.to_string(), "1!!3")
    
    prange.define(1.1, 3.1, 1, 1, 0)
    test_result("Test PRange::define(): float range closed", prange.to_string(), "1.1/3.1")
    
    prange.define(1.1, 3.1, 0, 1, 0)
    test_result("Test PRange::define(): float range open min closed max", prange.to_string(), "1.1!/3.1")
    
    prange.define(1.1, 3.1, 1, 0, 0)
    test_result("Test PRange::define(): float range closed min open max", prange.to_string(), "1.1/!3.1")
    
    prange.define(1.1, 3.1, 0, 0, 0)
    test_result("Test PRange::define(): float range open", prange.to_string(), "1.1!!3.1")
    
    /*
    TODO: test errors
       - discrete not bool
       - in_min / in_max not bool
       - min / max missing
       - min > max not bool
       - min / max not int while discrete
    */
}

// POr

function test_por_define() {
    class POr scalar por
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    pconstant_2 = PConstant()
    pconstant_2.define(2)
    
    pconstant_3 = PConstant()
    pconstant_3.define(2)
    
    por = POr()
    por.define((&pconstant_1, &pconstant_2, &pconstant_3))
    
    test_result("Test POr::define(): base", por.to_string(), "1 | 2 | 2")
}

// Tuple

/* function test_ptuple_define() {
    // TODO: write the function
}*/

///////////////////////////////////////////////////////////////////// compress()

// PEmpty

function test_pempty_compress() {
    class PEmpty scalar pempty
    class Pattern scalar compressed

    pempty = PEmpty()
    
    compressed = pempty.compress()

    test_result("Test PEmpty::compress()", compressed.to_string(), "Empty")
}

// PWild

function test_pwild_compress() {
    class PWild scalar pwild
    class Pattern scalar compressed

    pwild = PWild()
    
    compressed = pwild.compress()

    test_result("Test PWild::compress()", compressed.to_string(), "_")
}

// PConstant

function test_pconstant_compress() {
    class PConstant scalar pconstant
    class Pattern scalar compressed

    pconstant = PConstant()
    pconstant.define(1)
    
    compressed = pconstant.compress()

    test_result("Test PConstant::compress()", compressed.to_string(), "1")
}

// PRange

function test_prange_compress() {
    class PRange scalar prange
    class Pattern scalar compressed

    prange = PRange()
    
    prange.define(1, 3, 1, 1, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range closed", compressed.to_string(), "1/3")
    
    prange.define(1, 3, 0, 1, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range open min closed max", compressed.to_string(), "2/3")
    
    prange.define(1, 3, 1, 0, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range closed min open max", compressed.to_string(), "1/2")
    
    prange.define(1, 3, 0, 0, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range open", compressed.to_string(), "2")
    
    prange.define(1.1, 3.1, 1, 1, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range closed", compressed.to_string(), "1.1/3.1")
    
    prange.define(1.1, 3.1, 0, 1, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range open min closed max", compressed.to_string(), "1.1!/3.1")
    
    prange.define(1.1, 3.1, 1, 0, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range closed min open max", compressed.to_string(), "1.1/!3.1")
    
    prange.define(1.1, 3.1, 0, 0, 0)
    compressed = prange.compress()
    test_result("Test PRange::define(): float range open", compressed.to_string(), "1.1!!3.1")
    
    prange.define(1, 2, 0, 0, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): empty range", compressed.to_string(), "Empty")
    
}

// POr

function test_por_compress() {
    class POr scalar por
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class PRange scalar prange_1, prange_2
    class Pattern scalar compressed
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    pconstant_2 = PConstant()
    pconstant_2.define(2)
    
    pconstant_3 = PConstant()
    pconstant_3.define(2)
    
    prange_1 = PRange()
    prange_1.define(1, 3, 0, 1, 1)
    
    prange_2 = PRange()
    prange_2.define(1, 2, 0, 0, 1)
    
    por = POr()
    por.define((&pconstant_1, &pconstant_2))
    compressed = por.compress()
    test_result("Test POr::compress(): base", compressed.to_string(), "1 | 2")
    
    por = POr()
    por.define((&pconstant_1, &pconstant_2, &pconstant_3))
    compressed = por.compress()
    test_result("Test POr::compress(): shrink", compressed.to_string(), "1 | 2")
    
    por = POr()
    por.define((&pconstant_2, &pconstant_3))
    compressed = por.compress()
    test_result("Test POr::compress(): to constant", compressed.to_string(), "2")
    
    por = POr()
    por.define((&pconstant_1, &prange_1))
    compressed = por.compress()
    test_result("Test POr::compress(): compress each", compressed.to_string(), "1 | 2/3")
    
    por = POr()
    por.define((&prange_2, &prange_2))
    compressed = por.compress()
    test_result("Test POr::compress(): empty", compressed.to_string(), "Empty")
}

// Tuple

function test_ptuple_compress() {
    class Tuple scalar tuple
    class POr scalar por
    class PConstant scalar pconstant
    class PRange scalar prange_1, prange_2
    class Pattern scalar compressed
    
    pconstant = PConstant()
    pconstant.define(1)
    
    por = POr()
    por.define((&pconstant, &pconstant))
    
    prange_1 = PRange()
    prange_1.define(1, 3, 0, 1, 1)
    
    prange_2 = PRange()
    prange_2.define(1, 2, 0, 0, 1)
    
    tuple = Tuple()
    
    tuple.patterns = (&pconstant, &pconstant)
    compressed = tuple.compress()
    test_result("Test Tuple::compress(): base", compressed.to_string(), "(1, 1)")
    
    tuple.patterns = (&por, &prange_1)
    compressed = tuple.compress()
    test_result("Test Tuple::compress(): compress each", compressed.to_string(), "(1, 2/3)")
    
    tuple.patterns = (&por, &prange_2)
    compressed = tuple.compress()
    test_result("Test Tuple::compress(): empty", compressed.to_string(), "Empty")
}


////////////////////////////////////////////////////////////////////// overlap()

// PEmpty

function test_pempty_overlap() {
    class PEmpty scalar pempty
    class PConstant scalar pconstant
    class Pattern scalar overlap
    
    pempty = PEmpty()
    
    pconstant = PConstant()
    pconstant.define(1)
    
    overlap = pempty.overlap(pconstant)

    test_result("Test PEmpty::overlap()", overlap.to_string(), "Empty")
}

// PWild

function test_pwild_overlap() {
    class PWild scalar pwild
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    class Pattern scalar overlap
    
    pwild = PWild()
    
    // PEmpty is covered in previous test
    
    pconstant = PConstant()
    pconstant.define(1)
    overlap = pwild.overlap(pconstant)
    test_result("Test PWild::overlap() constant", overlap.to_string(), pconstant.to_string())
    
    prange = PRange()
    prange.define(0, 2, 1, 1, 1)
    overlap = pwild.overlap(prange)
    test_result("Test PWild::overlap() range", overlap.to_string(), prange.to_string())
    
    por = POr()
    por.push(pconstant)
    por.push(prange)
    overlap = pwild.overlap(por)
    test_result("Test PWild::overlap() or", overlap.to_string(), por.to_string())
}

// PConstant

function test_pconstant_overlap() {
    class PConstant scalar pconstant, pconstant_1, pconstant_2
    class PRange scalar prange_1, prange_2, prange_3, prange_4
    class POr scalar por
    class Pattern scalar overlap
    
    pconstant = PConstant()
    pconstant.define(1)
    
    // PEmpty is covered in previous test
    
    // Pwild is covered in previous test
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    overlap = pconstant.overlap(pconstant_1)
    test_result("Test PConstant::overlap() same constant", overlap.to_string(), "1")
    
    pconstant_2 = PConstant()
    pconstant_2.define(2)
    overlap = pconstant.overlap(pconstant_2)
    test_result("Test PConstant::overlap() other constant", overlap.to_string(), "Empty")
    
    prange_1 = PRange()
    prange_1.define(0, 2, 1, 1, 1)
    overlap = pconstant.overlap(prange_1)
    test_result("Test PConstant::overlap() range in", overlap.to_string(), "1")
    
    prange_2 = PRange()
    prange_2.define(2, 3, 1, 1, 1)
    overlap = pconstant.overlap(prange_2)
    test_result("Test PConstant::overlap() range out", overlap.to_string(), "Empty")
    
    prange_3 = PRange()
    prange_3.define(1, 2, 0, 1, 1)
    overlap = pconstant.overlap(prange_3)
    test_result("Test PConstant::overlap() min out", overlap.to_string(), "Empty")
    
    prange_4 = PRange()
    prange_4.define(0, 1, 1, 0, 1)
    overlap = pconstant.overlap(prange_4)
    test_result("Test PConstant::overlap() max out", overlap.to_string(), "Empty")
    
    por = POr()
    por.push(pconstant_2)
    por.push(prange_2)
    overlap = pconstant.overlap(por)
    test_result("Test PConstant::overlap() or out", overlap.to_string(), "Empty")
    
    por.push(pconstant_1)
    overlap = pconstant.overlap(por)
    test_result("Test PConstant::overlap() or in", overlap.to_string(), "1")
}

// PRange

function test_prange_overlap() {
    class PRange scalar prange, prange_1, prange_2, prange_3, prange_4, prange_5, prange_6, prange_7, prange_8
    class PConstant scalar pconstant_1, pconstant_2
    class POr scalar por
    class Pattern scalar overlap
    
    prange = PRange()
    prange.define(0, 3, 1, 1, 1)
    
    // PEmpty is covered in previous test
    
    // PWild is covered in previous test
    
    // PConstant is covered in previous test
    
    prange_1 = PRange()
    prange_1.define(0, 3, 1, 1, 1)
    overlap = prange.overlap(prange_1)
    test_result("Test PRange::overlap() same range", overlap.to_string(), "0/3")
    
    prange_2 = PRange()
    prange_2.define(1, 2, 1, 1, 1)
    overlap = prange.overlap(prange_2)
    test_result("Test PRange::overlap() range in", overlap.to_string(), "1/2")
    
    prange_3 = PRange()
    prange_3.define(10, 20, 1, 1, 1)
    overlap = prange.overlap(prange_3)
    test_result("Test PRange::overlap() range out", overlap.to_string(), "Empty")
    
    prange_4 = PRange()
    prange_4.define(0, 3, 0, 1, 1)
    overlap = prange.overlap(prange_4)
    test_result("Test PRange::overlap() min out", overlap.to_string(), "1/3")
    
    prange_5 = PRange()
    prange_5.define(0, 3, 1, 0, 1)
    overlap = prange.overlap(prange_5)
    test_result("Test PRange::overlap() max out", overlap.to_string(), "0/2")
    
    prange_6 = PRange()
    prange_6.define(-1, 1, 1, 1, 1)
    overlap = prange.overlap(prange_6)
    test_result("Test PRange::overlap() low", overlap.to_string(), "0/1")
    
    prange_7 = PRange()
    prange_7.define(2, 4, 1, 1, 1)
    overlap = prange.overlap(prange_7)
    test_result("Test PRange::overlap() high", overlap.to_string(), "2/3")
    
    prange = PRange()
    prange.define(0, 4, 0, 1, 0)
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    pconstant_2 = PConstant()
    pconstant_2.define(5)
    
    prange_8 = PRange()
    prange_8.define(2, 3, 1, 1, 1)
    
    por = POr()
    por.push(pconstant_1)
    por.push(pconstant_2)
    por.push(prange_8)
    overlap = prange.overlap(por)
    test_result("Test PRange::overlap() or", overlap.to_string(), "1 | 2/3")
}

// POr

function test_por_overlap() {
    class POr scalar por_1, por_2
    class PRange scalar prange_1, prange_2
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class Pattern scalar overlap
    
    // POr 1 : (0 | 1 | 2/4)
    
    por_1 = POr()
    
    pconstant_1 = PConstant()
    pconstant_1.define(0)
    
    pconstant_2 = PConstant()
    pconstant_2.define(1)
    
    prange_1 = PRange()
    prange_1.define(2, 4, 1, 1, 1)
    
    por_1.push(pconstant_1)
    por_1.push(pconstant_2)
    por_1.push(prange_1)
    
    // POr 2 : (10/20 | 3 | 1)
    
    por_2 = POr()
    
    prange_2 = PRange()
    prange_2.define(10, 20, 1, 1, 1)
    
    pconstant_3 = PConstant()
    pconstant_3.define(3)
    
    por_2.push(prange_2)
    por_2.push(pconstant_3)
    por_2.push(pconstant_2)
    
    // Check
    // - pconstant out
    // - same pconstant
    // - pconstant in prange
    // - prange out
    // - order does not matter
    
    overlap = por_1.overlap(por_2)
    
    test_result("Test POr::overlap() or", overlap.to_string(), "1 | 3")
}

///////////////////////////////////////////////////////////////////// includes()

// PEmpty

function test_pempty_includes() {
    class PEmpty scalar pempty, pempty_1
    class PConstant scalar pconstant
    real scalar included
    
    pempty = PEmpty()
    
    pempty_1 = PEmpty()
    
    included = pempty.includes(pempty_1)
    test_result("Test PEmpty::includes() empty", strofreal(included), "1")
    
    pconstant = PConstant()
    pconstant.define(1)
    
    included = pempty.includes(pconstant)
    test_result("Test PEmpty::includes() constant", strofreal(included), "0")
}

// PWild

function test_pwild_includes() {
    class PWild scalar pwild
    class PEmpty scalar pempty
    class PConstant scalar pconstant
    class PRange scalar prange
    class POr scalar por
    real scalar included
    
    pwild = PWild()
    
    pempty = PEmpty()
    included = pwild.includes(pempty)
    test_result("Test PWild::includes() empty", strofreal(included), "1")
    
    pconstant = PConstant()
    pconstant.define(1)
    included = pwild.includes(pconstant)
    test_result("Test PWild::includes() constant", strofreal(included), "1")
    
    prange = PRange()
    prange.define(0, 2, 1, 1, 1)
    included = pwild.includes(prange)
    test_result("Test PWild::includes() range", strofreal(included), "1")
    
    por = POr()
    por.push(pconstant)
    por.push(prange)
    included = pwild.includes(por)
    test_result("Test PWild::includes() or", strofreal(included), "1")
}

// PConstant

function test_pconstant_includes() {
    class PConstant scalar pconstant, pconstant_1, pconstant_2
    class PEmpty scalar pempty
    class PRange scalar prange_1, prange_2, prange_3
    class POr scalar por
    class Pattern scalar overlap
    real scalar included
    
    pconstant = PConstant()
    pconstant.define(1)
    
    pempty = PEmpty()
    included = pconstant.includes(pempty)
    test_result("Test PConstant::includes() empty", strofreal(included), "1")
    
    // PWild is equivalent to POr on its values
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    included = pconstant.includes(pconstant_1)
    test_result("Test PConstant::includes() same constant", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    pconstant_2.define(2)
    included = pconstant.includes(pconstant_2)
    test_result("Test PConstant::includes() other constant", strofreal(included), "0")
    
    prange_1 = PRange()
    prange_1.define(1, 1, 1, 1, 1)
    included = pconstant.includes(prange_1)
    test_result("Test PConstant::includes() range constant", strofreal(included), "1")
    
    prange_2 = PRange()
    prange_2.define(0, 2, 1, 1, 1)
    included = pconstant.includes(prange_2)
    test_result("Test PConstant::includes() range in", strofreal(included), "0")
    
    prange_3 = PRange()
    prange_3.define(2, 3, 1, 1, 1)
    included = pconstant.includes(prange_3)
    test_result("Test PConstant::includes() range out", strofreal(included), "0")
    
    por = POr()
    
    por.push(pconstant_1)
    included = pconstant.includes(por)
    test_result("Test PConstant::includes() or in", strofreal(included), "1")
    
    por.push(pconstant_2)
    included = pconstant.includes(por)
    test_result("Test PConstant::includes() or out", strofreal(included), "0")
}

// PRange

function test_prange_includes() {
    class PRange scalar prange, prange_1, prange_2, prange_3, prange_4, prange_5, prange_6, prange_7
    class PEmpty scalar pempty
    class PConstant scalar pconstant_1, pconstant_2
    class POr scalar por
    class Pattern scalar overlap
    real scalar included
    
    prange = PRange()
    prange.define(0, 3, 1, 1, 1)
    
    pempty = PEmpty()
    included = prange.includes(pempty)
    test_result("Test PRange::includes() empty", strofreal(included), "1")
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    included = prange.includes(pconstant_1)
    test_result("Test PRange::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    pconstant_2.define(5)
    included = prange.includes(pconstant_2)
    test_result("Test PRange::includes() constant out", strofreal(included), "0")
    
    // PWild is equivalent to POr on its values
    
    prange_1 = PRange()
    prange_1.define(0, 3, 1, 1, 1)
    included = prange.includes(prange_1)
    test_result("Test PRange::includes() same range", strofreal(included), "1")
    
    prange_2 = PRange()
    prange_2.define(1, 2, 1, 1, 1)
    included = prange.includes(prange_2)
    test_result("Test PRange::includes() range in", strofreal(included), "1")
    
    prange_3 = PRange()
    prange_3.define(10, 20, 1, 1, 1)
    included = prange.includes(prange_3)
    test_result("Test PRange::includes() range out", strofreal(included), "0")
    
    prange_4 = PRange()
    prange_4.define(0, 3, 0, 1, 1)
    included = prange_4.includes(prange) // reverse
    test_result("Test PRange::includes() min out", strofreal(included), "0")
    
    prange_5 = PRange()
    prange_5.define(0, 3, 1, 0, 1)
    included = prange_5.includes(prange) // reverse
    test_result("Test PRange::includes() max out", strofreal(included), "0")
    
    prange_6 = PRange()
    prange_6.define(-1, 1, 1, 1, 1)
    included = prange.includes(prange_6)
    test_result("Test PRange::includes() low", strofreal(included), "0")
    
    prange_7 = PRange()
    prange_7.define(2, 4, 1, 1, 1)
    included = prange.includes(prange_7)
    test_result("Test PRange::includes() high", strofreal(included), "0")
    
    por = POr()
    por.push(pconstant_1)
    included = prange.includes(por)
    test_result("Test PRange::includes() or in", strofreal(included), "1")
    
    por.push(pconstant_2)
    included = prange.includes(por)
    test_result("Test PRange::includes() or out", strofreal(included), "0")
}

// POr

function test_por_includes() {
    class POr scalar por, por_1
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class PRange scalar prange_1, prange_2, prange_3, prange_4
    real scalar included
    
    // POr : (0 | 1/4)
    
    por = POr()
    
    pconstant_1 = PConstant()
    pconstant_1.define(0)
    
    prange_1 = PRange()
    prange_1.define(1, 4, 1, 1, 1)
    
    por.push(pconstant_1)
    por.push(prange_1)
    
    included = por.includes(pconstant_1)
    test_result("Test POr::includes() constant in", strofreal(included), "1")
    
    pconstant_2 = PConstant()
    pconstant_2.define(2)
    
    included = por.includes(pconstant_2)
    test_result("Test POr::includes() constant in 2", strofreal(included), "1")
    
    pconstant_3 = PConstant()
    pconstant_3.define(-1)
    
    included = por.includes(pconstant_3)
    test_result("Test POr::includes() constant out", strofreal(included), "0")
    
    prange_2 = PRange()
    prange_2.define(2, 3, 1, 1, 1)
    
    included = por.includes(prange_2)
    test_result("Test POr::includes() range in", strofreal(included), "1")
    
    prange_3 = PRange()
    prange_3.define(-3, -1, 1, 1, 1)
    
    included = por.includes(prange_3)
    test_result("Test POr::includes() range out", strofreal(included), "0")
    
    prange_4 = PRange()
    prange_4.define(0, 2, 1, 1, 1) // = (0 | 1 | 2) in (0 | 1/4)
    
    included = por.includes(prange_4)
    test_result("Test POr::includes() range in across patterns", strofreal(included), "1")
    
    por_1 = POr()
    
    por_1.push(pconstant_1)
    included = por.includes(por_1)
    test_result("Test POr::includes() or in 1 element", strofreal(included), "1")
    
    por_1.push(prange_2)
    included = por.includes(por_1)
    test_result("Test POr::includes() or in 2 elements", strofreal(included), "1")
    
    por_1.push(pconstant_3)
    included = por.includes(por_1)
    test_result("Test POr::includes() or out", strofreal(included), "0")    
}

/////////////////////////////////////////////////////////////////// difference()

// PEmpty

function test_pempty_difference() {
    class PEmpty scalar pempty
    class Pattern scalar difference
    class PEmpty scalar pempty_1
    class PWild scalar pwild
    class PConstant scalar pconstant_1
    class PRange scalar prange_1
    class POr scalar por
    
    pempty = PEmpty()
    
    // PEmpty

    pempty_1 = PEmpty()
    
    difference = *pempty.difference(pempty_1)

    test_result("Test PEmpty::difference() empty", difference.to_string(), "Empty")

    // PWild

    pwild = PWild()
    
    difference = *pempty.difference(pwild)

    test_result("Test PEmpty::difference() wild", difference.to_string(), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    difference = *pempty.difference(pconstant_1)

    test_result("Test PEmpty::difference() constant", difference.to_string(), "Empty")

    // PRange

    prange_1 = PRange()
    prange_1.define(0, 2, 1, 1, 1)
    
    difference = *pempty.difference(prange_1)

    test_result("Test PEmpty::difference() range", difference.to_string(), "Empty")

    // POr

    por = POr()
    por.push(pconstant_1)
    por.push(prange_1)
    
    difference = *pempty.difference(por)

    test_result("Test PEmpty::difference() or", difference.to_string(), "Empty")
}

// PWild

function test_pwild_difference() {
    // Equivalent to POr with values
}

// PConstant

function test_pconstant_difference() {
    class PConstant scalar pconstant
    class Pattern scalar difference
    class PEmpty scalar pempty
    class PWild scalar pwild
    class PConstant scalar pconstant_1, pconstant_2
    class PRange scalar prange_1, prange_2
    class POr scalar por
    
    pconstant = PConstant()
    pconstant.define(1)
    
    // PEmpty

    pempty = PEmpty()
    
    difference = *pconstant.difference(pempty)

    test_result("Test PConstant::difference() empty", difference.to_string(), "1")

    // PWild

    pwild = PWild()
    
    difference = *pconstant.difference(pwild)

    test_result("Test PConstant::difference() wild", difference.to_string(), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    difference = *pconstant.difference(pconstant_1)

    test_result("Test PConstant::difference() constant same", difference.to_string(), "Empty")

    pconstant_2 = PConstant()
    pconstant_2.define(2)
    
    difference = *pconstant.difference(pconstant_2)

    test_result("Test PConstant::difference() constant different", difference.to_string(), "1")

    // PRange

    prange_1 = PRange()
    prange_1.define(0, 2, 1, 1, 1)
    
    difference = *pconstant.difference(prange_1)

    test_result("Test PConstant::difference() range in", difference.to_string(), "Empty")

    prange_2 = PRange()
    prange_2.define(-2, 0, 1, 1, 1)
    
    difference = *pconstant.difference(prange_2)

    test_result("Test PConstant::difference() range out", difference.to_string(), "1")

    // POr

    por = POr()
    por.push(pconstant_2)
    por.push(prange_2)
    
    difference = *pconstant.difference(por)

    test_result("Test PConstant::difference() range in", difference.to_string(), "1")

    por.push(pconstant_1)
    
    difference = *pconstant.difference(por)

    test_result("Test PConstant::difference() range out", difference.to_string(), "Empty")
}

// PRange

function test_prange_difference() {
    class PRange scalar prange
    class Pattern scalar difference
    class PEmpty scalar pempty
    class PWild scalar pwild
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class PRange scalar prange_1, prange_2, prange_3
    class POr scalar por
    
    prange = PRange()
    prange.define(0, 3, 1, 1, 1)
    
    // PEmpty

    pempty = PEmpty()
    
    difference = *prange.difference(pempty)

    test_result("Test PRange::difference() empty", difference.to_string(), "0/3")

    // PWild

    pwild = PWild()
    
    difference = *prange.difference(pwild)

    test_result("Test PRange::difference() wild", difference.to_string(), "Empty")

    // PConstant

    pconstant_1 = PConstant()
    pconstant_1.define(-1)
    
    difference = *prange.difference(pconstant_1)

    test_result("Test PRange::difference() constant out", difference.to_string(), "0/3")

    pconstant_2 = PConstant()
    pconstant_2.define(2)
    
    difference = *prange.difference(pconstant_2)

    test_result("Test PRange::difference() constant middle", difference.to_string(), "0/1 | 3")

    pconstant_3 = PConstant()
    pconstant_3.define(3)
    
    difference = *prange.difference(pconstant_3)

    test_result("Test PRange::difference() constant boundary", difference.to_string(), "0/2")

    // PRange

    prange_1 = PRange()
    prange_1.define(-2, -1, 1, 1, 1)
    
    difference = *prange.difference(prange_1)

    test_result("Test PRange::difference() range out", difference.to_string(), "0/3")
    
    prange_2 = PRange()
    prange_2.define(1, 2, 1, 1, 1)
    
    difference = *prange.difference(prange_2)

    test_result("Test PRange::difference() range in", difference.to_string(), "0 | 3")
    
    prange_3 = PRange()
    prange_3.define(0, 3, 1, 1, 1)
    
    difference = *prange.difference(prange_3)

    test_result("Test PRange::difference() range same", difference.to_string(), "Empty")
    
    // POr
    
    por = POr()
    por.push(pconstant_1)
    por.push(prange_1)
    
    difference = *prange.difference(por)

    test_result("Test PRange::difference() or out", difference.to_string(), "0/3")
    
    por.push(pconstant_3)
    
    difference = *prange.difference(por)

    test_result("Test PRange::difference() or in 1", difference.to_string(), "0/2")
    
    por.push(prange_2)
    
    difference = *prange.difference(por)

    test_result("Test PRange::difference() or in 2", difference.to_string(), "0")
}

// POr

function test_por_difference() {
    class POr scalar por
    class Pattern scalar difference
    class PEmpty scalar pempty
    class PWild scalar pwild
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class PRange scalar prange_1, prange_2, prange_3, prange_4
    class POr scalar por_1
    
    por = POr()
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    prange_1 = PRange()
    prange_1.define(3, 7, 1, 1, 1)
    
    por.push(&pconstant_1)
    por.push(&prange_1)
    
    // PEmpty
    
    pempty = PEmpty()
    
    difference = *por.difference(pempty)

    test_result("Test POr::difference() empty", difference.to_string(), "1 | 3/7")
    
    // PWild
    
    pwild = PWild()
    
    difference = *por.difference(pwild)

    test_result("Test POr::difference() wild", difference.to_string(), "Empty")
    
    // PConstant
    
    difference = *por.difference(pconstant_1)

    test_result("Test POr::difference() constant in 1", difference.to_string(), "3/7")
    
    pconstant_2 = PConstant()
    pconstant_2.define(5)
    
    difference = *por.difference(pconstant_2)

    test_result("Test POr::difference() constant in 2", difference.to_string(), "1 | 3/4 | 6/7")
    
    pconstant_3 = PConstant()
    pconstant_3.define(8)
    
    difference = *por.difference(pconstant_3)

    test_result("Test POr::difference() constant out", difference.to_string(), "1 | 3/7")
    
    // PRange
    
    difference = *por.difference(prange_1)

    test_result("Test POr::difference() range in", difference.to_string(), "1")
    
    prange_2 = PRange()
    prange_2.define(1, 4, 1, 1, 1)
    
    difference = *por.difference(prange_2)

    test_result("Test POr::difference() range across", difference.to_string(), "5/7")
    
    prange_3 = PRange()
    prange_3.define(-5, 0, 1, 1, 1)
    
    difference = *por.difference(prange_3)

    test_result("Test POr::difference() range out", difference.to_string(), "1 | 3/7")
    
    prange_4 = PRange()
    prange_4.define(0, 8, 1, 1, 1)
    
    difference = *por.difference(prange_4)

    test_result("Test POr::difference() ranger all", difference.to_string(), "Empty")
    
    // POr
    
    por_1 = POr()
    por_1.push(pconstant_3)
    por_1.push(prange_3)
    
    difference = *por.difference(por_1)
    
    por.to_string()
    por_1.to_string()

    test_result("Test POr::difference() or out", difference.to_string(), "1 | 3/7")
    
    por_1.push(pconstant_2)
    
    difference = *por.difference(por_1)

    test_result("Test POr::difference() or in 1", difference.to_string(), "1 | 3/4 | 6/7")
    
    por_1.push(prange_2)
    
    difference = *por.difference(por_1)

    test_result("Test POr::difference() or in 2", difference.to_string(), "6/7")
    
    por_1.push(prange_4)
    
    difference = *por.difference(por_1)

    test_result("Test POr::difference() or all", difference.to_string(), "Empty")
}

////////////////////////////////////////////////////////////////////// to_expr()

// PEmpty

function test_pempty_to_expr() {
    class PEmpty scalar pempty
    string scalar var_name

    var_name = "test_var"

    pempty = PEmpty()

    test_result("Test PEmpty::to_expr()", pempty.to_expr(var_name), "")
}

// PWild

function test_pwild_to_expr() {
    class PWild scalar pwild
    string scalar var_name

    var_name = "test_var"

    pwild = PWild()

    test_result("Test PWild::to_expr()", pwild.to_expr(var_name), "1")
}

// PConstant

function test_pconstant_to_expr() {
    class PConstant scalar pconstant
    string scalar var_name

    var_name = "test_var"

    pconstant = PConstant()
    pconstant.value = 1

    test_result("Test PConstant::to_expr() real", pconstant.to_expr(var_name), "test_var == `one_21x'")

    pconstant.value = `""a""'
    pconstant.value

    test_result("Test PConstant::to_expr() string", pconstant.to_expr(var_name), `"test_var == "a""')
}

// PRange

function test_prange_to_expr() {
    class PRange scalar prange
    string scalar var_name

    var_name = "test_var"
    
    prange = PRange()

    prange.define(0, 2, 1, 1, 1)
    test_result("Test PRange::to_expr() [0, 2]", prange.to_expr(var_name), "test_var >= `zero_21x' & test_var <= `two_21x'")

    prange.define(0, 2, 0, 1, 1)
    test_result("Test PRange::to_expr() ]0, 2]", prange.to_expr(var_name), "test_var > `zero_21x' & test_var <= `two_21x'")

    prange.define(0, 2, 1, 0, 1)
    test_result("Test PRange::to_expr() [0, 2[", prange.to_expr(var_name), "test_var >= `zero_21x' & test_var < `two_21x'")

    prange.define(0, 2, 0, 0, 1)
    test_result("Test PRange::to_expr() ]0, 2[", prange.to_expr(var_name), "test_var > `zero_21x' & test_var < `two_21x'")
}

// POr

function test_por_to_expr() {
    class POr scalar por
    class PConstant scalar pconstant
    class PRange scalar prange
    string scalar var_name

    var_name = "test_var"

    por = POr()

    test_result("Test POr::to_expr() empty", por.to_expr(var_name), "")

    pconstant = PConstant()
    pconstant.value = 1

    por.push(pconstant)

    test_result("Test POr::to_expr()", por.to_expr(var_name), "test_var == `one_21x'")

    prange = PRange()
    prange.define(2, 3, 1, 1, 1)

    por.push(prange)

    test_result("Test POr::to_expr()", por.to_expr(var_name), "(test_var == `one_21x') | (test_var >= `two_21x' & test_var <= `three_21x')")
}

// Tuple

function test_ptuple_to_expr() {
    class Tuple scalar tuple_1, tuple_2
    class PConstant scalar pconstant
    class PRange scalar prange
    class PWild scalar pwild
    class POr scalar por_1, por_2
    class Variable vector variables

    tuple_1 = Tuple()

    // 1

    pconstant = PConstant()
    pconstant.define(1)

    tuple_1.patterns = J(1, 1, NULL)
    tuple_1.patterns[1] = &pconstant

    variables = Variable(1)
    variables[1].name = "test_var_1"

    test_result("Test Tuple::to_expr(): one element", tuple_1.to_expr(variables), "test_var_1 == `one_21x'")

    // (1, 1/3)
 
    prange = PRange()
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 1

    tuple_1.patterns = J(2, 1, NULL)
    tuple_1.patterns[1] = &pconstant
    tuple_1.patterns[2] = &prange

    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[2].name = "test_var_2"

    test_result("Test Tuple::to_expr(): two elements", tuple_1.to_expr(variables), "(test_var_1 == `one_21x') & (test_var_2 >= `one_21x' & test_var_2 <= `three_21x')")

    // (1 | 1/3, _)

    por_1 = POr()
    por_1.push(pconstant)
    por_1.push(prange)

    pwild = PWild()

    tuple_1.patterns = J(2, 1, NULL)
    tuple_1.patterns[1] = &por_1
    tuple_1.patterns[2] = &pwild

    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[2].name = "test_var_2"

    test_result("Test Tuple::to_expr(): wildcard", tuple_1.to_expr(variables), "(test_var_1 == `one_21x') | (test_var_1 >= `one_21x' & test_var_1 <= `three_21x')")

    // (1 | 1/3, _) | (1, 1/3)
    
    tuple_2.patterns = J(2, 1, NULL) 
    tuple_2.patterns[1] = &pconstant
    tuple_2.patterns[2] = &prange
    
    por_2 = POr()
    por_2.push(tuple_1)
    por_2.push(tuple_2)
    
    variables = Variable(2)
    variables[1].name = "test_var_1"
    variables[2].name = "test_var_2"
    
    test_result("Test Tuple::to_expr(): POr of tuples", por_2.to_expr(variables), "((test_var_1 == `one_21x') | (test_var_1 >= `one_21x' & test_var_1 <= `three_21x')) | ((test_var_1 == `one_21x') & (test_var_2 >= `one_21x' & test_var_2 <= `three_21x'))")
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
