/*
Is it faster to compute the values with
- 'if condition'
- '* condition'

A constraint: the default value can have many conditions
- we either create a condition variable and use 0 as default
- skip this but check all the conditions

Result
- it's faster for integers but might be slower with too many default conditions
- it's a bit slower for double
- it's clearly slower for strings
- the command is less clear

=> We will stick with the normal method
*/

clear

local n_obs = 100000
local n_rep = 100

// Integer values

timer clear

quietly forvalues i = 1/`n_rep' {
    clear
    set obs `n_obs'
    gen int x = floor(runiform(0, 15)) + 1 // [1, 15]
    
    timer on 1
    gen int y_base = 4
    replace y_base = 1 if x == 1
    replace y_base = 2 if x == 2 | x == 3 | x == 4
    replace y_base = 3 if x >= 5 & x <= 9
    timer off 1

    timer on 2
    gen int cond = 1 * (x == 1) + 2 * (x == 2 | x == 3 | x == 4) + 3 * (x >= 5 & x <= 9)
    gen int y_multi = 4 * (cond == 0) + 1 * (cond == 1) + 2 * (cond == 2) + 3 * (cond == 3)
    drop cond
    timer off 2

    timer on 3
    gen int y_1L = 1 * (x == 1) + 2 * (x == 2 | x == 3 | x == 4) + 3 * (x >= 5 & x <= 9) + 4 * (x == 10 | x == 11 | x == 12 | x == 13 | x == 14 | x == 15)
    timer off 3
    
    assert y_base == y_multi
    assert y_base == y_1L
}

timer list

/*
   1:      1.81 /      100 =       0.0181
   2:      0.91 /      100 =       0.0091
   3:      0.54 /      100 =       0.0054
*/

// Double values

timer clear

quietly forvalues i = 1/`n_rep' {
    clear
    set obs `n_obs'
    gen int x = floor(runiform(0, 15)) + 1 // [1, 15]
    
    timer on 1
    gen double y_base = 4
    replace y_base = 1 if x == 1
    replace y_base = 2 if x == 2 | x == 3 | x == 4
    replace y_base = 3 if x >= 5 & x <= 9
    timer off 1

    timer on 2
    gen int cond = 1 * (x == 1) + 2 * (x == 2 | x == 3 | x == 4) + 3 * (x >= 5 & x <= 9)
    gen double y_multi = 4 * (cond == 0) + 1 * (cond == 1) + 2 * (cond == 2) + 3 * (cond == 3)
    drop cond
    timer off 2
    
    timer on 3
    gen double y_1L = 1 * (x == 1) + 2 * (x == 2 | x == 3 | x == 4) + 3 * (x >= 5 & x <= 9) + 4 * (x == 10 | x == 11 | x == 12 | x == 13 | x == 14 | x == 15)
    timer off 3
    
    assert y_base == y_multi
    assert y_base == y_1L
}

timer list

/*
   1:      0.42 /      100 =       0.0042
   2:      0.69 /      100 =       0.0069
   3:      0.46 /      100 =       0.0046
*/

// String values

timer clear

quietly forvalues i = 1/`n_rep' {
    clear
    set obs `n_obs'
    gen int x = floor(runiform(0, 15)) + 1 // [1, 15]
    
    timer on 1
    gen str y_base = "d"
    replace y_base = "a" if x == 1
    replace y_base = "b" if x == 2 | x == 3 | x == 4
    replace y_base = "c" if x >= 5 & x <= 9
    timer off 1

    timer on 2
    gen int cond = 1 * (x == 1) + 2 * (x == 2 | x == 3 | x == 4) + 3 * (x >= 5 & x <= 9)
    gen str y_multi = "d" * (cond == 0) + "a" * (cond == 1) + "b" * (cond == 2) + "c" * (cond == 3)
    drop cond
    timer off 2
    
    timer on 3
    gen str y_1L = "a" * (x == 1) + "b" * (x == 2 | x == 3 | x == 4) + "c" * (x >= 5 & x <= 9) + "d" * (x == 10 | x == 11 | x == 12 | x == 13 | x == 14 | x == 15)
    timer off 3
    
    assert y_base == y_multi
    assert y_base == y_1L
}

timer list

/*
   1:      1.71 /      100 =       0.0171
   2:      2.60 /      100 =       0.0260
   3:      2.96 /      100 =       0.0296
*/
