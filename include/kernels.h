#ifndef KERNELS_H
#define KERNELS_H

#include <stdint.h>

// src/saxpy.S
extern void saxpy_neon(float alpha, float *x_ptr, float *y_ptr, uint32_t length);
extern void saxpy_sve(float alpha, float *x_ptr, float *y_ptr, uint32_t length);
extern void saxpy_sme(float alpha, float *x_ptr, float *y_ptr, uint32_t length);

#endif
