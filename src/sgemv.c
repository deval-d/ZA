#include <arm_neon.h>

#define MR  16
#define NR  4

static void sgemv_i_outer(
    float alpha,
    float beta,
    float *a,
    float *x,
    float *y,
    uint32_t m,
    uint32_t n
) {
    uint32_t i = 0;

    for (; i + MR <= m; i += MR) {
        float32x4_t y0 = vmulq_n_f32(vld1q_f32(y + i + 0), beta);
        float32x4_t y1 = vmulq_n_f32(vld1q_f32(y + i + 4), beta);
        float32x4_t y2 = vmulq_n_f32(vld1q_f32(y + i + 8), beta);
        float32x4_t y3 = vmulq_n_f32(vld1q_f32(y + i + 12), beta);

        uint32_t j = 0;
        for (; j + NR <= n; j += NR) {
            float32x4_t xv = vmulq_n_f32(vld1q_f32(x + j), alpha);

            float *col0base = a + (j + 0) * m + i;
            float *col1base = a + (j + 1) * m + i;
            float *col2base = a + (j + 2) * m + i;
            float *col3base = a + (j + 3) * m + i;

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(col0base + 0), xv, 0);
            y1 = vfmaq_laneq_f32(y1, vld1q_f32(col0base + 4), xv, 0);
            y2 = vfmaq_laneq_f32(y2, vld1q_f32(col0base + 8), xv, 0);
            y3 = vfmaq_laneq_f32(y3, vld1q_f32(col0base + 12), xv, 0);

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(col1base + 0), xv, 1);
            y1 = vfmaq_laneq_f32(y1, vld1q_f32(col1base + 4), xv, 1);
            y2 = vfmaq_laneq_f32(y2, vld1q_f32(col1base + 8), xv, 1);
            y3 = vfmaq_laneq_f32(y3, vld1q_f32(col1base + 12), xv, 1);

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(col2base + 0), xv, 2);
            y1 = vfmaq_laneq_f32(y1, vld1q_f32(col2base + 4), xv, 2);
            y2 = vfmaq_laneq_f32(y2, vld1q_f32(col2base + 8), xv, 2);
            y3 = vfmaq_laneq_f32(y3, vld1q_f32(col2base + 12), xv, 2);

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(col3base + 0), xv, 3);
            y1 = vfmaq_laneq_f32(y1, vld1q_f32(col3base + 4), xv, 3);
            y2 = vfmaq_laneq_f32(y2, vld1q_f32(col3base + 8), xv, 3);
            y3 = vfmaq_laneq_f32(y3, vld1q_f32(col3base + 12), xv, 3);
        }

        for (; j < n; j++) {
            float xa = x[j] * alpha;
            float *colbase = a + j * m + i;

            y0 = vfmaq_n_f32(y0, vld1q_f32(colbase + 0), xa);
            y1 = vfmaq_n_f32(y1, vld1q_f32(colbase + 4), xa);
            y2 = vfmaq_n_f32(y2, vld1q_f32(colbase + 8), xa);
            y3 = vfmaq_n_f32(y3, vld1q_f32(colbase + 12), xa);
        }

        vst1q_f32(y + i + 0, y0);
        vst1q_f32(y + i + 4, y1);
        vst1q_f32(y + i + 8, y2);
        vst1q_f32(y + i + 12, y3);
    }

    for (; i + 4 <= m; i += 4) {
        float32x4_t y0 = vmulq_n_f32(vld1q_f32(y + i), beta);

        uint32_t j = 0;
        for (; j + NR <= n; j += NR) {
            float32x4_t xv = vmulq_n_f32(vld1q_f32(x + j), alpha);

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 0) * m + i), xv, 0);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 1) * m + i), xv, 1);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 2) * m + i), xv, 2);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 3) * m + i), xv, 3);
        }

        for (; j < n; j++) {
            float xa = x[j] * alpha;
            y0 = vfmaq_n_f32(y0, vld1q_f32(a + j * m + i), xa);
        }

        vst1q_f32(y + i, y0);
    }

    for (; i < m; i++) {
        float yi = y[i] * beta;

        for (uint32_t j = 0; j < n; j++) {
            yi += alpha * x[j] * a[j * m + i];
        }

        y[i] = yi;
    }
}

static void sgemv_j_outer(
    float alpha,
    float beta,
    float *a,
    float *x,
    float *y,
    uint32_t m,
    uint32_t n
) {
    uint32_t j = 0;

    for (; j + NR <= n; j += NR) {
        float32x4_t xv = vmulq_n_f32(vld1q_f32(x + j), alpha);
        uint32_t i = 0;

        for (; i + MR <= m; i += MR) {
            float *col0base = a + (j + 0) * m + i;
            float *col1base = a + (j + 1) * m + i;
            float *col2base = a + (j + 2) * m + i;
            float *col3base = a + (j + 3) * m + i;

            float32x4_t a00 = vld1q_f32(col0base + 0);
            float32x4_t a10 = vld1q_f32(col0base + 4);
            float32x4_t a20 = vld1q_f32(col0base + 8);
            float32x4_t a30 = vld1q_f32(col0base + 12);
            float32x4_t a01 = vld1q_f32(col1base + 0);
            float32x4_t a11 = vld1q_f32(col1base + 4);
            float32x4_t a21 = vld1q_f32(col1base + 8);
            float32x4_t a31 = vld1q_f32(col1base + 12);
            float32x4_t a02 = vld1q_f32(col2base + 0);
            float32x4_t a12 = vld1q_f32(col2base + 4);
            float32x4_t a22 = vld1q_f32(col2base + 8);
            float32x4_t a32 = vld1q_f32(col2base + 12);
            float32x4_t a03 = vld1q_f32(col3base + 0);
            float32x4_t a13 = vld1q_f32(col3base + 4);
            float32x4_t a23 = vld1q_f32(col3base + 8);
            float32x4_t a33 = vld1q_f32(col3base + 12);

            float32x4_t y0 = vld1q_f32(y + i + 0);
            float32x4_t y1 = vld1q_f32(y + i + 4);
            float32x4_t y2 = vld1q_f32(y + i + 8);
            float32x4_t y3 = vld1q_f32(y + i + 12);

            if (j == 0) {
                y0 = vmulq_n_f32(y0, beta);
                y1 = vmulq_n_f32(y1, beta);
                y2 = vmulq_n_f32(y2, beta);
                y3 = vmulq_n_f32(y3, beta);
            }

            y0 = vfmaq_laneq_f32(y0, a00, xv, 0);
            y1 = vfmaq_laneq_f32(y1, a10, xv, 0);
            y2 = vfmaq_laneq_f32(y2, a20, xv, 0);
            y3 = vfmaq_laneq_f32(y3, a30, xv, 0);
            y0 = vfmaq_laneq_f32(y0, a01, xv, 1);
            y1 = vfmaq_laneq_f32(y1, a11, xv, 1);
            y2 = vfmaq_laneq_f32(y2, a21, xv, 1);
            y3 = vfmaq_laneq_f32(y3, a31, xv, 1);
            y0 = vfmaq_laneq_f32(y0, a02, xv, 2);
            y1 = vfmaq_laneq_f32(y1, a12, xv, 2);
            y2 = vfmaq_laneq_f32(y2, a22, xv, 2);
            y3 = vfmaq_laneq_f32(y3, a32, xv, 2);
            y0 = vfmaq_laneq_f32(y0, a03, xv, 3);
            y1 = vfmaq_laneq_f32(y1, a13, xv, 3);
            y2 = vfmaq_laneq_f32(y2, a23, xv, 3);
            y3 = vfmaq_laneq_f32(y3, a33, xv, 3);

            vst1q_f32(y + i + 0, y0);
            vst1q_f32(y + i + 4, y1);
            vst1q_f32(y + i + 8, y2);
            vst1q_f32(y + i + 12, y3);
        }

        for (; i + 4 <= m; i += 4) {
            float32x4_t y0 = vld1q_f32(y + i);

            if (j == 0) {
                y0 = vmulq_n_f32(y0, beta);
            }

            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 0) * m + i), xv, 0);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 1) * m + i), xv, 1);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 2) * m + i), xv, 2);
            y0 = vfmaq_laneq_f32(y0, vld1q_f32(a + (j + 3) * m + i), xv, 3);

            vst1q_f32(y + i, y0);
        }

        for (; i < m; i++) {
            if (j == 0) {
                y[i] *= beta;
            }

            y[i] += a[(j + 0) * m + i] * vgetq_lane_f32(xv, 0);
            y[i] += a[(j + 1) * m + i] * vgetq_lane_f32(xv, 1);
            y[i] += a[(j + 2) * m + i] * vgetq_lane_f32(xv, 2);
            y[i] += a[(j + 3) * m + i] * vgetq_lane_f32(xv, 3);
        }
    }

    for (; j < n; j++) {
        float xa = x[j] * alpha;
        uint32_t i = 0;

        for (; i + MR <= m; i += MR) {
            float32x4_t y0 = vld1q_f32(y + i + 0);
            float32x4_t y1 = vld1q_f32(y + i + 4);
            float32x4_t y2 = vld1q_f32(y + i + 8);
            float32x4_t y3 = vld1q_f32(y + i + 12);

            if (j == 0) {
                y0 = vmulq_n_f32(y0, beta);
                y1 = vmulq_n_f32(y1, beta);
                y2 = vmulq_n_f32(y2, beta);
                y3 = vmulq_n_f32(y3, beta);
            }

            float *colbase = a + j * m + i;
            y0 = vfmaq_n_f32(y0, vld1q_f32(colbase + 0), xa);
            y1 = vfmaq_n_f32(y1, vld1q_f32(colbase + 4), xa);
            y2 = vfmaq_n_f32(y2, vld1q_f32(colbase + 8), xa);
            y3 = vfmaq_n_f32(y3, vld1q_f32(colbase + 12), xa);

            vst1q_f32(y + i + 0, y0);
            vst1q_f32(y + i + 4, y1);
            vst1q_f32(y + i + 8, y2);
            vst1q_f32(y + i + 12, y3);
        }

        for (; i + 4 <= m; i += 4) {
            float32x4_t y0 = vld1q_f32(y + i);

            if (j == 0) {
                y0 = vmulq_n_f32(y0, beta);
            }

            y0 = vfmaq_n_f32(y0, vld1q_f32(a + j * m + i), xa);
            vst1q_f32(y + i, y0);
        }

        for (; i < m; i++) {
            if (j == 0) {
                y[i] *= beta;
            }

            y[i] += a[j * m + i] * xa;
        }
    }
}

void sgemv_neon(
    float alpha,
    float beta,
    float *a,
    float *x,
    float *y,
    uint32_t m,
    uint32_t n
) {
    if (n == 0) {
        for (uint32_t i = 0; i < m; i++) {
            y[i] *= beta;
        }
        return;
    }

    if (m <= MR || m * n <= 2048 || (m <= 2 * MR && n <= 32 * NR)) {
        sgemv_i_outer(alpha, beta, a, x, y, m, n);
        return;
    }

    sgemv_j_outer(alpha, beta, a, x, y, m, n);
}
