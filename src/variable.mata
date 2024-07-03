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
    string scalar quoted
    string vector x, xsort, levels
    real vector selection
    class PRange scalar prange
    class PConstant scalar pconstant
    real scalar i, min, max, n_miss, precision
    real matrix data

    // We don't need to check if value is already included in POr pattern
    check_includes = 0

    // TODO: improve depending on syntax and adapt to other types

    if (this.type == "string") {
        st_sview(x = "", ., this.name)

        // Getting the levels is a bottleneck of the algorithm
        // When the sample size grows
        // Simplified code from 'uniqrows.mata'
        xsort = sort(x, 1)
        selection = 1 \ (xsort[|2,.\.,.|] :!= xsort[|1,.\(rows(x)-1),.|])
        levels = select(xsort, selection)

        for (i = 1; i <= length(levels); i++) {
            quoted = `"""' + levels[i] + `"""'
            this.values.insert(&parse_constant(quoted), check_includes)
        }
    }
    else if (this.type == "int" | this.type == "float") {
        st_view(data=., ., this.name)
        
        min = min(data)
        max = max(data)
        
        if (this.type == "float") {
        	// Due to rounding approximations, we need to extend the boundaries
            precision = 0.00000001
            
        	min = min - precision
        	max = max + precision
        }
        
        timer_off(24)

        prange = PRange()
        prange.define(min, max, 1, 1, this.type == "int")
        this.values.insert(&prange, check_includes)

        n_miss = missing(data)
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
