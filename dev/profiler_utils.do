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

local PROFILER_DEPTH    256
local PROFILER_CAPACITY 1024

local PROFILER          struct Profiler scalar

local PROFILER_MIN_TIME 1000

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
}

struct Profiler scalar new_profiler() {
    `PROFILER' profiler
    
    profiler = Profiler()
    
    profiler.capacity = `PROFILER_CAPACITY'
    profiler.length = 0
    
    profiler.names = J(profiler.capacity, 1, "")
    profiler.times = J(profiler.capacity, 2, .)
    profiler.depths = J(profiler.capacity, 1, .)
    
    profiler.depth = 0
    
    profiler.current = 0
    profiler.positions = J(`PROFILER_DEPTH', 1, .)
    
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
    	profiler->positions = profiler->positions \ profiler->positions
    }
    profiler->positions[profiler->current] = profiler->length
    
    // increase result stack capacity if needed
    if (profiler->length > profiler->capacity) {
        profiler->names = profiler->names \ J(profiler->capacity, 1, "")
        profiler->times = profiler->times \ J(profiler->capacity, 2, .)
        profiler->depths = profiler->depths \ J(profiler->capacity, 1, .)
        
        profiler->capacity = profiler->capacity * 2
    }
    
    // increase depthc
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

struct ProfilerNode {
	string scalar name
    real scalar parent
	real vector children
    real scalar time
    real scalar depth
}

struct ProfilerNode vector build_profiler_tree(`PROFILER' profiler, real scalar min_time) {
	struct ProfilerNode vector nodes
    real matrix filter, times, depths
    string vector names
    real scalar current, n, i, index
    
    nodes = ProfilerNode(profiler.length + 1)
    nodes[1].name = "PROFILER"
    nodes[1].parent = 0
    nodes[1].children = J(0, 1, .)
    nodes[1].time = 0
    nodes[1].depth = 0
    
    current = 1
    
    filter = (profiler.times[., 2] :- profiler.times[., 1]) :> min_time
    filter = filter :& ((1..rows(profiler.times))' :<= profiler.length)
    
    times  = select(profiler.times, filter)
    depths = select(profiler.depths, filter)
    names  = select(profiler.names, filter)
    
    n = rows(times)
    
	for (i = 1; i <= n; i++) {
    	index = i + 1
        
        nodes[index].name = names[i]
        nodes[index].parent = current
        nodes[index].children = J(0, 1, .)
        nodes[index].time = times[i, 2] - times[i, 1]
        nodes[index].depth = depths[i]
        
        if (nodes[index].depth == 1) {
        	nodes[1].time = nodes[1].time + nodes[index].time
        }
        
        while (nodes[current].depth != nodes[index].depth - 1) {
        	current = nodes[current].parent
        }
        
        nodes[current].children = nodes[current].children \ index
        
        current = index
    }
    
    return(nodes)
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
	real scalar i, n_children, new_index
    
    if (tree[index].depth == 0 || tree[index].time > min_time) {
        printf(
            "%s%s%s %fms\n",
            beginning,
            indicator,
            tree[index].name,
            tree[index].time
        )
    }
    
    n_children = length(tree[index].children)
    
	for (i = 1; i <= n_children; i++) {
    	new_index = tree[index].children[i]
        
        if (i == n_children) {
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
    
    tree = build_profiler_tree(profiler, min_time)
    
    profiler_print_node(tree, 1, "", " ", "", min_time)
}

void profiler_summarize(`PROFILER' profiler) {
    pointer scalar Table
    real matrix values
    string vector names
	real scalar i, infos, sorted
    
    Table = asarray_create()
    asarray_notfound(Table, (0, 0))
    
    for (i = 1; i <= profiler.length; i++) {
    	infos = asarray(Table, profiler.names[i])
        asarray(
            Table,
            profiler.names[i],
            (infos[1] + profiler.times[i, 2] - profiler.times[i, 1], infos[2] + 1)
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
    	printf("%-30s %6.0fx %9.0fms\n", names[i], values[i, 2], values[i, 1])
    }
}

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