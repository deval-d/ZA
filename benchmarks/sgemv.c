#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define ALPHA 1.000001f
#define BETA -0.250001f
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

    float *a_ptr = bench_vec_float(max_elements);
    float *x_ptr = bench_vec_float(max_n);
    float *y_ptr = bench_vec_float(max_m);

    float *y_neon = malloc(max_m * sizeof(*y_neon));
    float *y_sme4 = malloc(max_m * sizeof(*y_sme4));
    float *y_sme8 = malloc(max_m * sizeof(*y_sme8));
    float *y_main = malloc(max_m * sizeof(*y_main));

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
            sgemv_neon(ALPHA, BETA, a_ptr, x_ptr, y_neon, m, n)
        );
        BENCH(
            sme4_time,
            n_iter,
            n_warm,
            sgemv_sme4xVGx4(ALPHA, BETA, a_ptr, x_ptr, y_sme4, m, n)
        );
        BENCH(
            sme8_time,
            n_iter,
            n_warm,
            sgemv_sme8xVGx4(ALPHA, BETA, a_ptr, x_ptr, y_sme8, m, n)
        );
        BENCH(
            main_time,
            n_iter,
            n_warm,
            sgemv(ALPHA, BETA, a_ptr, x_ptr, y_main, m, n)
        );

        display_bench_l2(
            "sgemv",
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
