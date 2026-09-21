#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHA 1.000000000000001
#define BETA -0.250000000000001
#define TARGET_ELEMENTS 10000000

int main(void) {
    double neon_time;
    double sme4_time;
    double sme8_time;
    double main_time;

    uint32_t sizes[][2] = L2_SIZES;
    uint32_t n_sizes = sizeof(sizes) / sizeof(sizes[0]);

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

    double *a_ptr = bench_vec_double(max_elements);
    double *x_ptr = bench_vec_double(max_n);
    double *y_ptr = bench_vec_double(max_m);

    double *y_neon = malloc(max_m * sizeof(*y_neon));
    double *y_sme4 = malloc(max_m * sizeof(*y_sme4));
    double *y_sme8 = malloc(max_m * sizeof(*y_sme8));
    double *y_main = malloc(max_m * sizeof(*y_main));

    for (uint32_t i = 0; i < n_sizes; i++) {
        uint32_t m = sizes[i][0];
        uint32_t n = sizes[i][1];
        uint32_t elements = m * n;

        uint32_t n_iter = TARGET_ELEMENTS / elements;
        if (n_iter < 10) n_iter = 10;
        uint32_t n_warm = n_iter / 10;

        memcpy(y_neon, y_ptr, m * sizeof(*y_neon));
        memcpy(y_sme4, y_ptr, m * sizeof(*y_sme4));
        memcpy(y_sme8, y_ptr, m * sizeof(*y_sme8));
        memcpy(y_main, y_ptr, m * sizeof(*y_main));

        BENCH(
            neon_time,
            n_iter,
            n_warm,
            dgemv_neon(ALPHA, BETA, a_ptr, x_ptr, y_neon, m, n)
        );
        BENCH(
            sme4_time,
            n_iter,
            n_warm,
            dgemv_sme4xVGx4(ALPHA, BETA, a_ptr, x_ptr, y_sme4, m, n)
        );
        BENCH(
            sme8_time,
            n_iter,
            n_warm,
            dgemv_sme8xVGx4(ALPHA, BETA, a_ptr, x_ptr, y_sme8, m, n)
        );
        BENCH(
            main_time,
            n_iter,
            n_warm,
            dgemv(ALPHA, BETA, a_ptr, x_ptr, y_main, m, n)
        );

        display_bench_l2(
            "dgemv",
            neon_time,
            sme4_time,
            sme8_time,
            main_time,
            m,
            n,
            i == 0 ? 1 : 0
        );
    }

    free(a_ptr);
    free(x_ptr);
    free(y_ptr);
    free(y_neon);
    free(y_sme4);
    free(y_sme8);
    free(y_main);

    return 0;
}
