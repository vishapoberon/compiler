#define _GNU_SOURCE
#include <dlfcn.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "SharedModulesSupport.h"

#ifndef VOC_RESOURCE_ROOT
#define VOC_RESOURCE_ROOT "/usr/share/voc"
#endif

/* The handles returned by open are deliberately never closed after __init.
   In particular, dlclose is NOT an implementation of Heap.FreeModule. */

static int identifier(const char *s, size_t maximum)
{
    size_t n = 0;
    if (!((*s >= 'A' && *s <= 'Z') || (*s >= 'a' && *s <= 'z'))) return 0;
    for (; *s; s++, n++) {
        if (!((*s >= 'A' && *s <= 'Z') || (*s >= 'a' && *s <= 'z') ||
              (*s >= '0' && *s <= '9') || *s == '_')) return 0;
    }
    return n <= maximum;
}

/* Empty path components mean the current directory, as in loksh. */
static int directory(const char **path, char *dir, size_t capacity)
{
    const char *end;
    size_t n;
    if (!*path) return 0;
    end = strchr(*path, ':');
    n = end ? (size_t)(end - *path) : strlen(*path);
    if (n >= capacity) { *path = end ? end + 1 : NULL; return -1; }
    memcpy(dir, *path, n);
    dir[n] = 0;
    if (!n) strcpy(dir, ".");
    *path = end ? end + 1 : NULL;
    return 1;
}

static int filename(char *out, size_t capacity, const char *dir,
    const char *name, const char *model, const char *extension)
{
    int n = snprintf(out, capacity, "%s/libvoc-%s-%s.%s", dir, name, model, extension);
    return n >= 0 && (size_t)n < capacity;
}

void VOCShared_default_path(char *path, ADDRESS capacity)
{
    Dl_info info;
    char dir[4096], *slash;
    const char *env = getenv("VOC_MODULE_PATH");
    if (env) { snprintf(path, (size_t)capacity, "%s", env); return; }
    snprintf(path, (size_t)capacity, ".");
    /* The loader's directory works with both shared and embedded cores. */
    if (dladdr((void *)VOCShared_open, &info) && info.dli_fname) {
        snprintf(dir, sizeof dir, "%s", info.dli_fname);
        slash = strrchr(dir, '/');
        if (slash) {
            *slash = 0;
            snprintf(path, (size_t)capacity, ".:%s", dir);
        }
    }
}

ADDRESS VOCShared_open(const char *name, const char *path, const char *model,
    INT32 short_size, INT32 int_size, INT32 long_size, INT32 set_size,
    char *error, ADDRESS capacity)
{
    char dir[4096], file[8192], symbol[128];
    const char *cursor = path;
    void *handle = NULL;
    const INT32 *abi;
    const INT32 expected[] = {2, sizeof(ADDRESS), short_size, int_size,
        long_size, set_size, sizeof(Heap_ModuleDesc), sizeof(Heap_CmdDesc), 1};
    size_t i;
    int status, found = 0;

    if (!identifier(name, sizeof(Heap_ModuleName) - 1)) {
        snprintf(error, (size_t)capacity, "invalid module name (maximum %zu characters)", sizeof(Heap_ModuleName) - 1);
        return 0;
    }
    while ((status = directory(&cursor, dir, sizeof dir))) {
        if (status < 0 || !filename(file, sizeof file, dir, name, model, "so")) continue;
        if (access(file, F_OK) == 0) {
            found = 1;
            handle = dlopen(file, RTLD_NOW | RTLD_GLOBAL);
            break;
        }
    }
    if (!found) {
        snprintf(file, sizeof file, "libvoc-%s-%s.so", name, model);
        handle = dlopen(file, RTLD_NOW | RTLD_GLOBAL);
    }
    if (!handle) {
        const char *message = dlerror();
        snprintf(error, (size_t)capacity, "%s", message ? message : "library not found");
        return 0;
    }

    snprintf(symbol, sizeof symbol, "%s__voc_abi", name);
    abi = dlsym(handle, symbol);
    if (!abi) {
        snprintf(error, (size_t)capacity, "%s: missing VOC shared-module ABI descriptor", file);
        dlclose(handle);
        return 0;
    }
    for (i = 0; i < sizeof expected / sizeof expected[0]; i++) {
        if (abi[i] != expected[i]) {
            snprintf(error, (size_t)capacity, "%s: incompatible VOC shared-module ABI", file);
            dlclose(handle);
            return 0;
        }
    }
    snprintf(symbol, sizeof symbol, "%s__init", name);
    if (!dlsym(handle, symbol)) {
        snprintf(error, (size_t)capacity, "%s: missing %s", file, symbol);
        dlclose(handle);
        return 0;
    }
    error[0] = 0;
    return (ADDRESS)handle;
}

void *VOCShared_body(ADDRESS handle, const char *name)
{
    char symbol[128];
    snprintf(symbol, sizeof symbol, "%s__init", name);
    return dlsym((void *)handle, symbol);
}

static void symbol_path(char *path, size_t capacity, const char *model)
{
    const char *env = getenv("VOC_SYM_PATH");
    const char *root = getenv("VOCROOT");
    const char *subdir = !strcmp(model, "O2") ? "2" : (!strcmp(model, "OC") ? "C" : "V");
    if (env) { snprintf(path, capacity, "%s", env); return; }
    if (!root) root = VOC_RESOURCE_ROOT;
    snprintf(path, capacity, "%s/modular/%s/sym", root, subdir);
}

static void enumerate_directory(const char *dir, const char *model,
    VOCShared_Visitor visit, int symbols)
{
    char suffix[32], name[sizeof(Heap_ModuleName)];
    DIR *stream;
    struct dirent *entry;
    size_t n, prefix_size = symbols ? 0 : 7, suffix_size;
    if (!(stream = opendir(dir))) return;
    if (symbols) snprintf(suffix, sizeof suffix, ".sym");
    else snprintf(suffix, sizeof suffix, "-%s.so", model);
    suffix_size = strlen(suffix);
    while ((entry = readdir(stream))) {
        n = strlen(entry->d_name);
        if (n <= prefix_size + suffix_size ||
            (!symbols && strncmp(entry->d_name, "libvoc-", prefix_size)) ||
            strcmp(entry->d_name + n - suffix_size, suffix)) continue;
        n -= prefix_size + suffix_size;
        if (n >= sizeof name) continue;
        memcpy(name, entry->d_name + prefix_size, n);
        name[n] = 0;
        if (!symbols && !strcmp(name, "core")) continue; /* Runtime, not an Oberon module. */
        if (identifier(name, sizeof name - 1)) visit((CHAR *)name, sizeof name);
    }
    closedir(stream);
}

void VOCShared_modules(const char *path, const char *model, VOCShared_Visitor visit)
{
    char dir[4096], symbols[8192];
    const char *cursor = path;
    int status;
    while ((status = directory(&cursor, dir, sizeof dir))) {
        if (status < 0) continue;
        enumerate_directory(dir, model, visit, 0);
        enumerate_directory(dir, model, visit, 1);
    }
    symbol_path(symbols, sizeof symbols, model);
    cursor = symbols;
    while ((status = directory(&cursor, dir, sizeof dir)))
        if (status > 0) enumerate_directory(dir, model, visit, 1);
}

int VOCShared_symbol(const char *name, const char *path, const char *model,
    char *file, ADDRESS capacity)
{
    char dir[4096], symbols[8192];
    const char *cursor = path;
    int pass, status, n;
    if (!identifier(name, sizeof(Heap_ModuleName) - 1)) return 0;
    symbol_path(symbols, sizeof symbols, model);
    for (pass = 0; pass < 2; pass++, cursor = symbols) {
        while ((status = directory(&cursor, dir, sizeof dir))) {
            if (status < 0) continue;
            n = snprintf(file, (size_t)capacity, "%s/%s.sym", dir, name);
            if (n >= 0 && n < capacity && !access(file, R_OK)) return 1;
        }
    }
    return 0;
}
