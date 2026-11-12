#include <stdint.h>

static float a[257], b[257];
static int32_t integers[257];

int main(void)
{
    for (int i = 0; i < 257; ++i) {
        a[i] = i;
        b[i] = i * 2;
        integers[i] = -99;
    }
    float *pa = a, *pb = b;
    int32_t *pi = integers;
    float factor = 3;
    uint64_t count = 255;
    int32_t start = 1;
    #pragma omp target teams distribute parallel for map(tofrom: pa[0:257], pi[0:257]) map(to: pb[0:257]) firstprivate(factor, count, start)
    for (uint64_t offset = 0; offset < count; ++offset) {
        int32_t r = offset + start;
        pa[r] += pb[r] * factor;
        pi[r] = r * 4;
    }
    for (int i = 1; i < 256; ++i) {
        if (a[i] != i * 7 || integers[i] != i * 4) return 78;
    }
    if (a[0] != 0 || a[256] != 256 || integers[0] != -99 || integers[256] != -99) return 78;
    return 0;
}
