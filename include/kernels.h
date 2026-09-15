#ifndef KERNELS_H
#define KERNELS_H

#include <stdint.h>


/// NEON implementation
extern void saxpy_neon(float alpha, float *x_ptr, float *y_ptr, uint32_t n);
/// SVE implementation
extern void saxpy_sve(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits 
extern void saxpy_sme8xVGx4(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits 
extern void saxpy_sme4xVGx4(float alpha, float *x_ptr, float *y_ptr, uint32_t n);

/// main optimized `saxpy` 
///
/// `y += alpha * x` 
/// 
/// dispatches to 
///     NEON for n < 512 
///     SME  for n >= 512   
///
/// SME kernel is chosen based on the physical SVL. 
extern void saxpy(float alpha, float *x_ptr, float *y_ptr, uint32_t n);


/// NEON implementation 
extern void sscal_neon(float alpha, float *x_ptr, uint32_t n);
/// SVE implementation 
extern void sscal_sve(float alpha, float *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits 
extern void sscal_sme8xVGx4(float alpha, float *x_ptr, uint32_t n);
/// SME implementation for hardware with SVL = 128 bits 
extern void sscal_sme4xVGx4(float alpha, float *x_ptr, uint32_t n);

/// main optimized `sscal` 
///
/// `x *= alpha` 
/// 
/// dispatches to 
///     NEON for n < 1024 
///     SME  for n >= 1024   
///
/// SME kernel is chosen based on the physical SVL. 
extern void sscal(float alpha, float *x_ptr, uint32_t n); 


/// NEON implementation 
extern float sdot_neon(float *x_ptr, float *y_ptr, uint32_t n);
/// SVE implementation 
extern float sdot_sve(float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits 
extern float sdot_sme8xVGx4(float *x_ptr, float *y_ptr, uint32_t n);
/// SME implementation for hardware with SVL = 128 bits 
extern float sdot_sme4xVGx4(float *x_ptr, float *y_ptr, uint32_t n);

/// main optimized `sdot`
///
/// `x · y` 
///
/// dispatches to 
///     NEON for n < 1750 
///     SME  for n >= 1750
///
/// SME kernel is chosen based on the physical SVL. 
extern float sdot(float *x_ptr, float *y_ptr, uint32_t n);

#endif
