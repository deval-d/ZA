#ifndef KERNELS_H
#define KERNELS_H

#include <stdint.h>

extern uint32_t isamax_neon(float *x_ptr, uint32_t n);
extern uint32_t isamax_sve(float *x_ptr, uint32_t n);

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


/// NEON implementation 
extern float sasum_neon(float *x_ptr, uint32_t n);
/// SVE implementation 
extern float sasum_sve(float *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits 
extern float sasum_sme8xVGx4(float *x_ptr, uint32_t n);
/// SME implementation for hardware with SVL = 128 bits 
extern float sasum_sme4xVGx4(float *x_ptr, uint32_t n);

/// main optimized `sasum`
///
/// `argmax(|x_i|)`
///
/// dispatches to 
///     NEON for n < 2725 
///     SME  for n >= 2725
///
/// SME kernel is chosen based on the physical SVL. 
extern float sasum(float *x_ptr, uint32_t n);


/// NEON implementation
extern void scopy_neon(float *x_ptr, float *y_ptr, uint32_t n);
/// SVE implementation
extern void scopy_sve(float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for any SVL hardware 
extern void scopy_sme(float *x_ptr, float *y_ptr, uint32_t n);


/// main optimized `scopy` 
///
/// `y <- x` 
/// 
/// dispatches to 
///     NEON for n < 496
///     SME  for n >= 496   
extern void scopy(float *x_ptr, float *y_ptr, uint32_t n);


/// NEON implementation
extern void sswap_neon(float *x_ptr, float *y_ptr, uint32_t n);
/// SVE implementation
extern void sswap_sve(float *x_ptr, float *y_ptr, uint32_t n);

/// SME implementation for any SVL hardware
extern void sswap_sme(float *x_ptr, float *y_ptr, uint32_t n);


/// main optimized `sswap`
///
/// `y <-> x`
///
/// dispatches to SME for:
///     n == 320
///     380 <= n <= 384
///     424 <= n <= 448
///     n >= 472
/// and to NEON otherwise.
extern void sswap(float *x_ptr, float *y_ptr, uint32_t n);


/// NEON implementation 
extern float snrm2_neon(float *x_ptr, uint32_t n);

/// SVE implementation 
extern float snrm2_sve(float *x_ptr, uint32_t n);

/// main optimized `snrm2`
///
/// `sqrt(sum(|x_i|^2))` 
///
/// dispatches to 
///     NEON for all n
extern float snrm2(float *x_ptr, uint32_t n);


/// NEON implementation 
extern uint32_t isamax_neon(float *x_ptr, uint32_t n);

/// main optimized `isamax`
///
/// `sum(|x_i|)` 
///
/// dispatches to 
///     NEON for all n 
extern uint32_t isamax(float *x_ptr, uint32_t n);


/// NEON implementation
extern void daxpy_neon(double alpha, double *x_ptr, double *y_ptr, uint32_t n);
/// SVE implementation
extern void daxpy_sve(double alpha, double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits
extern void daxpy_sme8xVGx4(double alpha, double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits
extern void daxpy_sme4xVGx4(double alpha, double *x_ptr, double *y_ptr, uint32_t n);

/// main optimized `daxpy`
///
/// `y += alpha * x`
///
/// dispatches to
///     NEON for n < 360
///     SME  for n >= 360
///
/// SME kernel is chosen based on the physical SVL.
extern void daxpy(double alpha, double *x_ptr, double *y_ptr, uint32_t n);


/// NEON implementation
extern void dscal_neon(double alpha, double *x_ptr, uint32_t n);
/// SVE implementation
extern void dscal_sve(double alpha, double *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits
extern void dscal_sme8xVGx4(double alpha, double *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits
extern void dscal_sme4xVGx4(double alpha, double *x_ptr, uint32_t n);

/// main optimized `dscal`
///
/// `x *= alpha`
///
/// dispatches to
///     NEON for n < 456
///     SME  for n >= 456
///
/// SME kernel is chosen based on the physical SVL.
extern void dscal(double alpha, double *x_ptr, uint32_t n);


/// NEON implementation
extern double ddot_neon(double *x_ptr, double *y_ptr, uint32_t n);
/// SVE implementation
extern double ddot_sve(double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits
extern double ddot_sme8xVGx4(double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits
extern double ddot_sme4xVGx4(double *x_ptr, double *y_ptr, uint32_t n);

/// main optimized `ddot`
///
/// `x · y`
///
/// dispatches to
///     NEON for n < 936
///     SME  for n >= 936
///
/// SME kernel is chosen based on the physical SVL.
extern double ddot(double *x_ptr, double *y_ptr, uint32_t n);


/// NEON implementation
extern double dasum_neon(double *x_ptr, uint32_t n);
/// SVE implementation
extern double dasum_sve(double *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL >= 256 bits
extern double dasum_sme8xVGx4(double *x_ptr, uint32_t n);

/// SME implementation for hardware with SVL = 128 bits
extern double dasum_sme4xVGx4(double *x_ptr, uint32_t n);

/// main optimized `dasum`
///
/// `sum(|x_i|)`
///
/// dispatches to
///     NEON for n < 1096
///     SME  for n >= 1096
///
/// SME kernel is chosen based on the physical SVL.
extern double dasum(double *x_ptr, uint32_t n);


/// NEON implementation
extern void dcopy_neon(double *x_ptr, double *y_ptr, uint32_t n);
/// SVE implementation
extern void dcopy_sve(double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for any SVL hardware
extern void dcopy_sme(double *x_ptr, double *y_ptr, uint32_t n);

/// main optimized `dcopy`
///
/// `y <- x`
///
/// dispatches to
///     NEON for n < 308
///     SME  for n >= 308
extern void dcopy(double *x_ptr, double *y_ptr, uint32_t n);


/// NEON implementation
extern void dswap_neon(double *x_ptr, double *y_ptr, uint32_t n);
/// SVE implementation
extern void dswap_sve(double *x_ptr, double *y_ptr, uint32_t n);

/// SME implementation for any SVL hardware
extern void dswap_sme(double *x_ptr, double *y_ptr, uint32_t n);

/// main optimized `dswap`
///
/// `y <-> x`
///
/// dispatches to SME for:
///     n == 160
///     190 <= n <= 192
///     212 <= n <= 224
///     n >= 236
/// and to NEON otherwise.
extern void dswap(double *x_ptr, double *y_ptr, uint32_t n);


/// NEON implementation
extern double dnrm2_neon(double *x_ptr, uint32_t n);

/// main optimized `dnrm2`
///
/// `sqrt(sum(|x_i|^2))`
///
/// dispatches to
///     NEON for all n
extern double dnrm2(double *x_ptr, uint32_t n);


/// NEON implementation
extern uint32_t idamax_neon(double *x_ptr, uint32_t n);
/// SVE implementation
extern uint32_t idamax_sve(double *x_ptr, uint32_t n);

/// main optimized `idamax`
///
/// `argmax(|x_i|)`
///
/// dispatches to
///     NEON for all n
extern uint32_t idamax(double *x_ptr, uint32_t n);

#endif
