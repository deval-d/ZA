#include "helpers.h"
#include "kernels.h"
#include <string.h>

uint32_t idamax_ref(double *x_ptr, uint32_t length) { 
    uint32_t max_idx = 0; 
    double max_val = 0; 

    double val; 
    for (uint32_t idx = 0; idx < length; idx++) {
        val = fabs(x_ptr[idx]);
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
    double *x_ptr = random_vec_double(max_length);

    uint32_t sum_ref;
    uint32_t neon;
    uint32_t sve;

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = idamax_ref(x_ptr, length);
        neon = idamax_neon(x_ptr, length);
        sve = idamax_sve(x_ptr, length);

        double sum_reff = (double) sum_ref;
        double neonf    = (double) neon; 
        double svef     = (double) sve; 

        result |= assert_eq_vec_double(&neonf, &sum_reff, 1);
        result |= assert_eq_vec_double(&svef, &sum_reff, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all idamax tests passed.\n");
    }
    
    return result; 
}
