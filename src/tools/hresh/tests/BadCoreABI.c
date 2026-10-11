#include "Heap.h"
#include <stdlib.h>

/* Layout alone is insufficient: a library must use this host's core. */
static const INT32 other_core = VOC_CORE_ABI_PROFILE;
export const INT32 *BadCoreABI__voc_runtime = &other_core;
#if defined(VOC_TEST_MODEL_2)
#define MODEL_SIZES 1, 2, 4, 4
#elif defined(VOC_TEST_MODEL_C)
#define MODEL_SIZES 2, 4, 8, 4
#elif defined(VOC_TEST_MODEL_V)
#define MODEL_SIZES 1, 4, 8, 8
#else
#error select the test type model
#endif
export const INT32 BadCoreABI__voc_abi[] = {
    VOC_SHARED_ABI_FORMAT, sizeof(ADDRESS), MODEL_SIZES,
    sizeof(Heap_ModuleDesc), sizeof(Heap_CmdDesc), VOC_CORE_ABI_PROFILE
};

export void *BadCoreABI__init(void)
{
    abort(); /* The loader must reject this library before initialization. */
}
