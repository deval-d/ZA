#include "helpers.h"
#include "kernels.h"
#include <string.h>

#define TARGET_ELEMENTS 10000000

int main(void) { 
    double neon_time; 
    double main_time;

    uint32_t lengths[] = L1_LENGTHS;
    uint32_t n_lengths = sizeof(lengths) / sizeof(lengths[0]);

    uint32_t max_length = lengths[n_lengths - 1];
    float *x_ptr = bench_vec_float(max_length);

    for (uint32_t i = 0; i < n_lengths; i++) {
        uint32_t length = lengths[i];

        uint32_t n_iter = TARGET_ELEMENTS / length; 
        if (n_iter < 10000) n_iter = 10000; 
        uint32_t n_warm = n_iter / 10;

        BENCH(neon_time, n_iter, n_warm, snrm2_neon(x_ptr, length));
        BENCH(main_time, n_iter, n_warm, snrm2(x_ptr, length));

        if (i == 0) {
            printf(
                "%-10s %6s | %12s %12s %12s\n",
                "routine", "length", "neon (s)", "main (s)", "main speedup"
            );
        }
        printf(
            "%-10s %6u | %12.5g %12.5g %11.6fx\n",
            "snrm2", length, neon_time, main_time, neon_time / main_time
        );
    }

    free(x_ptr);

    return 0;
} 


