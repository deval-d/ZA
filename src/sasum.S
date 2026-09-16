.text

.global _sasum 
.p2align 4 

_sasum:
    cmp     w1, #2725 
    b.lo    _sasum_neon 

    rdsvl   x9, #1 
    cmp     x9, #32 
    b.lo    _sasum_sme4xVGx4 
    b       _sasum_sme8xVGx4 


.global _sasum_neon
.p2align 4

_sasum_neon:
    lsr     w2, w1, #4 
    and     w3, w1, #15 
    lsr     w3, w3, #2 
    and     w4, w1, #3 

    movi    v0.4s, #0 
    movi    v1.4s, #0 
    movi    v2.4s, #0 
    movi    v3.4s, #0 

    // sign mask 
    mov     w5, #0x7fffffff 
    dup     v16.4s, w5 

    cbz     w2, .Lsimd_4

.Lsimd_16_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 

    and     v4.16b, v4.16b, v16.16b 
    and     v5.16b, v5.16b, v16.16b 
    and     v6.16b, v6.16b, v16.16b 
    and     v7.16b, v7.16b, v16.16b 

    fadd    v0.4s, v0.4s, v4.4s 
    fadd    v1.4s, v1.4s, v5.4s 
    fadd    v2.4s, v2.4s, v6.4s 
    fadd    v3.4s, v3.4s, v7.4s 

    subs    w2, w2, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4: 
    cbz     w3, .Lreduce 

.Lsimd_4_loop:
    ldr     q4, [x0], #16 

    and     v4.16b, v4.16b, v16.16b 

    fadd    v0.4s, v0.4s, v4.4s 

    subs    w3, w3, #1 
    b.ne    .Lsimd_4_loop 

.Lreduce:
    fadd    v0.4s, v0.4s, v1.4s 
    fadd    v2.4s, v2.4s, v3.4s 
    fadd    v0.4s, v0.4s, v2.4s 
    faddp   v0.4s, v0.4s, v0.4s
    faddp   s0, v0.2s 

.Lscalar:
    cbz     w4, .Lneon_done

.Lscalar_loop:
    ldr     s4, [x0], #4 

    fmov    w6, s4 
    and     w6, w6, w5
    fmov    s4, w6

    fadd    s0, s0, s4 

    subs    w4, w4, #1
    b.ne    .Lscalar_loop 

.Lneon_done:
    ret 


.global _sasum_sve
.p2align 4 

_sasum_sve:
    mov     w1, w1

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    // base index 
    mov     w8, #0 
    mov     w9, #0x7fffffff

    // accumulator 
    dup     z0.s, w8 
    // sign mask 
    dup     z1.s, w9

    whilelo p0.s, x8, x1
    b.none  .Lsve_reduce 

.Lsve_loop:
    ld1w    z2.s, p0/z, [x0, x8, lsl #2] 
    and     z2.s, p0/m, z2.s, z1.s 
    fadd    z0.s, p0/m, z0.s, z2.s 

    incw    x8 

    whilelo p0.s, x8, x1 
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


.global _sasum_sme4xVGx4
.p2align 4 

_sasum_sme4xVGx4:
    mov     w1, w1 

    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za}

    cntw    x2 
    mov     w8, #0 

    // base 4xVGx4 index 
    mov     x12, #0 
    
    // number of float32's 4xVGx4 
    lsl     w3, w2, #4 
    // number of full 4xVGx4s 
    udiv    w4, w1, w3 
    cbz     w4, .Lsme4_tail_loop

    ptrue   pn8.s 

.Lsme4_full_loop:
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 
    add     x15, x14, x2, lsl #2 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x12, lsl #2]
    and     z4.s, z4.s, #0x7fffffff 
    and     z5.s, z5.s, #0x7fffffff 
    and     z6.s, z6.s, #0x7fffffff 
    and     z7.s, z7.s, #0x7fffffff 

    ld1w    {z8.s-z11.s}, pn8/z, [x0, x13, lsl #2]
    and     z8.s, z8.s, #0x7fffffff 
    and     z9.s, z9.s, #0x7fffffff 
    and     z10.s, z10.s, #0x7fffffff 
    and     z11.s, z11.s, #0x7fffffff 

    ld1w    {z12.s-z15.s}, pn8/z, [x0, x14, lsl #2]
    and     z12.s, z12.s, #0x7fffffff 
    and     z13.s, z13.s, #0x7fffffff 
    and     z14.s, z14.s, #0x7fffffff 
    and     z15.s, z15.s, #0x7fffffff 

    ld1w    {z16.s-z19.s}, pn8/z, [x0, x15, lsl #2] 
    and     z16.s, z16.s, #0x7fffffff 
    and     z17.s, z17.s, #0x7fffffff 
    and     z18.s, z18.s, #0x7fffffff 
    and     z19.s, z19.s, #0x7fffffff

    fadd    za.s[w8, 0, vgx4], {z4.s-z7.s} 
    fadd    za.s[w8, 0, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, 0, vgx4], {z12.s-z15.s}
    fadd    za.s[w8, 0, vgx4], {z16.s-z19.s}

    incw    x12, all, mul #16 
    subs    w4, w4, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 
    add     x15, x14, x2, lsl #2 

    whilelo pn8.s, x12, x1, vlx4 
    b.none  .Lsme4_reduce 

    whilelo pn9.s, x13, x1, vlx4 
    whilelo pn10.s, x14, x1, vlx4 
    whilelo pn11.s, x15, x1, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x12, lsl #2]
    and     z4.s, z4.s, #0x7fffffff 
    and     z5.s, z5.s, #0x7fffffff 
    and     z6.s, z6.s, #0x7fffffff 
    and     z7.s, z7.s, #0x7fffffff 

    ld1w    {z8.s-z11.s}, pn9/z, [x0, x13, lsl #2]
    and     z8.s, z8.s, #0x7fffffff 
    and     z9.s, z9.s, #0x7fffffff 
    and     z10.s, z10.s, #0x7fffffff 
    and     z11.s, z11.s, #0x7fffffff 

    ld1w    {z12.s-z15.s}, pn10/z, [x0, x14, lsl #2]
    and     z12.s, z12.s, #0x7fffffff 
    and     z13.s, z13.s, #0x7fffffff 
    and     z14.s, z14.s, #0x7fffffff 
    and     z15.s, z15.s, #0x7fffffff 

    ld1w    {z16.s-z19.s}, pn11/z, [x0, x15, lsl #2] 
    and     z16.s, z16.s, #0x7fffffff 
    and     z17.s, z17.s, #0x7fffffff 
    and     z18.s, z18.s, #0x7fffffff 
    and     z19.s, z19.s, #0x7fffffff

    fadd    za.s[w8, 0, vgx4], {z4.s-z7.s} 
    fadd    za.s[w8, 0, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, 0, vgx4], {z12.s-z15.s}
    fadd    za.s[w8, 0, vgx4], {z16.s-z19.s}

    incw    x12, all, mul #16 
    b       .Lsme4_tail_loop

.Lsme4_reduce:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]

    fadd    z4.s, z4.s, z5.s
    fadd    z6.s, z6.s, z7.s
    fadd    z4.s, z4.s, z6.s

    ptrue   p0.s
    faddv   s0, p0, z4.s

.Lsme4_done:
    fmov    w3, s0 

    smstop 

    fmov    s0, w3 
    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 
        

.global _sasum_sme8xVGx4 
.p2align 4 

_sasum_sme8xVGx4:
    mov     w1, w1 

    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 

    cntw    x2 
    mov     w8, #0 
    lsr     w9, w2, #1 

    // base 8xVGx4 idx 
    mov     w5, #0 

    // number of float32's in 32 SVLs 
    lsl     w3, w2, #5 

    // number of full 8xVGx4s 
    udiv    w4, w1, w3 
    cbz     w4, .Lsme8_tail_loop 

    ptrue   pn8.s

.Lsme8_full_loop:
    add     x6, x5, x2, lsl #2 
    add     x7, x6, x2, lsl #2 
    add     x10, x7, x2, lsl #2 
    add     x11, x10, x2, lsl #2 
    add     x12, x11, x2, lsl #2 
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x5, lsl #2]
    and     z0.s, z0.s, #0x7fffffff 
    and     z1.s, z1.s, #0x7fffffff 
    and     z2.s, z2.s, #0x7fffffff 
    and     z3.s, z3.s, #0x7fffffff 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x6, lsl #2]
    and     z4.s, z4.s, #0x7fffffff 
    and     z5.s, z5.s, #0x7fffffff 
    and     z6.s, z6.s, #0x7fffffff 
    and     z7.s, z7.s, #0x7fffffff 

    ld1w    {z8.s-z11.s}, pn8/z, [x0, x7, lsl #2]
    and     z8.s, z8.s, #0x7fffffff 
    and     z9.s, z9.s, #0x7fffffff 
    and     z10.s, z10.s, #0x7fffffff 
    and     z11.s, z11.s, #0x7fffffff 

    ld1w    {z12.s-z15.s}, pn8/z, [x0, x10, lsl #2] 
    and     z12.s, z12.s, #0x7fffffff 
    and     z13.s, z13.s, #0x7fffffff 
    and     z14.s, z14.s, #0x7fffffff 
    and     z15.s, z15.s, #0x7fffffff 

    fadd    za.s[w8, 0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, 0, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, 0, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, 0, vgx4], {z12.s-z15.s}

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x11, lsl #2]
    and     z0.s, z0.s, #0x7fffffff 
    and     z1.s, z1.s, #0x7fffffff 
    and     z2.s, z2.s, #0x7fffffff 
    and     z3.s, z3.s, #0x7fffffff 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x12, lsl #2]
    and     z4.s, z4.s, #0x7fffffff 
    and     z5.s, z5.s, #0x7fffffff 
    and     z6.s, z6.s, #0x7fffffff 
    and     z7.s, z7.s, #0x7fffffff 

    ld1w    {z8.s-z11.s}, pn8/z, [x0, x13, lsl #2]
    and     z8.s, z8.s, #0x7fffffff 
    and     z9.s, z9.s, #0x7fffffff 
    and     z10.s, z10.s, #0x7fffffff 
    and     z11.s, z11.s, #0x7fffffff 

    ld1w    {z12.s-z15.s}, pn8/z, [x0, x14, lsl #2] 
    and     z12.s, z12.s, #0x7fffffff 
    and     z13.s, z13.s, #0x7fffffff 
    and     z14.s, z14.s, #0x7fffffff 
    and     z15.s, z15.s, #0x7fffffff 

    fadd    za.s[w8, 0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, 0, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, 0, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, 0, vgx4], {z12.s-z15.s}

    incw    x5, all, mul #16 
    incw    x5, all, mul #16 
    subs    w4, w4, #1 
    b.ne    .Lsme8_full_loop

.Lsme8_tail_loop:
    add     x6, x5, x2, lsl #2 
    add     x7, x6, x2, lsl #2 
    add     x10, x7, x2, lsl #2 

    whilelo pn8.s, x5, x1, vlx4 
    b.none  .Lsme8_reduce 

    whilelo pn9.s, x6, x1, vlx4
    whilelo pn10.s, x7, x1, vlx4 
    whilelo pn11.s, x10, x1, vlx4

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x5, lsl #2]
    and     z0.s, z0.s, #0x7fffffff 
    and     z1.s, z1.s, #0x7fffffff 
    and     z2.s, z2.s, #0x7fffffff 
    and     z3.s, z3.s, #0x7fffffff 

    ld1w    {z4.s-z7.s}, pn9/z, [x0, x6, lsl #2]
    and     z4.s, z4.s, #0x7fffffff 
    and     z5.s, z5.s, #0x7fffffff 
    and     z6.s, z6.s, #0x7fffffff 
    and     z7.s, z7.s, #0x7fffffff 

    ld1w    {z8.s-z11.s}, pn10/z, [x0, x7, lsl #2]
    and     z8.s, z8.s, #0x7fffffff 
    and     z9.s, z9.s, #0x7fffffff 
    and     z10.s, z10.s, #0x7fffffff 
    and     z11.s, z11.s, #0x7fffffff 

    ld1w    {z12.s-z15.s}, pn11/z, [x0, x10, lsl #2] 
    and     z12.s, z12.s, #0x7fffffff 
    and     z13.s, z13.s, #0x7fffffff 
    and     z14.s, z14.s, #0x7fffffff 
    and     z15.s, z15.s, #0x7fffffff 

    fadd    za.s[w8, 0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, 0, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, 0, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, 0, vgx4], {z12.s-z15.s}

    incw    x5, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_reduce:
    mov     {z0.s-z3.s}, za.s[w8, 0, vgx4]

    fadd    z0.s, z0.s, z1.s 
    fadd    z2.s, z2.s, z3.s 
    fadd    z0.s, z0.s, z2.s 

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
