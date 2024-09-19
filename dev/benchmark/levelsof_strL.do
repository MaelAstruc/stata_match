clear all

set obs 100000
gen strL ystrL = string(mod(_n, 1000))

program levels_strL_1, sortpreserve
    syntax varlist(max=1)
    
    tempvar levels

    timer on  11
    timer off 11
    
    timer on  12
    bysort `varlist': gen `levels' = `varlist' if _n == 1
    timer off 12
    
    timer on  13
    moveup `levels' , overwrite
    timer off 13
    
    timer on  14
    count if !missing(`levels')
    scalar N = r(N)
    timer off 14

    timer on  15
    mata {
        N = st_numscalar("N")
        levels = st_sdata((1..N)', "`levels'")
    }
    timer off 15
end

program levels_strL_2, sortpreserve
    syntax varlist(max=1)
    
    tempvar n_init
    tempvar cond
    tempvar indices

    timer on  21
    gen `n_init' = _n
    timer off 21
    
    timer on  22
    bysort `varlist': gen `indices' = `n_init' if _n == 1
    timer off 22
    
    timer on  23
    moveup `indices', overwrite
    timer off 23
    
    timer on  24
    count if !missing(`indices')
    scalar N = r(N)
    timer off 24
    
    timer on  25
    mata {
        N = st_numscalar("N")
        indices = st_data((1..N)', "`indices'")
        levels = st_sdata(indices, "`varlist'")
    }
    timer off 25
end

program levels_strL_3, sortpreserve
    syntax varlist(max=1)
    
    tempvar indices

    timer on  31
    timer off 31
    
    timer on  32
    bysort `varlist': gen `indices' = 1 if _n == 1
    timer off 32
    
    timer on  33
    timer off 33
    
    timer on  34
    timer off 34
    
    timer on  35
    mata {
        cond = J(1, 0, .)
        st_view(cond, ., "`indices'")
        i = J(1, 0, .)
        w = J(1, 0, .)
        maxindex(cond, 1, i, w)
        levels = st_sdata(i, "`varlist'")
    }
    timer off 35
end

program levels_strL_4
    syntax varlist(max=1)
    
    tempvar n_init
    tempvar indices

    timer on  41
    gen `n_init' = _n
    timer off 41
    
    timer on  42
    bysort `varlist': gen `indices' = 1 if _n == 1
    timer off 42
    
    timer on  43
    timer off 43
    
    timer on  44
    timer off 44
    
    timer on  45
    mata {
        cond = J(1, 0, .)
        st_view(cond, ., "`indices'")
        i = J(1, 0, .)
        w = J(1, 0, .)
        maxindex(cond, 1, i, w)
        levels = st_sdata(i, "`varlist'")
    }
    timer off 45
    
    timer on  46
    sort `n_init'
    timer off 46
    
end

mata
void function levels_strL_5(string scalar varlist) {
    string scalar n_init, indices
    real matrix cond, i, w
    transmorphic vector levels
    
    timer_on(51)
    n_init = st_tempname()
    stata("gen " + n_init + " = _n")
    timer_off(51)
    
    timer_on(52)
    indices = st_tempname()
    stata("bysort " + varlist + ": gen " + indices + " = 1 if _n == 1")
    timer_off(52)
    
    timer_on(53)
    timer_off(53)
    
    timer_on(54)
    timer_off(54)
    
    timer_on(55)
    cond = J(1, 0, .)
    st_view(cond, ., indices)
    i = J(1, 0, .)
    w = J(1, 0, .)
    maxindex(cond, 1, i, w)
    levels = st_sdata(i, varlist)
    timer_off(55)
    
    timer_on(56)
    stata("sort " + n_init)
    timer_off(56)
}
end

program levels_strL_5
    syntax varlist(max=1)
    
    mata: levels_strL_5("`varlist'")
end

mata
void function levels_strL_6(string scalar varlist) {
    string scalar n_init, indices
    real matrix cond, i, w
    transmorphic vector levels
    
    timer_on(61)
    n_init = st_tempname()
    stata("gen " + n_init + " = _n")
    timer_off(61)
    
    timer_on(62)
    indices = st_tempname()
    stata("bysort " + varlist + ": gen " + indices + " = _n == 1")
    timer_off(62)
    
    timer_on(63)
    timer_off(63)
    
    timer_on(64)
    timer_off(64)
    
    timer_on(65)
    cond = J(1, 0, .)
    st_view(cond, ., indices)
    i = J(1, 0, .)
    w = J(1, 0, .)
    maxindex(cond, 1, i, w)
    levels = st_sdata(i, varlist)
    timer_off(65)
    
    timer_on(66)
    stata("sort " + n_init)
    timer_off(66)
}
end

program levels_strL_6
    syntax varlist(max=1)
    
    mata: levels_strL_6("`varlist'")
end

timer clear

forvalues i = 1/1000 {
    timer on  1
    quietly levelsof ystrL
    timer off 1

    timer on  10
    quietly levels_strL_1 ystrL
    timer off 10
    
    timer on  20
    quietly levels_strL_2 ystrL
    timer off 20
    
    timer on  30
    quietly levels_strL_3 ystrL
    timer off 30
    
    timer on  40
    quietly levels_strL_4 ystrL
    timer off 40
    
    timer on  50
    quietly levels_strL_5 ystrL
    timer off 50
    
    timer on  60
    quietly levels_strL_6 ystrL
    timer off 60
}

timer list

/*
   1:    388.51 /     1000 =       0.3885
  10:    324.98 /     1000 =       0.3250
  11:      0.00 /     1000 =       0.0000
  12:    217.90 /     1000 =       0.2179
  13:     64.42 /     1000 =       0.0644
  14:      4.07 /     1000 =       0.0041
  15:      0.70 /     1000 =       0.0007
  20:    289.13 /     1000 =       0.2891
  21:      2.48 /     1000 =       0.0025
  22:    177.71 /     1000 =       0.1777
  23:     66.50 /     1000 =       0.0665
  24:      2.58 /     1000 =       0.0026
  25:      1.78 /     1000 =       0.0018
  30:    224.17 /     1000 =       0.2242
  31:      0.00 /     1000 =       0.0000
  32:    175.89 /     1000 =       0.1759
  33:      0.00 /     1000 =       0.0000
  34:      0.00 /     1000 =       0.0000
  35:      9.72 /     1000 =       0.0097
  40:    209.33 /     1000 =       0.2093
  41:      2.45 /     1000 =       0.0025
  42:    176.91 /     1000 =       0.1769
  43:      0.00 /     1000 =       0.0000
  44:      0.00 /     1000 =       0.0000
  45:      9.57 /     1000 =       0.0096
  46:     20.31 /     1000 =       0.0203
  50:    207.91 /     1000 =       0.2079
  51:      2.29 /     1000 =       0.0023
  52:    175.42 /     1000 =       0.1754
  53:      0.00 /     1000 =       0.0000
  54:      0.00 /     1000 =       0.0000
  55:      9.56 /     1000 =       0.0096
  56:     20.13 /     1000 =       0.0201
  60:    205.78 /     1000 =       0.2058
  61:      2.31 /     1000 =       0.0023
  62:    174.56 /     1000 =       0.1746
  63:      0.00 /     1000 =       0.0000
  64:      0.00 /     1000 =       0.0000
  65:      8.14 /     1000 =       0.0081
  66:     20.29 /     1000 =       0.0203
*/
