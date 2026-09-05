clear
set obs 10000000
timer clear
gen int x = runiform(0, 15) + 1
gen y_base = "d"
replace y_base = "a" if x == 1
replace y_base = "b" if x == 2 | x == 3 | x == 4
replace y_base = "c" if x >= 5 & x <= 9
forvalues i = 1/100 {
timer on 1
quietly count if x != 1
timer off 1
}
forvalues i = 1/100 {
timer on 2
quietly replace y_base = "e" if x != 1
timer off 2
}
forvalues i = 1/100 {
timer on 3
capture assert x != 1
timer off 3
}
forvalues i = 1/100 {
timer on 4
capture assert x != 1, fast
timer off 4
}
forvalues i = 1/100 {
timer on 5
capture assert x != 99
timer off 5
}
forvalues i = 1/100 {
timer on 6
capture assert x != 99, fast
timer off 6
}
timer list

/*
pmatch newvar, style prix (
    ("luxe", 10000~max)  => "luxe",
    ("luxe", min~!10000) => _unreachable,
)

local var1 style
local var2 prix

replace if 

assert !(`var1' == "luxe" & `var2' < 10000), fast


warning 
*/

