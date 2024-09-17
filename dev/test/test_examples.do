**# Example 1

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "very low"  if rep78 == 1
replace var_1 = "low"       if rep78 == 2
replace var_1 = "mid"       if rep78 == 3
replace var_1 = "high"      if rep78 == 4
replace var_1 = "very high" if rep78 == 5
replace var_1 = "missing"   if rep78 == .

* With the pmatch command

pmatch var_2, variables(rep78) body( ///
    1 = "very low",                 ///
    2 = "low",                      ///
    3 = "mid",                      ///
    4 = "high",                     ///
    5 = "very high",                ///
    . = "missing",                  ///
)

test_variables, expected(var_1) result(var_2) test("End to end: Example 1")

**# Example 2: Range patterns

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "cheap"     if price >= 0    & price <  6000
replace var_1 = "normal"    if price >= 6000 & price <  9000
replace var_1 = "expensive" if price >= 9000 & price <= 16000
replace var_1 = "missing"   if price == .

* With the pmatch command

pmatch var_2, variables(price) body( ///
    min/!6000   = "cheap",          ///
    6000/!9000  = "normal",         ///
    9000/max    = "expensive",      ///
    .           = "missing",        ///
)

test_variables, expected(var_1) result(var_2) test("End to end: Example 2")

**# Example 3: Or patterns

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "low"     if rep78 == 1 | rep78 == 2
replace var_1 = "mid"     if rep78 == 3
replace var_1 = "high"    if rep78 == 4 | rep78 == 5
replace var_1 = "missing" if rep78 == .

* With the pmatch command

pmatch var_2, variables(rep78) body( ///
    1 | 2  = "low",                 ///
    3      = "mid",                 ///
    4 | 5  = "high",                ///
    .      = "missing",             ///
)

test_variables, expected(var_1) result(var_2) test("End to end: Example 3")

**# Example 4: Wildcard patterns

sysuse auto, clear

* Usual way

gen var_1 = "other"
replace var_1 = "very low" if rep78 == 1
replace var_1 = "low"      if rep78 == 2

* With the pmatch command

pmatch var_2, variables(rep78) body( ///
    1 = "very low",                 ///
    2 = "low",                      ///
    _ = "other",                    ///
)

test_variables, expected(var_1) result(var_2) test("End to end: Example 4")

**# Example 5: Tuple patterns

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "case 1"  if rep78 < 3 & price <  10000
replace var_1 = "case 2"  if rep78 < 3 & price >= 10000
replace var_1 = "case 3"  if rep78 >= 3
replace var_1 = "missing" if rep78 == . | price == .

* With the pmatch command

pmatch var_2, variables(rep78 price) body( ///
    (min/!3, min/!10000) = "case 1",      ///
    (min/!3, 10000/max)  = "case 2",      ///
    (3/max,  _)          = "case 3",      ///
    (., _) | (_, .)      = "missing",     ///
)

test_variables, expected(var_1) result(var_2) test("End to end: Example 5")

**# Example 6: Exhaustiveness

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "very low"  if rep78 == 1
replace var_1 = "low"       if rep78 == 2
replace var_1 = "mid"       if rep78 == 3
replace var_1 = "high"      if rep78 == 4
replace var_1 = "very high" if rep78 == 5

* With the pmatch command

pmatch var_2, variables(rep78) body( ///
    1 = "very low",                 ///
    2 = "low",                      ///
    3 = "mid",                      ///
    4 = "high",                     ///
    5 = "very high",                ///
)

// Warning : Missing values
//     .

test_variables, expected(var_1) result(var_2) test("End to end: Example 6")

**# Example 7: Overlaps

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "cheap"     if price >= 0    & price <= 6000
replace var_1 = "normal"    if price >= 6000 & price <= 9000
replace var_1 = "expensive" if price >= 9000 & price <= 16000
replace var_1 = "missing"   if price == .

* With the pmatch command

pmatch var_2, variables(price) body( ///
    min/6000  = "cheap",            ///
    6000/9000 = "normal",           ///
    9000/max  = "expensive",        ///
    .         = "missing",          ///
)

// Warning : Arm 2 has overlaps
//     Arm 1: 6000
// Warning : Arm 3 has overlaps
//     Arm 2: 9000

test_variables, expected(var_1) result(var_2) test("End to end: Example 7")

**# Example 8: Usefulness

sysuse auto, clear

* Usual way

gen var_1 = ""
replace var_1 = "cheap"     if price >= 0    & price <  6000
replace var_1 = "normal"    if price >= 6000 & price <= 9000
replace var_1 = "expensive" if price >= 9000 & price <= 16000
replace var_1 = "missing"   if price == .

* With the pmatch command

pmatch var_2, variables(price) body( ///
    min/!6000  = "cheap",            ///
    6000/!9000 = "normal",           ///
    9000/max  = "expensive",        ///
    min/max   = "oops",        ///
    .         = "missing",          ///
)

// Warning : Arm 4 is not useful
// Warning : Arm 4 has overlaps
//     Arm 1: 3291/5999
//     Arm 2: 6000/8999
//     Arm 3: 9000/15906


test_variables, expected(var_1) result(var_2) test("End to end: Example 8")

**# Example 9: Label values

drop _all

set obs 100
gen int color = runiform(1, 4)
label define color_label 1 "Red" 2 "Green" 3 "Blue"
label values color color_label 

pmatch color_hex, variables(color) body ( ///
    1     = "#FF0000" , ///
    2     = "#00FF00" , ///
   "Blue" = "#0000FF" , ///
)
