// WindowsWrapper.h
//
// Includes Windows.h while avoiding conflicts with Oberon types.

#undef BOOLEAN
#undef CHAR
#include <windows.h>
#define BOOLEAN char
#define CHAR    unsigned char
