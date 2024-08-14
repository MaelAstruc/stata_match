mata

// Called with PatternList(), cannot be directly called
void PatternList::new() {
    // The default capacity when created is 8
    this.patterns = J(1, 8, NULL)
    this.capacity = 8
    this.length = 0
}

void PatternList::print() {
    printf("%s", this.to_string())
}

string scalar PatternList::to_string(string scalar sep) {
    string scalar str
    class Pattern scalar pattern
    real scalar i

    str = ""

    for (i = 1; i <= this.length; i++) {
        pattern = *this.patterns[i]
        if (i == 1) {
            str = pattern.to_string()
        }
        else {
            str = str + sep + pattern.to_string()
        }
    }

    return(str)
}

string scalar PatternList::to_expr(string scalar sep) {
    string scalar str
    class Pattern scalar pattern
    real scalar i

    str = ""

    for (i = 1; i <= this.length; i++) {
        pattern = *this.patterns[i]
        if (i == 1) {
            str = pattern.to_expr()
        }
        else {
            str = str + sep + pattern.to_expr()
        }
    }

    return(str)
}

transmorphic scalar PatternList::compress() {
    class PatternList scalar new_pat
    real scalar i

    new_pat = this

    for (i = 1; i <= new_pat.length; i++) {
        if (classname(new_pat.get_pat(i)) == "PEmpty") {
            new_pat.swap_remove(i)
        }
    }

    if (new_pat.length == 0) {
        return(PEmpty())
    }
    else if (new_pat.length == 1) {
        return(new_pat.get_pat(1))
    }
    else {
        return(new_pat)
    }
}

transmorphic scalar PatternList::overlap(class Pattern scalar pattern) {
    class Pattern scalar pattern_i
    class PatternList scalar overlap
    real scalar i

    for (i = 1; i <= this.length; i ++) {
        pattern_i = this.get_pat(i)
        overlap.push(&pattern_i.overlap(pattern))
    }

    return(overlap.compress())
}

pointer scalar PatternList::difference(class Pattern scalar pattern) {
    class Pattern scalar pattern_i
    class PatternList scalar differences
    real scalar i

    for (i = 1; i <= this.length; i ++) {
        pattern_i = this.get_pat(i)
        differences.append(pattern_i.difference(pattern))
    }

    return(&differences.compress())
}


// Resize the dynamic array
void PatternList::resize(real scalar new_capacity) {
    check_integer(new_capacity, "Array new capacity")

    if (new_capacity == 0) {
        errprintf("Cannot resize to a capacity of 0\n")
        exit(_error(3300))
    }
    else if (new_capacity > this.capacity) {
        // This needs to changed if the type is not a pointer
        this.patterns = this.patterns, J(1, new_capacity - this.capacity, NULL)
        this.capacity = new_capacity
    }
    else {
        this.patterns = this.patterns[1..new_capacity]
        this.capacity = new_capacity
        this.length = new_capacity
    }
}

// Add a new element at the end of the values and resize if required
void PatternList::push(pointer scalar value) {
    // Double the capacity if the dynamic is filled
    if (this.length == this.capacity) {
        this.resize(this.capacity * 2)
    }

    this.length = this.length + 1
    this.patterns[this.length] = value
}

// Add an array of new elements at the end and resize if required
void PatternList::append(pointer rowvector new_values) {
    real scalar new_capacity, new_length

    new_length = this.length + cols(new_values)

    // Increase to the right power of two if needed
    if (new_length > this.capacity) {
        new_capacity = 2^ceil(log(new_length) / log(2))
        this.resize(new_capacity)
    }

    this.patterns[this.length+1..new_length] = new_values
    this.length = new_length
}

// Replace a value at a given index
void PatternList::replace(transmorphic scalar value, real scalar index) {
    transmorphic scalar new_value
    
    check_range(index, "replace")

    if (eltype(value) == "pointer") {
        this.patterns[index] = value
    }
    else {
        new_value = value // Copy value before reference
        this.patterns[index] = &new_value
    }
    
}

// Get the pointer at a given index
pointer scalar PatternList::get(real scalar index) {
    check_range(index, "get")

    return(this.patterns[index])
}

// Get the pattern at a given index
transmorphic scalar PatternList::get_pat(real scalar index) {
    return(*this.get(index))
}

// Removes the value at a given index
void PatternList::remove(real scalar index) {
    check_range(index, "remove")

    this.patterns[index..length-1] = this.patterns[index+1..length]
    this.length = this.length - 1
}

// Swap the value at a given index with the last value and decrease the length
void PatternList::swap_remove(real scalar index) {
    check_range(index, "swap and remove")

    this.patterns[index] = this.patterns[length]
    this.length = this.length - 1
}

// Remove all the values
void PatternList::clear() {
    if (this.length == 0) {
        return
    }

    this.patterns[1..(this.length)] = J(1, this.length, NULL)

    this.length = 0
}

// Util function to check for missing, negative or float values
void PatternList::check_integer(real scalar value, string scalar message) {
    if (value == .) {
        errprintf("%s cannot be a missing value\n", message)
        exit(_error(3351))
    }

    if (value < 0) {
        errprintf("%s should be a positive integer, found %f\n", message, value)
        exit(_error(3398))
    }

    if (trunc(value) != value) {
        errprintf("%s should be an integer, found %f\n", message, value)
        exit(_error(3398))
    }
}

// Util check if the index is in range
void PatternList::check_range(real scalar index, string scalar verb) {
    check_integer(index, "Index")

    if (index == 0) {
        errprintf("Cannot %s a value at index 0\n", verb)
        exit(_error(3300))
    }
    else if (index > this.length) {
        errprintf(
            "Cannot %s a value at index %f in an array of length %f\n",
            verb, index, this.length
        )
        exit(_error(3300))
    }
}

end
