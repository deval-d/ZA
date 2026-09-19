#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHAS {0.0f, 1.0f, 3.1415926f, 100000.0f}

void dscal_ref(double alpha, double *x_ptr, uint32_t n) {
    for (uint32_t idx = 0; idx < n; idx++) { 
        x_ptr[idx] *= alpha; 
    }
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    double alphas[] = ALPHAS; 
    uint32_t n_alphas = sizeof(alphas) / sizeof(alphas[0]);

    uint32_t max_length = lengths[n_lengths - 1]; 
    double *x_ptr_base = random_vec_double(max_length);

    double *x_ptr_ref = malloc(max_length * sizeof(*x_ptr_ref));
    double *x_ptr_neon = malloc(max_length * sizeof(*x_ptr_neon));
    double *x_ptr_sve = malloc(max_length * sizeof(*x_ptr_sve));
    double *x_ptr_sme4 = malloc(max_length * sizeof(*x_ptr_sme4)); 
    double *x_ptr_sme8 = malloc(max_length * sizeof(*x_ptr_sme8));

    int result = 0;
    for (uint32_t i = 0; i < n_alphas; i++) { 
        for (uint32_t j = 0; j < n_lengths; j++) { 
            uint32_t length = lengths[j]; 
            double alpha = alphas[i]; 

            memcpy(x_ptr_ref, x_ptr_base, length * sizeof(*x_ptr_ref)); 
            memcpy(x_ptr_neon, x_ptr_base, length * sizeof(*x_ptr_neon));
            memcpy(x_ptr_sve, x_ptr_base, length * sizeof(*x_ptr_sve));
            memcpy(x_ptr_sme4, x_ptr_base, length * sizeof(*x_ptr_sme4));
            memcpy(x_ptr_sme8, x_ptr_base, length * sizeof(*x_ptr_sme8));

            dscal_ref(alpha, x_ptr_ref, length);
            dscal_neon(alpha, x_ptr_neon, length);
            dscal_sve(alpha, x_ptr_sve, length);
            dscal_sme4xVGx4(alpha, x_ptr_sme4, length);
            dscal_sme8xVGx4(alpha, x_ptr_sme8, length);

            result |= assert_eq_vec_double(x_ptr_neon, x_ptr_ref, length);
            result |= assert_eq_vec_double(x_ptr_sve, x_ptr_ref, length); 
            result |= assert_eq_vec_double(x_ptr_sme4, x_ptr_ref, length);
            result |= assert_eq_vec_double(x_ptr_sme8, x_ptr_ref, length);
        }
    }

    free(x_ptr_base);
    free(x_ptr_ref);
    free(x_ptr_neon);
    free(x_ptr_sve);
    free(x_ptr_sme4);
    free(x_ptr_sme8);

    if (!result) {
        printf("all dscal tests passed.\n");
    }
    
    return result; 
}


