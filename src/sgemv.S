.text

.global _sgemv
.p2align 4

_sgemv:
    cmp     w3, #16
    b.ls    _sgemv_neon

    mul     w5, w3, w4
    cmp     w5, #1536
    b.ls    _sgemv_neon

    cmp     w3, #32
    b.hi    _sgemv_sme
    cmp     w4, #64
    b.ls    _sgemv_neon
    b       _sgemv_sme


.global _sgemv_neon
.p2align 4

_sgemv_neon:
    cmp     w3, #16
    b.ls    _sgemv_neon_i_outer

    mul     w5, w3, w4
    cmp     w5, #2048
    b.ls    _sgemv_neon_i_outer

    cmp     w3, #32
    b.hi    _sgemv_neon_j_outer
    cmp     w4, #128
    b.ls    _sgemv_neon_i_outer
    b       _sgemv_neon_j_outer


.global _sgemv_neon_i_outer
.p2align 4

_sgemv_neon_i_outer:
    mov     w5, #0
    cmp     w3, #16
    b.lo    .Li_rows4

.Li_rows16_loop:
    add     x9, x2, w5, uxtw #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

    mov     w6, #0

.Li_16x4_loop:
    add     w8, w6, #4
    cmp     w8, w4
    b.hi    .Li_16x1

    add     x10, x1, w6, uxtw #2
    ldr     q20, [x10]
    fmul    v20.4s, v20.4s, v0.s[0]

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #2

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[1]
    fmla    v17.4s, v22.4s, v20.s[1]
    fmla    v18.4s, v23.4s, v20.s[1]
    fmla    v19.4s, v24.4s, v20.s[1]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[2]
    fmla    v17.4s, v22.4s, v20.s[2]
    fmla    v18.4s, v23.4s, v20.s[2]
    fmla    v19.4s, v24.4s, v20.s[2]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[3]
    fmla    v17.4s, v22.4s, v20.s[3]
    fmla    v18.4s, v23.4s, v20.s[3]
    fmla    v19.4s, v24.4s, v20.s[3]

    mov     w6, w8
    b       .Li_16x4_loop

.Li_16x1:
    cmp     w6, w4
    b.hs    .Li_16_store

.Li_16x1_loop:
    add     x10, x1, w6, uxtw #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_16x1_loop

.Li_16_store:
    add     x9, x2, w5, uxtw #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w5, w5, #16
    sub     w7, w3, w5
    cmp     w7, #16
    b.hs    .Li_rows16_loop

.Li_rows4:
    sub     w7, w3, w5
    cmp     w7, #4
    b.lo    .Li_scalar

.Li_rows4_loop:
    add     x9, x2, w5, uxtw #2
    ldr     q16, [x9]
    fmul    v16.4s, v16.4s, v1.s[0]

    mov     w6, #0

.Li_4x4_loop:
    add     w8, w6, #4
    cmp     w8, w4
    b.hi    .Li_4x1

    add     x10, x1, w6, uxtw #2
    ldr     q20, [x10]
    fmul    v20.4s, v20.4s, v0.s[0]

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[1]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[2]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[3]

    mov     w6, w8
    b       .Li_4x4_loop

.Li_4x1:
    cmp     w6, w4
    b.hs    .Li_4_store

.Li_4x1_loop:
    add     x10, x1, w6, uxtw #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_4x1_loop

.Li_4_store:
    add     x9, x2, w5, uxtw #2
    str     q16, [x9]

    add     w5, w5, #4
    sub     w7, w3, w5
    cmp     w7, #4
    b.hs    .Li_rows4_loop

.Li_scalar:
    cmp     w5, w3
    b.hs    .Li_done

.Li_scalar_row_loop:
    add     x9, x2, w5, uxtw #2
    ldr     s16, [x9]
    fmul    s16, s16, s1

    mov     w6, #0
    cbz     w4, .Li_scalar_store

.Li_scalar_col_loop:
    add     x10, x1, w6, uxtw #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #2
    ldr     s21, [x10]
    fmadd   s16, s21, s20, s16

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_scalar_col_loop

.Li_scalar_store:
    str     s16, [x9]
    add     w5, w5, #1
    cmp     w5, w3
    b.lo    .Li_scalar_row_loop

.Li_done:
    ret


.global _sgemv_neon_j_outer
.p2align 4

_sgemv_neon_j_outer:
    mov     w5, #0
    cmp     w4, #4
    b.lo    .Lj_cols1

.Lj_cols4_loop:
    add     x9, x1, w5, uxtw #2
    ldr     q20, [x9]
    fmul    v20.4s, v20.4s, v0.s[0]

    mov     w6, #0
    cmp     w3, #16
    b.lo    .Lj_4_rows4

.Lj_4_rows16_loop:
    add     x9, x2, w6, uxtw #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    w5, .Lj_4_rows16_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

.Lj_4_rows16_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[1]
    fmla    v17.4s, v22.4s, v20.s[1]
    fmla    v18.4s, v23.4s, v20.s[1]
    fmla    v19.4s, v24.4s, v20.s[1]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[2]
    fmla    v17.4s, v22.4s, v20.s[2]
    fmla    v18.4s, v23.4s, v20.s[2]
    fmla    v19.4s, v24.4s, v20.s[2]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[3]
    fmla    v17.4s, v22.4s, v20.s[3]
    fmla    v18.4s, v23.4s, v20.s[3]
    fmla    v19.4s, v24.4s, v20.s[3]

    add     x9, x2, w6, uxtw #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w6, w6, #16
    sub     w7, w3, w6
    cmp     w7, #16
    b.hs    .Lj_4_rows16_loop

.Lj_4_rows4:
    sub     w7, w3, w6
    cmp     w7, #4
    b.lo    .Lj_4_scalar

.Lj_4_rows4_loop:
    add     x9, x2, w6, uxtw #2
    ldr     q16, [x9]

    cbnz    w5, .Lj_4_rows4_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]

.Lj_4_rows4_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[1]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[2]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[3]

    add     x9, x2, w6, uxtw #2
    str     q16, [x9]

    add     w6, w6, #4
    sub     w7, w3, w6
    cmp     w7, #4
    b.hs    .Lj_4_rows4_loop

.Lj_4_scalar:
    cmp     w6, w3
    b.hs    .Lj_4_next

.Lj_4_scalar_loop:
    add     x9, x2, w6, uxtw #2
    ldr     s16, [x9]

    cbnz    w5, .Lj_4_scalar_accumulate
    fmul    s16, s16, s1

.Lj_4_scalar_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2

    ldr     s21, [x10]
    fmla    s16, s21, v20.s[0]
    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[1]
    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[2]
    add     w7, w7, w3
    add     x10, x0, w7, uxtw #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[3]

    str     s16, [x9]
    add     w6, w6, #1
    cmp     w6, w3
    b.lo    .Lj_4_scalar_loop

.Lj_4_next:
    add     w5, w5, #4
    sub     w7, w4, w5
    cmp     w7, #4
    b.hs    .Lj_cols4_loop

.Lj_cols1:
    cmp     w5, w4
    b.hs    .Lj_done

.Lj_cols1_loop:
    add     x9, x1, w5, uxtw #2
    ldr     s20, [x9]
    fmul    s20, s20, s0

    mov     w6, #0
    cmp     w3, #16
    b.lo    .Lj_1_rows4

.Lj_1_rows16_loop:
    add     x9, x2, w6, uxtw #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    w5, .Lj_1_rows16_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

.Lj_1_rows16_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     x9, x2, w6, uxtw #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w6, w6, #16
    sub     w7, w3, w6
    cmp     w7, #16
    b.hs    .Lj_1_rows16_loop

.Lj_1_rows4:
    sub     w7, w3, w6
    cmp     w7, #4
    b.lo    .Lj_1_scalar

.Lj_1_rows4_loop:
    add     x9, x2, w6, uxtw #2
    ldr     q16, [x9]

    cbnz    w5, .Lj_1_rows4_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]

.Lj_1_rows4_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]
    str     q16, [x9]

    add     w6, w6, #4
    sub     w7, w3, w6
    cmp     w7, #4
    b.hs    .Lj_1_rows4_loop

.Lj_1_scalar:
    cmp     w6, w3
    b.hs    .Lj_1_next

.Lj_1_scalar_loop:
    add     x9, x2, w6, uxtw #2
    ldr     s16, [x9]

    cbnz    w5, .Lj_1_scalar_accumulate
    fmul    s16, s16, s1

.Lj_1_scalar_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #2
    ldr     s21, [x10]
    fmadd   s16, s21, s20, s16
    str     s16, [x9]

    add     w6, w6, #1
    cmp     w6, w3
    b.lo    .Lj_1_scalar_loop

.Lj_1_next:
    add     w5, w5, #1
    cmp     w5, w4
    b.lo    .Lj_cols1_loop

.Lj_done:
    ret


.global _sgemv_sme
.p2align 4

_sgemv_sme:
    rdsvl   x5, #1
    cmp     x5, #32
    b.lo    _sgemv_sme4xVGx4
    b       _sgemv_sme8xVGx4


.global _sgemv_sme8xVGx4
.p2align 4

/// alpha   s0
/// beta    s1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.s = dup alpha
//  z1.s = dup beta
//
//  x5 = cntw
//  x6 = j
//  x7 = i
//
//  w8 = first ZA group
//  w9 = second ZA group, spaced halfway across ZA
//
//  keep 8xVGx4 worth of y in ZA live, so 32 SVL's.
//
//  loop over i:
//      load z1.s * y[i .. i + 32 * x5] into ZA
//      loop over j:
//          z3.s = dup z0.s * x[j]
//          {z4.s-z7.s} = A[j * m + i .. j * m + i + 4 * x5]
//          za.s[w8, 0, vgx4] += {z4.s-z7.s} * z3.s
//          ...
//          za.s[w9, 3, vgx4] += {z16.s-z19.s} * z3.s
//      store ZA into y[i .. i + 32 * x5]
//
//  leftover rows:
//      keep 4xVGx4 or 1xVGx4 worth of y in ZA live.
_sgemv_sme8xVGx4:
    mov     w3, w3
    mov     w4, w4

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w5, s0
    fmov    w6, s1

    smstart

    fmov    s0, w5
    dup     z0.s, z0.s[0]
    fmov    s1, w6
    dup     z1.s, z1.s[0]

    cntw    x5
    mov     x7, #0
    mov     w8, #0
    lsr     w9, w5, #1

.Lsme_8xVGx4_i_loop:
    cmp     x7, x3
    b.hs    .Lsme_8xVGx4_done

    sub     x10, x3, x7
    lsl     x11, x5, #2
    cmp     x10, x11
    b.ls    .Lsme_8xVGx4_1x_tail
    lsl     x11, x5, #4
    cmp     x10, x11
    b.ls    .Lsme_8xVGx4_4x_tail

    mov     x10, x7
    whilelo pn8.s, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn12.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn13.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn14.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn15.s, x10, x3, vlx4

    mov     x10, x7
    ld1w    {z4.s-z7.s}, pn8/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn9/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn10/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn11/z, [x2, x10, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s
    fmul    z8.s, z8.s, z1.s
    fmul    z9.s, z9.s, z1.s
    fmul    z10.s, z10.s, z1.s
    fmul    z11.s, z11.s, z1.s
    fmul    z12.s, z12.s, z1.s
    fmul    z13.s, z13.s, z1.s
    fmul    z14.s, z14.s, z1.s
    fmul    z15.s, z15.s, z1.s
    fmul    z16.s, z16.s, z1.s
    fmul    z17.s, z17.s, z1.s
    fmul    z18.s, z18.s, z1.s
    fmul    z19.s, z19.s, z1.s

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w8, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w8, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w8, 3, vgx4], {z16.s-z19.s}

    add     x10, x10, x5, lsl #2
    ld1w    {z4.s-z7.s}, pn12/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn13/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn14/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn15/z, [x2, x10, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s
    fmul    z8.s, z8.s, z1.s
    fmul    z9.s, z9.s, z1.s
    fmul    z10.s, z10.s, z1.s
    fmul    z11.s, z11.s, z1.s
    fmul    z12.s, z12.s, z1.s
    fmul    z13.s, z13.s, z1.s
    fmul    z14.s, z14.s, z1.s
    fmul    z15.s, z15.s, z1.s
    fmul    z16.s, z16.s, z1.s
    fmul    z17.s, z17.s, z1.s
    fmul    z18.s, z18.s, z1.s
    fmul    z19.s, z19.s, z1.s

    mov     za.s[w9, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w9, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w9, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w9, 3, vgx4], {z16.s-z19.s}

    mov     x6, #0
    mov     x11, x1

.Lsme_8xVGx4_j_loop:
    whilelo p0.s, x6, x4
    b.none  .Lsme_8xVGx4_store

    ldr     s3, [x11], #4
    fmul    s3, s3, s0
    dup     z3.s, z3.s[0]

    madd    x10, x6, x3, x7

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x10, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x10, x10, x5, lsl #2
    ld1w    {z4.s-z7.s}, pn12/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn13/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn14/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn15/z, [x0, x10, lsl #2]

    fmla    za.s[w9, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w9, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w9, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w9, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x6, x6, #1
    b       .Lsme_8xVGx4_j_loop

.Lsme_8xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4]

    mov     x10, x7
    st1w    {z4.s-z7.s}, pn8, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z8.s-z11.s}, pn9, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z12.s-z15.s}, pn10, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z16.s-z19.s}, pn11, [x2, x10, lsl #2]

    mov     {z4.s-z7.s}, za.s[w9, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w9, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w9, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w9, 3, vgx4]

    add     x10, x10, x5, lsl #2
    st1w    {z4.s-z7.s}, pn12, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z8.s-z11.s}, pn13, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z12.s-z15.s}, pn14, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z16.s-z19.s}, pn15, [x2, x10, lsl #2]

    incw    x7, all, mul #16
    incw    x7, all, mul #16
    b       .Lsme_8xVGx4_i_loop

.Lsme_8xVGx4_4x_tail:
    mov     x10, x7
    whilelo pn8.s, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.s, x10, x3, vlx4

    mov     x10, x7
    ld1w    {z4.s-z7.s}, pn8/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn9/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn10/z, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn11/z, [x2, x10, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s
    fmul    z8.s, z8.s, z1.s
    fmul    z9.s, z9.s, z1.s
    fmul    z10.s, z10.s, z1.s
    fmul    z11.s, z11.s, z1.s
    fmul    z12.s, z12.s, z1.s
    fmul    z13.s, z13.s, z1.s
    fmul    z14.s, z14.s, z1.s
    fmul    z15.s, z15.s, z1.s
    fmul    z16.s, z16.s, z1.s
    fmul    z17.s, z17.s, z1.s
    fmul    z18.s, z18.s, z1.s
    fmul    z19.s, z19.s, z1.s

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w8, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w8, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w8, 3, vgx4], {z16.s-z19.s}

    mov     x6, #0
    mov     x11, x1

.Lsme_8xVGx4_4x_j_loop:
    whilelo p0.s, x6, x4
    b.none  .Lsme_8xVGx4_4x_store

    ldr     s3, [x11], #4
    fmul    s3, s3, s0
    dup     z3.s, z3.s[0]

    madd    x10, x6, x3, x7

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x10, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x6, x6, #1
    b       .Lsme_8xVGx4_4x_j_loop

.Lsme_8xVGx4_4x_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4]

    mov     x10, x7
    st1w    {z4.s-z7.s}, pn8, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z8.s-z11.s}, pn9, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z12.s-z15.s}, pn10, [x2, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    st1w    {z16.s-z19.s}, pn11, [x2, x10, lsl #2]
    b       .Lsme_8xVGx4_done

.Lsme_8xVGx4_1x_tail:
    whilelo pn8.s, x7, x3, vlx4
    b.none  .Lsme_8xVGx4_done

    ld1w    {z4.s-z7.s}, pn8/z, [x2, x7, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}

    mov     x6, #0
    mov     x11, x1

.Lsme_8xVGx4_1x_j_loop:
    whilelo p0.s, x6, x4
    b.none  .Lsme_8xVGx4_1x_store

    ldr     s3, [x11], #4
    fmul    s3, s3, s0
    dup     z3.s, z3.s[0]

    madd    x10, x6, x3, x7
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s

    add     x6, x6, #1
    b       .Lsme_8xVGx4_1x_j_loop

.Lsme_8xVGx4_1x_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    st1w    {z4.s-z7.s}, pn8, [x2, x7, lsl #2]

.Lsme_8xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret


.global _sgemv_sme4xVGx4
.p2align 4

/// alpha   s0
/// beta    s1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.s = dup alpha
//  z1.s = dup beta
//
//  x5 = cntw
//  x6 = j
//  x7 = i
//
//  keep 4xVGx4 worth of y in ZA live, so 16 SVL's.
//
//  za.s[w8, 0, vgx4] = z1.s * y[i .. i + 4 * x5 ]
//  za.s[w8, 1, vgx4] = z1.s * y[i + 4cntw .. i + 8 * x5]
//  za.s[w8, 2, vgx4] = z1.s * y[i + 8cntw .. i + 12 * x5]
//  za.s[w8, 3, vgx4] = z1.s * y[i + 12cntw .. i + 16 * x5]
//
//  loop over i:
//      load z1.s * y[i .. i + 16 * x5] into ZA
//      loop over j:
//          z3.s = dup z0.s * x[j]
//          {z4.s-z7.s} = A[j * m + i .. j * m + i + 4 * x5]
//          za.s[w8, 0, vgx4] += {z4.s-z7.s} * z3.s
//          ...
//          za.s[w8, 3, vgx4] += {z16.s-z19.s} * z3.s
//      store ZA into y[i .. i + 16 * x5]
//
//  leftover rows:
//      keep 1xVGx4 worth of y in ZA live, so 4 SVL's.
_sgemv_sme4xVGx4:
    mov     w3, w3
    mov     w4, w4

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w5, s0
    fmov    w6, s1

    smstart

    fmov    s0, w5
    dup     z0.s, z0.s[0]
    fmov    s1, w6
    dup     z1.s, z1.s[0]

    cntw    x5
    mov     x7, #0
    mov     w8, #0

.Lsme_4xVGx4_i_loop:
    cmp     x7, x3
    b.hs    .Lsme_4xVGx4_done

    sub     x9, x3, x7
    lsl     x10, x5, #2
    cmp     x9, x10
    b.ls    .Lsme_1xVGx4_tail

    mov     x12, x7
    add     x13, x12, x5, lsl #2
    add     x14, x13, x5, lsl #2
    add     x15, x14, x5, lsl #2

    whilelo pn8.s, x12, x3, vlx4
    b.none  .Lsme_4xVGx4_done
    whilelo pn9.s, x13, x3, vlx4
    whilelo pn10.s, x14, x3, vlx4
    whilelo pn11.s, x15, x3, vlx4

    ld1w    {z4.s-z7.s}, pn8/z, [x2, x12, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x2, x13, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x2, x14, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x2, x15, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s
    fmul    z8.s, z8.s, z1.s
    fmul    z9.s, z9.s, z1.s
    fmul    z10.s, z10.s, z1.s
    fmul    z11.s, z11.s, z1.s
    fmul    z12.s, z12.s, z1.s
    fmul    z13.s, z13.s, z1.s
    fmul    z14.s, z14.s, z1.s
    fmul    z15.s, z15.s, z1.s
    fmul    z16.s, z16.s, z1.s
    fmul    z17.s, z17.s, z1.s
    fmul    z18.s, z18.s, z1.s
    fmul    z19.s, z19.s, z1.s

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w8, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w8, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w8, 3, vgx4], {z16.s-z19.s}

    mov     x6, #0
    mov     x11, x1

.Lsme_4xVGx4_j_loop:
    whilelo p0.s, x6, x4
    b.none  .Lsme_4xVGx4_store

    ldr     s3, [x11], #4
    fmul    s3, s3, s0
    dup     z3.s, z3.s[0]

    madd    x10, x6, x3, x7

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x10, lsl #2]
    add     x10, x10, x5, lsl #2
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x10, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x6, x6, #1
    b       .Lsme_4xVGx4_j_loop

.Lsme_4xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x2, x12, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x2, x13, lsl #2]
    st1w    {z12.s-z15.s}, pn10, [x2, x14, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x2, x15, lsl #2]

    incw    x7, all, mul #16
    b       .Lsme_4xVGx4_i_loop

.Lsme_1xVGx4_tail:
    whilelo pn8.s, x7, x3, vlx4
    b.none  .Lsme_4xVGx4_done

    ld1w    {z4.s-z7.s}, pn8/z, [x2, x7, lsl #2]

    fmul    z4.s, z4.s, z1.s
    fmul    z5.s, z5.s, z1.s
    fmul    z6.s, z6.s, z1.s
    fmul    z7.s, z7.s, z1.s

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}

    mov     x6, #0
    mov     x11, x1

.Lsme_1xVGx4_j_loop:
    whilelo p0.s, x6, x4
    b.none  .Lsme_1xVGx4_store

    ldr     s3, [x11], #4
    fmul    s3, s3, s0
    dup     z3.s, z3.s[0]

    madd    x10, x6, x3, x7
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s

    add     x6, x6, #1
    b       .Lsme_1xVGx4_j_loop

.Lsme_1xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    st1w    {z4.s-z7.s}, pn8, [x2, x7, lsl #2]

.Lsme_4xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
