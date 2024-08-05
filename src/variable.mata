mata

string scalar Variable::to_string() {
    string rowvector levels_str
    real scalar i

    levels_str = J(1, length(this.levels), "")

    for (i = 1; i <= length(this.levels); i = i + 1) {
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

void Variable::init(string scalar variable) {
    this.name = variable
    this.init_type()
    this.init_levels()
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
    real scalar check_includes
    string vector x_str, levels_str
    real vector x_num, levels_int
    class PRange scalar prange
    class PConstant scalar pconstant
    real scalar i, min, max, n_miss, precision

    // All the levels are unique by definition
    check_includes = 0

    // TODO: improve depending on syntax and adapt to other types

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
        st_view(x_num = ., ., this.name)
        
        precision = 0.00000001

        this.levels = minmax(x_num)
        this.levels[1] = this.levels[1] - precision
        this.levels[2] = this.levels[2] + precision

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

end
