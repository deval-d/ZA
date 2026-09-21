#ifndef TEST_HELPERS_H
#define TEST_HELPERS_H 

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MIN_RAND_FLOAT -100.0f
#define MAX_RAND_FLOAT  100.0f 
#define ATOL_FLOAT 1e-6
#define RTOL_FLOAT 1e-6

#define MIN_RAND_DOUBLE -100.0
#define MAX_RAND_DOUBLE  100.0
#define ATOL_DOUBLE 1e-12
#define RTOL_DOUBLE 1e-12

#define L1_LENGTHS {0, 1, 2, 3, 4, 5, 6, 7, 8, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 255, 256, 511, 512, 513, 1023, 1024}

#define L2_SIZES { \
    {4, 4}, {8, 8}, {16, 16}, {32, 32}, {64, 64}, {128, 128}, \
    {256, 256}, {512, 512}, {1024, 1024}, {1536, 1536}, {2048, 2048}, \
    {16, 256}, {256, 16}, {32, 1024}, {1024, 32}, \
    {64, 2048}, {2048, 64}, {256, 1024}, {1024, 256}, \
    {512, 2048}, {2048, 512} \
}

static float* random_vec_float(uint32_t length) { 
    float *buffer = malloc(length * sizeof(*buffer)); 

    float random_number; 
    for (uint32_t idx = 0; idx < length; idx++) {
        random_number = MIN_RAND_FLOAT + ((float) rand() 
            / RAND_MAX) * (MAX_RAND_FLOAT - MIN_RAND_FLOAT);   

        buffer[idx] = random_number;
    }

    return buffer;
}

static int assert_eq_vec_float(float *measured, float *expected, uint32_t length) {
    int result = 0; 
    for (uint32_t idx = 0; idx < length; idx++) {
        float diff = fabsf(expected[idx] - measured[idx]);

        if (diff >= ATOL_FLOAT + RTOL_FLOAT * fabsf(expected[idx])) { 
            result = 1; 
            printf(
                "measured: %12.9g, expected: %12.9g, diff: %12.9g\n", 
                measured[idx], 
                expected[idx],
                diff 
            );
        }
    }

    return result; 
}

static double* random_vec_double(uint32_t length) {
    double *buffer = malloc(length * sizeof(*buffer));

    double random_number;
    for (uint32_t idx = 0; idx < length; idx++) {
        random_number = MIN_RAND_DOUBLE + ((double) rand()
            / RAND_MAX) * (MAX_RAND_DOUBLE - MIN_RAND_DOUBLE);

        buffer[idx] = random_number;
    }

    return buffer;
}

static int assert_eq_vec_double(double *measured, double *expected, uint32_t length) {
    int result = 0;
    for (uint32_t idx = 0; idx < length; idx++) {
        double diff = fabs(expected[idx] - measured[idx]);

        if (diff >= ATOL_DOUBLE + RTOL_DOUBLE * fabs(expected[idx])) {
            result = 1;
            printf(
                "measured: %18.17g, expected: %18.17g, diff: %18.17g\n",
                measured[idx],
                expected[idx],
                diff
            );
        }
    }

    return result;
}


#endif
