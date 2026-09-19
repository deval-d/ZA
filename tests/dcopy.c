#include "helpers.h"
#include "kernels.h"
#include <string.h>

void dcopy_ref(double *x_ptr, double *y_ptr, uint32_t length) { 
    for (uint32_t idx = 0; idx < length; idx++) {
        y_ptr[idx] = x_ptr[idx];
    }
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    uint32_t max_length = lengths[n_lengths - 1]; 
    double *x_ptr = random_vec_double(max_length);
    double *y_ptr_base = random_vec_double(max_length);

    double *y_ptr_ref = malloc(max_length * sizeof(*y_ptr_ref));
    double *y_ptr_neon = malloc(max_length * sizeof(*y_ptr_neon));
    double *y_ptr_sve = malloc(max_length * sizeof(*y_ptr_sve));
    double *y_ptr_sme = malloc(max_length * sizeof(*y_ptr_sme));

    int result = 0;
    for (uint32_t j = 0; j < n_lengths; j++) { 
        uint32_t length = lengths[j]; 

        memcpy(y_ptr_ref, y_ptr_base, length * sizeof(*y_ptr_ref)); 
        memcpy(y_ptr_neon, y_ptr_base, length * sizeof(*y_ptr_neon));
        memcpy(y_ptr_sve, y_ptr_base, length * sizeof(*y_ptr_sve));
        memcpy(y_ptr_sme, y_ptr_base, length * sizeof(*y_ptr_sme));

        dcopy_ref(x_ptr, y_ptr_ref, length);
        dcopy_neon(x_ptr, y_ptr_neon, length);
        dcopy_sve(x_ptr, y_ptr_sve, length);
        dcopy_sme(x_ptr, y_ptr_sme, length);

        result |= assert_eq_vec_double(y_ptr_neon, y_ptr_ref, length);
        result |= assert_eq_vec_double(y_ptr_sve, y_ptr_ref, length); 
        result |= assert_eq_vec_double(y_ptr_sme, y_ptr_ref, length);
    }

    free(x_ptr);
    free(y_ptr_base);
    free(y_ptr_ref);
    free(y_ptr_neon);
    free(y_ptr_sve);
    free(y_ptr_sme);

    if (!result) {
        printf("all dcopy tests passed.\n");
    }
    
    return result; 
}
