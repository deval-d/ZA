.text

.global _sswap 
.p2align 4 

_sswap:
    cmp     x2, #320
    b.lo    _sswap_neon
    b.eq    _sswap_sme

    cmp     x2, #380
    b.lo    _sswap_neon
    cmp     x2, #384
    b.ls    _sswap_sme

    cmp     x2, #424
    b.lo    _sswap_neon
    cmp     x2, #448
    b.ls    _sswap_sme

    cmp     x2, #472
    b.lo    _sswap_neon
    b       _sswap_sme


.global _sswap_neon 
.p2align 4 

_sswap_neon:
    cbz     x2, .Lneon_done 

    lsr     x3, x2, #4 
    and     x4, x2, #15 
    lsr     x4, x4, #2 
    and     x5, x2, #3 

    cbz     x3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q0, q1, [x0]
    ldp     q2, q3, [x0, #32] 
    ldp     q4, q5, [x1]
    ldp     q6, q7, [x1, #32] 

    stp     q0, q1, [x1], #32 
    stp     q2, q3, [x1], #32 
    stp     q4, q5, [x0], #32 
    stp     q6, q7, [x0], #32

    subs    x3, x3, #1 
    b.ne    .Lsimd_16_loop

.Lsimd_4:
    cbz     x4, .Lscalar 

.Lsimd_4_loop:
    ldr     q0, [x0] 
    ldr     q1, [x1]
    str     q0, [x1], #16 
    str     q1, [x0], #16 

    subs    x4, x4, #1 
    b.ne    .Lsimd_4_loop 

.Lscalar:
    cbz     x5, .Lneon_done 

.Lscalar_loop:
    ldr     s0, [x0]
    ldr     s1, [x1]
    str     s0, [x1], #4 
    str     s1, [x0], #4

    subs    x5, x5, #1 
    b.ne    .Lscalar_loop 

.Lneon_done:
    ret


.global _sswap_sve 
.p2align 4 

_sswap_sve:
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm 

    mov     x3, #0 

    whilelo p0.s, x3, x2 
    b.none  .Lsve_done 

.Lsve_loop:
    ld1w    z0.s, p0/z, [x0, x3, lsl #2]
    ld1w    z1.s, p0/z, [x1, x3, lsl #2] 
    st1w    z0.s, p0, [x1, x3, lsl #2]
    st1w    z1.s, p0, [x0, x3, lsl #2]

    incw    x3 

    whilelo p0.s, x3, x2
    b.first .Lsve_loop

.Lsve_done:
    smstop  sm 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _sswap_sme 
.p2align 4 

_sswap_sme: 
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 

    mov     x3, #0  
    cntw    x4 

    lsl     x5, x4, #5
    udiv    x6, x2, x5 
    ptrue   pn8.s 

    cbz     x6, .Lsme4_full

.Lsme8_full:
    add     x7, x3, x4, lsl #2   
    add     x8, x7, x4, lsl #2 
    add     x9, x8, x4, lsl #2 
    add     x10, x9, x4, lsl #2
    add     x11, x10, x4, lsl #2 
    add     x12, x11, x4, lsl #2
    add     x13, x12, x4, lsl #2

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x3, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x9, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x3, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x7, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x8, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x9, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x3, lsl #2]
    st1w    {z4.s-z7.s}, pn8, [x1, x7, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x8, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x9, lsl #2]

    st1w    {z16.s-z19.s}, pn8, [x0, x3, lsl #2]
    st1w    {z20.s-z23.s}, pn8, [x0, x7, lsl #2]
    st1w    {z24.s-z27.s}, pn8, [x0, x8, lsl #2]
    st1w    {z28.s-z31.s}, pn8, [x0, x9, lsl #2]

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x13, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x10, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x11, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x12, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x13, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x10, lsl #2]
    st1w    {z4.s-z7.s}, pn8, [x1, x11, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x12, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x13, lsl #2]

    st1w    {z16.s-z19.s}, pn8, [x0, x10, lsl #2]
    st1w    {z20.s-z23.s}, pn8, [x0, x11, lsl #2]
    st1w    {z24.s-z27.s}, pn8, [x0, x12, lsl #2]
    st1w    {z28.s-z31.s}, pn8, [x0, x13, lsl #2]

    add     x3, x3, x5 

    subs    x6, x6, #1 
    b.ne    .Lsme8_full

.Lsme4_full:
    // number of float32's in 16 SVLs
    lsl     x5, x4, #4

    // number of full 4xVGx4s remaining
    sub     x6, x2, x3
    udiv    x6, x6, x5
    cbz     x6, .Lsme_tail

    add     x7, x3, x4, lsl #2   
    add     x8, x7, x4, lsl #2 
    add     x9, x8, x4, lsl #2 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x3, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x9, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x3, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x7, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x8, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x9, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x3, lsl #2]
    st1w    {z4.s-z7.s}, pn8, [x1, x7, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x8, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x9, lsl #2]

    st1w    {z16.s-z19.s}, pn8, [x0, x3, lsl #2]
    st1w    {z20.s-z23.s}, pn8, [x0, x7, lsl #2]
    st1w    {z24.s-z27.s}, pn8, [x0, x8, lsl #2]
    st1w    {z28.s-z31.s}, pn8, [x0, x9, lsl #2] 

    add     x3, x3, x5

    subs    x6, x6, #1
    b.ne    .Lsme4_full

.Lsme_tail:
    whilelo pn8.s, x3, x2, vlx4
    b.none  .Lsme_done

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x3, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x3, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x3, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x3, lsl #2]

    add     x3, x3, x4, lsl #2
    b       .Lsme_tail

.Lsme_done:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
