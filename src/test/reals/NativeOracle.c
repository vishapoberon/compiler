/* Differential test oracle only: production conversions are in Reals.Mod. */
#include "SYSTEM.h"
#include "Reals.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

static uint64_t seed = 1;
static uint64_t next(void) {
    seed ^= seed << 13;
    seed ^= seed >> 7;
    seed ^= seed << 17;
    return seed;
}

static void check(const char *text) {
    double actual = Reals_ParseLongReal((CHAR*)text, strlen(text) + 1);
    double expected = strtod(text, NULL);
    float small = Reals_ParseReal((CHAR*)text, strlen(text) + 1);
    float expected_small = strtof(text, NULL);
    if (memcmp(&actual, &expected, sizeof actual) ||
        memcmp(&small, &expected_small, sizeof small)) {
        fprintf(stderr, "parse %s: %.17g / %.17g; %.9g / %.9g\n",
                text, actual, expected, small, expected_small);
        abort();
    }
}

int main(int argc, char **argv) {
    int i;
    __INIT(argc, argv);
    __MODULE_IMPORT(Reals);
    for (i = 0; i < 20000; ++i) {
        uint64_t bits = next();
        uint32_t small_bits = (uint32_t)next();
        double value;
        float small;
        char text[128];
        memcpy(&value, &bits, sizeof value);
        if (isfinite(value)) {
            double actual;
            snprintf(text, sizeof text, "%.17e", value);
            check(text);
            Reals_FormatLongReal(value, (CHAR*)text, sizeof text);
            actual = strtod(text, NULL);
            if (memcmp(&actual, &value, sizeof actual)) {
                fprintf(stderr, "format %.17g -> %s -> %.17g\n", value, text, actual);
                abort();
            }
        }
        memcpy(&small, &small_bits, sizeof small);
        if (isfinite(small)) {
            float actual;
            snprintf(text, sizeof text, "%.9e", (double)small);
            check(text);
            actual = Reals_ParseReal((CHAR*)text, strlen(text) + 1);
            if (memcmp(&actual, &small, sizeof actual)) abort();
        }
    }
    puts("random real conversion/format vectors passed");
    __FINI;
    return 0;
}
