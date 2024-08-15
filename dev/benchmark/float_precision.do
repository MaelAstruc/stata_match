/*
Stata and Mata have a limit to float precision because the underlying values are
binary. In this package I parse the users values, convert them to reals in Mata,
and use them latter in commands as strings. For this I need to determine the
correct formating when coverting the reals to strings.

This do-file explores
    - the different limits of floats
    - the impact of the number of decimals in %g format
    - a bug (I think) in strofreal()
    - a solution with %21x format
*/

mata

10^-307 == 0              // false
10^-308 == 0              // true
// -> the smallest possible value is 10^-308

1.0   + 10^-307 == 1.0    // false
1.0   + 10^-15  == 1.0    // false
1.0   + 10^-16  == 1.0    // true
0.1   + 10^-17  == 0.1    // false
0.1   + 10^-18  == 0.1    // true
0.01  + 10^-17  == 0.01   // false
0.01  + 10^-18  == 0.01   // true
// -> mata seems to ignore any decimal after the 15th in scientific notation

strtoreal(strofreal(10^-307, "%16.0g")) == 10^-307    // false
strtoreal(strofreal(10^-307, "%22.0g")) == 10^-307    // false
strtoreal(strofreal(10^-307, "%23.0g")) == 10^-307    // true
// -> we still need to keep 21 decimals if we keep this conversion

strofreal(10^-307, "%22.0g")         // 9.99999999999977e-308
strofreal(10^-307, "%23.0g")         // 10^-307
// -> other values might require more, but I don't know the maximum

for (i = -308; i <= 308; i++) {
    x_num = 10^i
    x_str = strofreal(x_num, "%24.0g")
    x_back = strtoreal(x_str)
    are_same = (x_back == x_num)
    if (are_same == 0) {
        i
        x_num
        x_str
        x_back
        x_num - x_back
    }
}

// Handles most cases
// But there is still a difference for 10^19 and 10^20 and no width seem to correct it.
// - this does not happen on every run
// - other values do not work anymore with larger widths such as 10^21, 10^22, 10^23

strofreal(10^19, "%23.0g")    //    1.0000000000000000e+19
strofreal(10^19, "%24.0g")    //    1000000000000000000.\x17
strofreal(10^19, "%25.0g")    //    1000000000000000000.\x17
strofreal(10^19, "%26.0g")    //    1000000000000000000.\x17

sprintf("%s", strofreal(10^19, "%23.0g"))    //    1.0000000000000000e+19
sprintf("%s", strofreal(10^19, "%24.0g"))    //    1.00000000000000000e+19
sprintf("%s", strofreal(10^19, "%25.0g"))    //    1.000000000000000000e+19
sprintf("%s", strofreal(10^19, "%26.0g"))    //    1000000000000000000.8\x0c\x1c

// No idea what happens

// Ask on Statalist
// Nice response from Danial Klein
// https://www.statalist.org/forums/forum/general-stata-discussion/mata/1760958-bug-with-strofreal
// https://blog.stata.com/2011/02/10/how-to-read-the-percent-21x-format-part-2/

// %21x is the right format for perfect accuracy in my case

for (i = -308; i <= 308; i++) {
    x_num = 10^i
    x_str = strofreal(x_num, "%21x")
    x_back = strtoreal(x_str)
    are_same = (x_back == x_num)
    if (are_same == 0) {
        i
        x_num
        x_str
        x_back
        x_num - x_back
    }
}

end