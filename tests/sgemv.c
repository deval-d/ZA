#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHAS {0.0f, 1.0f, 3.1415926f, 100000.0f}
#define BETAS  {0.0f, 1.0f, -1.0f, 3.1415926f}

void sgemv_ref(
    float alpha,
    float beta,
    float *a_ptr,
    float *x_ptr,
    float *y_ptr,
    uint32_t m,
    uint32_t n
) {
    for (uint32_t i = 0; i < m; i++) {
        float y = beta * y_ptr[i];
        for (uint32_t j = 0; j < n; j++) {
            y = fmaf(a_ptr[j * m + i], alpha * x_ptr[j], y);
        }
        y_ptr[i] = y;
    }
}

int main(void) {
    uint32_t sizes[][2] = L2_SIZES;
    uint32_t n_sizes = sizeof(sizes) / sizeof(sizes[0]);

    float alphas[] = ALPHAS;
    uint32_t n_alphas = sizeof(alphas) / sizeof(alphas[0]);

    float betas[] = BETAS;
    uint32_t n_betas = sizeof(betas) / sizeof(betas[0]);

    uint32_t max_m = 0;
    uint32_t max_n = 0;
    uint32_t max_elements = 0;
    for (uint32_t i = 0; i < n_sizes; i++) {
        uint32_t m = sizes[i][0];
        uint32_t n = sizes[i][1];
        if (m > max_m) max_m = m;
        if (n > max_n) max_n = n;
        if (m * n > max_elements) max_elements = m * n;
    }

    float *a_ptr = random_vec_float(max_elements);
    float *x_ptr = random_vec_float(max_n);
    float *y_ptr_base = random_vec_float(max_m);

    float *y_ptr_ref = malloc(max_m * sizeof(*y_ptr_ref));
    float *y_ptr_neon = malloc(max_m * sizeof(*y_ptr_neon));
    float *y_ptr_sme4 = malloc(max_m * sizeof(*y_ptr_sme4));
    float *y_ptr_sme8 = malloc(max_m * sizeof(*y_ptr_sme8));
    float *y_ptr_main = malloc(max_m * sizeof(*y_ptr_main));

    int result = 0;
    for (uint32_t i = 0; i < n_alphas; i++) {
        for (uint32_t j = 0; j < n_betas; j++) {
            for (uint32_t k = 0; k < n_sizes; k++) {
                uint32_t m = sizes[k][0];
                uint32_t n = sizes[k][1];
                float alpha = alphas[i];
                float beta = betas[j];

                memcpy(y_ptr_ref, y_ptr_base, m * sizeof(*y_ptr_ref));
                memcpy(y_ptr_neon, y_ptr_base, m * sizeof(*y_ptr_neon));
                memcpy(y_ptr_sme4, y_ptr_base, m * sizeof(*y_ptr_sme4));
                memcpy(y_ptr_sme8, y_ptr_base, m * sizeof(*y_ptr_sme8));
                memcpy(y_ptr_main, y_ptr_base, m * sizeof(*y_ptr_main));

                sgemv_ref(alpha, beta, a_ptr, x_ptr, y_ptr_ref, m, n);
                sgemv_neon(alpha, beta, a_ptr, x_ptr, y_ptr_neon, m, n);
                sgemv_sme4xVGx4(alpha, beta, a_ptr, x_ptr, y_ptr_sme4, m, n);
                sgemv_sme8xVGx4(alpha, beta, a_ptr, x_ptr, y_ptr_sme8, m, n);
                sgemv(alpha, beta, a_ptr, x_ptr, y_ptr_main, m, n);

                result |= assert_eq_vec_float(y_ptr_neon, y_ptr_ref, m);
                result |= assert_eq_vec_float(y_ptr_sme4, y_ptr_ref, m);
                result |= assert_eq_vec_float(y_ptr_sme8, y_ptr_ref, m);
                result |= assert_eq_vec_float(y_ptr_main, y_ptr_ref, m);
            }
        }
    }

    free(a_ptr);
    free(x_ptr);
    free(y_ptr_base);
    free(y_ptr_ref);
    free(y_ptr_neon);
    free(y_ptr_sme4);
    free(y_ptr_sme8);
    free(y_ptr_main);

    if (!result) {
        printf("all sgemv tests passed.\n");
    }

    return result;
}
