/*
Do-file to test the pattern classes and methods
*/

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
    
    test_result("Test PRange::to_string(): integer range closed", prange.to_string(), "1~3")
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 0
    prange.in_max = 1
    prange.discrete = 1
    
    test_result("Test PRange::to_string(): integer range open min closed max", prange.to_string(), "1!~3")
    
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 0
    prange.discrete = 1
    
    test_result("Test PRange::to_string(): integer range closed min open max", prange.to_string(), "1~!3")
    
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
    
    test_result("Test PRange::to_string(): float range closed", prange.to_string(), "1.1~3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 0
    prange.in_max = 1
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range open min closed max", prange.to_string(), "1.1!~3.1")
    
    prange.min = 1.1
    prange.max = 3.1
    prange.in_min = 1
    prange.in_max = 0
    prange.discrete = 0
    
    test_result("Test PRange::to_string(): float range closed min open max", prange.to_string(), "1.1~!3.1")
    
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
    
    test_result("Test POr::to_string(): two elements", por.to_string(), "1 | 1~3")
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
    
    test_result("Test POr::to_string(): one element", tuple.to_string(), "1")
    
    prange = PRange()
    prange.min = 1
    prange.max = 3
    prange.in_min = 1
    prange.in_max = 1
    prange.discrete = 1
    
    tuple.patterns = J(2, 1, NULL)
    tuple.patterns[1] = &pconstant
    tuple.patterns[2] = &prange
    test_result("Test POr::to_string(): two elements", tuple.to_string(), "(1, 1~3)")
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
    
    pconstant_1 = PConstant()
    pconstant_1.value = 1
    
    pconstant_2 = PConstant()
    pconstant_2.value = 2
    
    variable = Variable()
    variable.values = POr()
    variable.values.patterns.patterns[1] = &pconstant_1
    variable.values.patterns.patterns[2] = &pconstant_2
    variable.values.patterns.length = 2
    
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
    test_result("Test PRange::define(): integer range closed", prange.to_string(), "1~3")
    
    prange.define(1, 3, 0, 1, 1)
    test_result("Test PRange::define(): integer range open min closed max", prange.to_string(), "1!~3")
    
    prange.define(1, 3, 1, 0, 1)
    test_result("Test PRange::define(): integer range closed min open max", prange.to_string(), "1~!3")
    
    prange.define(1, 3, 0, 0, 1)
    test_result("Test PRange::define(); integer range open", prange.to_string(), "1!!3")
    
    prange.define(1.1, 3.1, 1, 1, 0)
    test_result("Test PRange::define(): float range closed", prange.to_string(), "1.1~3.1")
    
    prange.define(1.1, 3.1, 0, 1, 0)
    test_result("Test PRange::define(): float range open min closed max", prange.to_string(), "1.1!~3.1")
    
    prange.define(1.1, 3.1, 1, 0, 0)
    test_result("Test PRange::define(): float range closed min open max", prange.to_string(), "1.1~!3.1")
    
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
    por.define((&pconstant_1, &pconstant_2, &pconstant_3), 0)
    
    test_result("Test POr::define(): base", por.to_string(), "1 | 2 | 2")
    
    por = POr()
    por.define((&pconstant_1, &pconstant_2, &pconstant_3), 1)
    
    test_result("Test POr::define(): check includes", por.to_string(), "1 | 2")
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
    test_result("Test PRange::compress(): real range closed", compressed.to_string(), "1~3")
    
    prange.define(1, 3, 0, 1, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range open min closed max", compressed.to_string(), "2~3")
    
    prange.define(1, 3, 1, 0, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range closed min open max", compressed.to_string(), "1~2")
    
    prange.define(1, 3, 0, 0, 1)
    compressed = prange.compress()
    test_result("Test PRange::compress(): real range open", compressed.to_string(), "2")
    
    prange.define(1.1, 3.1, 1, 1, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range closed", compressed.to_string(), "1.1~3.1")
    
    prange.define(1.1, 3.1, 0, 1, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range open min closed max", compressed.to_string(), "1.1!~3.1")
    
    prange.define(1.1, 3.1, 1, 0, 0)
    compressed = prange.compress()
    test_result("Test PRange::compress(): float range closed min open max", compressed.to_string(), "1.1~!3.1")
    
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
    por.define((&pconstant_1, &pconstant_2), 0)
    compressed = por.compress()
    test_result("Test POr::compress(): base", compressed.to_string(), "1 | 2")
    
    por = POr()
    por.define((&pconstant_1, &pconstant_2, &pconstant_3), 0)
    compressed = por.compress()
    test_result("Test POr::compress(): shrink", compressed.to_string(), "1 | 2")
    
    por = POr()
    por.define((&pconstant_2, &pconstant_3), 1)
    compressed = por.compress()
    test_result("Test POr::compress(): to constant", compressed.to_string(), "2")
    
    por = POr()
    por.define((&pconstant_1, &prange_1), 1)
    compressed = por.compress()
    test_result("Test POr::compress(): compress each", compressed.to_string(), "1 | 2~3")
    
    por = POr()
    por.define((&prange_2, &prange_2), 1)
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
    test_result("Test Tuple::compress(): compress each", compressed.to_string(), "(1, 2~3)")
    
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
    por.insert(pconstant)
    por.insert(prange)
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
    por.insert(pconstant_2)
    por.insert(prange_2)
    overlap = pconstant.overlap(por)
    test_result("Test PConstant::overlap() or out", overlap.to_string(), "Empty")
    
    por.insert(pconstant_1)
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
    test_result("Test PRange::overlap() same range", overlap.to_string(), "0~3")
    
    prange_2 = PRange()
    prange_2.define(1, 2, 1, 1, 1)
    overlap = prange.overlap(prange_2)
    test_result("Test PRange::overlap() range in", overlap.to_string(), "1~2")
    
    prange_3 = PRange()
    prange_3.define(10, 20, 1, 1, 1)
    overlap = prange.overlap(prange_3)
    test_result("Test PRange::overlap() range out", overlap.to_string(), "Empty")
    
    prange_4 = PRange()
    prange_4.define(0, 3, 0, 1, 1)
    overlap = prange.overlap(prange_4)
    test_result("Test PRange::overlap() min out", overlap.to_string(), "1~3")
    
    prange_5 = PRange()
    prange_5.define(0, 3, 1, 0, 1)
    overlap = prange.overlap(prange_5)
    test_result("Test PRange::overlap() max out", overlap.to_string(), "0~2")
    
    prange_6 = PRange()
    prange_6.define(-1, 1, 1, 1, 1)
    overlap = prange.overlap(prange_6)
    test_result("Test PRange::overlap() low", overlap.to_string(), "0~1")
    
    prange_7 = PRange()
    prange_7.define(2, 4, 1, 1, 1)
    overlap = prange.overlap(prange_7)
    test_result("Test PRange::overlap() high", overlap.to_string(), "2~3")
    
    prange = PRange()
    prange.define(0, 4, 0, 1, 0)
    
    pconstant_1 = PConstant()
    pconstant_1.define(1)
    
    pconstant_2 = PConstant()
    pconstant_2.define(5)
    
    prange_8 = PRange()
    prange_8.define(2, 3, 1, 1, 1)
    
    por = POr()
    por.insert(pconstant_1)
    por.insert(pconstant_2)
    por.insert(prange_8)
    overlap = prange.overlap(por)
    test_result("Test PRange::overlap() or", overlap.to_string(), "1 | 2~3")
}

// POr

function test_por_overlap() {
    class POr scalar por_1, por_2
    class PRange scalar prange_1, prange_2
    class PConstant scalar pconstant_1, pconstant_2, pconstant_3
    class Pattern scalar overlap
    
    // POr 1 : (0 | 1 | 2~4)
    
    por_1 = POr()
    
    pconstant_1 = PConstant()
    pconstant_1.define(0)
    
    pconstant_2 = PConstant()
    pconstant_2.define(1)
    
    prange_1 = PRange()
    prange_1.define(2, 4, 1, 1, 1)
    
    por_1.insert(pconstant_1)
    por_1.insert(pconstant_2)
    por_1.insert(prange_1)
    
    // POr 2 : (10~20 | 3 | 1)
    
    por_2 = POr()
    
    prange_2 = PRange()
    prange_2.define(10, 20, 1, 1, 1)
    
    pconstant_3 = PConstant()
    pconstant_3.define(3)
    
    por_2.insert(prange_2)
    por_2.insert(pconstant_3)
    por_2.insert(pconstant_2)
    
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

// TODO

// PWild

// TODO

// PConstant

// TODO

// PRange

// TODO

// POr

// TODO

/////////////////////////////////////////////////////////////////// difference()

// PEmpty

// TODO

// PWild

// TODO

// PConstant

// TODO

// PRange

// TODO

// POr

// TODO

////////////////////////////////////////////////////////////////////// to_expr()

// PEmpty

// TODO

// PWild

// TODO

// PConstant

// TODO

// PRange

// TODO

// POr

// TODO

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

// test_pempty_includes()
// test_pwild_includes()
// test_pconstant_includes()
// test_prange_includes()
// test_por_includes()
// test_ptuple_includes()

// difference()

// test_pempty_difference()
// test_pwild_difference()
// test_pconstant_difference()
// test_prange_difference()
// test_por_difference()
// test_ptuple_difference()

// to_expr()

// test_pempty_to_expr()
// test_pwild_to_expr()
// test_pconstant_to_expr()
// test_prange_to_expr()
// test_por_to_expr()
// test_ptuple_to_expr()

end
