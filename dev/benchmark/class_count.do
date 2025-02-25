* Check number of objects created

clear all

local obs = 100

capture program drop pmatch check_dtype check_replace
mata: mata clear

run "dev/main_utils.do"
run "pkg/pmatch.ado"

mata

CLASS_NAMES = (
    "Pattern",
    "PEmpty",
    "PWild",
    "PConstant",
    "PRange",
    "POr",
    "Tuple",
    "TupleOr",
    "TupleWild",
    "TupleEmpty",
    "Variable",
    "Arm",
    "Match_report",
    "Usefulness"
)

N_Pattern = 0
N_PEmpty = 0
N_PWild = 0
N_PConstant = 0
N_PRange = 0
N_POr = 0
N_Tuple = 0
N_TupleOr = 0
N_TupleEmpty = 0
N_TupleWild = 0
N_Variable = 0
N_Arm = 0
N_Match_report = 0
N_Usefulness = 0

void reset_class_count() {
    string scalar class_names
    pointer(real scalar) N
    real scalar i
    
    class_names = *findexternal("CLASS_NAMES")
    
    for (i = 1; i <= length(class_names); i++) {
        N = findexternal("N_" + class_names[i])
        *N = 0
    }
}

void print_class_count() {
    string scalar class_names
    pointer(real scalar) N
    real scalar i, n
    
    class_names = *findexternal("CLASS_NAMES")
    
    printf("%-15s %12s\n", "CLASS NAME", "INSTANCES")
    
    for (i = 1; i <= length(class_names); i++) {
        n = *findexternal("N_" + class_names[i])
        printf("  %-15s %10.0f\n", class_names[i], n)
    }
}

void increase_class_count(transmorphic scalar instance) {
    pointer(real scalar) N
    string scalar class_name
    
    class_name = classname(instance)
    N = findexternal("N_" + class_name)
    *N = *N + 1
    // printf("new %s; ", class_name)
}

void increase_pattern_count(string scalar pattern_name) {
    pointer(real scalar) N
    
    N = findexternal("N_" + pattern_name)
    *N = *N + 1
    // printf("new %s; ", pattern_name)
}
end

// Redefine the new functions

local T              transmorphic      matrix
local POINTER        pointer           scalar
local POINTERS       pointer           vector
local REAL           real              scalar
local STRING         string            scalar
local STRINGS        string            vector

local PATTERN        real              matrix

local EMPTY          real              rowvector
local WILD           real              matrix
local CONSTANT       real              rowvector
local RANGE          real              rowvector
local OR             real              matrix

local EMPTY_TYPE     0
local WILD_TYPE      1
local CONSTANT_TYPE  2
local RANGE_TYPE     3
local OR_TYPE        4

local TUPLEEMPTY     struct TupleEmpty scalar
local TUPLEOR        struct TupleOr    scalar
local TUPLE          struct Tuple      scalar
local TUPLEWILD      struct TupleWild  scalar

local VARIABLE       class Variable    scalar
local VARIABLES      class Variable    vector

local ARM            class Arm         scalar
local ARMS           class Arm         vector

mata
mata drop new_pempty() new_pwild() new_pconstant() new_prange() new_por() new_tupleor()

`EMPTY' new_pempty() {
    increase_pattern_count("PEmpty")
    
    return((`EMPTY_TYPE', 0, 0, 0))
}

`WILD' new_pwild(`VARIABLE' variable) {
    `WILD' pwild
    `CONSTANT' pconstant
    `REAL' i, n_pat, variable_type
    
    increase_pattern_count("PWild")
    
    variable_type = variable.get_type_nb()
    
    check_var_type(variable_type)
    
    n_pat = length(variable.levels)
    
    pwild = (`WILD_TYPE', n_pat, 0, variable_type) \ J(n_pat, 4, 0)
    
    if (variable.type == "string") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(i, variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "int") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "float") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else if (variable.type == "double") {
        for (i = 1; i <= n_pat; i++) {
            pconstant = new_pconstant(variable.levels[i], variable_type)
            pwild[i + 1, .] = pconstant
        }
    }
    else {
        errprintf(
            "Unexpected variable type for variable '%s': '%s'\n",
            variable.name, variable.stata_type
        )
        exit(_error(3256))
    }
    
    return(pwild)
}

`CONSTANT' new_pconstant(`REAL' value, `REAL' variable_type) {
    increase_pattern_count("PConstant")
    
    check_var_type(variable_type)
    
    return((`CONSTANT_TYPE', value, value, variable_type))
}

`RANGE' new_prange(`REAL' min, `REAL' max, `REAL' variable_type) {
    increase_pattern_count("PRange")
    
    check_var_type(variable_type)

    if (min == . | max == .) {
        errprintf("Range boundaries should be non-missing reals\n")
        exit(_error(3253))
    }
    
    if (variable_type == 1 | variable_type == 4) {
        if (!isint(min) | !isint(max)) {
            errprintf("Range is discrete but boundaries are not integers\n")
            exit(_error(3498))
        }
    }
    
    return((`RANGE_TYPE', min, max, variable_type))
}

`OR' new_por() {
    increase_pattern_count("POr")
    
    return((`OR_TYPE', 0, 0, 0) \ J(8, 4, 0))
}

/*
void Tuple::new() {
    increase_class_count(this)
}
*/

`TUPLEOR' new_tupleor() {
    `TUPLEOR' tuples
    
    increase_pattern_count("TupleOr")
    
    tuples = TupleOr()
    tuples.length = 0
    tuples.list = J(1, 8, NULL)
    
    return(tuples)
}

/*
void TupleEmpty::new() {
    increase_class_count(this)
}
*/

/*
void TupleWild::new() {
    increase_class_count(this)
}
*/

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

mata: reset_class_count()

set obs `obs'

gen int x = runiform(0, 15) + 1 // [1, 15]

gen y_base = "d"
replace y_base = "a" if x == 1
replace y_base = "b" if x == 2 | x == 3 | x == 4
replace y_base = "c" if x >= 5 & x <= 9

pmatch y, v(x) b(    ///
    1         = "a",  ///
    2 | 3 | 4 = "b",  ///
    5/9       = "c",  ///
    _         = "d"   ///
)

assert y_base == y

capture log close
log using "dev/logs/class_count.log", replace

mata: print_class_count()

log close
