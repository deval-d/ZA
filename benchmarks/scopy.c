#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define TARGET_ELEMENTS 10000000

int main(void) { 
    double neon_time; 
    double sve_time;
    double sme_time; 
    double main_time;

    uint32_t lengths[] = L1_LENGTHS;
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]);

    uint32_t max_length = lengths[n_lengths - 1];
    float *x_ptr = bench_vec_float(max_length);
    float *y_ptr = bench_vec_float(max_length);

    float *y_neon = malloc(max_length * sizeof(*y_neon));
    float *y_sve = malloc(max_length * sizeof(*y_sve));
    float *y_sme = malloc(max_length * sizeof(*y_sme));
    float *y_main = malloc(max_length * sizeof(*y_main));

    for (uint32_t i = 0; i < n_lengths; i++) {
        uint32_t length = lengths[i];

        uint32_t n_iter = TARGET_ELEMENTS / length; 
        if (n_iter < 10000) n_iter = 10000; 
        uint32_t n_warm = n_iter / 10;

        memcpy(y_neon, y_ptr, length * sizeof(*y_neon));
        memcpy(y_sve, y_ptr, length * sizeof(*y_sve));
        memcpy(y_sme, y_ptr, length * sizeof(*y_sme));
        memcpy(y_main, y_ptr, length * sizeof(*y_main));

        BENCH(neon_time, n_iter, n_warm, scopy_neon(x_ptr, y_neon, length));
        BENCH(sve_time, n_iter, n_warm, scopy_sve(x_ptr, y_sve, length));
        BENCH(sme_time, n_iter, n_warm, scopy_sme(x_ptr, y_sme, length));
        BENCH(main_time, n_iter, n_warm, scopy(x_ptr, y_main, length));

        display_bench("scopy", neon_time, sve_time, sme_time, main_time, length, i == 0 ? 1 : 0); 
    }

    free(x_ptr);
    free(y_ptr);
    free(y_neon);
    free(y_sve);
    free(y_sme);
    free(y_main);

    return 0;
} 

