#include <omp.h>
#include <stdint.h>

int main(int argc, char **argv)
{
    int values[32], initial[32], on_host = 0;
    if (argc > 2) {
        if (argv[1][0] == '6') {
            uint64_t limit = 32;
            #pragma omp target teams distribute parallel for map(from: values[0:32], initial[0:32]) firstprivate(limit)
            for (uint64_t i = 0; i < limit; ++i) {
                values[i] = (int)i + 1;
                initial[i] = omp_is_initial_device();
            }
        } else {
            int limit = 32;
            #pragma omp target teams distribute parallel for map(from: values[0:32], initial[0:32]) firstprivate(limit)
            for (int i = 0; i < limit; ++i) {
                values[i] = i + 1;
                initial[i] = omp_is_initial_device();
            }
        }
    } else if (argc > 1 && argv[1][0] == '6') {
        #pragma omp target teams distribute parallel for map(from: values[0:32], initial[0:32])
        for (uint64_t i = 0; i < 32; ++i) {
            values[i] = (int)i + 1;
            initial[i] = omp_is_initial_device();
        }
    } else {
        #pragma omp target teams distribute parallel for map(from: values[0:32], initial[0:32])
        for (int i = 0; i < 32; ++i) {
            values[i] = i + 1;
            initial[i] = omp_is_initial_device();
        }
    }
    for (int i = 0; i < 32; ++i) {
        if (values[i] != i + 1) return 78;
        on_host |= initial[i];
    }
    return on_host ? 77 : 0;
}
