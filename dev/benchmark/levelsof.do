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

mata
function unique_integers_6(string scalar name) {
    string scalar matname
    real matrix _
    
    matname = st_tempname()
    
    stata("quietly tab " + name + ", missing matrow(" + matname + ")")
    _ = st_matrix(matname)
}
end

/*
Need to double check the values
    - N_MATA_SORT: Optimal number of observations where sampling overhead is acceptable
    - N_SAMPLE:    Optimal sampling size
    - N_USE_TAB:   Optimal estimated number of levels
    - N_MATA_HASH: Optimal size for hash
N_MATA_HASH is to chose between algorithms, when the hash becomes faster.
    - For floats, we use it only when tab is not chosen and the sample is large enough
        - compare hash and uniqrows()
        - try different N from 10K to 1M
        - verify with different number of levels above 100 (100 to 10K)
        - verify with different versions (8 to max)
        - verify with different number of processors
    - For strings, we use it when the sample is large enough
        - compare hash and uniqrows()
        - try different N from 10K to 1M
        - verify with different number of levels above 100 (100 to 10K)
        - verify with different versions (8 to max)
        - verify with different number of processors
N_USE_TAB is to chose between algorithm, when tab is faster
    - for integers we compare tab and uniqrowsofinteger()
        - try different number of levels between 10 and 1K
        - verify with different N from 1K to 100K
        - verify with different versions (8 to max)
        - verify with different number of processors
    - for floats we compare tab and uniqrows()
        - try different number of levels between 10 and 1K
        - verify with different N from 1K to 100K
        - verify with different versions (8 to max)
        - verify with different number of processors
N_SAMPLE is to estimate the number of levels based on a sample
    - we prioritise accuracy of the function should_tab()
        - we want to correctly assess if the number of levels is too large
        - it's not important if it says 1 instead of 90
        - we just want it to say correctly if it's above or below the cutoff
        - but measure the overhead
    - it's the same for integerer and floats
        - test different sample sizes (100 to 1K)
        - test with different number of levels for 10 to 1K
        - test with different distributions (uniform, power)
Compare
    - tab 
    - tab with should_tab() and uniqrows*()
        - for int and float
        - for various sample size below 10K (we know that tab is faster and the overhead is fixed)
        - for different number of levels
*/
local N_MATA_SORT 2000
local N_SAMPLE    200
local N_USE_TAB   50
local N_MATA_HASH 1000000

mata
// From levels of code
real scalar multiplicity(real scalar s, real scalar n) {
/*
   Estimates multiplicity m of values in dataset based on

   s = # singletons in sample of size n

   uses approximation E(# singletons) = n*((m - 1)/m)^(n - 1)
*/
        return(1/(1 - (s/n)^(1/(n - 1))))
}

function should_tab(real colvector x) {
    real scalar     N, S, multi
    string scalar   state
    real colvector  y
    real matrix     t

    // Take a random sample of x
    state = rngstate()
    rseed(987654321)
    y = srswor(x, `N_SAMPLE')
    rngstate(state)

    // Compute the number of unique levels in sample
    t = uniqrows(y, 1)
    n = rows(t)

    // If too many unique values in sample, return
    if (n >= `N_USE_TAB') {
        return(0)
    }

    // Compute the number of unique values that appear only once
    s = sum(t[., 2] :== 1)
    
    // Estimate multiplicity in the sample
    multi = multiplicity(sum(t[., 2] :== 1), rows(t))
    return(multi <= `N_USE_TAB')
}

function unique_integers_9(string scalar name) {
    real matrix x, _
    string scalar matname
    
    st_view(x=., ., name)
    
    // Not enough observations, sampling is too costly
    // Don't rely on tab in case of worst case where levels > 100
    if (length(x) < `N_MATA_SORT') {
        _ = uniqrowsofinteger(x)
    }
    else if (should_tab(x)) {
        matname = st_tempname()
        stata("quietly tab " + name + ", missing matrow(" + matname + ")")
        _ = st_matrix(matname)
    }
    else {
        _ = uniqrowsofinteger(x)
    }
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

mata
function unique_reals_6(string scalar name) {
    string scalar matname
    real matrix _
    
    matname = st_tempname()
    
    stata("quietly tab " + name + ", missing matrow(" + matname + ")")
    _ = st_matrix(matname)
}
end

mata
transmorphic colvector levels_htable_float(transmorphic matrix x) {
    real matrix _
    real scalar n, h, res
    struct Htable scalar levels

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

    return(htable_keys(levels))
}

function unique_reals_9(string scalar name) {
    real matrix x, _
    string scalar matname
    
    st_view(x=., ., name)
    
    // Not enough observations, sampling is too costly
    // Don't rely on tab in case of worst case where levels > 100
    if (length(x) < `N_MATA_SORT') {
        _ = uniqrowssort(x)
    }
    else if (should_tab(x)) {
        matname = st_tempname()
        stata("quietly tab " + name + ", missing matrow(" + matname + ")")
        _ = st_matrix(matname)
    }
    else if (length(x) >= `N_MATA_HASH') {
        _ = levels_htable_float(x)
    }
    else {
        _ = uniqrowssort(x)
    }
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

mata
string colvector function levels_htable_str(string colvector x) {
    real scalar n, h, res
    struct Htable scalar levels

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

    return(htable_keys(levels))
}

function unique_strings_9(string scalar name) {
    string matrix x, _
    
    st_sview(x="", ., name)
    
    if (length(x) >= `N_MATA_HASH') {
        _ = levels_htable_str(x)
    }
    else {
        _ = uniqrowssort(x)
    }
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
        
        timer on 16
        mata: unique_integers_6("x_int")
        timer off 16
        
        timer on 19
        mata: unique_integers_9("x_int")
        timer off 19
        
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
        
        timer on 26
        mata: unique_reals_6("x_real")
        timer off 26
        
        timer on 29
        mata: unique_reals_9("x_real")
        timer off 29
        
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
        
        timer on 39
        mata: unique_strings_9("x_string")
        timer off 39
        
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
- The tab command is faster with small number of levels (< 100)
- However, it does not seem slower with a small number of observations

For reals we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Directly use uniqrowssort() instead of uniqrows()
- Beyond we don't gain anything using levelsof core code
- With large data bases (>=1M), using Associative Arrays seems faster
- A simpler version of a Hash table with the right functions is even faster
- It outperforms the uniqrowssort() function for N >= 100K
- The tab command is faster with small number of levels (<= 100)
- However, it does not seem slower with a small number of observations

For strings we can improve it
- Skip the Stata layer of levelsof and call the mata functions
- Beyond there is no clear gains
- The Hash Table version is faster for strings too if N >= 100K
- Encode variables and treat it as an integer
- Tab is not possible with string functions
    - Stata matrices only support numbers and we cannot save the results
- strL are always done with a specific code based on the 'bysort' command

For encoded strings, we have the same optimizations as integers
*/

/*
The choice of algorithm depending on
* the type
* the number of obs
* the expected number of levels

- integer
    - if small number of levels (estimated based on sampling)
        -> tab command
    - else
        -> uniqrowsofinteger()
- floats
    - if small number of levels (estimated based on sampling)
        -> tab command
    - else
        - if samll number of observations
            -> uniqrowssort()
        - else
            -> hash table
- strings (not strL)
    - if small number of observations (N < 100K)
        -> 34: uniqrowssort()
    - else
        -> hash table
*/

// Check estimation of number of levels

/*
    // Found in paper
    // TODO: add refs
    // https://www.vldb.org/conf/1995/P311.PDF
    // Note: Accurate for a sample of 10%
real scalar unique_shlosser(real matrix t, real scalar N) {
    real scalar    n, d, q, imax, _q, num, den
    real colvector f, rangei
    
    n = sum(t[., 2])
    d = rows(t)
    q = n/N
    
    imax = max(t[., 2])
    
    f = J(imax, 1, 0)
    for (i = 1; i <= imax; i++) {
        f[i] = sum(t[., 2] :== i)
    }
    
    rangei = (1..imax)'
    
    _q = 1-q
    num = f[1] * sum((_q :^ rangei) :* f)
    den = sum(rangei :* q :* (_q :^ (rangei :- 1)) :* f) 
    
    return(d + num / den)
}

mata
    N = 10000000
    N_LEVELS = 1000
    N_SAMPLE = 1000
    strofreal(N_SAMPLE / N * 100) + "%"

    // Uniform low not skewed
    x = runiformint(N, 1, 1, 100)
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x))

    // Uniform low not skewed
    x = runiformint(N, 1, 1, 1000)
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x))

    // Uniform low not skewed
    x = runiformint(N, 1, 1, 10000)
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x))

    // Exponential low b = 0.5
    x = floor(rexponential(N, 1, 0.5))
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x))
    
    // Exponential low b = 1
    x = floor(rexponential(N, 1, 1))
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x));
    
    // Exponential low b = 1.5
    x = floor(rexponential(N, 1, 1.5))
    y = x[1..N_SAMPLE]
    t = uniqrows(y, 1)
    
    length(uniqrows(x))
    multiplicity(sum(t[., 2] :== 1), rows(t))
    unique_shlosser(t, rows(x))
end
*/

/*
I might have done some things wrong
But Shlosser does not produce good results with small samples- or many levels
*/
