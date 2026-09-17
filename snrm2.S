.text 

.global _snrm2_neon_fast 
.p2align 4 

_snrm2_neon_fast: 
    cbz     x1, .Lneon_fast_done 

    lsr     x2, x1, #4 
    and     x3, x1, #15 
    lsr     x3, x3, #2 
    and     x4, x1, #3 

    movi    v0.4s, #0 
    movi    v1.4s, #0 
    movi    v2.4s, #0 
    movi    v3.4s, #0 

    cbz     x2, .Lsimd_4_fast 

.Lsimd_16_fast_loop: 
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 

    fmla    v0.4s, v4.4s, v4.4s 
    fmla    v1.4s, v5.4s, v5.4s 
    fmla    v2.4s, v6.4s, v6.4s 
    fmla    v3.4s, v7.4s, v7.4s 

    subs    x2, x2, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4_fast: 
    cbz     x3, .Lreduce_fast 

.Lsimd_4_fast_loop:
    ldr     q4, [x0], #32 
    fmla    v0.4s, v4.4s, v4.4s 
    
    subs    x3, x3, #1 
    b.ne    .Lsimd_4_fast_loop 

.Lreduce_fast: 
    fadd    v0.4s, v0.4s, v1.4s 
    fadd    v2.4s, v2.4s, v3.4s 
    fadd    v0.4s, v0.4s, v2.4s 
    faddp   v0.4s, v0.4s, v0.4s 
    faddp   s0, v0.2s

.Lscalar_fast:
    ldr     s4, [x0], #4 
    fmadd   s0, s4, s4, s0 

    subs    x4, x4, #1 
    b.ne    .Lscalar_fast 

.Lneon_fast_done:
    ret 


    

