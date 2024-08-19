* Check number of objects created

clear all

local obs = 100

do "pmatch.ado"

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
N_Match_report = 0
N_Usefulness = 0

void increase_class_count(transmorphic instance) {
    pointer(real scalar) N
    string scalar class_name
    
    class_name = classname(instance)
    
    N = findexternal("N_" + class_name)
    *N = *N + 1
    // printf("new %s; ", class_name)
}

mata drop PEmpty::new()
void PEmpty::new() {
    increase_class_count(this)
}

void PWild::new() {
    increase_class_count(this)
}

void PConstant::new() {
    increase_class_count(this)
}

void PRange::new() {
    increase_class_count(this)
}

void PatternList::new() {
    increase_class_count(this)
    
    // The default capacity when created is 8
    this.patterns = J(1, 8, NULL)
    this.capacity = 8
    this.length = 0
}

void POr::new() {
    increase_class_count(this)
}

void Tuple::new() {
    increase_class_count(this)
}

void Variable::new() {
    increase_class_count(this)
}

void Arm::new() {
    increase_class_count(this)
}

void Match_report::new() {
    increase_class_count(this)
}

void Usefulness::new() {
    increase_class_count(this)
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
pmatch y, v(x) b(    ///
    1         => "a",  ///
    2 | 3 | 4 => "b",  ///
    5~9       => "c",  ///
    _         => "d"   ///
)

assert y_base == y


capture log close
log using "dev/logs/class_count.log", replace

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
N_Match_report
N_Usefulness
end

log close
