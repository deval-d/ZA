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
    double *x_ptr = bench_vec_double(max_length);
    double *y_ptr = bench_vec_double(max_length);

    for (uint32_t i = 0; i < n_lengths; i++) {
        uint32_t length = lengths[i];

        uint32_t n_iter = TARGET_ELEMENTS / length; 
        if (n_iter < 10000) n_iter = 10000; 
        uint32_t n_warm = n_iter / 10;

        BENCH(neon_time, n_iter, n_warm, ddot_neon(x_ptr, y_ptr, length));
        BENCH(sve_time, n_iter, n_warm, ddot_sve(x_ptr, y_ptr, length));
        BENCH(sme_time, n_iter, n_warm, ddot_sme8xVGx4(x_ptr, y_ptr, length));
        BENCH(main_time, n_iter, n_warm, ddot(x_ptr, y_ptr, length));

        display_bench("ddot", neon_time, sve_time, sme_time, main_time, length, i == 0 ? 1 : 0); 
    }

    free(x_ptr);
    free(y_ptr);

    return 0;
} 

