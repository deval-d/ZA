#include "helpers.h"
#include "kernels.h"
#include <string.h>

double dnrm2_ref(double *x_ptr, uint32_t length) { 
    double scale = 0.0f;
    double ssq = 1.0f;

    for (uint32_t idx = 0; idx < length; idx++) {
        double value = fabs(x_ptr[idx]);
        if (value == 0.0f) continue;

        if (value > scale) {
            double ratio = scale / value;
            ssq = 1.0f + ssq * ratio * ratio;
            scale = value;
        } else {
            double ratio = value / scale;
            ssq += ratio * ratio;
        }
    }

    return scale * sqrt(ssq);
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    double *x_ptr = random_vec_double(max_length);

    double sum_ref;
    double neon;
    double sve;

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        sum_ref = dnrm2_ref(x_ptr, length);
        neon = dnrm2_neon(x_ptr, length);
        sve = dnrm2_sve(x_ptr, length);

        result |= assert_eq_vec_double(&neon, &sum_ref, 1);
        result |= assert_eq_vec_double(&sve, &sum_ref, 1);
    }

    free(x_ptr);

    if (!result) {
        printf("all dnrm2 tests passed.\n");
    }
    
    return result; 
}
