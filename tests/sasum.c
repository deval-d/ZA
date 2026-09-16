#include "helpers.h"
#include "kernels.h"
#include <string.h>

float sasum_ref(float *x_ptr, uint32_t length) { 
    float sum = 0;
    for (uint32_t idx = 0; idx < length; idx++) {
        sum += fabsf(x_ptr[idx]);
    }

    return sum;
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    float *x_ptr = random_vec_float(max_length);

    float sum_ref;
    float neon;
    float sve;
    float sme4xVGx4;
    float sme8xVGx4; 

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = sasum_ref(x_ptr, length);
        neon = sasum_neon(x_ptr, length);
        sve = sasum_sve(x_ptr, length);
        sme4xVGx4 = sasum_sme4xVGx4(x_ptr, length);
        sme8xVGx4 = sasum_sme8xVGx4(x_ptr, length);

        result |= assert_eq_vec_float(&neon, &sum_ref, 1);
        result |= assert_eq_vec_float(&sve, &sum_ref, 1);
        result |= assert_eq_vec_float(&sme4xVGx4, &sum_ref, 1);
        result |= assert_eq_vec_float(&sme8xVGx4, &sum_ref, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all sasum tests passed.\n");
    }
    
    return result; 
}

