clear all

local BT struct BT scalar

local N_init = 8

mata
struct BT {
	real matrix values
    real colvector status
}

void init_bt(`BT' bt) {
	bt.values = J(`N_init', 2, .)
	bt.status = J(`N_init', 1, 0)
}

void append(`BT' bt, real matrix values, | real scalar sort) {
	real scalar i
    
    if (args() == 2) {
    	sort = 1
    }
    
    if (sort) {
        append_sorted(bt, sort_merge(values))
    }
    else {
        for (i = 1; i <= rows(values); i++) {
            push(bt, values[i, .])
        }
    }
}

void push(`BT' bt, real rowvector value) {
	push_recursive(bt, value, 1)
}

void push_recursive(`BT' bt, real rowvector value, real scalar node) {
	// "push_recursive at " + strofreal(node)
	real rowvector res
    
	if (node >= rows(bt.values)) {
    	// >= : if n is filled, 2n+1 is needed and resizing 2n is not enough
        bt.values = bt.values \ J(rows(bt.values),   2, .)
        bt.status = bt.status \ J(length(bt.status), 1, 0)
    }
    
    if (bt.status[node] == 0) {
    	// "    push_recursive (" + invtokens(strofreal(value), ", ")  + ") at " + strofreal(node)
    	bt.values[node, .] = value
    	bt.status[node] = 1
        return
    }
    
    if (value[2] < bt.values[node, 1]) {
    	push_recursive(bt, value, 2 * node)
        return
    }
    
    if (value[1] > bt.values[node, 2]) {
    	push_recursive(bt, value, 2 * node + 1)
        return
    }
    
    merge(bt, value, node)
}

void merge(`BT' bt, real rowvector value, real scalar node) {
	// "merge at " + strofreal(node)
	real rowvector new_value
    
    assert(node <= rows(bt.values))
    assert(bt.status[node] == 1)
    assert(value[1] <= bt.values[node, 2] & value[2] >= bt.values[node, 1])
    
    new_value = min((value[1], bt.values[node, 1])), max((value[2], bt.values[node, 2]))
    
    if (new_value[1] < bt.values[node, 1]) {
    	res = merge_recursive(bt, new_value, 2 * node, 1)
        new_value[1] = res[1]
    }
    
    if (new_value[2] > bt.values[node, 2]) {
    	res = merge_recursive(bt, new_value, 2 * node + 1, 2)
        new_value[2] = res[2]
    }
    
    bt.values[node, .] = new_value
}

real rowvector merge_recursive(`BT' bt, real rowvector value, real scalar node, real scalar drop) {
	// "merge_recursive at " + strofreal(node)
	real rowvector new_value
    
    // drop
    // 0 if should not drop
    // 1 if can drop right
    // 2 if can drop left

    if (node > rows(bt.values)) {
    	// "    exit 1"
        return(value)
    }
    
    if (bt.status[node] == 0) {
        // "    exit 2"
        return(value)
    }
    
    if (value[2] < bt.values[node, 1]) {
        return(merge_recursive(bt, value, 2 * node, drop * drop == 1))
    }
    else if (value[1] > bt.values[node, 2]) {
        return(merge_recursive(bt, value, 2 * node + 1, drop * drop == 2))
    }
    
    new_value = min((value[1], bt.values[node, 1])), max((value[2], bt.values[node, 2]))
    
    if (new_value[1] < bt.values[node, 1]) {
    	res = merge_recursive(bt, new_value, 2 * node, drop * drop == 1)
        new_value[1] = res[1]
    }
    
    if (new_value[2] > bt.values[node, 2]) {
    	res = merge_recursive(bt, new_value, 2 * node + 1, drop * drop == 2)
        new_value[2] = res[2]
    }
    
    if (node > 1) {
    	parent = bt.values[floor(node / 2), .]
        
        if (drop == 1 & new_value[1] <= bt.values[node, 2]) {
        	drop_recursive(bt, 2 * node + 1)
        }
        
        if (drop == 2 & new_value[2] >= bt.values[node, 1]) {
        	drop_recursive(bt, 2 * node)
        }
        
        remove(bt, node)
    }
    
    return(new_value)
}


void remove(`BT' bt, real scalar node) {
	// "remove at " + strofreal(node)
    if (node > rows(bt.values)) {
        return
    }
    
    if (bt.status[node] == 0) {
        return
    }

    bt.values[node, .] = (., .)
    bt.status[node] = 0
    
    move_up_recursive(bt, 2 * node)
    move_up_recursive(bt, 2 * node + 1)
}

void drop_recursive(`BT' bt, real scalar node) {
	// "drop_recursive at " + strofreal(node)
    if (node > rows(bt.values)) {
    	// "    exit 1"
        return
    }
    
    if (bt.status[node] == 0) {
    	// "    exit 2"
        return
    }

    bt.values[node, .] = (., .)
    bt.status[node] = 0
    
    drop_recursive(bt, 2 * node)
    drop_recursive(bt, 2 * node + 1)
}

void move_up_recursive(`BT' bt, real scalar node) {
	// "move_up_recursive at " + strofreal(node)
    if (node > rows(bt.values)) {
    	// "    exit 1"
        return
    }
    
    if (bt.status[node] == 0) {
    	// "    exit 2"
        return
    }

    temp = bt.values[node, .]
    
    bt.values[node, .] = (., .)
    bt.status[node] = 0
    
    push(bt, temp)
    
    // "new state"
    // bt.values
    
    move_up_recursive(bt, 2 * node)
    move_up_recursive(bt, 2 * node + 1)
}

real matrix sort_merge(real matrix x) {
	real matrix res
	real scalar i, k
    
	res = sort(x, (1, -2))
    k = 1
    for (i = 2; i <= rows(res); i++) {
        if (res[i, 1] > res[k, 2]) {
            k++
            res[k, .] = res[i, .]
        }
        else {
            res[k, 2] = max((res[k, 2], res[i, 2]))
            res[i, .] = J(1, cols(res), .)
        }
    }
    
    return(res[1..k, .])
}

void append_sorted(`BT' bt, real matrix A) {
	append_sorted_recursive(bt, A, 1, rows(A))
}

void append_sorted_recursive(`BT' bt, real matrix A, real scalar min, real scalar max) {
    if (min > max) {
    	return
    }
    
    if (min == max) {
    	push(bt, A[min, .])
    }
    else {
    	mid = ceil((min + max) / 2)
    	push(bt, A[mid, .])
        append_sorted_recursive(bt, A, min, mid - 1)
        append_sorted_recursive(bt, A, mid + 1, max)
    }
}

real matrix BT_to_array(`BT' bt) {
	real colvector A
    
    A = J(sum(bt.status), 2, .)
	(void) BT_to_array_recursive(bt, A, 1, 1)
    
    return(A)
}

real scalar BT_to_array_recursive(`BT' bt, real matrix A, real scalar index, real scalar node) {
    if (node > rows(bt.values)) {
    	return(index)
    }
    
    if (bt.status[node] == 0) {
    	return(index)
    }
    
	index = BT_to_array_recursive(bt, A, index, 2 * node)
    A[index, .] = bt.values[node, .]
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
x = ( 1,  1) \
    ( 2,  3) \
    (-1,  0) \
    ( 5,  9) \
    (-5, -2) \
    ( 3,  4) \
    ( 4,  5) \
    (-7, -6) \
    (-9, -8)

y = sort_merge(x)

bt_1 = BT()
init_bt(bt_1)
append(bt_1, x)
A1 = BT_to_array(bt_1)

bt_2 = BT()
init_bt(bt_2)
append_sorted(bt_2, y)
A2 = BT_to_array(bt_2)

assert(A1 == A2)
end

mata
N = 1000
T = 100

bt_1 = BT()
bt_2 = BT()
bt_3 = BT()

timer_clear()

rseed(15)

for (t = 1; t <= T; t++) {
	init_bt(bt_1)
    init_bt(bt_2)
    init_bt(bt_3)
    
    x = runiformint(N, 1, -N*10, N*10)
    x = (x, (x :+ runiformint(N, 1, 0, 10)))
    
    timer_on(1)
    append(bt_1, x, 0)
    timer_off(1)
    
    timer_on(2)
    y = sort_merge(x)
    timer_off(2)
    
    timer_on(3)
    append_sorted(bt_2, y)
    timer_off(3)
    
    timer_on(4)
    append(bt_3, x)
    timer_off(4)
    
    A1 = BT_to_array(bt_1)
    A2 = BT_to_array(bt_2)
    A3 = BT_to_array(bt_2)

    assert(y == A1)
    assert(y == A2)
    assert(y == A3)
}

timer()

/*
timer report
  1.       17.2 /      100 =    .17207
  2.       .051 /      100 =    .00051
  3.       .508 /      100 =    .00508
  4.       .569 /      100 =    .00569
 11.       16.2 /     3204 =  .0050515
 12.        .13 /    22701 =  5.73e-06
*/
end