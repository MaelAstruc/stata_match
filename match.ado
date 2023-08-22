capture program drop match

program define match
	syntax varlist, REPlace(varlist) Branches(str) [NOERROR NOWARNING]
	
	match_branches `varlist', replace(`replace') branches(`branches')
	
	check_levelsof `varlist', replace(`replace') `noerror' `nowarning'
end

capture program drop match_branches

program define match_branches
	syntax varlist, REPlace(varlist) Branches(str)
	
	local n_var: word count `varlist'
	
	if `n_var' == 1 {
		local branches = ustrregexra("`branches'", "\\$", "`varlist'")
	}
	else {
		local i = 0
		foreach var of local varlist {
			local i = `i' + 1
			local branches = ustrregexra("`branches'", "\\$`i'", "`var'")
		}
	}
	
	// tokenize the branches
	tokenize "`branches'", parse(";")
	
	// execute each branch
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
		match_branch `replace', branch(``i'')
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
