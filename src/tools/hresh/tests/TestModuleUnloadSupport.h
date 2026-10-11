#ifndef VOC_TEST_MODULE_UNLOAD_SUPPORT_H
#define VOC_TEST_MODULE_UNLOAD_SUPPORT_H
#include "SYSTEM.h"
ADDRESS VOCUnload_hold(ADDRESS procedure);
void VOCUnload_release(ADDRESS handle);
ADDRESS VOCUnload_scrub(void);
#endif
