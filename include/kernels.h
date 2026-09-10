#ifndef KERNELS_H
#define KERNELS_H

#include <stdint.h>


/// NEON implementation
extern void saxpy_neon(float alpha, float *x_ptr, float *y_ptr, uint32_t n);
/// SVE implementation
extern void saxpy_sve(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits 
extern void saxpy_sme8(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits 
extern void saxpy_sme4(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// main optimized `saxpy` 
///
/// `y += alpha * x` 
/// 
/// dispatches to 
///     NEON for n < 512 
///     SME  for n >= 512   
///
/// SME kernel is chosen based on the physical SVL. 
extern void saxpy(float alpha, float *x_ptr, float *y_ptr, uint32_t length);

#endif
