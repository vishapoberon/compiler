#define _GNU_SOURCE
#include <dlfcn.h>
#include "TestModuleUnloadSupport.h"

ADDRESS VOCUnload_hold(ADDRESS procedure)
{
    Dl_info info;
    if (!dladdr((void *)procedure, &info)) return 0;
    return (ADDRESS)dlopen(info.dli_fname, RTLD_NOW | RTLD_NOLOAD);
}

void VOCUnload_release(ADDRESS handle)
{
    if (handle) dlclose((void *)handle);
}

ADDRESS VOCUnload_scrub(void)
{
    /* Overwrite discarded helper frames, not any live caller's storage.
       Conservative stack roots otherwise depend on each compiler's layout. */
    volatile ADDRESS discarded[32768];
    size_t i;
    for (i = 0; i < sizeof discarded / sizeof discarded[0]; ++i) discarded[i] = 0;
    return discarded[0];
}
