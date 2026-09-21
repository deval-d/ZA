#ifndef BENCH_HELPERS_H
#define BENCH_HELPERS_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define L1_LENGTHS {4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384}

#define L2_SIZES { \
    {4, 4}, {8, 8}, {16, 16}, {32, 32}, {64, 64}, {128, 128}, \
    {256, 256}, {512, 512}, {1024, 1024}, {1536, 1536}, {2048, 2048}, \
    {16, 256}, {256, 16}, {32, 1024}, {1024, 32}, \
    {64, 2048}, {2048, 64}, {256, 1024}, {1024, 256}, \
    {512, 2048}, {2048, 512} \
}

#define BENCH(result, n_iter, n_warm, expr) do {        \
    for (uint32_t _i = 0; _i < (n_warm); _i++) expr;    \
                                                        \
    clock_t _beg = clock();                             \
    for (uint32_t _j = 0; _j < (n_iter); _j++) expr;    \
    clock_t _end = clock();                             \
                                                        \
    (result) = (double) (_end - _beg)                   \
        / CLOCKS_PER_SEC                                \
        / (double) (n_iter);                            \
} while(0) 

static float* bench_vec_float(uint32_t length) {
    float *buffer = malloc(length * sizeof(*buffer));

    for (uint32_t idx = 0; idx < length; idx++) {
        buffer[idx] = (float) rand() / RAND_MAX; 
    }

    return buffer; 
}

static double* bench_vec_double(uint32_t length) {
    double *buffer = malloc(length * sizeof(*buffer));

    for (uint32_t idx = 0; idx < length; idx++) {
        buffer[idx] = (double) rand() / RAND_MAX;
    }

    return buffer;
}

static void display_bench(
    char* routine, 
    double neon_s, 
    double sve_s,
    double sme_s,
    double main_s, 
    uint32_t length, 
    int title 
) {
    if (title) { 
        printf(
            "%-10s %6s | %12s %12s %12s %12s %12s %12s %12s\n", 
            "routine",
            "length",
            "neon (s)",
            "sve (s)",
            "sme (s)", 
            "main (s)",
            "sve speedup",
            "sme speedup", 
            "main speedup"
        );
    }
    printf(
        "%-10s %6u | %12.5g %12.5g %12.5g %12.5g %11.6fx %11.6fx %11.6fx\n",
        routine, 
        (unsigned int) length,
        neon_s,
        sve_s,
        sme_s,
        main_s, 
        neon_s / sve_s, 
        neon_s / sme_s, 
        neon_s / main_s
    ); 
}

static void display_bench_l2(
    char* routine,
    double neon_s,
    double sme4_s,
    double sme8_s,
    double main_s,
    uint32_t m,
    uint32_t n,
    int title
) {
    if (title) {
        printf(
            "%-10s %6s %6s | %12s %12s %12s %12s %12s %12s %12s\n",
            "routine",
            "m",
            "n",
            "neon (s)",
            "sme4 (s)",
            "sme8 (s)",
            "main (s)",
            "sme4 speedup",
            "sme8 speedup",
            "main speedup"
        );
    }
    printf(
        "%-10s %6u %6u | %12.5g %12.5g %12.5g %12.5g %11.6fx %11.6fx %11.6fx\n",
        routine,
        (unsigned int) m,
        (unsigned int) n,
        neon_s,
        sme4_s,
        sme8_s,
        main_s,
        neon_s / sme4_s,
        neon_s / sme8_s,
        neon_s / main_s
    );
}

#endif 
