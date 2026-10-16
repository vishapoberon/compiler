MODULE PlatformNative;

(* Thin Win32 directory bindings. Native structure layouts remain private. *)
IMPORT SYSTEM;

PROCEDURE -AInclude '#include "WindowsWrapper.h"';
PROCEDURE -error(): SYSTEM.INT32 'GetLastError()';
PROCEDURE Error*(): SYSTEM.INT32;
BEGIN RETURN error() END Error;
PROCEDURE -entrySize(): SYSTEM.ADDRESS 'sizeof(WIN32_FIND_DATAA)';
PROCEDURE EntrySize*(): SYSTEM.ADDRESS;
BEGIN RETURN entrySize() END EntrySize;
PROCEDURE -invalid(): SYSTEM.ADDRESS '(ADDRESS)INVALID_HANDLE_VALUE';
PROCEDURE Invalid*(): SYSTEM.ADDRESS;
BEGIN RETURN invalid() END Invalid;
PROCEDURE -attributes(path: ARRAY OF CHAR): SYSTEM.INT32 'GetFileAttributesA((char*)path)';
PROCEDURE Attributes*(path: ARRAY OF CHAR): SYSTEM.INT32;
BEGIN RETURN attributes(path) END Attributes;
PROCEDURE -invalidAttributes(value: SYSTEM.INT32): BOOLEAN '(DWORD)value == INVALID_FILE_ATTRIBUTES';
PROCEDURE InvalidAttributes*(value: SYSTEM.INT32): BOOLEAN;
BEGIN RETURN invalidAttributes(value) END InvalidAttributes;
PROCEDURE -directory(value: SYSTEM.INT32): BOOLEAN '(value & FILE_ATTRIBUTE_DIRECTORY) != 0';
PROCEDURE Directory*(value: SYSTEM.INT32): BOOLEAN;
BEGIN RETURN directory(value) END Directory;
PROCEDURE -directoryError(): SYSTEM.INT32 'ERROR_DIRECTORY';
PROCEDURE DirectoryError*(): SYSTEM.INT32;
BEGIN RETURN directoryError() END DirectoryError;
PROCEDURE -noMemory(): SYSTEM.INT32 'ERROR_NOT_ENOUGH_MEMORY';
PROCEDURE NoMemory*(): SYSTEM.INT32;
BEGIN RETURN noMemory() END NoMemory;
PROCEDURE -nameTooLong(): SYSTEM.INT32 'ERROR_INSUFFICIENT_BUFFER';
PROCEDURE NameTooLong*(): SYSTEM.INT32;
BEGIN RETURN nameTooLong() END NameTooLong;
PROCEDURE -noFiles(error: SYSTEM.INT32): BOOLEAN 'error == ERROR_FILE_NOT_FOUND';
PROCEDURE NoFiles*(error: SYSTEM.INT32): BOOLEAN;
BEGIN RETURN noFiles(error) END NoFiles;
PROCEDURE -noMoreFiles(error: SYSTEM.INT32): BOOLEAN 'error == ERROR_NO_MORE_FILES';
PROCEDURE NoMoreFiles*(error: SYSTEM.INT32): BOOLEAN;
BEGIN RETURN noMoreFiles(error) END NoMoreFiles;
PROCEDURE -first(pattern: ARRAY OF CHAR; entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS
  '(ADDRESS)FindFirstFileA((char*)pattern, (WIN32_FIND_DATAA*)entry)';
PROCEDURE First*(pattern: ARRAY OF CHAR; entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
BEGIN RETURN first(pattern, entry) END First;
PROCEDURE -next(search, entry: SYSTEM.ADDRESS): BOOLEAN
  'FindNextFileA((HANDLE)search, (WIN32_FIND_DATAA*)entry) != 0';
PROCEDURE Next*(search, entry: SYSTEM.ADDRESS): BOOLEAN;
BEGIN RETURN next(search, entry) END Next;
PROCEDURE -close(search: SYSTEM.ADDRESS): BOOLEAN 'FindClose((HANDLE)search) != 0';
PROCEDURE Close*(search: SYSTEM.ADDRESS): BOOLEAN;
BEGIN RETURN close(search) END Close;
PROCEDURE -entryName(entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS '(ADDRESS)((WIN32_FIND_DATAA*)entry)->cFileName';
PROCEDURE EntryName*(entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
BEGIN RETURN entryName(entry) END EntryName;

END PlatformNative.
