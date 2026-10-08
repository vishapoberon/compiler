#ifndef VOC_SHARED_MODULES_SUPPORT_H
#define VOC_SHARED_MODULES_SUPPORT_H

#include "Heap.h"

typedef void (*VOCShared_Visitor)(CHAR *name, ADDRESS length);

void VOCShared_default_path(char *path, ADDRESS capacity);
ADDRESS VOCShared_open(const char *name, const char *path, const char *model,
    INT32 short_size, INT32 int_size, INT32 long_size, INT32 set_size,
    char *error, ADDRESS capacity);
void *VOCShared_body(ADDRESS handle, const char *name);
void VOCShared_modules(const char *path, const char *model, VOCShared_Visitor visit);
int VOCShared_symbol(const char *name, const char *path, const char *model,
    char *filename, ADDRESS capacity);

#endif
