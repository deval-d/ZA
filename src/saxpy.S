.text 

.global _saxpy_neon
.p2align 4 

_saxpy_neon:
    cbz     w2, .Lneon_done 

    lsr     w3, w2, #4 
    and     w4, w2, #15 
    lsr     w4, w4, #2 
    and     w5, w2, #3 

    cbz     w3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q1, q2, [x0], #32 
    ldp     q3, q4, [x0], #32 
    ldp     q16, q17, [x1] 
    ldp     q18, q19, [x1, #32]

    fmla    v16.4s, v1.4s, v0.s[0]
    fmla    v17.4s, v2.4s, v0.s[0]
    fmla    v18.4s, v3.4s, v0.s[0]
    fmla    v19.4s, v4.4s, v0.s[0]

    stp     q16, q17, [x1], #32
    stp     q18, q19, [x1], #32

    subs    w3, w3, #1
    b.ne    .Lsimd_16_loop 

.Lsimd_4: 
    cbz     w4, .Lneon_scalar 

.Lsimd_4_loop:
    ldr     q1, [x0], #16 
    ldr     q2, [x1] 

    fmla    v2.4s, v1.4s, v0.s[0]
     
    str     q2, [x1], #16 

    subs    w4, w4, #1 
    b.ne    .Lsimd_4_loop 

.Lneon_scalar: 
    cbz     w5, .Lneon_done 

.Lneon_scalar_loop:
    ldr     s1, [x0], #4 
    ldr     s2, [x1]

    fmadd   s2, s0, s1, s2 

    str     s2, [x1], #4 

    subs    w5, w5, #1 
    b.ne    .Lneon_scalar_loop 

.Lneon_done: 
    ret 
   

.global _saxpy_sve 
.p2align 4 

_saxpy_sve:
    sub     sp, sp, #64 
    stp     d8, d9, [sp] 
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0 

    smstart sm 

    fmov    s0, w3 
    dup     z0.s, z0.s[0]

    mov     w4, #0 
    whilelo p0.s, w4, w2 
    b.none  .Lsve_done 

.Lsve_loop:
    ld1w    z1.s, p0/z, [x0] 
    ld1w    z2.s, p0/z, [x1] 

    fmla    z2.s, p0/m, z1.s, z0.s 

    st1w    z2.s, p0 [x1]

    addvl   x0, x0, #1 
    addvl   x1, x1, #1 

    incw    x4
    whilelo p0.s, w4, w2 
    b.first .Lsve_loop 

.Lsve_done:
    smstop  sm

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 


.global _saxpy_sme 
.p2align 4 

_saxpy_sme:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, 16]
    stp     d12, d13, [sp, 32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0 

    smstart 

    fmov    s0, w3 
    dup     z0.s, z0.s[0]

    mov     w8, #0 
    mov     w9, #8 

    cntw    x4 
    lsl     x13, x4, #5 
    udiv    x13, x2, x13 
    cbz     x13, .Lsme_tail 

    // base index 
    mov     x5, #0 
    ptrue   pn8.s 

.Lsme_full:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 
    add     x15, x14, x4, lsl #2 
    add     x10, x15, x4, lsl #2 
    add     x11, x10, x4, lsl #2
    add     x12, x11, x4, lsl #2 

.Lsme_full_loop:
    ld1w    {z4.s-z7.s}, pn8/z, [x1, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x1, x6, lsl #2] 
    ld1w    {z12.s-z15.s}, pn8/z, [x1, x7, lsl #2] 
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x14, lsl #2]
    
    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w8, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w8, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w8, 3, vgx4], {z16.s-z19.s} 

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x15, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x1, x10, lsl #2] 
    ld1w    {z12.s-z15.s}, pn8/z, [x1, x11, lsl #2] 
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x12, lsl #2]
    
    mov     za.s[w9, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w9, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w9, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w9, 3, vgx4], {z16.s-z19.s} 

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

    st1w    {z4.s-z7.s}, pn8, [x1, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x6, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x7, lsl #2] 
    st1w    {z16.s-z19.s}, pn8, [x1, x14, lsl #2] 

    mov     {z4.s-z7.s}, za.s[w9, 0, vgx4]
    mov     {z8.s-z11.s}, za.s[w9, 1, vgx4]
    mov     {z12.s-z15.s}, za.s[w9, 2, vgx4]
    mov     {z16.s-z19.s}, za.s[w9, 3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x1, x15, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x10, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x11, lsl #2] 
    st1w    {z16.s-z19.s}, pn8, [x1, x12, lsl #2]
     
    incw    x5, all, mul #16 
    incw    x5, all, mul #16

    subs    x13, x13, #1 
    b.ne    .Lsme_full 

.Lsme_tail:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

.Lsme_tail_loop:
    whilelo pn8.s, x5, x2, vlx4 
    b.none  .Lsme_done 

    whilelo pn9.s, x6, x2, vlx4
    whilelo pn10.s, x7, x2, vlx4 
    whilelo pn11.s, x14, x2, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x5, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x1, x6, lsl #2] 
    ld1w    {z12.s-z15.s}, pn10/z, [x1, x7, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x1, x14, lsl #2] 

    mov     za.s[w8, 0, vgx4], {z4.s-z7.s}
    mov     za.s[w8, 1, vgx4], {z8.s-z11.s}
    mov     za.s[w8, 2, vgx4], {z12.s-z15.s}
    mov     za.s[w8, 3, vgx4], {z16.s-z19.s}

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

    st1w    {z4.s-z7.s}, pn8, [x1, x5, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x1, x6, lsl #2] 
    st1w    {z12.s-z15.s}, pn10, [x1, x7, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x1, x14, lsl #2]

    incw    x5, all, mul #16 
    b       .Lsme_tail 

.Lsme_done:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 


    




    
