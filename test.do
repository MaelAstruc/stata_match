************************************* TEST *************************************

// This do-file is not necessary, it just checks that all the commands work properly.

do "match.ado"

sysuse auto, clear

******************************************************************** Test switch

// Test match with a string

gen test = ""
capture switch test = price, b( 				///
	price < 4000	  					@ "cheap"; 			///
	price >= 4000 & price < 8000 		@ "medium"; 		///
	price > 8000	 					@ "expensive" 		///
)
assert _rc == 0
assert test == "cheap" if price < 4000
assert test == "medium" if price >= 4000 & price < 8000
assert test == "expensive" if price > 8000
drop test

// Test match with a numeric

gen test = .
capture switch test = price, b( 		///
	price < 4000	  					@ 1; 		///
	price >= 4000 & price < 8000 		@ 2; 		///
	price > 8000	 					@ 3 		///
)
assert _rc == 0
assert test == 1 if price < 4000
assert test == 2 if price >= 4000 & price < 8000
assert test == 3 if price > 8000
drop test

// Test the '$' replacement with a string

gen test = ""
capture switch test = price, b( 		///
	$ < 4000	  				@ "cheap"; 			///
	$ >= 4000 & $ < 8000 		@ "medium"; 		///
	$ > 8000	 				@ "expensive" 		///
)
assert _rc == 0
assert test == "cheap" if price < 4000
assert test == "medium" if price >= 4000 & price < 8000
assert test == "expensive" if price > 8000
drop test

// Test the '$' replacement with a numeric

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  			@ 1; 				///
	$ >= 4000 & $ < 8000 	@ 2; 				///
	$ > 8000	 			@ 3					///
)
assert _rc == 0
assert test == 1 if price < 4000
assert test == 2 if price >= 4000 & price < 8000
assert test == 3 if price > 8000
drop test

// Test the '$' replacement with two variables

gen test = ""
capture switch test = rep78 + price, b( 	///
	$1 == 1	& $2 <= 5000	@ "low and cheap"; 			///
	$1 == 1	& $2  > 5000	@ "low and expensive"; 		///
	$1 == 3					@ "mid"; 					///
	$1 == 4					@ "high" 					///
)
assert _rc == 0
assert test == "low and cheap" if rep78 == 1 & price <= 5000
assert test == "low and expensive" if rep78 == 1 & price > 5000
assert test == "mid" if rep78 == 3
assert test == "high" if rep78 == 4
drop test

// Test empty branch at the end

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	$ >= 4000 & $ < 8000 		@ 2; 			///
	$ > 8000	 				@ 3;			///
												///
)
assert _rc == 0
assert test == 1 if price < 4000
assert test == 2 if price >= 4000 & price < 8000
assert test == 3 if price > 8000
drop test

// Test empty branch in the middle

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
								   ;			///
	$ >= 4000 & $ < 8000 		@ 2; 			///
	$ > 8000	 				@ 3				///
)
assert _rc == 197
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test missing condition in branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  			@ 1; 				///
							@ 2; 				///
	$ > 8000	 			@ 3					///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test missing '@' in branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	$ >= 4000 & $ < 8000		  2; 			///
	$ > 8000	 				@ 3				///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test missing value in branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	$ >= 4000 & $ < 8000		@  ; 			///
	$ > 8000	 				@ 3				///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test extra '@' at the beginning of branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	@ $ >= 4000 & $ < 8000		@@ 2; 			///
	$ > 8000	 				@ 3				///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test extra '@' in the middle og branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	$ >= 4000 & $ < 8000		@@ 2; 			///
	$ > 8000	 				@ 3				///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

// Test extra '@' at the end of branch 2

gen test = .
capture switch test = price, b( 	///
	$ < 4000	  				@ 1; 			///
	$ >= 4000 & $ < 8000		@ 2@;	 		///
	$ > 8000	 				@ 3				///
)
assert _rc == 102
assert test == 1 if price < 4000
assert test == . if price >= 4000
drop test

******************************************************************** Test match

// Test match_levelsof (the replacements are done)

gen test = ""
capture match test = rep78, b( 		///
	rep78 == 1 | rep78 == 2 	@ "low"; 	///
	rep78 == 3 					@ "mid"; 	///
	rep78 == 4 				 	@ "high"	///
)
assert _rc == 102
assert test == "low" if rep78 == 1 | rep78 == 2
assert test == "mid" if rep78 == 3
assert test == "high" if rep78 == 4
drop test

// Test match_levelsof with noerror

gen test = ""
capture match test = rep78, noerror b( 	///
	rep78 == 1 | rep78 == 2 	@ "low"; 		///
	rep78 == 3 					@ "mid"; 		///
	rep78 == 4 					@ "high" 		///
)
assert _rc == 0
assert test == "low" if rep78 == 1 | rep78 == 2
assert test == "mid" if rep78 == 3
assert test == "high" if rep78 == 4
drop test

******************************** All test passed *******************************
