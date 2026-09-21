#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHAS {0.0, 1.0, 3.141592653589793, 100000.0}
#define BETAS  {0.0, 1.0, -1.0, 3.141592653589793}

void dgemv_ref(
    double alpha,
    double beta,
    double *a_ptr,
    double *x_ptr,
    double *y_ptr,
    uint32_t m,
    uint32_t n
) {
    for (uint32_t i = 0; i < m; i++) {
        double y = 0.0;
        for (uint32_t j = 0; j < n; j++) {
            y = fma(a_ptr[j * m + i], x_ptr[j], y);
        }
        y_ptr[i] = alpha * y + beta * y_ptr[i];
    }
}

int assert_eq_dgemv(double *measured, double *expected, uint32_t length) {
    int result = 0;
    for (uint32_t i = 0; i < length; i++) {
        double diff = fabs(expected[i] - measured[i]);
        if (diff >= 1e-10 + 1e-10 * fabs(expected[i])) {
            result = 1;
            printf(
                "measured: %18.17g, expected: %18.17g, diff: %18.17g\n",
                measured[i],
                expected[i],
                diff
            );
        }
    }
    return result;
}

int main(void) {
    uint32_t sizes[][2] = L2_SIZES;
    uint32_t n_sizes = sizeof(sizes) / sizeof(sizes[0]);

    double alphas[] = ALPHAS;
    uint32_t n_alphas = sizeof(alphas) / sizeof(alphas[0]);

    double betas[] = BETAS;
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

    double *a_ptr = random_vec_double(max_elements);
    double *x_ptr = random_vec_double(max_n);
    double *y_ptr_base = random_vec_double(max_m);

    double *y_ptr_ref = malloc(max_m * sizeof(*y_ptr_ref));
    double *y_ptr_neon = malloc(max_m * sizeof(*y_ptr_neon));
    double *y_ptr_sme4 = malloc(max_m * sizeof(*y_ptr_sme4));
    double *y_ptr_sme8 = malloc(max_m * sizeof(*y_ptr_sme8));
    double *y_ptr_main = malloc(max_m * sizeof(*y_ptr_main));

    int result = 0;
    for (uint32_t i = 0; i < n_alphas; i++) {
        for (uint32_t j = 0; j < n_betas; j++) {
            for (uint32_t k = 0; k < n_sizes; k++) {
                uint32_t m = sizes[k][0];
                uint32_t n = sizes[k][1];
                double alpha = alphas[i];
                double beta = betas[j];

                memcpy(y_ptr_ref, y_ptr_base, m * sizeof(*y_ptr_ref));
                memcpy(y_ptr_neon, y_ptr_base, m * sizeof(*y_ptr_neon));
                memcpy(y_ptr_sme4, y_ptr_base, m * sizeof(*y_ptr_sme4));
                memcpy(y_ptr_sme8, y_ptr_base, m * sizeof(*y_ptr_sme8));
                memcpy(y_ptr_main, y_ptr_base, m * sizeof(*y_ptr_main));

                dgemv_ref(alpha, beta, a_ptr, x_ptr, y_ptr_ref, m, n);
                dgemv_neon(alpha, beta, a_ptr, x_ptr, y_ptr_neon, m, n);
                dgemv_sme4xVGx4(alpha, beta, a_ptr, x_ptr, y_ptr_sme4, m, n);
                dgemv_sme8xVGx4(alpha, beta, a_ptr, x_ptr, y_ptr_sme8, m, n);
                dgemv(alpha, beta, a_ptr, x_ptr, y_ptr_main, m, n);

                result |= assert_eq_dgemv(y_ptr_neon, y_ptr_ref, m);
                result |= assert_eq_dgemv(y_ptr_sme4, y_ptr_ref, m);
                result |= assert_eq_dgemv(y_ptr_sme8, y_ptr_ref, m);
                result |= assert_eq_dgemv(y_ptr_main, y_ptr_ref, m);
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
        printf("all dgemv tests passed.\n");
    }

    return result;
}
