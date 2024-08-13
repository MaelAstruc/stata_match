* Check number of objects created

clear all

local obs = 100

do "main.do"

mata

N_PEmpty = 0
N_PWild = 0
N_PConstant = 0
N_PRange = 0
N_POr = 0
N_PatternList = 0
N_Tuple = 0
N_Variable = 0
N_Arm = 0
N_Usefulness = 0

mata drop PEmpty::new()
void PEmpty::new() {
	pointer(real scalar) N_PEmpty
	
    N_PEmpty = findexternal("N_PEmpty")
	*N_PEmpty = *N_PEmpty + 1
}

void PWild::new() {
    pointer(real scalar) N_PWild
	
    N_PWild = findexternal("N_PWild")
	*N_PWild = *N_PWild + 1
}

void PConstant::new() {
    pointer(real scalar) N_PConstant
	
    N_PConstant = findexternal("N_PConstant")
	*N_PConstant = *N_PConstant + 1
}

void PRange::new() {
    pointer(real scalar) N_PRange
	
    N_PRange = findexternal("N_PRange")
	*N_PRange = *N_PRange + 1
}

void PatternList::new() {
    pointer(real scalar) N_PatternList
	
	// The default capacity when created is 8
    this.patterns = J(1, 8, NULL)
    this.capacity = 8
    this.length = 0
	
    N_PatternList = findexternal("N_PatternList")
	*N_PatternList = *N_PatternList + 1
}

void POr::new() {
    pointer(real scalar) N_POr
	
    N_POr = findexternal("N_POr")
	*N_POr = *N_POr + 1
}

void Tuple::new() {
    pointer(real scalar) N_Tuple
	
    N_Tuple = findexternal("N_Tuple")
	*N_Tuple = *N_Tuple + 1
}

void Variable::new() {
    pointer(real scalar) N_Variable
	
    N_Variable = findexternal("N_Variable")
	*N_Variable = *N_Variable + 1
}

void Arm::new() {
    pointer(real scalar) N_Arm
	
    N_Arm = findexternal("N_Arm")
	*N_Arm = *N_Arm + 1
}

void Usefulness::new() {
    pointer(real scalar) N_Usefulness
	
    N_Usefulness = findexternal("N_Usefulness")
	*N_Usefulness = *N_Usefulness + 1
}
end

clear

clear
set obs `obs'

gen int x = runiform(0, 15) + 1 // [1, 15]

gen y_base = "d"
replace y_base = "a" if x == 1
replace y_base = "b" if x == 2 | x == 3 | x == 4
replace y_base = "c" if x >= 5 & x <= 9

gen y = ""
match y, v(x) b(    ///
	1         => "a",  ///
	2 | 3 | 4 => "b",  ///
	5~9       => "c",  ///
	_         => "d"   ///
)

assert y_base == y


log using "benchmark/logs/class_count.log", replace

dis "`c(current_date)'"
dis "`c(current_time)'"

mata
N_PEmpty
N_PWild
N_PConstant
N_PRange
N_POr
N_PatternList
N_Tuple
N_Variable
N_Arm
N_Usefulness
end

log close