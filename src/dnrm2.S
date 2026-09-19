.text

.global _dnrm2 
.p2align 4 

_dnrm2: 
    b    _dnrm2_neon


.global _dnrm2_neon
.p2align 4

_dnrm2_neon:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    mov     x8, x0

    movi    v0.2d, #0
    movi    v1.2d, #0
    movi    v2.2d, #0
    movi    v3.2d, #0

    cbz     w2, .Lneon_max_2

.Lneon_max_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fabs    v16.2d, v16.2d
    fabs    v17.2d, v17.2d
    fabs    v18.2d, v18.2d
    fabs    v19.2d, v19.2d

    fmax    v0.2d, v0.2d, v16.2d
    fmax    v1.2d, v1.2d, v17.2d
    fmax    v2.2d, v2.2d, v18.2d
    fmax    v3.2d, v3.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_max_8_loop

.Lneon_max_2:
    cbz     w3, .Lneon_max_reduce

.Lneon_max_2_loop:
    ldr     q16, [x8], #16
    fabs    v16.2d, v16.2d
    fmax    v0.2d, v0.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_max_2_loop

.Lneon_max_reduce:
    fmax    v0.2d, v0.2d, v1.2d
    fmax    v2.2d, v2.2d, v3.2d
    fmax    v0.2d, v0.2d, v2.2d
    fmaxp   d0, v0.2d

    cbz     w4, .Lneon_scale

.Lneon_max_scalar_loop:
    ldr     d16, [x8], #8
    fabs    d16, d16
    fmax    d0, d0, d16

    subs    w4, w4, #1
    b.ne    .Lneon_max_scalar_loop

.Lneon_scale:
    fcmp    d0, #0.0
    b.eq    .Lneon_done
    fcmp    d0, d0
    b.vs    .Lneon_done

    fmov    x6, d0
    mov     x7, #0x7ff0000000000000
    cmp     x6, x7
    b.eq    .Lneon_done

    lsr     x7, x6, #52
    and     x7, x7, #0x7ff
    cmp     x7, #2045
    b.hs    .Lneon_divide_scale
    cbz     x7, .Lneon_divide_scale

    fmov    d1, #1.0
    fdiv    d1, d1, d0
    dup     v1.2d, v1.d[0]
    mov     w6, #0
    b       .Lneon_sum_setup

.Lneon_divide_scale:
    dup     v1.2d, v0.d[0]
    mov     w6, #1

.Lneon_sum_setup:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    mov     x8, x0

    movi    v2.2d, #0
    movi    v3.2d, #0
    movi    v4.2d, #0
    movi    v5.2d, #0

    cbnz    w6, .Lneon_divide_8
    cbz     w2, .Lneon_sum_2

.Lneon_sum_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fmul    v16.2d, v16.2d, v1.2d
    fmul    v17.2d, v17.2d, v1.2d
    fmul    v18.2d, v18.2d, v1.2d
    fmul    v19.2d, v19.2d, v1.2d

    fmla    v2.2d, v16.2d, v16.2d
    fmla    v3.2d, v17.2d, v17.2d
    fmla    v4.2d, v18.2d, v18.2d
    fmla    v5.2d, v19.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_sum_8_loop
    b       .Lneon_sum_2

.Lneon_divide_8:
    cbz     w2, .Lneon_divide_2

.Lneon_divide_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fdiv    v16.2d, v16.2d, v1.2d
    fdiv    v17.2d, v17.2d, v1.2d
    fdiv    v18.2d, v18.2d, v1.2d
    fdiv    v19.2d, v19.2d, v1.2d

    fmla    v2.2d, v16.2d, v16.2d
    fmla    v3.2d, v17.2d, v17.2d
    fmla    v4.2d, v18.2d, v18.2d
    fmla    v5.2d, v19.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_divide_8_loop

.Lneon_divide_2:
    cbz     w3, .Lneon_sum_reduce

.Lneon_divide_2_loop:
    ldr     q16, [x8], #16
    fdiv    v16.2d, v16.2d, v1.2d
    fmla    v2.2d, v16.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_divide_2_loop
    b       .Lneon_sum_reduce

.Lneon_sum_2:
    cbz     w3, .Lneon_sum_reduce

.Lneon_sum_2_loop:
    ldr     q16, [x8], #16
    fmul    v16.2d, v16.2d, v1.2d
    fmla    v2.2d, v16.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_sum_2_loop

.Lneon_sum_reduce:
    fadd    v2.2d, v2.2d, v3.2d
    fadd    v4.2d, v4.2d, v5.2d
    fadd    v2.2d, v2.2d, v4.2d
    faddp   d2, v2.2d

    cbz     w4, .Lneon_sqrt
    cbnz    w6, .Lneon_scalar_divide_loop

.Lneon_scalar_loop:
    ldr     d16, [x8], #8
    fmul    d16, d16, d1
    fmadd   d2, d16, d16, d2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_loop
    b       .Lneon_sqrt

.Lneon_scalar_divide_loop:
    ldr     d16, [x8], #8
    fdiv    d16, d16, d1
    fmadd   d2, d16, d16, d2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_divide_loop

.Lneon_sqrt:
    fsqrt   d2, d2
    fmul    d0, d0, d2

.Lneon_done:
    ret
