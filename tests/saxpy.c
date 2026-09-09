#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHAS {0.0f, 1.0f, 3.1415926f, 100000.0f}

void saxpy_ref(float alpha, float *x_ptr, float *y_ptr, uint32_t length) { 
    for (uint32_t idx = 0; idx < length; idx++) {
        y_ptr[idx] += alpha * x_ptr[idx];
    }
}

int main(void) { 
    uint32_t lengths[] = L1_LENGTHS; 
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]); 

    float alphas[] = ALPHAS; 
    uint32_t n_alphas = sizeof(alphas) / sizeof(alphas[0]);

    uint32_t max_length = lengths[n_lengths - 1]; 
    float *x_ptr = random_vec_float(max_length);
    float *y_ptr_base = random_vec_float(max_length);

    float *y_ptr_ref = malloc(max_length * sizeof(*y_ptr_ref));
    float *y_ptr_neon = malloc(max_length * sizeof(*y_ptr_neon));
    float *y_ptr_sve = malloc(max_length * sizeof(*y_ptr_sve));
    float *y_ptr_sme = malloc(max_length * sizeof(*y_ptr_sme)); 

    int result = 0;
    for (uint32_t i = 0; i < n_alphas; i++) { 
        for (uint32_t j = 0; j < n_lengths; j++) { 
            uint32_t length = lengths[j]; 
            float alpha = alphas[i]; 

            memcpy(y_ptr_ref, y_ptr_base, length * sizeof(*y_ptr_ref)); 
            memcpy(y_ptr_neon, y_ptr_base, length * sizeof(*y_ptr_neon));
            memcpy(y_ptr_sve, y_ptr_base, length * sizeof(*y_ptr_sve));
            memcpy(y_ptr_sme, y_ptr_base, length * sizeof(*y_ptr_sme)); 

            saxpy_ref(alpha, x_ptr, y_ptr_ref, length);
            saxpy_neon(alpha, x_ptr, y_ptr_neon, length);
            saxpy_sve(alpha, x_ptr, y_ptr_sve, length);
            saxpy_sme(alpha, x_ptr, y_ptr_sme, length);

            result |= assert_eq_vec_float(y_ptr_neon, y_ptr_ref, length);
            result |= assert_eq_vec_float(y_ptr_sve, y_ptr_ref, length); 
            result |= assert_eq_vec_float(y_ptr_sme, y_ptr_ref, length);
        }
    }

    free(x_ptr);
    free(y_ptr_base);
    free(y_ptr_ref);
    free(y_ptr_neon);
    free(y_ptr_sve);
    free(y_ptr_sme);

    if (!result) {
        printf("all saxpy tests passed.\n");
    }
    
    return result; 
}

