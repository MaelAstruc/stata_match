sysuse auto, clear

gen long one = 1

tempvar use
tempname tframe

mata
    var = "rep78"
    use0 = st_local("use")
    vartype = st_vartype(var)
    fcn0 = "count"
    
    use0
    fcn0
    
    (void)_collapse_init()

    vars_no = st_varindex(var)
    weight_var_no = -1
    
    res = _collapse_setup(by_vars_nos, weight_var_no, "")
    res
    
    usevar_no = st_varindex(var)
    
    res = _collapse_add(use0, usevar_no, fcn0)
    res
    
    res = _collapse_compute()
    res
    
    res = _collapse_get_level()
    res
    
    tframe = ""
    
    use0
    vartype
    tframe
    
    stata("drop _all")
    stata("set obs 1")
    
    res = _collapse_post_to_data(use0, vartype, (""), tframe)
    
    (void)_collapse_clear()
end

label var rep78 `"(count) rep78"'
format rep78 %8.0g

restore, not
