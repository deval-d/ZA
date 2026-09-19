#include "helpers.h"
#include "kernels.h"
#include <string.h>

double dasum_ref(double *x_ptr, uint32_t length) { 
    double sum = 0;
    for (uint32_t idx = 0; idx < length; idx++) {
        sum += fabs(x_ptr[idx]);
    }

    return sum;
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    double *x_ptr = random_vec_double(max_length);

    double sum_ref;
    double neon;
    double sve;
    double sme4xVGx4;
    double sme8xVGx4; 

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = dasum_ref(x_ptr, length);
        neon = dasum_neon(x_ptr, length);
        sve = dasum_sve(x_ptr, length);
        sme4xVGx4 = dasum_sme4xVGx4(x_ptr, length);
        sme8xVGx4 = dasum_sme8xVGx4(x_ptr, length);

        result |= assert_eq_vec_double(&neon, &sum_ref, 1);
        result |= assert_eq_vec_double(&sve, &sum_ref, 1);
        result |= assert_eq_vec_double(&sme4xVGx4, &sum_ref, 1);
        result |= assert_eq_vec_double(&sme8xVGx4, &sum_ref, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all dasum tests passed.\n");
    }
    
    return result; 
}

