clear all

mata: mata set matastrict off

run "dev/benchmark/htable_draft.mata"

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

mata
function unique_integers_4(string scalar name) {
    real matrix x, _
    real scalar n
    
    levels = asarray_create("real", 1)
    
    st_view(x=., ., name)
    
    n = length(x)
    
    for (i = 1; i <= n; i++) {
        if (!asarray_contains(levels, x[i])) {
            asarray(levels, x[i], .)
        }
    }
    
    _ = asarray_keys(levels)
}
end

mata
function unique_integers_5(string scalar name) {
    real matrix x, _
    real scalar n, h, res
    struct Htable scalar levels

    st_view(x=., ., name)
    levels = htable_create(.)

    n = length(x)

    for (i = 1; i <= n; i++) {
        key = x[i]

        h = hash1(key, levels.capacity)

        if (levels.status[h]) {
            res = htable_newloc_dup(levels, key, h)
        }
        else {
            res = h
        }

        if (res) {
            (void) levels.N++
            levels.keys[res] = key
            levels.status[res] = 1

            if (levels.N * 2 >= levels.capacity) {
                htable_expand(levels)
            }
        }
    }

    _ = htable_keys(levels)
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

mata
function unique_reals_4(string scalar name) {
    real matrix x, _
    real scalar n
    
    levels = asarray_create("real", 1)
    
    st_view(x=., ., name)
    
    n = length(x)
    
    for (i = 1; i <= n; i++) {
        if (!asarray_contains(levels, x[i])) {
            asarray(levels, x[i], .)
        }
    }
    
    _ = asarray_keys(levels)
}
end

mata
function unique_reals_5(string scalar name) {
    real matrix x, _
    real scalar n, h, res
    struct Htable scalar levels

    st_view(x=., ., name)
    levels = htable_create(.)

    n = length(x)

    for (i = 1; i <= n; i++) {
        key = x[i]

        h = hash1(key, levels.capacity)

        if (levels.status[h]) {
            res = htable_newloc_dup(levels, key, h)
        }
        else {
            res = h
        }

        if (res) {
            (void) levels.N++
            levels.keys[res] = key
            levels.status[res] = 1

            if (levels.N * 2 >= levels.capacity) {
                htable_expand(levels)
            }
        }
    }

    _ = htable_keys(levels)
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

mata
function unique_strings_5(string scalar name) {
    string matrix x, _
    real scalar n
    
    levels = asarray_create("string", 1)
    
    st_sview(x="", ., name)
    
    n = length(x)
    
    for (i = 1; i <= n; i++) {
        if (!asarray_contains(levels, x[i])) {
            asarray(levels, x[i], .)
        }
    }
    
    _ = sort(asarray_keys(levels), 1)
}
end

mata
function unique_strings_6(string scalar name) {
    string matrix x, _
    real scalar n, h, res
    struct Htable scalar levels

    st_sview(x="", ., name)
    levels = htable_create("")

    n = length(x)

    for (i = 1; i <= n; i++) {
        key = x[i]

        h = hash1(key, levels.capacity)

        if (levels.status[h]) {
            res = htable_newloc_dup(levels, key, h)
        }
        else {
            res = h
        }

        if (res) {
            (void) levels.N++
            levels.keys[res] = key
            levels.status[res] = 1

            if (levels.N * 2 >= levels.capacity) {
                htable_expand(levels)
            }
        }
    }

    _ = htable_keys(levels)
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

/////////////////////////////////////////////////////////////////// MAIN PROGRAM

program bench_all
    syntax, n_obs(integer) n_levels(integer) n_rep(integer)

    // Create data
    drop _all

    set obs `n_obs'
    egen x_int = seq(), from(1) to(`n_levels')
    gen x_real = x_int + 0.1
    gen x_string = string(x_int)
    encode x_string, gen(x_encoded)

    // Randomize order of observations

    gen random = rnormal()
    sort random
    drop random

    // Time

    local 10p = `n_rep' / 10
    timer clear

    forvalues i = 1/`n_rep' {
        if (mod(`i', `10p') == 0) {
            dis "`i' / `n_rep'"
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
        
        timer on 14
        mata: unique_integers_4("x_int")
        timer off 14
        
        timer on 15
        mata: unique_integers_5("x_int")
        timer off 15
        
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
        
        timer on 24
        mata: unique_reals_4("x_real")
        timer off 24
        
        timer on 25
        mata: unique_reals_5("x_real")
        timer off 25
        
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
        
        timer on 35
        mata: unique_strings_5("x_string")
        timer off 35
        
        timer on 36
        mata: unique_strings_6("x_string")
        timer off 36
        
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

end

//////////////////////////////////////////////////////////////////// ESTIMATIONS

capture log close
log using "dev/logs/bench_levelsof.log", replace

bench_all, n_obs(1000)     n_levels(10)   n_rep(1000)
bench_all, n_obs(10000)    n_levels(10)   n_rep(100)
bench_all, n_obs(100000)   n_levels(10)   n_rep(10)
bench_all, n_obs(1000000)  n_levels(10)   n_rep(1)
bench_all, n_obs(10000000) n_levels(10)   n_rep(1)

bench_all, n_obs(1000)     n_levels(100)  n_rep(1000)
bench_all, n_obs(10000)    n_levels(100)  n_rep(100)
bench_all, n_obs(100000)   n_levels(100)  n_rep(10)
bench_all, n_obs(1000000)  n_levels(100)  n_rep(1)
bench_all, n_obs(10000000) n_levels(100)  n_rep(1)

bench_all, n_obs(1000)     n_levels(1000) n_rep(1000)
bench_all, n_obs(10000)    n_levels(1000) n_rep(100)
bench_all, n_obs(100000)   n_levels(1000) n_rep(10)
bench_all, n_obs(1000000)  n_levels(1000) n_rep(1)
bench_all, n_obs(10000000) n_levels(1000) n_rep(1)

log close

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
- A Hash Table is always slower even at N = 10M

For reals we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Directly use uniqrowssort() instead of uniqrows()
- Beyond we don't gain anything using levelsof core code
- With large data bases (>=1M), using Associative Arrays seems faster
- A simpler version of a Hash table with the right functions is even faster
- It outperforms the uniqrowssort() function for N >= 100K

For strings we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Beyond there is no clear gains
- The Hash Table version is faster for strings too if N >= 100K
- Encode variables and treat it as an integer

For encoded strings, we have the same optimizations as integers
*/

