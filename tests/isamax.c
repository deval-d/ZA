#include "helpers.h"
#include "kernels.h"
#include <string.h>

uint32_t isamax_ref(float *x_ptr, uint32_t length) { 
    uint32_t max_idx = 0; 
    float max_val = 0; 

    float val; 
    for (uint32_t idx = 0; idx < length; idx++) {
        val = fabsf(x_ptr[idx]);
        if (val > max_val) {
            max_val = val;
            max_idx = idx; 
        }
    }

    return max_idx; 
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    float *x_ptr = random_vec_float(max_length);

    uint32_t sum_ref;
    uint32_t neon;
    uint32_t sve;

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = isamax_ref(x_ptr, length);
        neon = isamax_neon(x_ptr, length);
        sve = isamax_sve(x_ptr, length);

        float sum_reff = (float) sum_ref;
        float neonf    = (float) neon; 
        float svef     = (float) sve; 

        result |= assert_eq_vec_float(&neonf, &sum_reff, 1);
        result |= assert_eq_vec_float(&svef, &sum_reff, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all isamax tests passed.\n");
    }
    
    return result; 
}
