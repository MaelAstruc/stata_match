**#************************************************************** Load functions

clear all

do "dev/benchmark/htable_draft.mata"

**#************************************************************************ Test

mata
    H = htable_create("")

    for (i = 1; i <= 2048; i++) {
        key = strofreal(i)
        assert(!htable_contains(H, key))
        htable_add(H, key)
        assert(htable_contains(H, key))
    }

    (void) htable_keys(H)
end

mata
    H = htable_create("")

    for (i = 1; i <= 2048; i++) {
        key = strofreal(i)
        res = htable_index(H, key)
        asserteq(res[1], 0)
        htable_add_at(H, key, res[2])
        res = htable_index(H, key)
        asserteq(res[1], 1)
    }

    (void) htable_keys(H)
end

**#******************************************************************* Benchmark

// Functions

mata
    string colvector function unique_asarray(string scalar name) {
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

        return(sort(asarray_keys(levels), 1))
    }
end

mata
    string colvector function unique_htable(string scalar name) {
        string matrix x, _
        real scalar n

        st_sview(x="", ., name)
        levels = htable_create("")

        n = length(x)

        for (i = 1; i <= n; i++) {
            if (!htable_contains(levels, x[i])) {
                htable_add(levels, x[i])
            }
        }

        return(htable_keys(levels))
    }
end

mata
    string colvector function unique_htable_index(string scalar name) {
        string matrix x, _
        real scalar i, n
        struct Htable scalar levels

        st_sview(x="", ., name)
        levels = htable_create("")

        n = length(x)

        for (i = 1; i <= n; i++) {
        	res = htable_index(levels, x[i])
            if (!res[1]) {
                htable_add_at(levels, x[i], res[2])
            }
        }

        return(htable_keys(levels))
    }
end

mata
    string colvector function unique_htable_add_new(string scalar name) {
        string matrix x, _
        real scalar n

        st_sview(x="", ., name)
        levels = htable_create("")

        n = length(x)

        for (i = 1; i <= n; i++) {
            htable_add_new(levels, x[i])
        }

        return(htable_keys(levels))
    }
end

mata
    string colvector function unique_htable_newloc(string scalar name) {
        string matrix x, _
        real scalar i, n
        struct Htable scalar levels

        st_sview(x="", ., name)
        levels = htable_create("")

        n = length(x)

        for (i = 1; i <= n; i++) {
        	h = htable_newloc(levels, x[i])
            if (h) {
                htable_add_at(levels, x[i], h)
            }
        }

        return(htable_keys(levels))
    }
end

mata
    string colvector function unique_htable_unroll(string scalar name) {
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

        return(htable_keys(levels))
    }
end

// Data

drop _all

local n_obs 10000

set obs `n_obs'
egen x_int = seq(), from(1) to(100)
gen float x_real = x_int
gen x_string = string(x_int)

// Prepare

forvalues i = 1/100 {
    mata: res1 = unique_asarray("x_string")
    mata: res2 = unique_htable("x_string")
    mata: res3 = unique_htable_index("x_string")
    mata: res4 = unique_htable_add_new("x_string")
    mata: res5 = unique_htable_newloc("x_string")
    mata: res6 = unique_htable_unroll("x_string")
}


// Time

timer clear

forvalues i = 1/100 {
    timer on 1
    mata: res1 = unique_asarray("x_string")
    timer off 1

    timer on 2
    mata: res2 = unique_htable("x_string")
    timer off 2

    timer on 3
    mata: res3 = unique_htable_index("x_string")
    timer off 3

    timer on 4
    mata: res4 = unique_htable_add_new("x_string")
    timer off 4

    timer on 5
    mata: res5 = unique_htable_newloc("x_string")
    timer off 5
    
    timer on 6
    mata: res6 = unique_htable_unroll("x_string")
    timer off 6
}

mata
    asserteq(res1, res2)
    asserteq(res1, res3)
    asserteq(res1, res4)
    asserteq(res1, res5)
    asserteq(res1, res6)
end

timer list
