#include <omp.h>

int main(void)
{
    int initial = 1;
    #pragma omp target map(from: initial)
    {
        initial = omp_is_initial_device();
    }
    return initial ? 77 : 0;
}
