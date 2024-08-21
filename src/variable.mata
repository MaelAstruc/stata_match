mata

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

void Variable::init_levels() {
    string vector x_str
    real vector x_num
    real scalar i

    if (this.type == "string") {
        st_sview(x_str = "", ., this.name)

        this.levels = uniqrowssort(x_str)

        for (i = 1; i <= length(this.levels); i++) {
            this.levels[i] = `"""' + this.levels[i] + `"""'
        }
    }
    else if (this.type == "int") {
        st_view(x_num = ., ., this.name)

        this.levels = uniqrowsofinteger(x_num)
    }
    else if (this.type == "float") {
        this.set_minmax()
        
        this.levels = this.get_min(), this.get_max()
        
        if (hasmissing(x_num) > 0) {
            this.levels = this.levels, .
        }
    }
    else {
        errprintf(
            "Unexpected variable type for variable %s: %s\n",
            this.name, this.stata_type
        )
        exit(_error(3256))
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

end
