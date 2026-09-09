#ifndef TEST_HELPERS_H
#define TEST_HELPERS_H 

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MIN_RAND_FLOAT -10000.0f
#define MAX_RAND_FLOAT  10000.0f 
#define ATOL_FLOAT 1e-6
#define RTOL_FLOAT 1e-6

#define L1_LENGTHS {0, 1, 2, 3, 4, 5, 6, 7, 8, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 255, 256, 511, 512, 513, 1023, 1024}

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
                "measured: %10.5g, expected: %10.5g, diff: %10.5g\n", 
                measured[idx], 
                expected[idx],
                diff 
            );
        }
    }

    return result; 
}


#endif
