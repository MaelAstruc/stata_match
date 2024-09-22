/////////////////////////////////////////////////////////// One variable integer

// Use drop _all instead of clear to test with different versions
// If clear <= 9, it also clears mata and we cannot run the command
drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 4 & x1 <= 5

pmatch y2, v(x1) b( ///
    1      = "a",  ///
    2 | 3  = "b",  ///
    4/5    = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one integer")

///////////////////////////////////////////////// One variable integer with gaps

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]
replace x1 = x1 * 2                // {2, 4, 6, 8, 10, 12}

gen y1 = ""
replace y1 = "a" if x1 == 2
replace y1 = "b" if x1 == 4 | x1 == 6
replace y1 = "c" if x1 >= 8 & x1 <= 12

pmatch y2, v(x1) b( ///
    2      = "a",  ///
    4 | 6  = "b",  ///
    8/12   = "c",  ///
)

test_variables, expected(y1) result(y2) test("End to end: one integer with gaps")

///////////////////////////////////////////////////////////// One variable float

drop _all

set obs 100

gen float x1 = runiform(1, 6) // [1, 6[
replace x1 = 1 in 1
replace x1 = 2 in 2
replace x1 = 3 in 3

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 4 & x1 <= 5

pmatch y2, v(x1) b( ///
    1      = "a",  ///
    2 | 3  = "b",  ///
    4/5    = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one float")

/////////////////////////////////////////////////////// Float precision constant

drop _all

set obs 100

gen x1 = .
replace x1 = 1.0x-0  in 1
replace x1 = 1.0x-1  in 2
replace x1 = 1.0x-2  in 3
replace x1 = 1.0x-3  in 4
replace x1 = 1.0x-4  in 5
replace x1 = 1.0x-5  in 6
replace x1 = 1.0x-6  in 7
replace x1 = 1.0x-7  in 8
replace x1 = 1.0x-8  in 9
replace x1 = 1.0x-9  in 10
replace x1 = 1.0x-a  in 11
replace x1 = 1.0x-b  in 12
replace x1 = 1.0x-c  in 13
replace x1 = 1.0x-d  in 14
replace x1 = 1.0x-e  in 15
replace x1 = 1.0x-f  in 16
replace x1 = 1.0x-10 in 17
replace x1 = 1.0x-11 in 18
replace x1 = 1.0x-12 in 19
replace x1 = 1.0x-13 in 20
replace x1 = 1.0x-14 in 21
replace x1 = 1.0x-15 in 22
replace x1 = 1.0x-16 in 23
replace x1 = 1.0x-17 in 24
replace x1 = 1.0x-18 in 25
replace x1 = 1.0x-19 in 26
replace x1 = 1.0x-1a in 27
replace x1 = 1.0x-1b in 28
replace x1 = 1.0x-1c in 29
replace x1 = 1.0x-1d in 30
replace x1 = 1.0x-1e in 31
replace x1 = 1.0x-1f in 32

gen y1 = ""
replace y1 = "0"  if x1 == 1.0x-0 
replace y1 = "1"  if x1 == 1.0x-1 
replace y1 = "2"  if x1 == 1.0x-2 
replace y1 = "3"  if x1 == 1.0x-3 
replace y1 = "4"  if x1 == 1.0x-4 
replace y1 = "5"  if x1 == 1.0x-5 
replace y1 = "6"  if x1 == 1.0x-6 
replace y1 = "7"  if x1 == 1.0x-7 
replace y1 = "8"  if x1 == 1.0x-8 
replace y1 = "9"  if x1 == 1.0x-9 
replace y1 = "a"  if x1 == 1.0x-a 
replace y1 = "b"  if x1 == 1.0x-b 
replace y1 = "c"  if x1 == 1.0x-c 
replace y1 = "d"  if x1 == 1.0x-d 
replace y1 = "e"  if x1 == 1.0x-e 
replace y1 = "f"  if x1 == 1.0x-f 
replace y1 = "10" if x1 == 1.0x-10
replace y1 = "11" if x1 == 1.0x-11
replace y1 = "12" if x1 == 1.0x-12
replace y1 = "13" if x1 == 1.0x-13
replace y1 = "14" if x1 == 1.0x-14
replace y1 = "15" if x1 == 1.0x-15
replace y1 = "16" if x1 == 1.0x-16
replace y1 = "17" if x1 == 1.0x-17
replace y1 = "18" if x1 == 1.0x-18
replace y1 = "19" if x1 == 1.0x-19
replace y1 = "1a" if x1 == 1.0x-1a
replace y1 = "1b" if x1 == 1.0x-1b
replace y1 = "1c" if x1 == 1.0x-1c
replace y1 = "1d" if x1 == 1.0x-1d
replace y1 = "1e" if x1 == 1.0x-1e
replace y1 = "1f" if x1 == 1.0x-1f

pmatch y2, v(x1) b(   ///
    1.0x-0  = "0" , ///
    1.0x-1  = "1" , ///
    1.0x-2  = "2" , ///
    1.0x-3  = "3" , ///
    1.0x-4  = "4" , ///
    1.0x-5  = "5" , ///
    1.0x-6  = "6" , ///
    1.0x-7  = "7" , ///
    1.0x-8  = "8" , ///
    1.0x-9  = "9" , ///
    1.0x-a  = "a" , ///
    1.0x-b  = "b" , ///
    1.0x-c  = "c" , ///
    1.0x-d  = "d" , ///
    1.0x-e  = "e" , ///
    1.0x-f  = "f" , ///
    1.0x-10 = "10", ///
    1.0x-11 = "11", ///
    1.0x-12 = "12", ///
    1.0x-13 = "13", ///
    1.0x-14 = "14", ///
    1.0x-15 = "15", ///
    1.0x-16 = "16", ///
    1.0x-17 = "17", ///
    1.0x-18 = "18", ///
    1.0x-19 = "19", ///
    1.0x-1a = "1a", ///
    1.0x-1b = "1b", ///
    1.0x-1c = "1c", ///
    1.0x-1d = "1d", ///
    1.0x-1e = "1e", ///
    1.0x-1f = "1f", ///
    _       = ""    ///
)

assert y1 == y2

test_variables, expected(y1) result(y2) test("End to end: float precision constant")

//////////////////////////////////////////////////////////// One variable string

drop _all

set obs 100

gen str x1 = string(floor(runiform(1, 5)))

gen y1 = "c"
replace y1 = "a" if x1 == "1"
replace y1 = "b" if x1 == "2" | x1 == "3"

pmatch y2, v(x1) b( ///
    "1"        = "a",  ///
    "2" | "3"  = "b",  ///
    _          = "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one string")

////////////////////////////////////////////////////////////// One variable strL

drop _all

set obs 100

gen strL x1 = string(floor(runiform(1, 5)))

gen y1 = "c"
replace y1 = "a" if x1 == "1"
replace y1 = "b" if x1 == "2" | x1 == "3"

pmatch y2, v(x1) b( ///
    "1"        = "a",  ///
    "2" | "3"  = "b",  ///
    _          = "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one strL")

////////////////////////////////////////////////////////////////// Two variables

drop _all

set obs 100

gen int x1 = floor(runiform(1, 4))
gen str x2 = string(floor(runiform(1, 4)))

gen y1 = "f"
replace y1 = "a" if x1 == 1           & x2 == "1"
replace y1 = "b" if x1 == 1           & (x2 == "2" | x2 == "3")
replace y1 = "c" if x1 >= 2 & x1 <= 3 & x2 == "1"
replace y1 = "d" if x1 >= 2 & x1 <  3 & x2 == "2"
replace y1 = "e" if x1 >  2 & x1 <= 3 & x2 == "2"

pmatch y2, v(x1 x2) b( ///
    (1,     "1")       = "a",  ///
    (1,     "2" | "3") = "b",  ///
    (2/3,   "1")       = "c",  ///
    (2/!3,  "2")       = "d",  ///
    (2!/3,  "2")       = "e",  ///
    (_, _)             = "f"   ///
)

test_variables, expected(y1) result(y2) test("End to end: two variables")

/////////////////////////////////////////////////////////// Integer min constant

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = "c"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3

pmatch y2, v(x1) b( ///
    min    = "a",  ///
    2 | 3  = "b",  ///
    _      = "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: 'min' as constant")

/////////////////////////////////////////////////////////// Integer max constant

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = ""
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 == 4

pmatch y2, v(x1) b( ///
    1      = "a",  ///
    2 | 3  = "b",  ///
    max    = "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: 'max' as constant")

////////////////////////////////////////////////////////////// Integer min range

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = "c"
replace y1 = "a" if x1 == 1 | x1 == 2
replace y1 = "b" if x1 == 3

pmatch y2, v(x1) b( ///
    min/2  = "a",  ///
    3      = "b",  ///
    _      = "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: 'min' in range")

////////////////////////////////////////////////////////////// Integer max range

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = ""
replace y1 = "a" if x1 == 1 | x1 == 2
replace y1 = "b" if x1 >= 3 & x1 <= 4

pmatch y2, v(x1) b( ///
    1 | 2   = "a",  ///
    3/max   = "b"   ///
)

test_variables, expected(y1) result(y2) test("End to end: 'max' in range")

///////////////////////////////////////////////////////////////// Exhaustiveness

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = ""
replace y1 = "a" if x1 == 1 | x1 == 2
replace y1 = "b" if x1 == 3

pmatch y2, v(x1) b( ///
    1 | 2   = "a",  ///
    3   = "b"   ///
)

test_variables, expected(y1) result(y2) test("End to end: non-exhaustive")

/////////////////////////////////////////////////////////////////////// Overlaps

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = ""
replace y1 = "a" if x1 == 1 | x1 == 2
replace y1 = "b" if x1 > 2

// pmatch y2, v(x1) b( 1 | 2 = "a", 2/max = "b")
pmatch y2, v(x1) b( ///
    1 | 2   = "a",  ///
    2/max   = "b"   ///
)

// We expect 2 to be "a", not "b" due to the overlap
test_variables, expected(y1) result(y2) test("End to end: overlaps")

///////////////////////////////////////////////////////////////////// Non-useful

drop _all

set obs 100

gen int x1 = floor(runiform(1, 5))

gen y1 = "a"

pmatch y2, v(x1) b( ///
    _   = "a",  ///
    1   = "b"   ///
)

test_variables, expected(y1) result(y2) test("End to end: non-useful")

/////////////////////////////////////////////////////////// Variable to generate

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 4 & x1 <= 5

pmatch y2, v(x1) b( ///
    1      = "a",  ///
    2 | 3  = "b",  ///
    4/5    = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: gen new var")

///////////////////////////////////////////////////////////// Without checks int

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 5 & x1 <= 6

pmatch y2, nocheck v(x1) b( ///
    min    = "a",  ///
    2 | 3  = "b",  ///
    5/max  = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: without checks")

/////////////////////////////////////////////////////////// Without checks float

drop _all

set obs 100

gen float x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 5 & x1 <= 6

pmatch y2, nocheck v(x1) b( ///
    min    = "a",  ///
    2 | 3  = "b",  ///
    5/max  = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: without checks")

////////////////////////////////////////////////////////// Without checks string

drop _all

set obs 100

gen str x1 = string(floor(runiform(1, 7))) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == "1"
replace y1 = "b" if x1 == "2" | x1 == "3"
replace y1 = "c" if x1 == "5" | x1 == "6"

pmatch y2, nocheck v(x1) b( ///
    "1"        = "a",  ///
    "2" | "3"  = "b",  ///
    "5" | "6"  = "c",  ///
    _          = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: without checks")

//////////////////////////////////////////////////////////// Match labeled value

drop _all

set obs 100

gen int x1 = runiform(1, 6) // [1, 5]
tostring x1, replace
replace  x1 = "V" if x1 == "1"
replace  x1 = "W" if x1 == "2"
replace  x1 = "X" if x1 == "3"
replace  x1 = "Y" if x1 == "4"
replace  x1 = "Z" if x1 == "5"
encode x1, gen(x2)

gen y1 = "d"
replace y1 = "a" if x2 == 1
replace y1 = "b" if x2 == 2 | x2 == 3
replace y1 = "c" if x2 == 4

pmatch y2, v(x2) b( ///
    1        = "a",  ///
    "W" | 3  = "b",  ///
    "Y"      = "c",  ///
    _        = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one integer")

/////////////////////////////////////////////////////////////// Check '|pattern'

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 == 4 | x1 == 5

pmatch y2, v(x1) b( ///
    1      = "a",  ///
    2 | 3  = "b",  ///
    4 |5   = "c",  ///
    _      = "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: check |pattern")

/////////////////////////////////////////////////////////// Check data type byte

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen byte y1 = 4
replace y1 = 1 if x1 == 1
replace y1 = 2 if x1 == 2 | x1 == 3
replace y1 = 3 if x1 >= 4 & x1 <= 5

pmatch byte y2, v(x1) b( ///
    1      = 1,          ///
    2 | 3  = 2,          ///
    4/5    = 3,          ///
    _      = 4           ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype byte")

//////////////////////////////////////////////////////// Check data type integer

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen int y1 = 4
replace y1 = 1 if x1 == 1
replace y1 = 2 if x1 == 2 | x1 == 3
replace y1 = 3 if x1 >= 4 & x1 <= 5

pmatch int y2, v(x1) b( ///
    1      = 1,         ///
    2 | 3  = 2,         ///
    4/5    = 3,         ///
    _      = 4          ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype int")

/////////////////////////////////////////////////////////// Check data type long

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen long y1 = 4
replace y1 = 1 if x1 == 1
replace y1 = 2 if x1 == 2 | x1 == 3
replace y1 = 3 if x1 >= 4 & x1 <= 5

pmatch long y2, v(x1) b( ///
    1      = 1,         ///
    2 | 3  = 2,         ///
    4/5    = 3,         ///
    _      = 4          ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype long")

////////////////////////////////////////////////////////// Check data type float

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen float y1 = 4.1
replace y1 = 1 if x1 == 1
replace y1 = 2 if x1 == 2 | x1 == 3
replace y1 = 3 if x1 >= 4 & x1 <= 5

pmatch float y2, v(x1) b( ///
    1      = 1,           ///
    2 | 3  = 2,           ///
    4/5    = 3,           ///
    _      = 4.1          ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype float")

///////////////////////////////////////////////////////// Check data type double

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen double y1 = 4
replace y1 = 1 if x1 == 1
replace y1 = 2 if x1 == 2 | x1 == 3
replace y1 = 3 if x1 >= 4 & x1 <= 5

pmatch double y2, v(x1) b( ///
    1      = 1,            ///
    2 | 3  = 2,            ///
    4/5    = 3,            ///
    _      = 4             ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype double")

/////////////////////////////////////////////////////////// Check data type str#

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen str1 y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch str1 y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype str1")

/////////////////////////////////////////////////////////// Check data type strL

drop _all

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: dtype str1")

/////////////////////////////////////////////////// Check few levels int and obs

drop _all

set obs 100

gen int x1 = floor(runiform(1, 11)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: int 10 levels, 100 obs")

////////////////////////////////////////////// Check few levels int and many obs

drop _all

set obs 10000

gen int x1 = floor(runiform(1, 11)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: int 10 levels, 10K obs")

////////////////////////////////////////////////////////// Check many levels int

drop _all

set obs 10000

gen int x1 = floor(runiform(1, 1001)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: int 1000 levels")

///////////////////////////////////////////////// Check few levels float and obs

drop _all

set obs 10000

gen float x1 = floor(runiform(1, 11)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: float 10 levels, 10K obs")

//////////////////////////////////////////// Check few levels float and many obs

drop _all

set obs 10000

gen float x1 = floor(runiform(1, 11)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: float 10 levels, 10K obs")

//////////////////////////////////////////////////////// Check many levels float

drop _all

set obs 10000

gen float x1 = floor(runiform(1, 1001)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: float 1000 levels, 10K obs")

//////////////////////////////////////////////// Check many levels float and obs

drop _all

set obs 1000000

gen float x1 = floor(runiform(1, 1001)) // [1, 6]

gen strL y1 = "4"
replace y1 = "1" if x1 == 1
replace y1 = "2" if x1 == 2 | x1 == 3
replace y1 = "3" if x1 >= 4 & x1 <= 5

pmatch strL y2, v(x1) b( ///
    1      = "1",        ///
    2 | 3  = "2",        ///
    4/5    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: float 1000 levels, 1M obs")

/////////////////////////////////////////////////////////// Check string few obs

drop _all

set obs 100

gen str2 x1 = string(floor(runiform(1, 11))) // [1, 10]

gen strL y1 = "4"
replace y1 = "1" if x1 == "1"
replace y1 = "2" if x1 == "2"
replace y1 = "3" if x1 == "3"

pmatch strL y2, v(x1) b( ///
    "1"    = "1",        ///
    "2"    = "2",        ///
    "3"    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: string 100 obs")

//////////////////////////////////////////////// Check many levels float and obs

drop _all

set obs 1000000

gen str2 x1 = string(floor(runiform(1, 11))) // [1, 10]

gen strL y1 = "4"
replace y1 = "1" if x1 == "1"
replace y1 = "2" if x1 == "2"
replace y1 = "3" if x1 == "3"

pmatch strL y2, v(x1) b( ///
    "1"    = "1",        ///
    "2"    = "2",        ///
    "3"    = "3",        ///
    _      = "4"         ///
)

test_variables, expected(y1) result(y2) test("End to end: string 1M levels")
