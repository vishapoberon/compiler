#ifndef VOC_PLATFORM_DIRECTORY_H
#define VOC_PLATFORM_DIRECTORY_H

/* Opaque directory cursors. No libc structure layout leaks into Oberon. */
#include <stdlib.h>
#include <string.h>
#include "SYSTEM.h"

#ifdef _WIN32
#include "WindowsWrapper.h"

typedef struct {
    HANDLE search;
    WIN32_FIND_DATAA entry;
    int first;
} VOC_Directory;

static inline int VOC_OpenDirectory(const char *path, ADDRESS *handle)
{
    VOC_Directory *dir;
    char *pattern;
    size_t n = strlen(path);
    DWORD attributes = GetFileAttributesA(path);
    *handle = 0;
    if (attributes == INVALID_FILE_ATTRIBUTES) return (int)GetLastError();
    if (!(attributes & FILE_ATTRIBUTE_DIRECTORY)) return ERROR_DIRECTORY;
    pattern = malloc(n + 3);
    dir = malloc(sizeof *dir);
    if (!pattern || !dir) {
        free(pattern); free(dir);
        return ERROR_NOT_ENOUGH_MEMORY;
    }
    memcpy(pattern, path, n);
    if (n && path[n - 1] != '/' && path[n - 1] != '\\') pattern[n++] = '/';
    pattern[n++] = '*'; pattern[n] = 0;
    dir->search = FindFirstFileA(pattern, &dir->entry);
    free(pattern);
    dir->first = dir->search != INVALID_HANDLE_VALUE;
    if (!dir->first) {
        DWORD error = GetLastError();
        if (error != ERROR_FILE_NOT_FOUND) { free(dir); return (int)error; }
    }
    *handle = (ADDRESS)dir;
    return 0;
}

static inline int VOC_ReadDirectory(ADDRESS handle, char *name,
    ADDRESS capacity, BOOLEAN *done)
{
    VOC_Directory *dir = (VOC_Directory *)handle;
    size_t n;
    *done = 0;
    if (capacity > 0) name[0] = 0;
    if (dir->search == INVALID_HANDLE_VALUE) { *done = 1; return 0; }
    if (!dir->first && !FindNextFileA(dir->search, &dir->entry)) {
        DWORD error = GetLastError();
        *done = 1;
        return error == ERROR_NO_MORE_FILES ? 0 : (int)error;
    }
    dir->first = 0;
    n = strlen(dir->entry.cFileName);
    if (capacity <= 0 || n >= (size_t)capacity) return ERROR_INSUFFICIENT_BUFFER;
    memcpy(name, dir->entry.cFileName, n + 1);
    return 0;
}

static inline int VOC_CloseDirectory(ADDRESS *handle)
{
    VOC_Directory *dir = (VOC_Directory *)*handle;
    int error = 0;
    if (!dir) return 0;
    if (dir->search != INVALID_HANDLE_VALUE && !FindClose(dir->search))
        error = (int)GetLastError();
    free(dir); *handle = 0;
    return error;
}

static inline BOOLEAN VOC_IsDirectory(const char *path)
{
    DWORD attributes = GetFileAttributesA(path);
    return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY);
}

#else
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>

static inline int VOC_OpenDirectory(const char *path, ADDRESS *handle)
{
    DIR *dir = opendir(path);
    *handle = (ADDRESS)dir;
    return dir ? 0 : errno;
}

static inline int VOC_ReadDirectory(ADDRESS handle, char *name,
    ADDRESS capacity, BOOLEAN *done)
{
    struct dirent *entry;
    size_t n;
    if (capacity > 0) name[0] = 0;
    errno = 0;
    entry = readdir((DIR *)handle);
    *done = entry == NULL;
    if (!entry) return errno;
    n = strlen(entry->d_name);
    if (capacity <= 0 || n >= (size_t)capacity) return ENAMETOOLONG;
    memcpy(name, entry->d_name, n + 1);
    return 0;
}

static inline int VOC_CloseDirectory(ADDRESS *handle)
{
    int result, error;
    if (!*handle) return 0;
    result = closedir((DIR *)*handle);
    error = result < 0 ? errno : 0;
    *handle = 0;
    return error;
}

static inline BOOLEAN VOC_IsDirectory(const char *path)
{
    struct stat info;
    return stat(path, &info) == 0 && S_ISDIR(info.st_mode);
}
#endif

#endif
