.text

.global _idamax
.p2align 4

_idamax:
    b       _idamax_neon


.global _idamax_neon
.p2align 4

_idamax_neon:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    mov     x5, #0
    mov     x6, #1
    mov     v17.d[0], x5
    mov     v17.d[1], x6

    mov     x7, #2
    dup     v16.2d, x7
    add     v18.2d, v17.2d, v16.2d
    add     v19.2d, v18.2d, v16.2d
    add     v28.2d, v19.2d, v16.2d

    movi    v0.2d, #0

    mov     v1.16b, v0.16b
    mov     v25.16b, v0.16b
    mov     v26.16b, v0.16b
    mov     v27.16b, v0.16b
    mov     v29.16b, v17.16b

    movi    v2.2d, #0
    movi    v22.2d, #0
    movi    v23.2d, #0
    movi    v24.2d, #0

    mov     x7, #8
    dup     v16.2d, x7

    cbz     w2, .Lsimd_2

.Lsimd_8_loop:
    ldp     q3, q4, [x0], #32
    ldp     q5, q6, [x0], #32

    fabs    v3.2d, v3.2d
    fabs    v4.2d, v4.2d
    fabs    v5.2d, v5.2d
    fabs    v6.2d, v6.2d

    fcmgt   v7.2d, v3.2d, v2.2d
    bit     v2.16b, v3.16b, v7.16b
    bit     v1.16b, v0.16b, v7.16b

    fcmgt   v7.2d, v4.2d, v22.2d
    bit     v22.16b, v4.16b, v7.16b
    bit     v25.16b, v0.16b, v7.16b

    fcmgt   v7.2d, v5.2d, v23.2d
    bit     v23.16b, v5.16b, v7.16b
    bit     v26.16b, v0.16b, v7.16b

    fcmgt   v7.2d, v6.2d, v24.2d
    bit     v24.16b, v6.16b, v7.16b
    bit     v27.16b, v0.16b, v7.16b

    add     v0.2d, v0.2d, v16.2d

    subs    w2, w2, #1
    b.ne    .Lsimd_8_loop

.Lsimd_2:
    mov     x7, #2
    dup     v16.2d, x7
    cbz     w3, .Lreduce

.Lsimd_2_loop:
    ldr     q3, [x0], #16
    fabs    v3.2d, v3.2d

    fcmgt   v7.2d, v3.2d, v2.2d
    bit     v2.16b, v3.16b, v7.16b
    bit     v1.16b, v0.16b, v7.16b

    add     v0.2d, v0.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lsimd_2_loop

.Lreduce:
    fcmgt   v7.2d, v22.2d, v2.2d
    fcmeq   v20.2d, v22.2d, v2.2d
    cmhi    v21.2d, v1.2d, v25.2d
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v22.16b, v7.16b
    bit     v1.16b, v25.16b, v7.16b
    bit     v29.16b, v18.16b, v7.16b

    fcmgt   v7.2d, v23.2d, v2.2d
    fcmeq   v20.2d, v23.2d, v2.2d
    cmhi    v21.2d, v1.2d, v26.2d
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v23.16b, v7.16b
    bit     v1.16b, v26.16b, v7.16b
    bit     v29.16b, v19.16b, v7.16b

    fcmgt   v7.2d, v24.2d, v2.2d
    fcmeq   v20.2d, v24.2d, v2.2d
    cmhi    v21.2d, v1.2d, v27.2d
    and     v20.16b, v20.16b, v21.16b
    orr     v7.16b, v7.16b, v20.16b
    bit     v2.16b, v24.16b, v7.16b
    bit     v1.16b, v27.16b, v7.16b
    bit     v29.16b, v28.16b, v7.16b

    add     v1.2d, v1.2d, v29.2d

    fmaxp   d16, v2.2d
    dup     v16.2d, v16.d[0]

    fcmeq   v7.2d, v2.2d, v16.2d
    mvn     v7.16b, v7.16b
    orr     v1.16b, v1.16b, v7.16b

    umov    x2, v1.d[0]
    umov    x5, v1.d[1]
    cmp     x2, x5
    csel    x2, x2, x5, lo

    umov    x3, v0.d[0]

    cbz     w4, .Lneon_done

    ldr     d3, [x0]
    fabs    d3, d3

    fcmp    d3, d16
    csel    w2, w3, w2, gt

.Lneon_done:
    mov     w0, w2
    ret


.global _idamax_sve
.p2align 4

_idamax_sve:
    cbz     w1, .Lsve_empty

    mov     w1, w1
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    mov     x2, #0

    dup     z0.d, #0
    index   z2.d, #0, #1
    mov     z1.d, z2.d

    whilelo p0.d, x2, x1

.Lsve_loop:
    ld1d    z3.d, p0/z, [x0, x2, lsl #3]
    fabs    z3.d, p0/m, z3.d

    fcmgt   p1.d, p0/z, z3.d, z0.d
    sel     z0.d, p1, z3.d, z0.d
    sel     z1.d, p1, z2.d, z1.d

    incd    z2.d
    incd    x2

    whilelo p0.d, x2, x1
    b.first .Lsve_loop

    ptrue   p0.d
    fmaxv   d4, p0, z0.d
    dup     z3.d, z4.d[0]

    fcmeq   p1.d, p0/z, z0.d, z3.d
    dup     z2.d, #-1
    sel     z1.d, p1, z1.d, z2.d
    uminv   d1, p0, z1.d

    fmov    x0, d1
    smstop sm

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret

.Lsve_empty:
    mov     w0, #0
    ret
