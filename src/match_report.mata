mata

class Match_report {
    class Usefulness vector usefulness
    transmorphic scalar missings

    void new()
    string vector to_string()
    void print()
}

void Match_report::new() {}

string vector Match_report::to_string() {
    class POr scalar por
    class Tuple scalar missing
    class Usefulness scalar usefulness
    string vector strings
    real scalar i

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

    strings = strings, "Warning : Missing values"

    if (classname(this.missings) == "POr") {
        por = this.missings
        for (i = 1; i <= por.patterns.length; i++) {
            missing = por.patterns.get_pat(i)
            strings = strings, sprintf("\t%s", missing.to_string())
        }
    }
    else {
        missing = this.missings
        strings = strings, sprintf("\t%s", missing.to_string())
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