
mata

`REAL' isbool(`REAL' x) {
    return(x == 0 | x == 1)
}

`REAL' isint(`REAL' x) {
    return(x == trunc(x))
}

void check_var_type(`REAL' variable_type) {
    if (!isint(variable_type) | variable_type < 0 | variable_type > 4) {
        errprintf(
            "Variable type number field should be 1, 2, 3 or 4: found %f\n",
            variable_type
        )
        exit(_error(3498))
    }
}

`STRING' type_details(object) {
    `STRING' eltype, orgtype
    
    eltype = eltype(object)
    orgtype = orgtype(object)
    
    if (eltype == "pointer" & orgtype == "scalar") {
        eltype = eltype + "(" + type_details(*object) + ")"
    }
    else if (eltype == "struct") {
        eltype = eltype + " " + structname(object)
    }
    else if (eltype == "classname") {
        eltype = eltype + " " + classname(object)
    }
    
    return(eltype + " " + orgtype)
}

void unknown_pattern(`T' pattern) {
    errprintf(
        "Unknown pattern of type: %s\n",
        type_details(pattern)
    )
    exit(_error(3250))
}

end
