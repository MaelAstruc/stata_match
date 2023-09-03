capture program drop match

program define match
	syntax varlist =/ exp, Branches(str) [NOERROR NOWARNING]
	
	switch `varlist' = `exp', branches(`branches')
	
	check_levelsof `exp', replace(`varlist') `noerror' `nowarning'
end

capture program drop switch

program define switch
	syntax varlist =/ exp, Branches(str)
	
	// Check left hand side
	local n_var_l: word count `varlist'
	
	if (`n_var_l' == 0) {
		dis "Expect a variable name before '='."
		error 102
	}
	if (`n_var_l' > 1) {
		dis "Expect only one variable name before '='."
		error 102
	}
	
	// Check right end side
	local exp = regexr("`exp'", "\+", "")
	dis "`exp'"
	local n_var_r: word count `exp'
	
	if `n_var_r' == 0 {
		dis "Expect at least one variable name after '='."
		error 102
	}
	
	// Replace variable reference by the name
	if `n_var_r' == 1 {
		local branches = ustrregexra("`branches'", "\\$", "`exp'")
	}
	else {
		local i = 0
		foreach var of local exp {
			local i = `i' + 1
			confirm variable `var'
			local branches = ustrregexra("`branches'", "\\$`i'", "`var'")
		}
	}
	
	// Tokenize the branches
	tokenize "`branches'", parse(";")
	
	// Execute each branch
	forvalues i = 1(2)1000 {
		if ("``i''" == ";") {
			local id = (`i' + 1) / 2
			local prev = `i' - 2
			local next = `i' + 1
			dis "Branch `id' is empty between:"
			dis "    ``prev''"
			dis "    ``next''"
			error 197
		}
		if ("``i''" == "") continue, break
	
		match_branch `varlist', branch(``i'')
	}
	
end

capture program drop match_branch

program define match_branch
	syntax varlist, Branch(str)
	
	tokenize "`branch'", parse("@")
	
	if "`1'" == "" {
		dis "Empty branch."
		error 102
	}
	if "`1'" == "@" {
		dis "Missing condition before '@' in branch:"
		dis "    `branch'"
		error 102
	}
	if "`3'" == "@" {
		dis "To many '@' in branch:"
		dis "    `branch'"
		error 102
	}
	if "`3'" == "" {
		dis "Missing value after '@' in branch:"
		dis "    `branch'"
		error 102
	}
	if "`4'" == "@" {
		dis "Found an extra @ after the value in branch:"
		dis "    `branch'"
		error 102
	}
	
	local condition `1'
	local value `3'
	
	dis ""
	dis "Condition: `condition'"
	
	local type: type `varlist'
	
	if substr("`type'", 1, 3) == "str" {
		replace `varlist' = "`value'" if `condition'
	}
	else {
		replace `varlist' = `value' if `condition'
	}
	
end

capture program drop check_levelsof

program define check_levelsof
	syntax varlist, REPlace(varlist) [NOERROR NOWARNING]
	
	local errors = 0
	
	foreach var of local varlist {
		quietly levelsof `var', local(levels)
		
		local type: type `var'
		
		dis ""
		foreach level of local levels {
			if substr("`type'", 1, 3) == "str" {
				quietly count if missing(`replace') & `var' == "`level'"
			}
			else {
				quietly count if missing(`replace') & `var' == `level'
			}
			if r(N) > 0 {
				if "`nowarning'" == "" {
					dis "Warning: missing level '`level'' for variable '`var'': `r(N)' observations."
				}
				local errors = `errors' + 1
			}
		}
		if "`nowarning'" == "" & `errors' > 0 {
			dis "Found `errors' errors for variable `var'."
		}
	}
	
	if "`noerror'" == "" & `errors' > 0 error 102
end
