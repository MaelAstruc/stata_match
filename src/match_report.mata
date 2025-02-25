mata

void Match_report::new() {}

string vector Match_report::to_string() {
    class Usefulness scalar usefulness
    string vector strings
    real scalar i
    
    strings = J(1, 0, "")

    for (i = 1; i <= length(this.usefulness); i++) {
        usefulness = this.usefulness[i]
        strings = strings, usefulness.to_string()
    }

    if (length(*this.missings) == 0) {
        return(strings)
    }

    if ((*this.missings)[1, 1] == `EMPTY_TYPE' | structname(*this.missings) == "TupleEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (eltype(*this.missings) == "real") {
        if ((*this.missings)[1, 1] == `OR_TYPE') {
            strings = strings, to_string_por(*this.missings)
        }
        else {
            strings = strings, to_string_pattern((*this.missings)[1, .])
        }
    }
    else {
        strings = strings, to_string_pattern(*this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(`T' pattern) {
    return(sprintf("    %s", ::to_string(pattern)))
}

string vector Match_report::to_string_por(`POR' por) {
    string vector strings
    `REAL' i, n_pat
    
    n_pat = por[1, 2]

    strings = J(1, n_pat, "")

    for (i = 1; i <= n_pat; i++) {
        strings[i] = this.to_string_pattern(por[i + 1, .])
    }

    return(strings)
}

void Match_report::print() {
    string vector strings
    real scalar i

    strings = this.to_string()

    displayas("error")
    for (i = 1; i <= length(strings); i++) {
        printf("    %s\n", strings[i])
    }
}

end
