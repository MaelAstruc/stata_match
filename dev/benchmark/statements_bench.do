timer clear

/*
Generating empty string and replacing by default value has a performance cost
Generating a string is faster than replacing it without conditions
%21x format is equivalent to the base notation, there is no performance cost
*/

quietly forvalues i = 1/1000 {
    clear
    set obs 10000
    
    gen int x = runiform(0, 15) + 1 // [1, 15]
    
    timer on 1
    gen y_base = "d"
    replace y_base = "a" if x == 1
    replace y_base = "b" if x == 2 | x == 3 | x == 4
    replace y_base = "c" if x >= 5 & x <= 9
    timer off 1
    
    timer on 2
    gen y_all = ""
    replace y_all = "d"
    replace y_all = "a" if x == 1
    replace y_all = "b" if (x == 2) | (x == 3) | (x == 4)
    replace y_all = "c" if x >= 5 & x <= 9
    timer off 2
    
    gen y_rep = ""
    timer on 3
    replace y_rep = "d"
    replace y_rep = "a" if x == 1
    replace y_rep = "b" if (x == 2) | (x == 3) | (x == 4)
    replace y_rep = "c" if x >= 5 & x <= 9
    timer off 3
    
    timer on 4
    gen y_21x = "d"
    replace y_21x = "a" if x == +1.0000000000000X+000
    replace y_21x = "b" if (x == +1.0000000000000X+001) | (x == +1.8000000000000X+001) | (x == +1.0000000000000X+002)
    replace y_21x = "c" if x >= +1.4000000000000X+002 & x <= +1.2000000000000X+003
    timer off 4
}

timer list

/*
. timer list
   1:      1.64 /     1000 =       0.0016
   2:      2.07 /     1000 =       0.0021
   3:      1.80 /     1000 =       0.0018
   4:      1.65 /     1000 =       0.0017
*/
