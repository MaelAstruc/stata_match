mata

string scalar Variable::to_string() {
    return(sprintf("'%s' (%s): %s", name, type, values.to_string()))
}

void Variable::print() {
    printf("%s", this.to_string())
}

void Variable::init(string scalar variable) {
    this.name = variable
    this.init_type()
    this.init_values()
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

void Variable::init_values() {
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

        levels_str = uniqrowssort(x_str)

        for (i = 1; i <= length(levels_str); i++) {
            pconstant = PConstant()
            pconstant.value = `"""' + levels_str[i] + `"""'
            this.values.insert(pconstant, check_includes)
        }
    }
    else if (this.type == "int") {
        st_view(x_num = ., ., this.name)

        levels_int = uniqrowsofinteger(x_num)

        for (i = 1; i <= length(levels_int); i++) {
            pconstant = PConstant()
            pconstant.value = levels_int[i]
            this.values.insert(pconstant, check_includes)
        }
    }
    else if (this.type == "float") {
        st_view(x_num = ., ., this.name)
        
        min = min(x_num)
        max = max(x_num)
        
        if (this.type == "float") {
            // Due to rounding approximations, we need to extend the boundaries
            precision = 0.00000001
            
            min = min - precision
            max = max + precision
        }
        
        prange = PRange()
        prange.define(min, max, 1, 1, this.type == "int")
        this.values.insert(&prange, check_includes)

        n_miss = missing(x_num)
        if (n_miss > 0) {
            pconstant = PConstant()
            pconstant.define(.)
            this.values.insert(&pconstant, check_includes)
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
