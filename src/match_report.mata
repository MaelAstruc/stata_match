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

    if (structname(*this.missings) == "PEmpty") {
        return(strings)
    }

    strings = strings, "Warning : Missing cases"

    if (structname(*this.missings) == "POr") {
        strings = strings, to_string_por(*this.missings)
    }
    else {
        strings = strings, to_string_pattern(*this.missings)
    }

    return(strings)
}

string scalar Match_report::to_string_pattern(transmorphic scalar pattern) {
    return(sprintf("    %s", ::to_string(pattern)))
}

string vector Match_report::to_string_por(struct POr scalar por) {
    string vector strings
    real scalar i

    strings = J(1, por.length, "")
    
    for (i = 1; i <= por.length; i++) {
        strings[i] = this.to_string_pattern(*por.patterns[i])
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
