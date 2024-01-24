mata

string scalar Tuple::to_string() {
	class Pattern scalar pattern
	string scalar str
	real scalar i
	
	if (length(this.patterns) == 0) {
		return("Empty Tuple: Error")
	}
	
	pattern = *this.patterns[1]
	
	str = pattern.to_string()
	
	if (length(this.patterns) > 1) {
	    for (i = 2; i <= length(this.patterns); i++) {
			pattern = *patterns[i]
			str = str + ", " + pattern.to_string()
		}
		
		str = "(" + str + ")"
	}
	
	return(str)
}

void Tuple::print() {
	displayas("text")
    printf("%s\n", this.to_string())
}

string scalar Tuple::to_expr(class Variable vector variables) {
	class Pattern scalar pattern
    string scalar str
	real scalar i
	
    if (length(this.patterns) != length(variables)) {
	    errprintf(
			"The tuples and variables have different sizes %f and %f",
			length(this.patterns), length(variables)
		)
		exit(_error(3300))
	}
	
    pattern = *this.patterns[1]
	str = pattern.to_expr(variables[1].name)
	
	for (i = 2; i <= length(this.patterns); i++) {
	    pattern = *this.patterns[i]
		pattern = pattern.compress()
		if (classname(pattern) != "PWild") {
			str = str + " & " + pattern.to_expr(variables[i].name)
		}
	}
	
	return(str)
}

transmorphic scalar Tuple::compress() {
	real scalar i
	
	for (i = 1; i <= length(this.patterns); i++) {
		this.patterns[i] = tuple_compress_i(this.patterns, i)
	}
	
	for (i = 1; i <= length(this.patterns); i++) {
		if (classname(*this.patterns[i]) == "PEmpty") {
			return(PEmpty())
		}
	}
	
	return(this)
}

pointer scalar function tuple_compress_i(pointer vector patterns, real scalar i) {
	class Pattern scalar pattern
	
	pattern = *patterns[i]
	return(&pattern.compress())
}

transmorphic Tuple::overlap(transmorphic scalar pattern) {
    class Pattern scalar pattern_i
	class Tuple scalar tuple, tuple_overlap
	class POr scalar por, por_overlap
	real scalar i
	
	if (classname(pattern) == "Tuple") {
		tuple = pattern
		tuple_overlap = Tuple()
		tuple_overlap.patterns = J(1, length(this.patterns), NULL)
		
		// We compute the overlap of each pattern in the tuple
		for (i = 1; i <= length(this.patterns); i++) {
			pattern_i = *this.patterns[i]
			tuple_overlap.patterns[i] = &pattern_i.overlap(*tuple.patterns[i])
		}
		
		return(tuple_overlap.compress())
	}
	else if (classname(pattern) == "POr") {
		por = pattern
		por_overlap = POr()
		
		// We compute the overlap for each tuple in the Or pattern
		for (i = 1; i <= por.len(); i++) {
			por_overlap.insert(&this.overlap(por.patterns.get_pat(i)))
		}
		
		return(por_overlap.compress())
	}
	else {
		errprintf("Unexpected pattern class: %s", classname(pattern))
		exit(_error(3260))
	}
}

real scalar Tuple::includes(class Tuple scalar tuple) {
    class Pattern scalar pattern_i
    real scalar included
	real scalar i
	
	check_tuples_length(this, tuple)
	
	included = 1
	
	for (i = 1; i <= length(this.patterns); i++) {
	    pattern_i = *this.patterns[i]
		if (!pattern_i.includes(*tuple.patterns[i])) {
		    included = 0
			break
		}
	}
	
	return(included)
}


void function check_tuples_length( ///
	class Tuple scalar tuple_1, ///
	class Tuple scalar tuple_2	///
) {
	if (length(tuple_1.patterns) != length(tuple_2.patterns)) {
	    errprintf(
			"The tuples different sizes %f and %f",
			length(tuple_1.patterns), length(tuple_2.patterns)
		)
		exit(_error(3300))
	}
}

/*
For two patterns of size n: (p_1, ...p_n) and (q_1, ..., q_n), we compute the
difference recursively. For the first patterns p_1 and q_1 we compute the
intersection inter_1, a pattern and the difference diff_1, a vectors of
patterns.

If n = 1, the difference is equal to diff_1.

If n == 2, the difference is composed of two parts:
	1. (diff_1, p_2), the combinaision of all the patterns in diff_n-1 with the pattern_n.
	2. (inter_1, diff_2), the combinaison of inter_n-1 with all the patterns in diff_n if diff_n is non-empty.

We recursively compute the difference between two tuples:
	1. We compute the interesection and the difference between two fields
	2. If they are the last fields, we return the difference
	3. Else we enter the recursive parts
		3.1 If 

We then compute the difference between the remaining fields
(p_2, ..., p_n) and (q_2, ..., q_n).

For the a field n, the difference is equal to diff_n. For a field (n-1), 

We recursively build the difference of all the fields up to the first one.
*/
pointer scalar Tuple::difference( ///
	transmorphic scalar pattern ///
) {
	class POr scalar por, por_result, res_inter, res_diff, result
	transmorphic scalar new_diff
	class Pattern scalar main_pattern, other_pattern, field_inter
	pointer vector field_diff
	class Tuple scalar tuple, new_main, new_other, new_diff_i
	class PatternList scalar pat_list
	real scalar i
	
	if (classname(pattern) == "PEmpty") {
		return(&this)
	}
	else if (classname(pattern) == "POr") {
		por = pattern
		por_result = POr()
		
		por_result.define(difference_list(this, por.patterns))
		
		return(&por_result.compress())
	}
	else if (classname(pattern) != "Tuple") {
		errprintf("Unexpected pattern class %s", classname(pattern))
		exit(_error(101))
	}
	
	tuple = pattern
	
	// The two parts we will return
	res_inter = POr()
	res_diff = POr()
	
	// Compute the field difference
	main_pattern = *this.patterns[1]
	other_pattern = *tuple.patterns[1]
	
	field_inter = main_pattern.overlap(other_pattern)
	field_diff = main_pattern.difference(other_pattern)
	
	// If there are no other fields
	if (length(this.patterns) == 1) {
		if (classname(*field_diff) != "PEmpty") {
			res_diff.insert(tuple_from_patterns(field_diff))
		}
	}
	else {
		// If the fields difference is empty there is no difference part
		if (classname(*field_diff) != "PEmpty") {
			res_diff.insert(tuple_from_patterns((field_diff, this.patterns[2..length(this.patterns)])))
		}
		
		// If the fields intersection is empty there is intersection part
		if (classname(field_inter) != "PEmpty") {
			// Build two tuples with the reaining patterns
			new_main = Tuple()
			new_main.patterns = this.patterns[2..length(this.patterns)]
			
			new_other = Tuple()
			new_other.patterns = tuple.patterns[2..length(this.patterns)]
			
			// Compute the difference
			new_diff = new_main.difference(new_other)
			
			// If non empty, we fill the tuples
			if (classname(*new_diff) == "Tuple") {
				new_diff_i = *new_diff
				res_inter.insert(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
			}
			else if (classname(*new_diff) == "PatternList") {
				pat_list = *new_diff
				for (i = 1; i <= pat_list.length; i++) {
					new_diff_i = pat_list.get_pat(i)
					res_inter.insert(tuple_from_patterns((&field_inter, new_diff_i.patterns)))
				}
			}
			else if (classname(*new_diff) != "PEmpty") {
				errprintf("Unexpected pattern of class '%s'", classname(pattern))
				exit(_error(3260))
			}
		}
	}
	
	result = POr()
	result.insert(&res_diff)
	result.insert(&res_inter)
	
	return(&result.compress())
}

pointer scalar function tuple_from_patterns(pointer vector patterns) {
	class Tuple scalar tuple
	
	tuple = Tuple()
	tuple.patterns = patterns
	return(&tuple)
}

// To compute the difference between a tuple and a list of tuple
// We have an issue:
// 1. Compute the difference between our tuple and the first one
// 2. We obtain zero, one or more tuple corresponding to the difference
// 3. Compute the difference between each of these tuples and the second one
// 4. We obtain a new vector of differences
// 5. We repeat until we have checked all the tuples in the list
// We can stop earlier if at some point we have no difference remaining
transmorphic scalar function difference_vec( ///
	class Pattern scalar pattern,
	class Tuple vector tuples ///
) {
	class PatternList scalar differences, pat_list
	transmorphic scalar new_differences
	pointer scalar difference_p
	real scalar i, j, index
	
	differences = PatternList()
	differences.push(&pattern)
	

	for (i = 1; i <= length(tuples); i++) {

		new_differences = *differences.difference(tuples[i])
		
		if (classname(new_differences) == "PEmpty") {
			return(new_differences)
		}
		else {
			differences = new_differences
		}
	}
	
    return(differences)
}


real scalar function is_empty_ctor(class Tuple vector tuples) {
    if (length(tuples) == 0) {
	    return(1)
	}
	else if (length(tuples) == 1) {
	    return(length(tuples[1].patterns) == 0)
	}
	else {
	    return(0)
	}
}


				// x = (1 | 2, 1 | 2, 1 | 2)
				// y = (1, 1 | 2, 1)
				// diff_tuple(x, y)
				// 1. diff((1 | 2, 1 | 2, 1 | 2), (1, 1 | 2, 1))
				//		- overlap(1 | 2, 1)
				//		=> overlap_pattern = 1
				//		- 1 | 2 - 1
				//		=> diff_field = 2
				//		=> not_overlap = (2, 1 | 2, 1 | 2)
				// 2. diff((1 | 2, 1 | 2), (1 | 2, 1))
				//		- overlap(1 | 2, 1 | 2)
				//		=> overlap_pattern = 1 | 2
				//		- 1 | 2 - 1 | 2
				//		=> diff_field = 0
				//		=> not_overlap = 0
				// 3. diff((1 | 2), (1))
				//		- overlap(1 | 2, 1)
				//		=> overlap_pattern = 1
				//		- 1 | 2 - 1
				//		=> diff_field = 2
				//		=> not_overlap = 2
				//		=> remaining = 0
				//  	return((2))
				// 2.	
				//		=> remaining_other_fields = (2)
				//		=> remaining = (1 | 2, 2)
				//		return((1 | 2, 2))
				// 1.
				//		=> remaining_other_fields = (1 | 2, 2)
				//		=> remaining = (1, 1 | 2, 2)
				//		return((2, 1 | 2, 1 | 2), (1, 1 | 2, 2))

				
end
