mata
mata drop compress_por()
real matrix compress_por(real matrix por) {
    real matrix por_compressed
    real matrix patterns
    real scalar i, k, n_pat
    real vector constants
    
    n_pat = por[1, 2]
    
    timer_on(1)
    por_compressed = por
    timer_off(1)
    
    timer_on(2)
    _sort(por_compressed[2..(n_pat + 1), .], (2, -3))
    timer_off(2)
    
    timer_on(3)
    k = 2
    por_compressed[k, .] = por_compressed[2, .]
    for (i = 3; i <= n_pat + 1; i++) {
        // We never push a wildcard pattern in a POr (it replaces it)
        // assert(patterns[i, 1] != `WILD_TYPE')
        if (por_compressed[i, 1] == 0 | por_compressed[i, 2] > por_compressed[i, 3]) {
            continue
        }
        else if (por_compressed[i, 2] > por_compressed[k, 3] + get_epsilon(por_compressed[k, 3], por_compressed[i, 4])) {
            k++
            por_compressed[k, .] = por_compressed[i, .]
        }
        else {
            por_compressed[k, 3] = max((por_compressed[k, 3], por_compressed[i, 3]))
        }
        
        // Adapt the type between constant or range
        // k is always at least 1 at this stage
        if (por_compressed[k, 2] == por_compressed[k, 3]) {
            por_compressed[k, 1] = 2
        }
        else {
            por_compressed[k, 1] = 3
        }
    }
    timer_off(3)
    
    por_compressed[1, 2] = k - 1
    return(por_compressed)
}

mata drop compress_por_2()
real matrix compress_por_2(real matrix por) {
    real matrix por_compressed
    real scalar type_nb, n, current_max
    real vector new_max, condition, pat_type, min, max
    
    timer_on(11)
    n = por[1, 2]
    type_nb = por[2, 4]
    por_compressed = por[2..(n + 1), .]
    por_compressed = select(por_compressed, (por_compressed[., 1] :== 2) :| (por_compressed[., 1] :== 3))
    por_compressed = select(por_compressed, por_compressed[., 2] :<= por_compressed[., 3])
    n = rows(por_compressed)
    timer_off(11)
    
    timer_on(12)
    _sort(por_compressed, (2, -3))
    timer_off(12)
    
    timer_on(13)
    current_max = por_compressed[., 3], (1..n)'
    condition = order(current_max, (1, 2)) :>= (1..n)'
    timer_off(13)
    
    timer_on(14)
    por_compressed = select(por_compressed, condition)
    n = rows(por_compressed)
    timer_off(14)
    
    
    timer_on(15)
    new_max = por_compressed[., 3]
    new_max = new_max :+ get_epsilon_vec(new_max, type_nb)
    timer_off(15)
    
    timer_on(16)
    condition = por_compressed[2..n, 2] :> new_max[1..(n - 1)]
    timer_off(16)
    
    timer_on(17)
    min = select(por_compressed[., 2], 1 \ condition)
    max = select(por_compressed[., 3], condition \ 1)
    n = rows(min)
    pat_type = J(n, 1, 2) :+ 
    (min :< max)
    por_compressed = pat_type, min, max, J(n, 1, type_nb)
    timer_off(17)
    
    return(por_compressed)
}

mata drop get_epsilon_vec()
real vector get_epsilon_vec(real colvector x, real scalar type_nb) {
    real scalar epsilon, epsilon0, epsilon_log2, epsilon0_log2
    real colvector x_log2, condition
    
    // We define epsilon and epsilon0 depending on the type
    //    epsilon  is the smallest 'e' such that x != x + e
    //    epsilon0 is the smallest 'e' such that 0 != 0 + e
    
    if (type_nb == 1) {
        return(J(rows(x), 1, 1))
    }
    else if (type_nb == 2) {
        epsilon = 1.0000000000000X-017
        epsilon0 = 1.0000000000000X-07f
    }
    else if (type_nb == 3) {
        epsilon = 1.0000000000000X-034
        epsilon0 = 1.0000000000000X-3fe
    }
    else if (type_nb == 4) {
        return(J(rows(x), 1, 0))
    }
    else {
        errprintf("Expected a variable type 1, 2, 3 or 4, found %f", type_nb)
        exit(_error(3250))
    }
    
    x_log2 = log(abs(x)) :/ log(2)
    epsilon_log2 = log(abs(epsilon)) / log(2)
    epsilon0_log2 = log(abs(epsilon0)) / log(2)

    condition = x_log2 :< (epsilon0_log2 - epsilon_log2)
    
    return(
        (epsilon0 :* condition) :+ 
        ((epsilon :* exp(floor(x_log2) :* log(2))) :* !condition)
    )
}
end

mata
x = J(1001, 4, .)
n_pat = 500

x[1, 1] = 4
x[1, 2] = n_pat
k = 1

for (i = 1; i <= n_pat; i++) {
    x[i + 1, 1] = 3
    x[i + 1, 2] = k++
    x[i + 1, 3] = k++
    x[i + 1, 4] = 1
}

x[n_pat + 1, 2] = x[n_pat + 1, 2] + 1

timer_clear()

for (i = 1; i <= 1000; i++) {
    timer_on(10)
    (void) compress_por(x)
    timer_off(10)
}

for (i = 1; i <= 1000; i++) {
    timer_on(20)
    (void) compress_por_2(x)
    timer_off(20)
}
timer()

x = J(16, 4, .)
n_pat = 4

x[1, 1] = 4
x[1, 2] = n_pat
k = 1

for (i = 1; i <= n_pat; i++) {
    x[i + 1, 1] = 3
    x[i + 1, 2] = k++
    x[i + 1, 3] = k++
    x[i + 1, 4] = 1
}

x[n_pat + 1, 2] = x[n_pat + 1, 2] + 1

timer_clear()

for (i = 1; i <= 100000; i++) {
    timer_on(10)
    (void) compress_por(x)
    timer_off(10)
}

for (i = 1; i <= 100000; i++) {
    timer_on(20)
    (void) compress_por_2(x)
    timer_off(20)
}
timer()

x = J(16, 4, .)
n_pat = 2

x[1, 1] = 4
x[1, 2] = n_pat
k = 1

for (i = 1; i <= n_pat; i++) {
    x[i + 1, 1] = 3
    x[i + 1, 2] = k++
    x[i + 1, 3] = k++
    x[i + 1, 4] = 1
}

x[n_pat + 1, 2] = x[n_pat + 1, 2] + 1

timer_clear()

for (i = 1; i <= 1000000; i++) {
    timer_on(10)
    (void) compress_por(x)
    timer_off(10)
}

for (i = 1; i <= 1000000; i++) {
    timer_on(20)
    (void) compress_por_2(x)
    timer_off(20)
}
timer()

end


