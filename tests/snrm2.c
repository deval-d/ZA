#include "helpers.h"
#include "kernels.h"
#include <string.h>

float snrm2_ref(float *x_ptr, uint32_t length) { 
    float scale = 0.0f;
    float ssq = 1.0f;

    for (uint32_t idx = 0; idx < length; idx++) {
        float value = fabsf(x_ptr[idx]);
        if (value == 0.0f) continue;

        if (value > scale) {
            float ratio = scale / value;
            ssq = 1.0f + ssq * ratio * ratio;
            scale = value;
        } else {
            float ratio = value / scale;
            ssq += ratio * ratio;
        }
    }

    return scale * sqrtf(ssq);
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    float *x_ptr = random_vec_float(max_length);

    float sum_ref;
    float neon;
    float sve;

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = snrm2_ref(x_ptr, length);
        neon = snrm2_neon(x_ptr, length);
        sve = snrm2_sve(x_ptr, length);

        result |= assert_eq_vec_float(&neon, &sum_ref, 1);
        result |= assert_eq_vec_float(&sve, &sum_ref, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all snrm2 tests passed.\n");
    }
    
    return result; 
}
