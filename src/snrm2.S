.text

.global _snrm2 
.p2align 4 

_snrm2: 
    b    _snrm2_neon


.global _snrm2_neon
.p2align 4

_snrm2_neon:
    lsr     w2, w1, #4
    and     w3, w1, #15
    lsr     w3, w3, #2
    and     w4, w1, #3

    mov     x8, x0

    movi    v0.4s, #0
    movi    v1.4s, #0
    movi    v2.4s, #0
    movi    v3.4s, #0

    cbz     w2, .Lneon_max_4

.Lneon_max_16_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fabs    v16.4s, v16.4s
    fabs    v17.4s, v17.4s
    fabs    v18.4s, v18.4s
    fabs    v19.4s, v19.4s

    fmax    v0.4s, v0.4s, v16.4s
    fmax    v1.4s, v1.4s, v17.4s
    fmax    v2.4s, v2.4s, v18.4s
    fmax    v3.4s, v3.4s, v19.4s

    subs    w2, w2, #1
    b.ne    .Lneon_max_16_loop

.Lneon_max_4:
    cbz     w3, .Lneon_max_reduce

.Lneon_max_4_loop:
    ldr     q16, [x8], #16
    fabs    v16.4s, v16.4s
    fmax    v0.4s, v0.4s, v16.4s

    subs    w3, w3, #1
    b.ne    .Lneon_max_4_loop

.Lneon_max_reduce:
    fmax    v0.4s, v0.4s, v1.4s
    fmax    v2.4s, v2.4s, v3.4s
    fmax    v0.4s, v0.4s, v2.4s
    fmaxv   s0, v0.4s

    cbz     w4, .Lneon_scale

.Lneon_max_scalar_loop:
    ldr     s16, [x8], #4
    fabs    s16, s16
    fmax    s0, s0, s16

    subs    w4, w4, #1
    b.ne    .Lneon_max_scalar_loop

.Lneon_scale:
    fcmp    s0, #0.0
    b.eq    .Lneon_done
    fcmp    s0, s0
    b.vs    .Lneon_done

    fmov    w6, s0
    mov     w7, #0x7f800000
    cmp     w6, w7
    b.eq    .Lneon_done

    lsr     w7, w6, #23
    and     w7, w7, #0xff
    cmp     w7, #253
    b.hs    .Lneon_divide_scale
    cbz     w7, .Lneon_divide_scale

    fmov    s1, #1.0
    fdiv    s1, s1, s0
    dup     v1.4s, v1.s[0]
    mov     w6, #0
    b       .Lneon_sum_setup

.Lneon_divide_scale:
    dup     v1.4s, v0.s[0]
    mov     w6, #1

.Lneon_sum_setup:
    lsr     w2, w1, #4
    and     w3, w1, #15
    lsr     w3, w3, #2
    and     w4, w1, #3

    mov     x8, x0

    movi    v2.4s, #0
    movi    v3.4s, #0
    movi    v4.4s, #0
    movi    v5.4s, #0

    cbnz    w6, .Lneon_divide_16
    cbz     w2, .Lneon_sum_4

.Lneon_sum_16_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fmul    v16.4s, v16.4s, v1.4s
    fmul    v17.4s, v17.4s, v1.4s
    fmul    v18.4s, v18.4s, v1.4s
    fmul    v19.4s, v19.4s, v1.4s

    fmla    v2.4s, v16.4s, v16.4s
    fmla    v3.4s, v17.4s, v17.4s
    fmla    v4.4s, v18.4s, v18.4s
    fmla    v5.4s, v19.4s, v19.4s

    subs    w2, w2, #1
    b.ne    .Lneon_sum_16_loop
    b       .Lneon_sum_4

.Lneon_divide_16:
    cbz     w2, .Lneon_divide_4

.Lneon_divide_16_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fdiv    v16.4s, v16.4s, v1.4s
    fdiv    v17.4s, v17.4s, v1.4s
    fdiv    v18.4s, v18.4s, v1.4s
    fdiv    v19.4s, v19.4s, v1.4s

    fmla    v2.4s, v16.4s, v16.4s
    fmla    v3.4s, v17.4s, v17.4s
    fmla    v4.4s, v18.4s, v18.4s
    fmla    v5.4s, v19.4s, v19.4s

    subs    w2, w2, #1
    b.ne    .Lneon_divide_16_loop

.Lneon_divide_4:
    cbz     w3, .Lneon_sum_reduce

.Lneon_divide_4_loop:
    ldr     q16, [x8], #16
    fdiv    v16.4s, v16.4s, v1.4s
    fmla    v2.4s, v16.4s, v16.4s

    subs    w3, w3, #1
    b.ne    .Lneon_divide_4_loop
    b       .Lneon_sum_reduce

.Lneon_sum_4:
    cbz     w3, .Lneon_sum_reduce

.Lneon_sum_4_loop:
    ldr     q16, [x8], #16
    fmul    v16.4s, v16.4s, v1.4s
    fmla    v2.4s, v16.4s, v16.4s

    subs    w3, w3, #1
    b.ne    .Lneon_sum_4_loop

.Lneon_sum_reduce:
    fadd    v2.4s, v2.4s, v3.4s
    fadd    v4.4s, v4.4s, v5.4s
    fadd    v2.4s, v2.4s, v4.4s
    faddp   v2.4s, v2.4s, v2.4s
    faddp   s2, v2.2s

    cbz     w4, .Lneon_sqrt
    cbnz    w6, .Lneon_scalar_divide_loop

.Lneon_scalar_loop:
    ldr     s16, [x8], #4
    fmul    s16, s16, s1
    fmadd   s2, s16, s16, s2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_loop
    b       .Lneon_sqrt

.Lneon_scalar_divide_loop:
    ldr     s16, [x8], #4
    fdiv    s16, s16, s1
    fmadd   s2, s16, s16, s2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_divide_loop

.Lneon_sqrt:
    fsqrt   s2, s2
    fmul    s0, s0, s2

.Lneon_done:
    ret


.global _snrm2_sve
.p2align 4

_snrm2_sve:
    mov     w1, w1
    cbz     w1, .Lsve_empty

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    mov     x2, #0
    dup     z0.s, #0

    whilelo p0.s, x2, x1

.Lsve_max_loop:
    ld1w    z1.s, p0/z, [x0, x2, lsl #2]
    fabs    z1.s, p0/m, z1.s
    fmax    z0.s, p0/m, z0.s, z1.s

    incw    x2

    whilelo p0.s, x2, x1
    b.first .Lsve_max_loop

    ptrue   p1.s
    fmaxv   s0, p1, z0.s

    fcmp    s0, #0.0
    b.eq    .Lsve_done
    fcmp    s0, s0
    b.vs    .Lsve_done

    fmov    w3, s0
    mov     w4, #0x7f800000
    cmp     w3, w4
    b.eq    .Lsve_done

    mov     x2, #0
    dup     z2.s, #0
    dup     z3.s, z0.s[0]

    whilelo p0.s, x2, x1

.Lsve_sum_loop:
    ld1w    z1.s, p0/z, [x0, x2, lsl #2]
    fdiv    z1.s, p0/m, z1.s, z3.s
    fmla    z2.s, p0/m, z1.s, z1.s

    incw    x2

    whilelo p0.s, x2, x1
    b.first .Lsve_sum_loop

    faddv   s2, p1, z2.s
    fsqrt   s2, s2
    fmul    s0, s0, s2

.Lsve_done:
    fmov    w3, s0
    smstop sm
    fmov    s0, w3

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret

.Lsve_empty:
    fmov    s0, wzr
    ret
