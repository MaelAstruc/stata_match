clear all

mata
mata clear
mata set matastrict on
mata set matalnum off
end

quietly include "src/declare.mata"
quietly include "src/pattern_list.mata"
quietly include "src/pattern.mata"
quietly include "src/variable.mata"
quietly include "src/tuple.mata"
quietly include "src/arm.mata"
quietly include "src/parser.mata"
quietly include "src/usefulness.mata"
quietly include "src/algorithm.mata"
quietly include "src/match.mata"
quietly include "src/match.ado"
