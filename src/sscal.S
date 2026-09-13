.text 

.global _sscal 
.p2align 4 

_sscal: 
    cmp     w1, #1024 
    b.lo    _sscal_neon 

    rdsvl   x9, #1 
    cmp     x9, #32 
    b.lo    _sscal_sme4xVGx4 
    b       _sscal_sme8xVGx4 


.global _sscal_neon
.p2align 4

_sscal_neon:
    cbz     w1, .Lneon_done 

    lsr     w2, w1, #4 
    and     w3, w1, #15 
    lsr     w3, w3, #2 
    and     w4, w1, #3 

    cbz     w2, .Lsimd_4 

.Lsimd_16_loop: 
    ldp     q1, q2, [x0]
    ldp     q3, q4, [x0, #32]

    fmul    v1.4s, v1.4s, v0.s[0]
    fmul    v2.4s, v2.4s, v0.s[0]
    fmul    v3.4s, v3.4s, v0.s[0]
    fmul    v4.4s, v4.4s, v0.s[0] 

    stp     q1, q2, [x0], #32
    stp     q3, q4, [x0], #32 

    subs    w2, w2, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     w3, .Lneon_scalar 

.Lsimd_4_loop:
    ldr     q1, [x0] 
    fmul    v1.4s, v1.4s, v0.s[0]
    str     q1, [x0], #16 

    subs    w3, w3, #1
    b.ne    .Lsimd_4_loop 

.Lneon_scalar:
    cbz     w4, .Lneon_done 

.Lneon_scalar_loop:
    ldr     s1, [x0]
    fmul    s1, s1, s0 
    str     s1, [x0], #4 

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_loop 

.Lneon_done:
    ret


.global _sscal_sve 
.p2align 4 

_sscal_sve:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w2, s0 

    smstart sm 

    fmov    s0, w2 
    dup     z0.s, z0.s[0]

    mov     w3, #0 
    whilelo p0.s, w3, w1
    b.none  .Lsve_done 

.Lsve_loop:
    ld1w    z1.s, p0/z, [x0]
    fmul    z1.s, p0/m, z1.s, z0.s
    st1w    z1.s, p0, [x0]

    addvl   x0, x0, #1 

    incw    x3 
    whilelo p0.s, w3, w1 
    b.first .Lsve_loop

.Lsve_done:
    smstop  sm 
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _sscal_sme4xVGx4
.p2align 4 

_sscal_sme4xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w2, s0 

    smstart
    zero    {za}

    fmov    s0, w2 
    dup     z0.s, z0.s[0]

    cntw    x4 
    
    mov     w8, #0 

    // base 4xVGx4 group index 
    mov     x5, #0 

    // how many float32's in 16 SVL's (4xVGx4)
    lsl     x13, x4, #4 

    // number of full 4xVGx4 chunks 
    udiv    x13, x1, x13 
    cbz     x13, .Lsme4_tail_loop

    ptrue   pn8.s 

.Lsme4_full_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x6, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x14, lsl #2] 

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z0.s 

    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4] 
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x6, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x7, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x14, lsl #2] 

    zero    {za}
    incw    x5, all, mul #16 
    subs    x13, x13, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.s, x5, x1, vlx4 
    b.none  .Lsme4_done 

    whilelo pn9.s, x6, x1, vlx4 
    whilelo pn10.s, x7, x1, vlx4 
    whilelo pn11.s, x14, x1, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x6, lsl #2] 
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x7, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x14, lsl #2] 

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z0.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z0.s 

    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x0, x6, lsl #2] 
    st1w    {z12.s-z15.s}, pn10, [x0, x7, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x0, x14, lsl #2]

    zero    {za}
    incw    x5, all, mul #16 
    b       .Lsme4_tail_loop 

.Lsme4_done: 
    smstop
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _sscal_sme8xVGx4
.p2align 4 

_sscal_sme8xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w2, s0 

    smstart 
    zero    {za} 

    fmov    s0, w2 
    dup     z0.s, z0.s[0]

    cntw    x4 
    
    mov     w8, #0 
    lsr     w9, w4, #1 

    // base 8xVGx4 group index 
    mov     x5, #0 

    // how many float32's in 32 SVL's (8xVGx4)
    lsl     x13, x4, #5 

    // number of full 8xVGx4 chunks 
    udiv    x13, x1, x13
    cbz     x13, .Lsme8_tail_loop

    ptrue   pn8.s 

.Lsme8_full_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 
    add     x15, x14, x4, lsl #2 
    add     x10, x15, x4, lsl #2 
    add     x11, x10, x4, lsl #2 
    add     x12, x11, x4, lsl #2 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x6, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x14, lsl #2] 

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z0.s 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x15, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x12, lsl #2] 

    fmla    za.s[w9, 0, vgx4], {z4.s-z7.s}, z0.s
    fmla    za.s[w9, 1, vgx4], {z8.s-z11.s}, z0.s
    fmla    za.s[w9, 2, vgx4], {z12.s-z15.s}, z0.s
    fmla    za.s[w9, 3, vgx4], {z16.s-z19.s}, z0.s 

    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4] 
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x6, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x7, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x14, lsl #2] 

    mov     {z4.s-z7.s}, za.s[w9, 0, vgx4] 
    mov     {z8.s-z11.s}, za.s[w9, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w9, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w9, 3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x15, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x10, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x11, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x12, lsl #2] 

    zero    {za}
    incw    x5, all, mul #16 
    incw    x5, all, mul #16 
    subs    x13, x13, #1 
    b.ne    .Lsme8_full_loop

.Lsme8_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.s, x5, x1, vlx4 
    b.none  .Lsme8_done 

    whilelo pn9.s, x6, x1, vlx4 
    whilelo pn10.s, x7, x1, vlx4 
    whilelo pn11.s, x14, x1, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x6, lsl #2] 
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x7, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x14, lsl #2] 

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z0.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z0.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z0.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z0.s

    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w8, 3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x0, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x0, x6, lsl #2] 
    st1w    {z12.s-z15.s}, pn10, [x0, x7, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x0, x14, lsl #2]

    zero    {za}
    incw    x5, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_done: 
    smstop
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret

  

    
    
 
