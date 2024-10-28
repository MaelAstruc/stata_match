clear all

local BT struct BT scalar

local N_init = 64

mata
struct BT {
    real colvector values
    real colvector status
    real scalar N
    real scalar height
}

void init_bt(`BT' bt) {
    bt.values = J(`N_init', 1, .)
    bt.status = J(`N_init', 1, 0)
    bt.N      = 0
}

void append(`BT' bt, real vector values) {
    real scalar i
    
    for (i = 1; i <= length(values); i++) {
        push(bt, values[i])
    }
}

void push(`BT' bt, real scalar value) {
    push_recursive(bt, value, 1)
}

void push_recursive(`BT' bt, real scalar value, real scalar node) {
    if (node > length(bt.values)) {
        bt.values = bt.values \ J(length(bt.values), 1, .)
        bt.status = bt.status \ J(length(bt.status), 1, 0)
    }
    
    if (bt.status[node] == 0) {
        bt.values[node] = value
        bt.status[node] = 1
        bt.N = bt.N + 1
        return
    }
    
    if (value == bt.values[node]) {
        return
    }
    
    if (value < bt.values[node]) {
        push_recursive(bt, value, 2 * node)
    }
    else {
        push_recursive(bt, value, 2 * node + 1)
    }
}

void append_sorted(`BT' bt, real colvector A) {
    append_sorted_recursive(bt, A, 1, length(A))
}

void append_sorted_recursive(`BT' bt, real colvector A, real scalar min, real scalar max) {
    if (min > max) {
        return
    }
    
    if (min == max) {
        push(bt, A[min])
    }
    else {
        mid = ceil((min + max) / 2)
        push(bt, A[mid])
        append_sorted_recursive(bt, A, min, mid - 1)
        append_sorted_recursive(bt, A, mid + 1, max)
    }
}

real colvector BT_to_array(`BT' bt) {
    real colvector A
    
    A = J(bt.N, 1, .)
    (void) BT_to_array_recursive(bt, A, 1, 1)
    
    return(A)
}

real scalar BT_to_array_recursive(`BT' bt, real colvector A, real scalar index, real scalar node) {
    if (node > length(bt.values)) {
        return(index)
    }
    
    if (bt.status[node] == 0) {
        return(index)
    }
    
    index = BT_to_array_recursive(bt, A, index, 2 * node)
    A[index] = bt.values[node]
    index = BT_to_array_recursive(bt, A, index + 1, 2 * node + 1)
    
    return(index)
}

void balance(`BT' bt) {
    real colvector A
    
    A = BT_to_array(bt)
    
    init_bt(bt)
    append_sorted(bt, A)
}
end

mata
N = 2^11
T = 1

x = (1..N)'
y = x

bt_1 = BT()
bt_2 = BT()
bt_3 = BT()

timer_clear()

for (t = 1; t <= T; t++) {
    t
    _jumble(y)
    
    init_bt(bt_1)
    init_bt(bt_2)
    init_bt(bt_3)
    
    timer_on(1)
    append(bt_1, y)
    timer_off(1)
    
    timer_on(2)
    append_sorted(bt_2, x)
    timer_off(2)
    
    timer_on(3)
    append_sorted(bt_3, sort(y, 1))
    timer_off(3)
    
    A1 = BT_to_array(bt_1)
    A2 = BT_to_array(bt_2)
    A3 = BT_to_array(bt_3)
    
    assert(x == A1)
    assert(x == A2)
    assert(x == A3)
}

timer()

/*
Append a random vector can take a lot of time depending on ordering
A sorted vector is bad for BT in array form and takes 2^(N-1) memory
Knowing that the vector is sorted allows to make the BT quickly
Sorting and inserting is fast
*/

end
