**#********************************************************** Automate profiling

/*
I want to profile the code

For that I need to know the time spent in each functions
But also the which function calls which one

For that I will store
- the name of the functions
- the time for each function
- the depth of the call

All of those are stored in dynamic arrays for which we have
- capacity
- length

For the time, we need the start and end time
- when we start the counter, we save the current time in the first column
- when we end the counter, we savec the current time in the end column

To add the end time on the current row, we need to know which one it was
- we have a stack of the initial positions
*/

local PROFILER_DEPTH        256
local PROFILER_CAPACITY    2^20
local PROFILER_CHILDREN     256
local PROFILER_MIN_TIME    1000
local PROFILER_N_OVERHEAD 10000

local PROFILER           struct Profiler scalar

mata

struct Profiler {
    real scalar length
    real scalar capacity
    
    string vector names
    real matrix times
    real vector depths
    
    real scalar depth
    
    real scalar current
    real scalar positions
    real scalar overhead
    
    struct ProfilerNode scalar tree
}

struct ProfilerNode {
	string scalar name
    real scalar parent
	real vector children
    real scalar n_children
    real scalar time
    real scalar depth
}

struct Profiler scalar new_profiler() {
    `PROFILER' profiler
    real scalar i
    
    profiler = Profiler()
    
    profiler.capacity = `PROFILER_CAPACITY'
    profiler.length = 0
    
    profiler.names = J(profiler.capacity, 1, "")
    profiler.times = J(profiler.capacity, 2, .)
    profiler.depths = J(profiler.capacity, 1, .)
    
    profiler.depth = 0
    
    profiler.current = 0
    profiler.positions = J(`PROFILER_DEPTH', 1, .)
    
    profiler.overhead = .
    
    profiler.tree = ProfilerNode(0)
    
    timer_clear(1)
    timer_on(1)
    
    return(profiler)
}

void profiler_on(string scalar name) {
    pointer(`PROFILER') scalar profiler
    
    profiler = findexternal("PROFILER")
    
    // the current position in the results stack
    (void) profiler->length++
    
    // where we store the current position in the positions stack
    (void) profiler->current++
    
    // store the current position (might overflow)
    if (profiler->current > length(profiler->positions)) {
        profiler->positions = profiler->positions \ J(profiler->current - 1, 1, .)
    }
    profiler->positions[profiler->current] = profiler->length
    
    // increase result stack capacity if needed
    if (profiler->length > profiler->capacity) {
        profiler->names = profiler->names \ J(profiler->capacity, 1, "")
        profiler->times = profiler->times \ J(profiler->capacity, 2, .)
        profiler->depths = profiler->depths \ J(profiler->capacity, 1, .)
        
        profiler->capacity = profiler->capacity * 2
    }
    
    // increase depth
    (void) profiler->depth++
    
    // save current information
    profiler->names[profiler->length] = name
    profiler->depths[profiler->length] = profiler->depth
    
    timer_off(1)
    profiler->times[profiler->length, 1] = timer_value(1)[1] * 1000
    timer_on(1)
}

void profiler_off() {
    pointer(`PROFILER') scalar profiler
    
    profiler = findexternal("PROFILER")
    
    // Save time in ms
    timer_off(1)
    profiler->times[profiler->positions[profiler->current], 2] = timer_value(1)[1] * 1000
    timer_on(1)

    // decrease depth
    (void) profiler->depth--
    
    // past position position in the positions stack
    (void) profiler->current--
}

struct ProfilerNode vector get_profiler_overhead(`PROFILER' profiler) {
	if (profiler.overhead == .) {
    	calibrate_profiler(profiler)
    }
    
    return(profiler.overhead)
}

void calibrate_profiler(`PROFILER' profiler) {
    real scalar i, length_before
	
    length_before = profiler.length
    
    timer_clear(99)
    
    timer_on(99)
    for (i = 0; i < `PROFILER_N_OVERHEAD'; i++) {
    	profiler_on("_CALIBRATION")
        profiler_off()
    }
    timer_off(99)
    
    profiler.overhead = timer_value(99)[1] * 1000 / `PROFILER_N_OVERHEAD'
    timer_clear(99)
    
    profiler.length = length_before
}

struct ProfilerNode vector get_profiler_tree(`PROFILER' profiler) {
	if (length(profiler.tree) == 0) {
    	profiler.tree = build_profiler_tree(profiler)
        remove_overhead(profiler)
    }
    
    return(profiler.tree)
}

struct ProfilerNode vector build_profiler_tree(`PROFILER' profiler) {
	struct ProfilerNode vector nodes
    real matrix filter, times, depths
    string vector names
    real scalar current, n, i, index
    
    nodes = ProfilerNode(profiler.length + 1)
    nodes[1].name = "PROFILER"
    nodes[1].parent = 0
    nodes[1].children = J(`PROFILER_CHILDREN', 1, .)
    nodes[1].n_children = 0
    nodes[1].time = 0.01 // Add 10us to be sure that PROFILER is before pmatch
    nodes[1].depth = 0
    
    filter = (1..rows(profiler.times))' :<= profiler.length
    
    times  = select(profiler.times, filter)
    depths = select(profiler.depths, filter)
    names  = select(profiler.names, filter)
    
    n = rows(times)
    current = 1
    
	for (i = 1; i <= n; i++) {
    	index = i + 1
        
        // Fill the node with the information
        nodes[index].name = names[i]
        nodes[index].parent = current // The parent is the last node of higher depth
        nodes[index].children = J(`PROFILER_CHILDREN', 1, .)
        nodes[index].n_children = 0
        nodes[index].time = times[i, 2] - times[i, 1]
        nodes[index].depth = depths[i]
        
        // Manually fill the time of the root node
        if (nodes[index].depth == 1) {
        	nodes[1].time = nodes[1].time + nodes[index].time
        }
        
        // Climb back the nodes until finding the parent of the node (index)
        while (nodes[current].depth != nodes[index].depth - 1) {
        	current = nodes[current].parent
        }
        
        // Add node (index) to the parent list of children and grow if needed
        nodes[current].n_children = nodes[current].n_children + 1
        if (nodes[current].n_children > length(nodes[current].children)) {
            nodes[current].children = nodes[current].children \ J(nodes[current].n_children - 1, 1, .)
        }
        nodes[current].children[nodes[current].n_children] = index
        
        current = index
    }
    
    return(nodes)
}

void remove_overhead(`PROFILER' profiler) {
	struct ProfilerNode vector tree
	real scalar base_overhead, top, current, i
    real vector overheads, stack, children, to_check
    
    base_overhead = get_profiler_overhead(profiler)
    tree = get_profiler_tree(profiler)
    
    overheads = J(length(tree), 1, .)
    
    stack = J(length(tree), 1, .)
    top = 1
    stack[top] = 1
    
	while (top > 0) {
    	current = stack[top]
        if (tree[current].n_children == 0) {
        	overheads[current] = base_overhead
            top--
        }
        else {
            children = tree[current].children[1..tree[current].n_children]
        	to_check = select(children, overheads[children] :== .)
            if (length(to_check) == 0) {
            	overheads[current] = sum(overheads[children]) + base_overhead
                top--
            }
            else {
            	stack[(top + 1)..(top + length(to_check))] = to_check
                top = top + length(to_check)
            }
        }
    }
    
    for (i = 1; i <= length(tree); i++) {
    	profiler.tree[i].time = tree[i].time - overheads[i]
    }
}

void profiler_print_node(
    struct ProfilerNode vector tree,
    real scalar index,
    string scalar beginning,
    string scalar old_string,
    string scalar indicator,
    real scalar min_time
) {
	string scalar new_string
	real scalar i, new_index
    
    if (tree[index].depth == 0 || tree[index].time > min_time) {
        printf(
            "%s%s%s %fms\n",
            beginning,
            indicator,
            tree[index].name,
            round(tree[index].time)
        )
    }
    
	for (i = 1; i <= tree[index].n_children; i++) {
    	new_index = tree[index].children[i]
        
        if (i == tree[index].n_children) {
            indicator  = "└─ "
            new_string = "   "
        }
        else {
            indicator  = "├─ "
            new_string = "│  "
        }
        
        profiler_print_node(
            tree,
            new_index,
            beginning + old_string,
            new_string,
            indicator,
            min_time
        )
    }
}

void profiler_print(`PROFILER' profiler, | real scalar min_time) {
	struct ProfilerNode vector tree
	real scalar i
    
    if (args() == 1) {
    	min_time = `PROFILER_MIN_TIME'
    }
    
    tree = get_profiler_tree(profiler)
    
    profiler_print_node(tree, 1, "", " ", "", min_time)
}

void profiler_summarize(`PROFILER' profiler) {
	struct ProfilerNode vector tree
    pointer scalar Table
    real matrix values
    string vector names
	real scalar i, infos, sorted
    string scalar name
    
    Table = asarray_create()
    asarray_notfound(Table, (0, 0))
    
    tree = get_profiler_tree(profiler)
    
    for (i = 2; i <= length(tree); i++) {
        name = sprintf("%-40s depth %-7.0f", tree[i].name, tree[i].depth)
    	infos = asarray(Table, name)
        asarray(
            Table,
            name,
            (infos[1] + tree[i].time, infos[2] + 1)
        )
    }

    names = asarray_keys(Table)
    values = J(asarray_elements(Table), 2, 0)
    
    for (i = 1; i <= length(names); i++) {
    	values[i, .] = asarray(Table, names[i])
    }
    
    sorted = order(values, -1)
    
    _collate(values, sorted)
    _collate(names, sorted)
    
    for (i = 1; i <= length(names); i++) {
    	printf("%s %6.0fx %9.0fms\n", names[i], values[i, 2], values[i, 1])
    }
}

// TODO: correct graph for overhead and start at 0
void profiler_graph(`PROFILER' profiler, | real scalar min_time) {
	string scalar cmd, color, name
    real matrix filter, times, depths, data, condition_depth, condition_function, gaps
    string matrix names, functions
    pointer(real matrix) scalar bar_mat
    pointer scalar colors
    real scalar i, j, max_depth
    
    if (args() == 1) {
    	min_time = 0
    }
    
    // Hashmap to store colors
    colors = asarray_create()
    asarray_notfound(colors, "")
    
    // Build matrix for area graphs
    filter = (profiler.times[., 2] :- profiler.times[., 1]) :> min_time
    filter = filter :& ((1..rows(profiler.times))' :<= profiler.length)
    
    if (!any(filter)) {
        errprintf("No function call with a time larger than %f\n", min_time)
        exit(2000)
    }
    
    times = select(profiler.times, filter)
    times = times, J(rows(times), 1, .)
    times = colshape(times, 1)
    
    depths = select(profiler.depths, filter)
    depths = depths, depths, J(rows(depths), 1, .)
    depths = colshape(depths, 1)    
    
    names = select(profiler.names, filter)
    names = names, names, J(rows(names), 1, "")
    names = colshape(names, 1)
    
    data = depths, times
    
    max_depth = max(depths)
    functions = uniqrows(names)
    
    gaps = depths :== .
    
    rmexternal("PROFILER_BAR_MAT")
    bar_mat = crexternal("PROFILER_BAR_MAT")

	for (i = 1; i <= max_depth; i++) {
    	condition_depth = (depths :== i) :| gaps
        
    	if (i == 1) {
        	cmd = "twoway"
        }
        else {
        	cmd = "addplot:"
        }
        
        for (j = 1; j <= length(functions); j++) {
        	name = functions[j]
        	condition_function = (names :== name) :| gaps
            
            *bar_mat = select(data, condition_depth :& condition_function)
            
            if (nonmissing(*bar_mat) == 0) {
            	continue
            }
            
            color = asarray(colors, name)
        
            if (color == "") {
                color = sprintf(
                    "%f %f %f",
                    runiformint(1, 1, 0, 255),
                    runiformint(1, 1, 0, 255),
                    runiformint(1, 1, 0, 255)
                )
                
                asarray(colors, name, color)
            }
        
            stata(sprintf(
                `"%s area matamatrix(PROFILER_BAR_MAT), cmissing(n) base(%f) fcolor("%s") lcolor(gs11) lwidth(0) legend(off) xtitle("Time (ms)") ytitle("Depth")"',
                cmd,
                i - 1,
                color
            ))
        }
    }
}

end


**#************************************************************************ TEST

/*
mata
real scalar fib_prof(real scalar n) {
	real scalar res
    
    profiler_on("fib")
    
	if (n == 0) res = 0
    else if (n == 1) res = 1
    else res = fib_prof(n - 1) + fib_prof(n - 2)
    
    profiler_off()
    
    return(res)
}

real scalar fib_noprof(real scalar n) {
	real scalar res
    
    // profiler_on("fib")
    
	if (n == 0) res = 0
    else if (n == 1) res = 1
    else res = fib_noprof(n - 1) + fib_noprof(n - 2)
    
    // profiler_off()
    
    return(res)
}

EXTERN = 1

void test_function_1() {
	pointer(real scalar) scalar ext
    
    ext = findexternal("EXTERN")
}

void test_function_2() {
	pointer(real scalar) scalar ext
    
    ext = findexternal("EXTERN")
}

real scalar fib_test(real scalar n) {
	real scalar res
    
    test_function_1()
    
	if (n == 0) res = 0
    else if (n == 1) res = 1
    else res = fib_test(n - 1) + fib_test(n - 2)
    
    test_function_2()
    
    return(res)
}

PROFILER = new_profiler()

fib_prof(24)
fib_prof(23)

profiler_print(PROFILER, 10000)

timer_clear(1)
timer_on(1)

fib_noprof(24)
fib_noprof(23)

timer_off(1)
printf("NO PROFILER %f ms", timer_value(1)[1] * 1000)

timer_clear(1)
timer_on(1)

fib_test(24)
fib_test(23)

timer_off(1)
printf("TEST %f ms", timer_value(1)[1] * 1000)


PROFILER = new_profiler()

fib_prof(24)
fib_prof(23)

profiler_print(PROFILER, 10000)

profiler_graph(PROFILER, 10)


end
*/