#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHAS {0.0f, 1.0f, 3.1415926f, 100000.0f}

void daxpy_ref(double alpha, double *x_ptr, double *y_ptr, uint32_t length) { 
    for (uint32_t idx = 0; idx < length; idx++) {
        y_ptr[idx] += alpha * x_ptr[idx];
    }
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    double alphas[] = ALPHAS; 
    uint32_t n_alphas = sizeof(alphas) / sizeof(alphas[0]);

    uint32_t max_length = lengths[n_lengths - 1]; 
    double *x_ptr = random_vec_double(max_length);
    double *y_ptr_base = random_vec_double(max_length);

    double *y_ptr_ref = malloc(max_length * sizeof(*y_ptr_ref));
    double *y_ptr_neon = malloc(max_length * sizeof(*y_ptr_neon));
    double *y_ptr_sve = malloc(max_length * sizeof(*y_ptr_sve));
    double *y_ptr_sme4 = malloc(max_length * sizeof(*y_ptr_sme4));
    double *y_ptr_sme8 = malloc(max_length * sizeof(*y_ptr_sme8));

    int result = 0;
    for (uint32_t i = 0; i < n_alphas; i++) { 
        for (uint32_t j = 0; j < n_lengths; j++) { 
            uint32_t length = lengths[j]; 
            double alpha = alphas[i]; 

            memcpy(y_ptr_ref, y_ptr_base, length * sizeof(*y_ptr_ref)); 
            memcpy(y_ptr_neon, y_ptr_base, length * sizeof(*y_ptr_neon));
            memcpy(y_ptr_sve, y_ptr_base, length * sizeof(*y_ptr_sve));
            memcpy(y_ptr_sme4, y_ptr_base, length * sizeof(*y_ptr_sme4)); 
            memcpy(y_ptr_sme8, y_ptr_base, length * sizeof(*y_ptr_sme8));

            daxpy_ref(alpha, x_ptr, y_ptr_ref, length);
            daxpy_neon(alpha, x_ptr, y_ptr_neon, length);
            daxpy_sve(alpha, x_ptr, y_ptr_sve, length);
            daxpy_sme4xVGx4(alpha, x_ptr, y_ptr_sme4, length);
            daxpy_sme8xVGx4(alpha, x_ptr, y_ptr_sme8, length);

            result |= assert_eq_vec_double(y_ptr_neon, y_ptr_ref, length);
            result |= assert_eq_vec_double(y_ptr_sve, y_ptr_ref, length); 
            result |= assert_eq_vec_double(y_ptr_sme4, y_ptr_ref, length);
            result |= assert_eq_vec_double(y_ptr_sme8, y_ptr_ref, length);
        }
    }

    free(x_ptr);
    free(y_ptr_base);
    free(y_ptr_ref);
    free(y_ptr_neon);
    free(y_ptr_sve);
    free(y_ptr_sme4);
    free(y_ptr_sme8);

    if (!result) {
        printf("all daxpy tests passed.\n");
    }
    
    return result; 
}

