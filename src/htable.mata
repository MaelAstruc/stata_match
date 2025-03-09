
**#***************************************************** Hash table struct utils

/*
Simple Hash Table with string keys and no values
Only the necessary parts for getting the levels in Variable() class methods
*/

local CAPACITY = 100
local RATIO    = 2

mata
struct Htable scalar htable_create(transmorphic scalar default_key, |real scalar capacity) {
    struct Htable H
    
    if (args() == 1) {
        capacity = `CAPACITY'
    }
    
    H          = Htable()
    H.capacity = capacity
    H.N        = 0
    H.dkey     = default_key 
    H.keys     = J(1, capacity, default_key)
    H.status   = J(1, capacity, 0)
    
    return(H)
}

void htable_add_at(struct Htable H, transmorphic scalar key, real scalar h) {
    (void) H.N++
    H.keys[h]   = key
    H.status[h] = 1
    
    if (H.N * `RATIO' >= H.capacity) {
        htable_expand(H)
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
    real scalar h, res, i
    transmorphic scalar key
    
    // profiler_on("htable_expand")
    
    newH = htable_create(H.dkey, H.capacity * `RATIO')
    
    for (i = 1; i <= H.capacity; i++) {
        if (H.status[i]) {
            key = H.keys[i]

            h = hash1(key, newH.capacity)

            if (newH.status[h]) {
                res = htable_newloc_dup(newH, key, h)
            }
            else {
                res = h
            }

            if (res) {
                (void) newH.N++
                newH.keys[res] = key
                newH.status[res] = 1
            }
        }
    }
    
    swap(H, newH)
    
    
    // profiler_off()
}

transmorphic colvector htable_keys(struct Htable H) {
    return(sort(select(H.keys, H.status)', 1))
}

end
