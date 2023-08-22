# Match statement for stata

The purpose of this `match` commands is to ensure that all the possible cases are covered when creating a variable. This might be useful when, after some time, you discover that an issue in your results comes from the second missing value '98', which exists only for 3 variables, while all the others use only '99'. This is a simple mistake easily avoided but sometimes not.

The `match` command combines two commands: `match_branches` and `check_levelsof`.

The `match_branches` command is a simple replacement of the `replace ... = ... if ...` statements. It also adds a `$` replacement character for the matched variables.

The `check_levelsof` command ensures that all levels of the variable have a corresponding value. It raises an error if any is missing and tells you which. It works with a list of variables and the error can be suppressed with the `noerror` option.

Feel free to open an issue and send comments.

## How to install

For now copy the ado-file and run it.

## Examples

```Stata
sysuse auto, clear

// Usual way with 'replace newvar = value if condition'
gen test_repif = ""
replace test_repif = "low" 	if rep78 == 1
replace test_repif = "mid" 	if rep78 == 3
replace test_repif = "high" 	if rep78 == 4

// With the match command: match var, replace(newvar) branches(condition @ value; ...)
gen test_match = ""
match_branches rep78, replace(test_match) branches( 	///
	rep78 == 1		@ "low"; 		///
	rep78 == 3		@ "mid"; 		///
	rep78 == 4		@ "high"		///
)

assert test_repif == test_match

// A bit of syntactic sugar: '$' replaces var in all the conditions and values
gen test_dol = ""
match_branches rep78, replace(test_dol) branches( 	///
	$ == 1		@ "low";			///
	$ == 3		@ "mid";			///
	$ == 4		@ "high" 		        ///
)

assert test_repif == test_dol

// More syntactic sugar: $1 replaces the first variable, $2 the second, etc
gen test_dols = ""
match_branches rep78 price, replace(test_dols) branches( 	///
	$1 == 1	& $2 <= 5000	@ "low and cheap"; 		///
	$1 == 1	& $2  > 5000	@ "low and expensive"; 		///
	$1 == 3			@ "mid"; 			///
	$1 == 4			@ "high" 			///
)

// Check if of the possibilities are covered
check_levelsof rep78, replace(test_match) noerror
* Warning: missing level '2' for variable 'rep78': 8 observations.
* Warning: missing level '5' for variable 'rep78': 11 observations.
* Found 2 errors for variable rep78.

// Finally, all at once
gen test_match_levels = ""
match rep78, replace(test_match_levels) branches( 	///
	$ == 1		@ "low"; 			///
	$ == 3		@ "mid"; 			///
	$ == 4		@ "high" 			///
)
* Warning: missing level '2' for variable 'rep78': 8 observations.
* Warning: missing level '5' for variable 'rep78': 11 observations.
* Found 2 errors for variable rep78.
```
## Known issues

* It uses `@`, `;` and `$` because the tokenizer does not support multiple characters
    * Any string with these characters will create a bug (if it does not, it's another bug)
	* These characters are not too common so it should be ok
	* This is because the code uses regex to split and replace characters
* check_levelsof checks if all the levels have values in a loop
	* it does not check if they are covered in the conditions
	* this means that there is a warning even if missing values are intended in the conditions
	* this implies that it does not check for the combinations of variables
	* this also implies that the checks are done after all the data is generated
	* this might be an issue for large datasets where you wait a long time
	* add the 'noerror' parameter to keep the partial results
* check_levelsof does not check for overlaping conditions
	* Doing this with final data and dummies is computationally expensive
	* The last branch is the one that matters if there are collisions
	* Just like replace if statements

## Futhermore

The following comments are beyond the scope of this project and are closer to a wishlist.

My ideal syntax to match two variables 'var1' (string with value "a", "b", "c") and 'var2' (float with values betwen 0 and 10) and generate a new variable 'newvar':

```Stata
gen newvar = match var1 var2 {
	$1 == "a"			=> 1,
	$1 == "b" & $2 <= 4		=> 2,
	$1 == "b" & $2 >= 4 & $2 < 8	=> 3,
	$1 == "b" & $2 > 9 & $2 <= 10	=> 4,
}
```

This would return these issues:

* Overlapping conditions: branches 2 and 3 for condition: `var1 == "b" & var2 == 4`
* Case not covered: `var1 == "b" & var2 >= 8 & var2 <= 9`
* Case not covered: `var1 == "c"`
* Case not covered: `var1 == ""`
* Case not covered: `var2 == .`

A proper parser would be the solution for most of the previous problems:

* This would allow to handle the special characters in strings
* With a clearly defined syntax, the logic of the conditions could be extracted
* The missing values could be properly checked if intensional or not
* The checks could be done before replacing the data
* This would be crucial with large datasets

However, beyond the parser, the underlying checks of the conditions might be challenging. For now I think it would require:

* Banning all the regex functions that introduce too much complexity
* Define the universe of possibilities
	* levelsof is perfect for strings and int
	* a valuesof function would give the range of a float variable with min and max
	* a concept of combinations between multiple variables
* Handle the float ranges
	* a concept of ranges, probably an object with a min and max
* Transform the conditions into conbinations of levels and ranges
	* maybe not so hard with a parser and the previous stuff
* Compare the conditions to see if they overlap
* Put all the conditions in the universe of possibilties

Intelligent people already did it in other languages, so looking there might be a good start. I took most of the ideas from Rust with its enums, but it's a statically typed language so I don't know how far the inspiration works. Maybe I will do it, probably not.
