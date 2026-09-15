.text 

.global _sdot 
.p2align 4 

_sdot:
    cmp     w2, #2048
    b.lo    _sdot_neon 

    rdsvl   x9, #1 
    cmp     x9, #32 
    b.lo    _sdot_sme4xVGx4 
    b       _sdot_sme8xVGx4 


.global _sdot_neon 
.p2align 4 

_sdot_neon:
    // number of 16-float chunks 
    lsr     w3, w2, #4 
    and     w4, w2, #15 
    // number of leftover 4-float chunks 
    lsr     w4, w4, #2 
    // number of scalar leftover 
    and     w5, w2, #3 

    movi    v0.16b, #0 
    movi    v1.16b, #0 
    movi    v2.16b, #0 
    movi    v3.16b, #0 

    cbz     w2, .Lneon_done 
    cbz     w3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 

    ldp     q16, q17, [x1], #32 
    ldp     q18, q19, [x1], #32 

    fmla    v0.4s, v4.4s, v16.4s 
    fmla    v1.4s, v5.4s, v17.4s 
    fmla    v2.4s, v6.4s, v18.4s 
    fmla    v3.4s, v7.4s, v19.4s

    subs    w3, w3, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     w4, .Lneon_reduce 

.Lsimd_4_loop:
    ldr     q4, [x0], #16 
    ldr     q5, [x1], #16 

    fmla    v0.4s, v4.4s, v5.4s 

    subs    w4, w4, #1 
    b.ne    .Lsimd_4 

.Lneon_reduce: 
    fadd    v0.4s, v0.4s, v1.4s 
    fadd    v2.4s, v2.4s, v3.4s 
    fadd    v0.4s, v0.4s, v2.4s 
    faddp   v0.4s, v0.4s, v0.4s 
    faddp   s0, v0.2s 

.Lscalar: 
    cbz     x5, .Lneon_done 

.Lscalar_loop:
    ldr     s1, [x0], #4 
    ldr     s2, [x1], #4 

    fmadd   s0, s1, s2, s0 

    subs    w5, w5, #1 
    b.ne    .Lscalar_loop 

.Lneon_done: 
    ret 


.global _sdot_sve 
.p2align 4 

_sdot_sve:
    mov     w2, w2
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm 

    fmov    s0, #0 
    dup     z0.s, z0.s[0]

    mov     w3, #0 
    whilelo p0.s, x3, x2 
    b.none  .Lsve_done

.Lsve_loop:
    ld1w    z1.s, p0/z, [x0]
    ld1w    z2.s, p0/z, [x1] 
    
    fmla    z0.s, p0/m, z1.s, z2.s 

    addvl   x0, x0, #1 
    addvl   x1, x1, #1 

    incw    x3 
    whilelo p0.s, x3, x2 
    b.first .Lsve_loop 

.Lsve_reduce:
    ptrue   p0.s 
    faddv   s0, p0, z0.s 

.Lsve_done:
    fmov    w3, s0 

    smstop  sm 

    fmov    s0, w3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret 


.global _sdot_sme4xVGx4 
.p2align 4 

_sdot_sme4xVGx4:
    mov     w2, w2
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    // x3 number of floats in SVL 
    cntw    x3 

    mov     w8, #0 
    
    // base 4xVGx4 group index 
    mov     x12, #0 

    // x5 number of floats in 4 SVLs 
    lsl     x5, x3, #4 

    // number of full 4xVGx4 chunks 
    udiv    x5, x2, x5 
    cbz     x5, .Lsme4_tail_loop

    ptrue   pn8.s 

.Lsme4_full_loop:
    add     x13, x12, x3, lsl #2 
    add     x14, x13, x3, lsl #2 
    add     x15, x14, x3, lsl #2 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x13, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x14, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x15, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x12, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x13, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x14, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x15, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w8, 1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w8, 2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w8, 3, vgx4], {z12.s-z15.s}, {z28.s-z31.s}

    incw    x12, all, mul #16
    subs    x5, x5, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x13, x12, x3, lsl #2 
    add     x14, x13, x3, lsl #2 
    add     x15, x14, x3, lsl #2 

    whilelo pn8.s, x12, x2, vlx4 
    b.none  .Lsme4_reduce 

    whilelo pn9.s, x13, x2, vlx4
    whilelo pn10.s, x14, x2, vlx4 
    whilelo pn11.s, x15, x2, vlx4

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z4.s-z7.s}, pn9/z, [x0, x13, lsl #2]
    ld1w    {z8.s-z11.s}, pn10/z, [x0, x14, lsl #2]
    ld1w    {z12.s-z15.s}, pn11/z, [x0, x15, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x12, lsl #2]
    ld1w    {z20.s-z23.s}, pn9/z, [x1, x13, lsl #2]
    ld1w    {z24.s-z27.s}, pn10/z, [x1, x14, lsl #2]
    ld1w    {z28.s-z31.s}, pn11/z, [x1, x15, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w8, 1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w8, 2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w8, 3, vgx4], {z12.s-z15.s}, {z28.s-z31.s}

    incw    x12, all, mul #16 
    b       .Lsme4_tail_loop 

.Lsme4_reduce:
    mov     {z0.s-z3.s}, za.s[w8, 0, vgx4]
    mov     {z4.s-z7.s}, za.s[w8, 1, vgx4]
    mov     {z8.s-z11.s}, za.s[w8, 2, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 3, vgx4]

    fadd    z0.s, z0.s, z4.s 
    fadd    z1.s, z1.s, z5.s 
    fadd    z2.s, z2.s, z6.s 
    fadd    z3.s, z3.s, z7.s 

    fadd    z8.s, z8.s, z12.s 
    fadd    z9.s, z9.s, z13.s 
    fadd    z10.s, z10.s, z14.s 
    fadd    z11.s, z11.s, z15.s 

    fadd    z0.s, z0.s, z8.s 
    fadd    z1.s, z1.s, z9.s 
    fadd    z2.s, z2.s, z10.s 
    fadd    z3.s, z3.s, z11.s 

    fadd    z0.s, z0.s, z1.s 
    fadd    z2.s, z2.s, z3.s 
    
    fadd    z0.s, z0.s, z2.s 

    ptrue   p0.s 
    faddv   s0, p0, z0.s

.Lsme4_done:
    fmov    w3, s0 

    smstop 

    fmov    s0, w3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
    

.global _sdot_sme8xVGx4
.p2align 4 

_sdot_sme8xVGx4:
    mov     w2, w2
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    cntw    x3 

    mov     w8, #0 
    lsr     w9, w3, #1 

    // base 8xVGx4 group index 
    mov     x4, #0 

    // how man float32's in 32 SVL's (8xVGx4)
    lsl     x14, x3, #5 

    // number of full 8xVGx4 chunks 
    udiv    x14, x2, x14
    cbz     x14, .Lsme8_tail_loop 

    ptrue   pn8.s 

.Lsme8_full_loop:
    add     x5, x4, x3, lsl #2 
    add     x6, x5, x3, lsl #2 
    add     x7, x6, x3, lsl #2 
    add     x10, x7, x3, lsl #2 
    add     x11, x10, x3, lsl #2 
    add     x12, x11, x3, lsl #2 
    add     x13, x12, x3, lsl #2

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x4, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x6, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x7, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x4, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x5, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x6, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x7, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w8, 1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w8, 2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w8, 3, vgx4], {z12.s-z15.s}, {z28.s-z31.s} 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x13, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x10, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x11, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x12, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x13, lsl #2]

    fmla    za.s[w9, 0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w9, 1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w9, 2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w9, 3, vgx4], {z12.s-z15.s}, {z28.s-z31.s}

    incw    x4, all, mul #16 
    incw    x4, all, mul #16 

    subs    x14, x14, #1 
    b.ne    .Lsme8_full_loop 

.Lsme8_tail_loop:
    add     x5, x4, x3, lsl #2 
    add     x6, x5, x3, lsl #2 
    add     x7, x6, x3, lsl #2 

    whilelo pn8.s, x4, x2, vlx4 
    b.none  .Lsme8_reduce 

    whilelo pn9.s, x5, x2, vlx4 
    whilelo pn10.s, x6, x2, vlx4 
    whilelo pn11.s, x7, x2, vlx4 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x4, lsl #2]
    ld1w    {z4.s-z7.s}, pn9/z, [x0, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn10/z, [x0, x6, lsl #2]
    ld1w    {z12.s-z15.s}, pn11/z, [x0, x7, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x4, lsl #2]
    ld1w    {z20.s-z23.s}, pn9/z, [x1, x5, lsl #2]
    ld1w    {z24.s-z27.s}, pn10/z, [x1, x6, lsl #2]
    ld1w    {z28.s-z31.s}, pn11/z, [x1, x7, lsl #2]

    fmla    za.s[w8, 0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w8, 1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w8, 2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w8, 3, vgx4], {z12.s-z15.s}, {z28.s-z31.s}

    incw    x4, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_reduce:
    mov     {z0.s-z3.s}, za.s[w8, 0, vgx4]
    mov     {z4.s-z7.s}, za.s[w8, 1, vgx4] 
    mov     {z8.s-z11.s}, za.s[w8, 2, vgx4]
    mov     {z12.s-z15.s}, za.s[w8, 3, vgx4] 

    fadd    z0.s, z0.s, z4.s 
    fadd    z1.s, z1.s, z5.s 
    fadd    z2.s, z2.s, z6.s 
    fadd    z3.s, z3.s, z7.s 

    fadd    z8.s, z8.s, z12.s 
    fadd    z9.s, z9.s, z13.s 
    fadd    z10.s, z10.s, z14.s 
    fadd    z11.s, z11.s, z15.s 

    mov     {z16.s-z19.s}, za.s[w9, 0, vgx4]
    mov     {z20.s-z23.s}, za.s[w9, 1, vgx4] 
    mov     {z24.s-z27.s}, za.s[w9, 2, vgx4]
    mov     {z28.s-z31.s}, za.s[w9, 3, vgx4] 

    fadd    z16.s, z16.s, z20.s 
    fadd    z17.s, z17.s, z21.s 
    fadd    z18.s, z18.s, z22.s 
    fadd    z19.s, z19.s, z23.s 

    fadd    z24.s, z24.s, z28.s 
    fadd    z25.s, z25.s, z29.s 
    fadd    z26.s, z26.s, z30.s 
    fadd    z27.s, z27.s, z31.s 

    fadd    z0.s, z0.s, z1.s 
    fadd    z2.s, z2.s, z3.s 
    fadd    z8.s, z8.s, z9.s 
    fadd    z10.s, z10.s, z11.s 
    fadd    z16.s, z16.s, z17.s
    fadd    z18.s, z18.s, z19.s 
    fadd    z24.s, z24.s, z25.s 
    fadd    z26.s, z26.s, z27.s 

    fadd    z0.s, z0.s, z2.s 
    fadd    z8.s, z8.s, z10.s 
    fadd    z16.s, z16.s, z18.s 
    fadd    z24.s, z24.s, z26.s 
    
    fadd    z0.s, z0.s, z8.s 
    fadd    z16.s, z16.s, z24.s 

    fadd    z0.s, z0.s, z16.s 

    ptrue   p0.s 
    faddv   s0, p0, z0.s

.Lsme8_done:
    fmov    w3, s0 

    smstop 

    fmov    s0, w3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
 
