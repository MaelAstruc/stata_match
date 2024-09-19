local CAPACITY = 100
local RATIO    = 2

mata
struct Htable {
    real         scalar    capacity
    real         scalar    N
    transmorphic scalar    dkey
    transmorphic rowvector keys
    real         rowvector status
}

/*
Simple Hash Table with string keys and no values
We can only add new elements and not remove it
*/

struct Htable scalar htable_create(transmorphic scalar default_key, |real scalar capacity) {
    struct Htable H
    
    if (args() == 1) {
        capacity = `CAPACITY'
    }
    
    H = Htable()
    H.capacity = capacity
    H.N        = 0
    H.dkey     = default_key 
    H.keys     = J(1, capacity, default_key)
    H.status   = J(1, capacity, 0)
    
    return(H)
}

void htable_add(struct Htable H, transmorphic scalar key) {
    real scalar h

    h = hash1(key, H.capacity)
    
    if (H.status[h]) {
        htable_add_dup(H, key, h)
    }
    else {
    	htable_add_at(H, key, h)
    }
}

void htable_add_dup(struct Htable H, transmorphic scalar key, real scalar h) {
    // Will always exit the loop because never at full capacity
    while (1) {
        if (H.status[h]) {
            if (H.keys[h] == key) {
                return
            }
            h++
        }
        else {
            htable_add_at(H, key, h)
            return
        }
        
        if (h > H.capacity) {
            h = 1
        }
    }
}

void htable_add_at(struct Htable H, transmorphic scalar key, real scalar h) {
    (void) H.N++
    H.keys[h]   = key
    H.status[h] = 1
    
    if (H.N * `RATIO' >= H.capacity) {
        htable_expand(H)
    }
}

void htable_add_new(struct Htable H, transmorphic scalar key) {
	res = htable_index(H, key)
    if (!res[1]) {
        htable_add_at(H, key, res[2])
    }
}

real scalar htable_contains(struct Htable H, transmorphic scalar key) {
    real scalar h

    h = hash1(key, H.capacity)
    
    if (H.status[h]) {
        return(htable_contains_dup(H, key, h))
    }
    else {
        return(0)
    }
}

real scalar htable_contains_dup(struct Htable H, transmorphic scalar key, real scalar h) {
    // Will always exit the loop because never at full capacity
    while (1) {
        if (H.status[h]) {
            if (H.keys[h] == key) {
                return(1)
            }
            h++
        }
        else {
            return(0)
        }
        
        if (h > H.capacity) {
            h = 1
        }
    }
}

// Check if it exist and position
real rowvector htable_index(struct Htable H, transmorphic scalar key) {
    real scalar h

    h = hash1(key, H.capacity)
    
    if (H.status[h]) {
        return(htable_index_dup(H, key, h))
    }
    else {
        return((0, h))
    }
}

real rowvector htable_index_dup(struct Htable H, transmorphic scalar key, real scalar h) {
    // Will exit the loop because never at full capacity
    while (1) {
        if (H.status[h]) {
            if (H.keys[h] == key) {
                return((1, h))
            }
            h++
        }
        else {
            return((0, h))
        }
        
        if (h > H.capacity) {
            h = 1
        }
    }
}

// Check if it exist and position
real scalar htable_newloc(struct Htable H, transmorphic scalar key) {
    real scalar h

    h = hash1(key, H.capacity)
    
    if (H.status[h]) {
        return(htable_newloc_dup(H, key, h))
    }
    else {
        return(h)
    }
}

real scalar htable_newloc_dup(struct Htable H, transmorphic scalar key, real scalar h) {
    // Will exit the loop because never at full capacity
    while (1) {
        if (H.status[h]) {
            if (H.keys[h] == key) {
                return(0)
            }
            h++
        }
        else {
            return(h)
        }
        
        if (h > H.capacity) {
            h = 1
        }
    }
}

void htable_expand(struct Htable H) {
    struct Htable scalar newH
    
    newH = htable_create(H.dkey, H.capacity * `RATIO')
    
    for (i = 1; i <= H.capacity; i++) {
        if (H.status[i]) {
        	// Can create copy with no check for the need to expand
            htable_add(newH, H.keys[i])
        }
    }
    
    swap(H, newH)
}

transmorphic colvector htable_keys(struct Htable H) {
	return(sort(select(H.keys, H.status)', 1))
}
end
