.text

.global _isamax
.p2align 4 

_isamax:
    b   _isamax_neon 


.global _isamax_neon
.p2align 4

_isamax_neon:
    lsr     w2, w1, #4 
    and     w3, w1, #15 
    lsr     w3, w3, #2 
    and     w4, w1, #3 

    mov     w5, #0 
    mov     w6, #1 
    mov     w7, #2 
    mov     w8, #3 
    mov     v17.s[0], w5 
    mov     v17.s[1], w6 
    mov     v17.s[2], w7 
    mov     v17.s[3], w8 

    movi    v16.4s, #4 
    add     v18.4s, v17.4s, v16.4s
    add     v19.4s, v18.4s, v16.4s
    add     v28.4s, v19.4s, v16.4s

    // current 16 float base
    movi    v0.4s, #0

    // maximum bases
    mov     v1.16b, v0.16b
    mov     v25.16b, v0.16b
    mov     v26.16b, v0.16b
    mov     v27.16b, v0.16b

    mov     v29.16b, v17.16b

    // maximum values
    movi    v2.4s, #0
    movi    v22.4s, #0
    movi    v23.4s, #0
    movi    v24.4s, #0

    // index updater
    movi    v16.4s, #16

    cbz     w2, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q3, q4, [x0], #32
    ldp     q5, q6, [x0], #32 

    fabs    v3.4s, v3.4s 
    fabs    v4.4s, v4.4s 
    fabs    v5.4s, v5.4s 
    fabs    v6.4s, v6.4s 

    fcmgt   v7.4s, v3.4s, v2.4s 
    bit     v2.16b, v3.16b, v7.16b
    bit     v1.16b, v0.16b, v7.16b

    fcmgt   v7.4s, v4.4s, v22.4s
    bit     v22.16b, v4.16b, v7.16b
    bit     v25.16b, v0.16b, v7.16b

    fcmgt   v7.4s, v5.4s, v23.4s
    bit     v23.16b, v5.16b, v7.16b
    bit     v26.16b, v0.16b, v7.16b

    fcmgt   v7.4s, v6.4s, v24.4s
    bit     v24.16b, v6.16b, v7.16b
    bit     v27.16b, v0.16b, v7.16b

    add     v0.4s, v0.4s, v16.4s

    subs    w2, w2, #1
    b.ne    .Lsimd_16_loop

.Lsimd_4:
    movi    v16.4s, #4

    cbz     w3, .Lreduce 

.Lsimd_4_loop:
    ldr     q3, [x0], #16 

    fabs    v3.4s, v3.4s 

    fcmgt   v7.4s, v3.4s, v2.4s 
    bit     v2.16b, v3.16b, v7.16b
    bit     v1.16b, v0.16b, v7.16b

    add     v0.4s, v0.4s, v16.4s 

    subs    w3, w3, #1 
    b.ne    .Lsimd_4_loop 

.Lreduce:
    fcmgt   v7.4s, v22.4s, v2.4s
    fcmeq   v20.4s, v22.4s, v2.4s
    cmhi    v21.4s, v1.4s, v25.4s
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v22.16b, v7.16b
    bit     v1.16b, v25.16b, v7.16b
    bit     v29.16b, v18.16b, v7.16b

    fcmgt   v7.4s, v23.4s, v2.4s
    fcmeq   v20.4s, v23.4s, v2.4s
    cmhi    v21.4s, v1.4s, v26.4s
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v23.16b, v7.16b
    bit     v1.16b, v26.16b, v7.16b
    bit     v29.16b, v19.16b, v7.16b

    fcmgt   v7.4s, v24.4s, v2.4s
    fcmeq   v20.4s, v24.4s, v2.4s
    cmhi    v21.4s, v1.4s, v27.4s
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v24.16b, v7.16b
    bit     v1.16b, v27.16b, v7.16b
    bit     v29.16b, v28.16b, v7.16b

    add     v1.4s, v1.4s, v29.4s

    fmaxv   s16, v2.4s 
    dup     v16.4s, v16.s[0]

    fcmeq   v7.4s, v2.4s, v16.4s 
    mvn     v7.16b, v7.16b
    orr     v1.16b, v1.16b, v7.16b

    // max index 
    uminv   s17, v1.4s 
    fmov    w2, s17 

    // curr index 
    umov    w3, v0.s[0] 

.Lscalar:
    cbz     w4, .Lneon_done 

.Lscalar_loop:
    ldr     s3, [x0], #4 
    fabs    s3, s3 

    fcmp    s3, s16 
    fcsel   s16, s3, s16, gt 
    csel    w2, w3, w2, gt 

    add     w3, w3, #1 

    subs    w4, w4, #1 
    b.ne    .Lscalar_loop 

.Lneon_done:
    mov     w0, w2 
    ret 


.global _isamax_sve
.p2align 4

_isamax_sve:
    cbz     w1, .Lsve_empty

    mov     w1, w1
    smstart sm

    mov     x2, #0

    dup     z0.s, #0
    index   z2.s, #0, #1
    mov     z1.d, z2.d

    whilelo p0.s, x2, x1

.Lsve_loop:
    ld1w    z3.s, p0/z, [x0, x2, lsl #2]
    fabs    z3.s, p0/m, z3.s

    fcmgt   p1.s, p0/z, z3.s, z0.s
    sel     z0.s, p1, z3.s, z0.s
    sel     z1.s, p1, z2.s, z1.s

    incw    z2.s
    incw    x2

    whilelo p0.s, x2, x1
    b.first .Lsve_loop

    ptrue   p0.s
    fmaxv   s4, p0, z0.s
    dup     z3.s, z4.s[0]

    fcmeq   p1.s, p0/z, z0.s, z3.s
    dup     z2.s, #-1
    sel     z1.s, p1, z1.s, z2.s
    uminv   s1, p0, z1.s

    fmov    w0, s1
    smstop sm
    ret

.Lsve_empty:
    mov     w0, #0
    ret





    
