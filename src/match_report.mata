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

    if (length(this.missings) == 0) {
        return(strings)
    }

    if (classname(this.missings) == "PEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (classname(this.missings) == "POr") {
        strings = strings, this.to_string_por(this.missings)
    }
    else {
        strings = strings, this.to_string_pattern(this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(class Pattern scalar pattern) {
    return(sprintf("    %s", pattern.to_string()))
}

string vector Match_report::to_string_por(class POr scalar por) {
    string vector strings
    real scalar i

    strings = J(1, por.len(), "")
    
    for (i = 1; i <= por.len(); i++) {
        strings[i] = this.to_string_pattern(por.get_pat(i))
    }
    
    return(strings)
}

void Match_report::print() {
    string vector strings
    real scalar i

    strings = this.to_string()

    displayas("error")
    for (i = 1; i <= length(strings); i++) {
        printf("\t%s\n", strings[i])
    }
}

end
