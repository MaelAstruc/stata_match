/////////////////////////////////////////////////////////// One variable integer

clear

set obs 100

gen int x1 = floor(runiform(1, 7)) // [1, 6]

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 4 & x1 <= 5

gen y2 = ""

match y2, v(x1) b( ///
    1      => "a",  ///
    2 | 3  => "b",  ///
    4~5    => "c",  ///
    _      => "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one integer")

///////////////////////////////////////////////////////////// One variable float

clear

set obs 100

gen float x1 = runiform(1, 6) // [1, 6[
replace x1 = 1 in 1
replace x1 = 2 in 2
replace x1 = 3 in 3

gen y1 = "d"
replace y1 = "a" if x1 == 1
replace y1 = "b" if x1 == 2 | x1 == 3
replace y1 = "c" if x1 >= 4 & x1 <= 5

gen y2 = ""

match y2, v(x1) b( ///
    1      => "a",  ///
    2 | 3  => "b",  ///
    4~5    => "c",  ///
    _      => "d"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one float")

* There might be an issue due to rounding error between stata and mata
* I might not happen during all tests due to random generation of input

/////////////////////////////////////////////////////////// One variable integer

clear

set obs 100

gen str x1 = string(floor(runiform(1, 5)))

gen y1 = "c"
replace y1 = "a" if x1 == "1"
replace y1 = "b" if x1 == "2" | x1 == "3"

gen y2 = ""

match y2, v(x1) b( ///
    "1"        => "a",  ///
    "2" | "3"  => "b",  ///
    _          => "c"   ///
)

test_variables, expected(y1) result(y2) test("End to end: one string")

////////////////////////////////////////////////////////////////// Two variables

clear

set obs 100

gen int x1 = floor(runiform(1, 4))
gen str x2 = string(floor(runiform(1, 4)))

gen y1 = "f"
replace y1 = "a" if x1 == 1           & x2 == "1"
replace y1 = "b" if x1 == 1           & (x2 == "2" | x2 == "3")
replace y1 = "c" if x1 >= 2 & x1 <= 3 & x2 == "1"
replace y1 = "d" if x1 >= 2 & x1 <  3 & x2 == "2"
replace y1 = "e" if x1 >  2 & x1 <= 3 & x2 == "2"

gen y2 = ""

match y2, v(x1, x2) b( ///
    (1,     "1")       => "a",  ///
    (1,     "2" | "3") => "b",  ///
    (2~3,   "1")       => "c",  ///
    (2~!3,  "2")       => "d",  ///
    (2!~3,  "2")       => "e",  ///
    (_, _)             => "f"   ///
)

test_variables, expected(y1) result(y2) test("End to end: two variables")
