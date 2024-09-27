mata
class Variable vector function init_variables(string scalar vars_exp, real scalar check) {
    class Variable vector variables
    pointer scalar t
    real scalar i, n_vars
    string vector vars_str
    
    t = tokeninit()
    tokenset(t, vars_exp)
    
    vars_str = tokengetall(t)
    
    n_vars = length(vars_str)
    
    variables = Variable(n_vars)
    
    for (i = 1; i <= n_vars; i++) {
        variables[i].init(vars_str[i], check)
    }
    
    return(variables)
}

void Variable::new() {}

string scalar Variable::to_string() {
    string rowvector levels_str
    real scalar i

    levels_str = J(1, length(this.levels), "")

    for (i = 1; i <= length(this.levels); i++) {
        if (this.type == "int" | this.type == "float" | this.type == "double") {
            levels_str[i] = strofreal(this.levels[i])
        }
        else {
            levels_str[i] = this.levels[i]
        }
    }

    return(
        sprintf(
            "'%s' (%s): (%s)",
            this.name,
            this.type,
            invtokens(levels_str)
        )
    )
}

void Variable::print() {
    printf("%s", this.to_string())
}

void Variable::init(string scalar variable, real scalar check) {
    this.name = variable
    this.min = .a
    this.max = .a
    
    this.init_type()
    if (check) {
        this.init_levels()
    }
}

void Variable::init_type() {
    string scalar var_type

    var_type = st_vartype(this.name)
    this.stata_type = var_type

    if (var_type == "byte" | var_type == "int" | var_type == "long") {
        this.type = "int"
    }
    else if (var_type == "float") {
        this.type = "float"
    }
    else if (var_type == "double") {
        this.type = "double"
    }
    else if (substr(var_type, 1, 3) == "str") {
        this.type = "string"
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}
end

// Different functions based on the `levelsof` command
local N_MATA_SORT 2000
local N_SAMPLE    200
local N_USE_TAB   50
local N_MATA_HASH 100000

mata
void Variable::init_levels() {
    if (this.type == "int") {
        this.init_levels_int()
    }
    else if (this.type == "float" | this.type == "double") {
        this.init_levels_float()
    }
    else if (this.type == "string") {
        this.init_levels_string()
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}

void Variable::init_levels_int() {
    if (st_nobs() < `N_MATA_SORT') {
        this.init_levels_int_base()
    }
    if (this.should_tab()) {
        this.init_levels_tab()
    }
    else {
        this.init_levels_int_base()
    }
}

void Variable::init_levels_float() {
    if (st_nobs() < `N_MATA_SORT') {
        this.init_levels_float_base()
    }
    if (this.should_tab()) {
        this.init_levels_tab()
    }
    if (st_nobs() > `N_MATA_HASH') {
        this.init_levels_hash()
    }
    else {
        this.init_levels_float_base()
    }
}

void Variable::init_levels_string() {
    if (this.stata_type == "strL") {
        this.init_levels_strL()
    }
    else if (st_nobs() > `N_MATA_HASH') {
        this.init_levels_hash()
    }
    else {
        this.init_levels_strN()
    }
    
    this.quote_levels()
}

void Variable::init_levels_int_base() {
    real vector x
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowsofinteger(x)
}

void Variable::init_levels_float_base() {
    real vector x
    
    st_view(x = ., ., this.name)
    
    this.levels = uniqrowssort(x)
}

// Similar to the `levelsof` command internals
// Removed some things not needed such as the frequency
// Benchmarks in dev/benchmark/levelsof_strL.do
void Variable::init_levels_strL() {
    string scalar n_init, indices
    real matrix cond, i, w
    
    n_init = st_tempname()
    indices = st_tempname()
    
    stata("gen " + n_init + " = _n")
    stata("bysort " + this.name + ": gen " + indices + " = _n == 1")
     
    st_view(cond, ., indices)
    maxindex(cond, 1, i, w)
    
    this.levels = st_sdata(i, this.name)
    
    stata("sort " + n_init)
}

void Variable::init_levels_strN() {
    string vector x
    
    st_sview(x = "", ., this.name)

    this.levels = uniqrowssort(x)
}

void Variable::init_levels_tab() {
    string scalar matname
    
    matname = st_tempname()
    
    stata("quietly tab " + this.name + ", missing matrow(" + matname + ")")
    this.levels = st_matrix(matname)
}

void Variable::init_levels_hash() {
    transmorphic vector x
    transmorphic scalar key
    struct Htable scalar levels
    real scalar n, h, res, i

    if (this.type == "string") {
        st_sview(x="", ., this.name)
        levels = htable_create("")
    }
    else {
        st_view(x=., ., this.name)
        levels = htable_create(.)
    }
    
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

    this.levels = htable_keys(levels)
}

real scalar Variable::should_tab() {
    real scalar     n, s, N, S, multi
    string scalar   state
    real colvector  x, y
    real matrix     t
    
    // Create a view
    st_view(x, ., this.name)

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

void Variable::quote_levels() {
    real scalar i
    
    for (i = 1; i <= length(this.levels); i++) {
        this.levels[i] = `"""' + this.levels[i] + `"""'
    }
}

void Variable::set_minmax() {
    real vector x_num, minmax
    
    minmax = minmax(x_num)
    
    if (length(this.levels) == 0) {
        st_view(x_num = ., ., this.name)
        minmax = minmax(x_num)
    }
    else {
        minmax = minmax(this.levels)
    }
    
    this.min = minmax[1]
    this.max = minmax[2]
}

real scalar Variable::get_min() {
    if (this.min == .a) {
        this.set_minmax()
    }
    
    return(this.min)
}

real scalar Variable::get_max() {
    if (this.max == .a) {
        this.set_minmax()
    }
    
    return(this.max)
}

real scalar Variable::get_type_nb() {
    if (this.type == "int") {
        return(1)
    }
    else if (this.type == "float") {
        return(2)
    }
    else if (this.type == "double") {
        return(3)
    }
    else if (this.type == "string") {
        return(4)
    }
    else {
        // TODO: improve error
        exit(1)
    }
}
end

**#************************************************************** Levelsof utils

mata
// From levelsof functions
real scalar multiplicity(real scalar s, real scalar n) {
        return(1/(1 - (s/n)^(1/(n - 1))))
}
end
