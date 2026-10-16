/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"




export INT32 PlatformNative_Attributes (CHAR *path, ADDRESS path__len);
export BOOLEAN PlatformNative_Close (INT64 search);
export BOOLEAN PlatformNative_Directory (INT32 value);
export INT32 PlatformNative_DirectoryError (void);
export INT64 PlatformNative_EntryName (INT64 entry);
export INT64 PlatformNative_EntrySize (void);
export INT32 PlatformNative_Error (void);
export INT64 PlatformNative_First (CHAR *pattern, ADDRESS pattern__len, INT64 entry);
export INT64 PlatformNative_Invalid (void);
export BOOLEAN PlatformNative_InvalidAttributes (INT32 value);
export INT32 PlatformNative_NameTooLong (void);
export BOOLEAN PlatformNative_Next (INT64 search, INT64 entry);
export BOOLEAN PlatformNative_NoFiles (INT32 error);
export INT32 PlatformNative_NoMemory (void);
export BOOLEAN PlatformNative_NoMoreFiles (INT32 error);

#include "WindowsWrapper.h"
#define PlatformNative_attributes(path, path__len)	GetFileAttributesA((char*)path)
#define PlatformNative_close(search)	FindClose((HANDLE)search) != 0
#define PlatformNative_directory(value)	(value & FILE_ATTRIBUTE_DIRECTORY) != 0
#define PlatformNative_directoryError()	ERROR_DIRECTORY
#define PlatformNative_entryName(entry)	(ADDRESS)((WIN32_FIND_DATAA*)entry)->cFileName
#define PlatformNative_entrySize()	sizeof(WIN32_FIND_DATAA)
#define PlatformNative_error()	GetLastError()
#define PlatformNative_first(pattern, pattern__len, entry)	(ADDRESS)FindFirstFileA((char*)pattern, (WIN32_FIND_DATAA*)entry)
#define PlatformNative_invalid()	(ADDRESS)INVALID_HANDLE_VALUE
#define PlatformNative_invalidAttributes(value)	(DWORD)value == INVALID_FILE_ATTRIBUTES
#define PlatformNative_nameTooLong()	ERROR_INSUFFICIENT_BUFFER
#define PlatformNative_next(search, entry)	FindNextFileA((HANDLE)search, (WIN32_FIND_DATAA*)entry) != 0
#define PlatformNative_noFiles(error)	error == ERROR_FILE_NOT_FOUND
#define PlatformNative_noMemory()	ERROR_NOT_ENOUGH_MEMORY
#define PlatformNative_noMoreFiles(error)	error == ERROR_NO_MORE_FILES

INT32 PlatformNative_Error (void)
{
	return PlatformNative_error();
}

INT64 PlatformNative_EntrySize (void)
{
	return PlatformNative_entrySize();
}

INT64 PlatformNative_Invalid (void)
{
	return PlatformNative_invalid();
}

INT32 PlatformNative_Attributes (CHAR *path, ADDRESS path__len)
{
	__DUP(path, path__len, CHAR);
	__DEL(path);
	return PlatformNative_attributes(path, path__len);
}

BOOLEAN PlatformNative_InvalidAttributes (INT32 value)
{
	return PlatformNative_invalidAttributes(value);
}

BOOLEAN PlatformNative_Directory (INT32 value)
{
	return PlatformNative_directory(value);
}

INT32 PlatformNative_DirectoryError (void)
{
	return PlatformNative_directoryError();
}

INT32 PlatformNative_NoMemory (void)
{
	return PlatformNative_noMemory();
}

INT32 PlatformNative_NameTooLong (void)
{
	return PlatformNative_nameTooLong();
}

BOOLEAN PlatformNative_NoFiles (INT32 error)
{
	return PlatformNative_noFiles(error);
}

BOOLEAN PlatformNative_NoMoreFiles (INT32 error)
{
	return PlatformNative_noMoreFiles(error);
}

INT64 PlatformNative_First (CHAR *pattern, ADDRESS pattern__len, INT64 entry)
{
	__DUP(pattern, pattern__len, CHAR);
	__DEL(pattern);
	return PlatformNative_first(pattern, pattern__len, entry);
}

BOOLEAN PlatformNative_Next (INT64 search, INT64 entry)
{
	return PlatformNative_next(search, entry);
}

BOOLEAN PlatformNative_Close (INT64 search)
{
	return PlatformNative_close(search);
}

INT64 PlatformNative_EntryName (INT64 entry)
{
	return PlatformNative_entryName(entry);
}


export void *PlatformNative__init(void)
{
	__DEFMOD;
	__REGMOD("PlatformNative", 0);
/* BEGIN */
	__ENDMOD;
}
