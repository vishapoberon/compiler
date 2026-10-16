/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"




export INT32 PlatformNative_BadFD (void);
export void PlatformNative_ClearError (void);
export INT32 PlatformNative_CloseDirectory (INT32 handle);
export INT32 PlatformNative_EntryName (INT32 entry);
export INT32 PlatformNative_Error (void);
export INT32 PlatformNative_GetTerminal (INT32 fd, INT32 state);
export UINT64 PlatformNative_InputFlags (INT32 state);
export UINT64 PlatformNative_InputRawMask (void);
export UINT64 PlatformNative_LocalFlags (INT32 state);
export UINT64 PlatformNative_LocalRawMask (void);
export INT32 PlatformNative_MakeDirectory (CHAR *path, ADDRESS path__len);
export INT32 PlatformNative_MinIndex (void);
export INT32 PlatformNative_NameTooLong (void);
export INT32 PlatformNative_NoMemory (void);
export INT32 PlatformNative_OpenDirectory (CHAR *path, ADDRESS path__len);
export INT32 PlatformNative_Overflow (void);
export INT32 PlatformNative_PathKind (CHAR *path, ADDRESS path__len, BOOLEAN follow, INT16 *kind);
export INT32 PlatformNative_ReadDirectory (INT32 handle);
export void PlatformNative_SetControl (INT32 state, INT32 index, INT32 value);
export void PlatformNative_SetInputFlags (INT32 state, UINT64 flags);
export void PlatformNative_SetLocalFlags (INT32 state, UINT64 flags);
export INT32 PlatformNative_SetTerminal (INT32 fd, INT32 state);
export INT32 PlatformNative_TerminalSize (void);
export INT32 PlatformNative_TimeIndex (void);
export INT32 PlatformNative_WindowSize (INT32 fd, INT32 *lines, INT32 *cols);

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#ifdef __TINYC__
#include_next <termios.h>
#else
#include <termios.h>
#endif
#define PlatformNative_badFD()	EBADF
#define PlatformNative_clearError()	errno = 0
#define PlatformNative_closeDirectory(handle)	closedir((DIR*)handle)
#define PlatformNative_columns()	window.ws_col
#define PlatformNative_entryName(entry)	(ADDRESS)((struct dirent*)entry)->d_name
#define PlatformNative_error()	errno
#define PlatformNative_getTerminal(fd, state)	tcgetattr(fd, (struct termios*)state)
#define PlatformNative_getWindow(fd)	ioctl(fd, TIOCGWINSZ, &window)
#define PlatformNative_inputFlags(state)	(UINT64)((struct termios*)state)->c_iflag
#define PlatformNative_inputRawMask()	(UINT64)(ICRNL | IXON)
#define PlatformNative_isDirectory()	S_ISDIR(info.st_mode)
#define PlatformNative_isRegular()	S_ISREG(info.st_mode)
#define PlatformNative_localFlags(state)	(UINT64)((struct termios*)state)->c_lflag
#define PlatformNative_localRawMask()	(UINT64)(ICANON | ECHO | ISIG | IEXTEN)
#define PlatformNative_lstat(path, path__len)	lstat((char*)path, &info)
#define PlatformNative_minIndex()	VMIN
#define PlatformNative_mkdir(path, path__len)	mkdir((char*)path, 0777)
#define PlatformNative_nameTooLong()	ENAMETOOLONG
#define PlatformNative_noMemory()	ENOMEM
#define PlatformNative_openDirectory(path, path__len)	(ADDRESS)opendir((char*)path)
#define PlatformNative_overflow()	EOVERFLOW
#define PlatformNative_readDirectory(handle)	(ADDRESS)readdir((DIR*)handle)
#define PlatformNative_rows()	window.ws_row
#define PlatformNative_setControl(state, index, value)	((struct termios*)state)->c_cc[index] = (cc_t)value
#define PlatformNative_setInputFlags(state, flags)	((struct termios*)state)->c_iflag = (tcflag_t)flags
#define PlatformNative_setLocalFlags(state, flags)	((struct termios*)state)->c_lflag = (tcflag_t)flags
#define PlatformNative_setTerminal(fd, state)	tcsetattr(fd, TCSANOW, (const struct termios*)state)
#define PlatformNative_stat(path, path__len)	stat((char*)path, &info)
#define PlatformNative_statBuffer()	struct stat info
#define PlatformNative_terminalSize()	sizeof(struct termios)
#define PlatformNative_timeIndex()	VTIME
#define PlatformNative_windowBuffer()	struct winsize window

INT32 PlatformNative_Error (void)
{
	return PlatformNative_error();
}

void PlatformNative_ClearError (void)
{
	PlatformNative_clearError();
}

INT32 PlatformNative_NameTooLong (void)
{
	return PlatformNative_nameTooLong();
}

INT32 PlatformNative_NoMemory (void)
{
	return PlatformNative_noMemory();
}

INT32 PlatformNative_BadFD (void)
{
	return PlatformNative_badFD();
}

INT32 PlatformNative_Overflow (void)
{
	return PlatformNative_overflow();
}

INT32 PlatformNative_OpenDirectory (CHAR *path, ADDRESS path__len)
{
	__DUP(path, path__len, CHAR);
	__DEL(path);
	return PlatformNative_openDirectory(path, path__len);
}

INT32 PlatformNative_ReadDirectory (INT32 handle)
{
	return PlatformNative_readDirectory(handle);
}

INT32 PlatformNative_EntryName (INT32 entry)
{
	return PlatformNative_entryName(entry);
}

INT32 PlatformNative_CloseDirectory (INT32 handle)
{
	return PlatformNative_closeDirectory(handle);
}

INT32 PlatformNative_PathKind (CHAR *path, ADDRESS path__len, BOOLEAN follow, INT16 *kind)
{
	INT32 result;
	__DUP(path, path__len, CHAR);
	PlatformNative_statBuffer();
	*kind = 0;
	if (follow) {
		result = PlatformNative_stat(path, path__len);
	} else {
		result = PlatformNative_lstat(path, path__len);
	}
	if (result < 0) {
		__DEL(path);
		return PlatformNative_error();
	}
	if (PlatformNative_isDirectory()) {
		*kind = 1;
	} else if (PlatformNative_isRegular()) {
		*kind = 2;
	}
	__DEL(path);
	return 0;
}

INT32 PlatformNative_MakeDirectory (CHAR *path, ADDRESS path__len)
{
	__DUP(path, path__len, CHAR);
	if (PlatformNative_mkdir(path, path__len) < 0) {
		__DEL(path);
		return PlatformNative_error();
	} else {
		__DEL(path);
		return 0;
	}
	__RETCHK;
}

INT32 PlatformNative_TerminalSize (void)
{
	return PlatformNative_terminalSize();
}

INT32 PlatformNative_GetTerminal (INT32 fd, INT32 state)
{
	return PlatformNative_getTerminal(fd, state);
}

INT32 PlatformNative_SetTerminal (INT32 fd, INT32 state)
{
	return PlatformNative_setTerminal(fd, state);
}

UINT64 PlatformNative_LocalFlags (INT32 state)
{
	return PlatformNative_localFlags(state);
}

UINT64 PlatformNative_InputFlags (INT32 state)
{
	return PlatformNative_inputFlags(state);
}

void PlatformNative_SetLocalFlags (INT32 state, UINT64 flags)
{
	PlatformNative_setLocalFlags(state, flags);
}

void PlatformNative_SetInputFlags (INT32 state, UINT64 flags)
{
	PlatformNative_setInputFlags(state, flags);
}

UINT64 PlatformNative_LocalRawMask (void)
{
	return PlatformNative_localRawMask();
}

UINT64 PlatformNative_InputRawMask (void)
{
	return PlatformNative_inputRawMask();
}

INT32 PlatformNative_MinIndex (void)
{
	return PlatformNative_minIndex();
}

INT32 PlatformNative_TimeIndex (void)
{
	return PlatformNative_timeIndex();
}

void PlatformNative_SetControl (INT32 state, INT32 index, INT32 value)
{
	PlatformNative_setControl(state, index, value);
}

INT32 PlatformNative_WindowSize (INT32 fd, INT32 *lines, INT32 *cols)
{
	PlatformNative_windowBuffer();
	if (PlatformNative_getWindow(fd) < 0) {
		return PlatformNative_error();
	}
	*lines = PlatformNative_rows();
	*cols = PlatformNative_columns();
	return 0;
}


export void *PlatformNative__init(void)
{
	__DEFMOD;
	__REGMOD("PlatformNative", 0);
	__REGCMD("ClearError", PlatformNative_ClearError);
/* BEGIN */
	__ENDMOD;
}
