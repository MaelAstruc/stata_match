clear all

mata: mata set matastrict off

/////////////////////////////////////////////////////////////////////// Integers

mata
function unique_integers_1(string scalar name) {
    real matrix x, _
    
    st_view(x=., ., name)
    _ = uniqrows(x)
}
end

mata
function unique_integers_2(string scalar name) {
    real matrix x, _
    
    st_view(x=., ., name)
    _ = uniqrowsofinteger(x)
}
end

mata
function unique_integers_3(string scalar name) {
    real matrix x, _
    real vector n, r, m, mvalue, minmax
    real scalar i, value, offset
    
    st_view(x=., ., name)
    
    // from uniqrowsofinteger()

    if (rows(x) == 0) {
        return(J(0, 1, .))
    }

    minmax = minmax(x)
    n = minmax[2] - minmax[1] + 1
    r = J( n, 1, 0)
    m = J(27, 1, 0)
    
    mvalue = (.\.a\.b\.c\.d\.e\.f\.g\.h\.i\.j\.k\.l\.m\.n\.o\.p\.q\.r\.s\.t\.u\.v\.w\.x\.y\.z)

    offset = minmax[1] - 1

    for (i = 1; i <= rows(x); ++i) {
        value = x[i]
        if (value < .) {
                r[value - offset] = 1
        }
        else {
                m = m :| (mvalue :== value)
        }
    }
    
    _ = select((minmax[1]::minmax[2] \ mvalue), r \ m)
}
end

///////////////////////////////////////////////////////////////////////// Floats

mata
function unique_reals_1(string scalar name) {
    real matrix x, _
    st_view(x=., ., name)
    _ = uniqrows(x)
}
end

mata
function unique_reals_2(string scalar name) {
    real matrix x, _
    st_view(x=., ., name)
    _ = uniqrowssort(x)
}
end

mata
function unique_reals_3(string scalar name) {
    real matrix x, _
    real vector xsort, sel
    real scalar n
    
    st_view(x=., ., name)
    
    if (rows(x) == 0) {
        return(J(0, cols(x), missingof(x)))
    }

    if (cols(x) == 0) {
        return(J(1, 0, missingof(x)))
    }

    n = rows(x)
    
    if (n == 1) {
        return(x)
    }

    xsort = sort(x, 1)
    
    sel = rowsum(J(1, cols(x), 1) \ (xsort[|2,.\.,.|] :!= xsort[|1,.\(n-1),.|]))
    
    _ = select(xsort, sel)
}
end

//////////////////////////////////////////////////////////////////////// Strings

mata
function unique_strings_1(string scalar name) {
    string matrix x, _
    
    st_sview(x="", ., name)
    _ = uniqrows(x)
}
end

mata
function unique_strings_2(string scalar name) {
    string matrix x, _
    
    st_sview(x="", ., name)
    _ = uniqrowssort(x)
}
end

mata
function unique_strings_3(string scalar name) {
    string matrix x, _
    string vector xsort
    real vector sel
    real scalar n
    
    st_sview(x="", ., name)
    
    if (rows(x) == 0) {
        return(J(0, cols(x), missingof(x)))
    }

    if (cols(x) == 0) {
        return(J(1, 0, missingof(x)))
    }

    n = rows(x)
    
    if (n == 1) {
        return(x)
    }

    xsort = sort(x, 1)
    
    sel = rowsum(J(1, cols(x), 1) \ (xsort[|2,.\.,.|] :!= xsort[|1,.\(n-1),.|]))
    
    _ = select(xsort, sel)
}
end

mata
function unique_strings_4(string scalar name) {
    string matrix x, _
    string vector xsort
    real vector sel
    
    st_sview(x="", ., name)
    
    xsort = sort(x, 1)
    
    sel = 1 \ (xsort[|2,.\.,.|] :!= xsort[|1,.\(rows(x)-1),.|])
    
    _ = select(xsort, sel)
}
end

//////////////////////////////////////////////////////////////////////// Encoded

mata
function unique_encoded_1(string scalar name) {
    real matrix x, _
    
    st_view(x=., ., name)
    _ = uniqrows(x)
}
end

mata
function unique_encoded_2(string scalar name) {
    real matrix x, _
    
    st_view(x=., ., name)
    _ = uniqrowsofinteger(x)
}
end

//////////////////////////////////////////////////////////////////// ESTIMATIONS

// Set-up

local N_OBS = 1000
local N_LEVELS = 100
local N_REP = 1000

// Create data

set obs `N_OBS'
egen x_int = seq(), from(1) to(`N_LEVELS')
gen x_real = x_int + 0.1
gen x_string = string(x_int)
encode x_string, gen(x_encoded)

// Randomize order of observations

gen random = rnormal()
sort random
drop random

// Time

timer clear

forvalues i = 1/`N_REP' {
    if (mod(`i', 100) == 0) {
        dis "`i' / `N_REP'"
    }
    
    timer on 10
    quietly levelsof x_int, missing
    timer off 10
    
    timer on 11
    mata: unique_integers_1("x_int")
    timer off 11
    
    timer on 12
    mata: unique_integers_2("x_int")
    timer off 12
    
    timer on 13
    mata: unique_integers_3("x_int")
    timer off 13
    
    timer on 20
    quietly levelsof x_real, missing
    timer off 20
    
    timer on 21
    mata: unique_reals_1("x_real")
    timer off 21
    
    timer on 22
    mata: unique_reals_2("x_real")
    timer off 22
    
    timer on 23
    mata: unique_reals_3("x_real")
    timer off 23
    
    timer on 30
    quietly levelsof x_string, missing
    timer off 30
    
    timer on 31
    mata: unique_strings_1("x_string")
    timer off 31
    
    timer on 32
    mata: unique_strings_2("x_string")
    timer off 32
    
    timer on 33
    mata: unique_strings_3("x_string")
    timer off 33
    
    timer on 34
    mata: unique_strings_4("x_string")
    timer off 34
    
    timer on 40
    quietly levelsof x_encoded, missing
    timer off 40
    
    timer on 41
    mata: unique_encoded_1("x_encoded")
    timer off 41
    
    timer on 42
    mata: unique_encoded_2("x_encoded")
    timer off 42
}

timer list

/*
N = 10^3
  10:      0.38 /     1000 =       0.0004
  11:      0.27 /     1000 =       0.0003
  12:      0.20 /     1000 =       0.0002
  13:      0.20 /     1000 =       0.0002
  20:      1.20 /     1000 =       0.0012
  21:      0.29 /     1000 =       0.0003
  22:      0.31 /     1000 =       0.0003
  23:      0.28 /     1000 =       0.0003
  30:      0.73 /     1000 =       0.0007
  31:      0.55 /     1000 =       0.0006
  32:      0.57 /     1000 =       0.0006
  33:      0.55 /     1000 =       0.0006
  34:      0.55 /     1000 =       0.0006
  40:      0.42 /     1000 =       0.0004
  41:      0.28 /     1000 =       0.0003
  42:      0.20 /     1000 =       0.0002
*/

/*
N = 10^4
  10:      2.19 /     1000 =       0.0022
  11:      2.94 /     1000 =       0.0029
  12:      1.38 /     1000 =       0.0014
  13:      1.33 /     1000 =       0.0013
  20:      4.78 /     1000 =       0.0048
  21:      3.21 /     1000 =       0.0032
  22:      3.17 /     1000 =       0.0032
  23:      3.17 /     1000 =       0.0032
  30:      6.04 /     1000 =       0.0060
  31:      5.39 /     1000 =       0.0054
  32:      5.38 /     1000 =       0.0054
  33:      5.31 /     1000 =       0.0053
  34:      5.27 /     1000 =       0.0053
  40:      2.30 /     1000 =       0.0023
  41:      2.91 /     1000 =       0.0029
  42:      1.40 /     1000 =       0.0014
*/

/*
N = 10^5
  10:     18.04 /     1000 =       0.0180
  11:     15.32 /     1000 =       0.0153
  12:     13.77 /     1000 =       0.0138
  13:     13.92 /     1000 =       0.0139
  20:     69.50 /     1000 =       0.0695
  21:     56.00 /     1000 =       0.0560
  22:     55.15 /     1000 =       0.0552
  23:     55.16 /     1000 =       0.0552
  30:    101.20 /     1000 =       0.1012
  31:     88.72 /     1000 =       0.0887
  32:     88.65 /     1000 =       0.0887
  33:     88.31 /     1000 =       0.0883
  34:     88.30 /     1000 =       0.0883
  40:     18.25 /     1000 =       0.0183
  41:     15.28 /     1000 =       0.0153
  42:     13.77 /     1000 =       0.0138
*/

/*
Conclusion :
- It's fast with integers
- It's slower with float
- It's even slower with strings
- The gap grows with the number of observations
- Encoding strings makes it as performent as integers

For integers we can improve it
- Skip the Stata layer of levelsof and call the mata functions
! Don't call uniqrows(), levelsof goes directly to uniqrowsofinteger()
- Beyond we don't gain anything

For reals we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Directly use uniqrowssort() instead of uniqrows()
- Beyond we don't gain anything

For strings we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Beyond there is no clear gains
- Encode variables and treat it as an integer

For encoded strings, we have the same optimizations as integers
*/

