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
        if (this.type == "int" | this.type == "float") {
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

    if (substr(var_type, 1, 3) == "str") {
        this.type = "string"
    }
    else if (var_type == "byte" | var_type == "int" | var_type == "long") {
        this.type = "int"
    }
    else if (var_type == "float" | var_type == "double") {
        this.type = "float"
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
    }
}

// Different functions based on the `levelsof` command
void Variable::init_levels() {
    if (this.type == "string") {
        this.init_levels_string()
    }
    else if (this.type == "int") {
        this.init_levels_int()
    }
    else if (this.type == "float") {
        this.init_levels_float()
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
    real vector x_num
    
    st_view(x_num = ., ., this.name)
    
    this.levels = uniqrowsofinteger(x_num)
}

void Variable::init_levels_float() {
    real vector x_num
    
    st_view(x_num = ., ., this.name)
    
    this.levels = uniqrowssort(x_num)
}

void Variable::init_levels_string() {
    real scalar i
    
    if (this.stata_type == "strL") {
        this.init_levels_strL()
    }
    else {
        this.init_levels_strN()
    }
    
    for (i = 1; i <= length(this.levels); i++) {
        this.levels[i] = `"""' + this.levels[i] + `"""'
    }
}

// Similar to the `levelsof` command internals
// Removed some things not needed such as the frequency
// Benchmarks in dev/benchmark/levelsof_strL.do
void Variable::init_levels_strL() {
    string scalar n_init, indices
    real matrix cond, i, w
    transmorphic vector levels
    
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
    string vector x_str
    
    st_sview(x_str = "", ., this.name)

    this.levels = uniqrowssort(x_str)
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

end
