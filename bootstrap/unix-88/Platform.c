/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "PlatformNative.h"

typedef
	void (*Platform_Command)(void);

typedef
	struct Platform_FileIdentity {
		INT32 volume, index, mtime;
	} Platform_FileIdentity;

typedef
	void (*Platform_SignalHandler)(INT32);


export BOOLEAN Platform_LittleEndian;
export INT16 Platform_PID;
export CHAR Platform_CWD[256];
static INT32 Platform_TimeStart;
export INT16 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
export CHAR Platform_NL[3];

export ADDRESS *Platform_FileIdentity__typ;

export BOOLEAN Platform_Absent (INT16 e);
export INT16 Platform_CaptureTerminalState (INT32 h, INT64 *state);
export INT16 Platform_Chdir (CHAR *n, ADDRESS n__len);
export INT16 Platform_Close (INT32 h);
export INT16 Platform_CloseDirectory (INT64 *handle);
export void Platform_CommandCritical (BOOLEAN enter);
export BOOLEAN Platform_ConnectionFailed (INT16 e);
export INT16 Platform_CopyTerminalState (INT64 source, INT64 *copy);
export void Platform_Delay (INT32 ms);
export BOOLEAN Platform_DifferentFilesystems (INT16 e);
export INT16 Platform_Error (void);
export void Platform_Exit (INT32 code);
export void Platform_GetClock (INT32 *t, INT32 *d);
export void Platform_GetEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);
export INT16 Platform_GetTerminalDimensions (INT32 h, INT32 *lines, INT32 *columns);
export INT16 Platform_GetTerminalSize (INT32 h, INT16 *lines, INT16 *columns);
export void Platform_GetTimeOfDay (INT32 *sec, INT32 *usec);
export INT16 Platform_Identify (INT32 h, Platform_FileIdentity *identity, ADDRESS *identity__typ);
export INT16 Platform_IdentifyByName (CHAR *n, ADDRESS n__len, Platform_FileIdentity *identity, ADDRESS *identity__typ);
export BOOLEAN Platform_Inaccessible (INT16 e);
export BOOLEAN Platform_Interrupted (INT16 e);
export BOOLEAN Platform_IsConsole (INT32 h);
export BOOLEAN Platform_IsDirectory (CHAR *path, ADDRESS path__len);
export void Platform_MTimeAsClock (Platform_FileIdentity i, INT32 *t, INT32 *d);
export void Platform_MakeTerminalRaw (INT64 state);
export INT16 Platform_MaxNameLength (void);
export INT16 Platform_MaxPathLength (void);
export INT16 Platform_New (CHAR *n, ADDRESS n__len, INT32 *h);
export BOOLEAN Platform_NoSuchDirectory (INT16 e);
export INT64 Platform_OSAllocate (INT64 size);
export void Platform_OSFree (INT64 address);
export INT16 Platform_OldRO (CHAR *n, ADDRESS n__len, INT32 *h);
export INT16 Platform_OldRW (CHAR *n, ADDRESS n__len, INT32 *h);
export INT16 Platform_OpenDirectory (CHAR *path, ADDRESS path__len, INT64 *handle);
export INT16 Platform_OpenFile (CHAR *n, ADDRESS n__len, INT16 access, INT16 creation, INT32 *h);
export INT16 Platform_Read (INT32 h, INT64 p, INT32 l, INT32 *n);
export INT16 Platform_ReadBuf (INT32 h, SYSTEM_BYTE *b, ADDRESS b__len, INT32 *n);
export INT16 Platform_ReadDirectory (INT64 handle, CHAR *name, ADDRESS name__len, BOOLEAN *done);
export void Platform_ReleaseTerminalState (INT64 *state);
export INT16 Platform_Rename (CHAR *o, ADDRESS o__len, CHAR *n, ADDRESS n__len);
export INT16 Platform_RestoreTerminalState (INT32 h, INT64 state);
export INT32 Platform_RunCommand (Platform_Command command);
export BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
export BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
export BOOLEAN Platform_SameTerminal (INT32 first, INT32 second);
export INT16 Platform_Seek (INT32 h, INT32 offset, INT16 whence);
export void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
export INT16 Platform_SetFileMTime (CHAR *n, ADDRESS n__len, INT32 year, INT32 month, INT32 day, INT32 hour, INT32 minute, INT32 second);
export void Platform_SetInterruptHandler (Platform_SignalHandler handler);
export void Platform_SetMTime (Platform_FileIdentity *target, ADDRESS *target__typ, Platform_FileIdentity source);
export void Platform_SetQuitHandler (Platform_SignalHandler handler);
export INT16 Platform_SetTerminalEcho (INT32 h, BOOLEAN enabled);
export INT16 Platform_SetTerminalInputMode (INT32 h, BOOLEAN raw);
export INT16 Platform_SetTerminalOutputMode (INT32 h, BOOLEAN raw);
export void Platform_SetTerminalTimeout (INT64 state, INT16 tenths);
export INT16 Platform_Size (INT32 h, INT32 *l);
export INT16 Platform_Sync (INT32 h);
export INT16 Platform_System (CHAR *cmd, ADDRESS cmd__len);
export INT16 Platform_Tell (INT32 h, INT32 *offset);
static BOOLEAN Platform_TerminalFD (INT32 h);
static void Platform_TestLittleEndian (void);
export INT32 Platform_Time (void);
export BOOLEAN Platform_TimedOut (INT16 e);
export BOOLEAN Platform_TooManyFiles (INT16 e);
export INT16 Platform_Truncate (INT32 h, INT32 l);
export INT16 Platform_Unlink (CHAR *n, ADDRESS n__len);
export INT16 Platform_Write (INT32 h, INT64 p, INT32 l);
export INT16 Platform_WriteCount (INT32 h, INT64 p, INT32 l, INT32 *n);
static void Platform_YMDHMStoClock (INT32 ye, INT32 mo, INT32 da, INT32 ho, INT32 mi, INT32 se, INT32 *t, INT32 *d);
export BOOLEAN Platform_getEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#include <errno.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#ifdef __TINYC__
#include_next <termios.h>
#else
#include <termios.h>
#endif
#include <time.h>
#include <unistd.h>
#include <utime.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define Platform_EACCES()	EACCES
#define Platform_EAGAIN()	EAGAIN
#define Platform_ECONNABORTED()	ECONNABORTED
#define Platform_ECONNREFUSED()	ECONNREFUSED
#define Platform_EHOSTUNREACH()	EHOSTUNREACH
#define Platform_EINTR()	EINTR
#define Platform_EINVAL()	EINVAL
#define Platform_EIO()	EIO
#define Platform_EMFILE()	EMFILE
#define Platform_ENETUNREACH()	ENETUNREACH
#define Platform_ENFILE()	ENFILE
#define Platform_ENOENT()	ENOENT
#define Platform_EROFS()	EROFS
#define Platform_ETIMEDOUT()	ETIMEDOUT
#define Platform_EXDEV()	EXDEV
#define Platform_NAMEMAX()	NAME_MAX
#define Platform_PATHMAX()	PATH_MAX
#define Platform_allocate(size)	(ADDRESS)((void*)malloc((size_t)size))
#define Platform_applymtime(n, n__len)	(mtimes.actime = mtimes.modtime, utime((char*)n, &mtimes))
#define Platform_chdir(n, n__len)	chdir((char*)n)
#define Platform_closefile(fd)	close(fd)
#define Platform_commandCritical(enter)	SYSTEM_CommandCritical(enter)
#define Platform_err()	errno
#define Platform_exit(code)	exit((int)code)
#define Platform_free(address)	free((void*)address)
#define Platform_fstat(fd)	fstat(fd, &s)
#define Platform_fsync(fd)	fsync(fd)
#define Platform_ftruncate(fd, l)	ftruncate(fd, l)
#define Platform_getcwd(cwd, cwd__len)	getcwd((char*)cwd, cwd__len)
#define Platform_getenv(var, var__len)	getenv((char*)var)
#define Platform_getpid()	(INTEGER)getpid()
#define Platform_gettimeval()	struct timeval tv; gettimeofday(&tv,0)
#define Platform_invalidmtime()	errno = EINVAL
#define Platform_isatty(fd)	isatty(fd)
#define Platform_lseek(fd, o, w)	lseek(fd, o, w)
#define Platform_makemtime()	(mtimes.modtime = mktime(&mtm)) != (time_t)-1
#define Platform_mtimevars()	struct tm mtm = {0}; struct utimbuf mtimes
#define Platform_nanosleep(s, ns)	struct timespec req, rem; req.tv_sec = s; req.tv_nsec = ns; nanosleep(&req, &rem)
#define Platform_openfile(n, n__len, access, creation)	open((char*)n, (access == 0 ? O_RDONLY : access == 1 ? O_WRONLY : O_RDWR) | (creation == 1 ? O_CREAT | O_TRUNC : creation == 2 ? O_CREAT : 0), 0666)
#define Platform_opennew(n, n__len)	open((char*)n, O_CREAT | O_TRUNC | O_RDWR, 0664)
#define Platform_openro(n, n__len)	open((char*)n, O_RDONLY)
#define Platform_openrw(n, n__len)	open((char*)n, O_RDWR)
#define Platform_readfile(fd, p, l)	(LONGINT)read(fd, (void*)(ADDRESS)(p), l)
#define Platform_rename(o, o__len, n, n__len)	rename((char*)o, (char*)n)
#define Platform_runCommand(command)	SYSTEM_RunCommand(command)
#define Platform_sameTerminal(first, second)	({ struct stat a, b; int same = 0; if (fstat(first, &a) == 0 && fstat(second, &b) == 0) same = S_ISCHR(a.st_mode) && S_ISCHR(b.st_mode) && a.st_rdev == b.st_rdev; same; })
#define Platform_sectotm(s)	struct tm *time = localtime((time_t*)&s)
#define Platform_seekcur()	SEEK_CUR
#define Platform_seekend()	SEEK_END
#define Platform_seekset()	SEEK_SET
#define Platform_setTerminalEcho(h, enabled)	({ struct termios t; int rc = tcgetattr(h, &t); if (rc == 0) { if (enabled) t.c_lflag |= ECHO; else t.c_lflag &= ~ECHO; rc = tcsetattr(h, TCSANOW, &t); } rc; })
#define Platform_setTerminalInputCooked(h)	({ struct termios t; int rc = tcgetattr(h, &t); if (rc == 0) { t.c_iflag |= ICRNL; t.c_lflag |= ICANON; t.c_cc[VEOF] = 4; t.c_cc[VEOL] = '\n'; rc = tcsetattr(h, TCSANOW, &t); } rc; })
#define Platform_setTerminalInputRaw(h)	({ struct termios t; int rc = tcgetattr(h, &t); if (rc == 0) { t.c_iflag &= ~ICRNL; t.c_lflag &= ~ICANON; t.c_cc[VMIN] = 1; t.c_cc[VTIME] = 0; rc = tcsetattr(h, TCSANOW, &t); } rc; })
#define Platform_setTerminalOutputMode(h, raw)	({ struct termios t; int rc = tcgetattr(h, &t); if (rc == 0) { if (raw) t.c_oflag &= ~(OPOST | OCRNL | ONLCR); else t.c_oflag |= OPOST | OCRNL | ONLCR; rc = tcsetattr(h, TCSANOW, &t); } rc; })
#define Platform_sethandler(s, h)	SystemSetHandler(s, (ADDRESS)h)
#define Platform_setmtimedate(year, month, day)	mtm.tm_year = (int)year-1900; mtm.tm_mon = (int)month-1; mtm.tm_mday = (int)day
#define Platform_setmtimetime(hour, minute, second)	mtm.tm_hour = (int)hour; mtm.tm_min = (int)minute; mtm.tm_sec = (int)second; mtm.tm_isdst = -1
#define Platform_stat(n, n__len)	stat((char*)n, &s)
#define Platform_statdev()	(LONGINT)s.st_dev
#define Platform_statino()	(LONGINT)s.st_ino
#define Platform_statmtime()	(LONGINT)s.st_mtime
#define Platform_statsize()	(ADDRESS)s.st_size
#define Platform_structstats()	struct stat s
#define Platform_system(str, str__len)	system((char*)str)
#define Platform_tmhour()	(LONGINT)time->tm_hour
#define Platform_tmmday()	(LONGINT)time->tm_mday
#define Platform_tmmin()	(LONGINT)time->tm_min
#define Platform_tmmon()	(LONGINT)time->tm_mon
#define Platform_tmsec()	(LONGINT)time->tm_sec
#define Platform_tmyear()	(LONGINT)time->tm_year
#define Platform_tvsec()	tv.tv_sec
#define Platform_tvusec()	tv.tv_usec
#define Platform_unlink(n, n__len)	unlink((char*)n)
#define Platform_writecount(value)	(LONGINT)value
#define Platform_writefile(fd, p, l)	write(fd, (void*)(ADDRESS)(p), l)

BOOLEAN Platform_TooManyFiles (INT16 e)
{
	return e == Platform_EMFILE() || e == Platform_ENFILE();
}

BOOLEAN Platform_NoSuchDirectory (INT16 e)
{
	return e == Platform_ENOENT();
}

BOOLEAN Platform_DifferentFilesystems (INT16 e)
{
	return e == Platform_EXDEV();
}

BOOLEAN Platform_Inaccessible (INT16 e)
{
	return (e == Platform_EACCES() || e == Platform_EROFS()) || e == Platform_EAGAIN();
}

BOOLEAN Platform_Absent (INT16 e)
{
	return e == Platform_ENOENT();
}

BOOLEAN Platform_TimedOut (INT16 e)
{
	return e == Platform_ETIMEDOUT();
}

BOOLEAN Platform_ConnectionFailed (INT16 e)
{
	return ((e == Platform_ECONNREFUSED() || e == Platform_ECONNABORTED()) || e == Platform_ENETUNREACH()) || e == Platform_EHOSTUNREACH();
}

BOOLEAN Platform_Interrupted (INT16 e)
{
	return e == Platform_EINTR();
}

INT16 Platform_MaxNameLength (void)
{
	return Platform_NAMEMAX();
}

INT16 Platform_MaxPathLength (void)
{
	return Platform_PATHMAX();
}

INT64 Platform_OSAllocate (INT64 size)
{
	return Platform_allocate(size);
}

void Platform_OSFree (INT64 address)
{
	Platform_free(address);
}

typedef
	CHAR (*EnvPtr__121)[1024];

BOOLEAN Platform_getEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len)
{
	EnvPtr__121 p = NIL;
	__DUP(var, var__len, CHAR);
	p = (EnvPtr__121)(ADDRESS)Platform_getenv(var, var__len);
	if (p != NIL) {
		__COPY(*p, val, val__len);
	}
	__DEL(var);
	return p != NIL;
}

void Platform_GetEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len)
{
	__DUP(var, var__len, CHAR);
	if (!Platform_getEnv(var, var__len, (void*)val, val__len)) {
		val[0] = 0x00;
	}
	__DEL(var);
}

void Platform_SetInterruptHandler (Platform_SignalHandler handler)
{
	Platform_sethandler(2, handler);
}

void Platform_SetQuitHandler (Platform_SignalHandler handler)
{
	Platform_sethandler(3, handler);
}

void Platform_SetBadInstructionHandler (Platform_SignalHandler handler)
{
	Platform_sethandler(4, handler);
}

INT32 Platform_RunCommand (Platform_Command command)
{
	return Platform_runCommand(command);
}

void Platform_CommandCritical (BOOLEAN enter)
{
	Platform_commandCritical(enter);
}

static void Platform_YMDHMStoClock (INT32 ye, INT32 mo, INT32 da, INT32 ho, INT32 mi, INT32 se, INT32 *t, INT32 *d)
{
	*d = (__ASHL((int)__MOD(ye, 100), 9) + __ASHL(mo + 1, 5)) + da;
	*t = (__ASHL(ho, 12) + __ASHL(mi, 6)) + se;
}

void Platform_GetClock (INT32 *t, INT32 *d)
{
	Platform_gettimeval();
	Platform_sectotm(Platform_tvsec());
	Platform_YMDHMStoClock(Platform_tmyear(), Platform_tmmon(), Platform_tmmday(), Platform_tmhour(), Platform_tmmin(), Platform_tmsec(), &*t, &*d);
}

void Platform_GetTimeOfDay (INT32 *sec, INT32 *usec)
{
	Platform_gettimeval();
	*sec = Platform_tvsec();
	*usec = Platform_tvusec();
}

INT32 Platform_Time (void)
{
	INT32 ms;
	Platform_gettimeval();
	ms = (int)__DIVF(Platform_tvusec(), 1000) + Platform_tvsec() * 1000;
	return (int)__MOD(ms - Platform_TimeStart, 2147483647);
}

void Platform_Delay (INT32 ms)
{
	INT32 s, ns;
	s = __DIV(ms, 1000);
	ns = (int)__MOD(ms, 1000) * 1000000;
	Platform_nanosleep(s, ns);
}

INT16 Platform_System (CHAR *cmd, ADDRESS cmd__len)
{
	__DUP(cmd, cmd__len, CHAR);
	__DEL(cmd);
	return Platform_system(cmd, cmd__len);
}

INT16 Platform_Error (void)
{
	return Platform_err();
}

INT16 Platform_OpenDirectory (CHAR *path, ADDRESS path__len, INT64 *handle)
{
	__DUP(path, path__len, CHAR);
	*handle = PlatformNative_OpenDirectory(path, path__len);
	if (*handle == 0) {
		__DEL(path);
		return __SHORTF(PlatformNative_Error(), 32768);
	} else {
		__DEL(path);
		return 0;
	}
	__RETCHK;
}

INT16 Platform_ReadDirectory (INT64 handle, CHAR *name, ADDRESS name__len, BOOLEAN *done)
{
	INT64 entry, address, i;
	CHAR ch;
	if (name__len > 0) {
		name[0] = 0x00;
	}
	PlatformNative_ClearError();
	entry = PlatformNative_ReadDirectory(handle);
	*done = entry == 0;
	if (*done) {
		return __SHORTF(PlatformNative_Error(), 32768);
	}
	address = PlatformNative_EntryName(entry);
	i = 0;
	for (;;) {
		__GET(address + i, ch, CHAR);
		if (i >= (INT64)name__len) {
			return __SHORTF(PlatformNative_NameTooLong(), 32768);
		}
		if (i == (INT64)(name__len - 1)) {
			name[__X(i, name__len)] = 0x00;
			if (ch != 0x00) {
				return __SHORTF(PlatformNative_NameTooLong(), 32768);
			}
		} else {
			name[__X(i, name__len)] = ch;
		}
		if (ch == 0x00) {
			return 0;
		}
		i += 1;
	}
	__RETCHK;
}

INT16 Platform_CloseDirectory (INT64 *handle)
{
	INT32 result;
	if (*handle == 0) {
		return 0;
	}
	result = PlatformNative_CloseDirectory(*handle);
	*handle = 0;
	if (result < 0) {
		return __SHORTF(PlatformNative_Error(), 32768);
	} else {
		return 0;
	}
	__RETCHK;
}

BOOLEAN Platform_IsDirectory (CHAR *path, ADDRESS path__len)
{
	INT16 kind;
	__DUP(path, path__len, CHAR);
	__DEL(path);
	return (PlatformNative_PathKind(path, path__len, 1, &kind) == 0 && kind == 1);
}

INT16 Platform_OldRO (CHAR *n, ADDRESS n__len, INT32 *h)
{
	INT16 fd;
	fd = Platform_openro(n, n__len);
	if (fd < 0) {
		return Platform_err();
	} else {
		*h = fd;
		return 0;
	}
	__RETCHK;
}

INT16 Platform_OldRW (CHAR *n, ADDRESS n__len, INT32 *h)
{
	INT16 fd;
	fd = Platform_openrw(n, n__len);
	if (fd < 0) {
		return Platform_err();
	} else {
		*h = fd;
		return 0;
	}
	__RETCHK;
}

INT16 Platform_New (CHAR *n, ADDRESS n__len, INT32 *h)
{
	INT16 fd;
	fd = Platform_opennew(n, n__len);
	if (fd < 0) {
		return Platform_err();
	} else {
		*h = fd;
		return 0;
	}
	__RETCHK;
}

INT16 Platform_OpenFile (CHAR *n, ADDRESS n__len, INT16 access, INT16 creation, INT32 *h)
{
	INT32 fd;
	fd = Platform_openfile(n, n__len, access, creation);
	if (fd < 0) {
		return Platform_err();
	} else {
		*h = fd;
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Close (INT32 h)
{
	if (Platform_closefile(h) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_SetFileMTime (CHAR *n, ADDRESS n__len, INT32 year, INT32 month, INT32 day, INT32 hour, INT32 minute, INT32 second)
{
	Platform_mtimevars();
	Platform_setmtimedate(year, month, day);
	Platform_setmtimetime(hour, minute, second);
	if (Platform_makemtime() == 0) {
		Platform_invalidmtime();
		return Platform_err();
	} else if (Platform_applymtime(n, n__len) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

BOOLEAN Platform_IsConsole (INT32 h)
{
	return Platform_isatty(h) != 0;
}

static BOOLEAN Platform_TerminalFD (INT32 h)
{
	return (h >= 0 && h <= 2147483647);
}

INT16 Platform_CaptureTerminalState (INT32 h, INT64 *state)
{
	INT32 error;
	*state = 0;
	if (!Platform_TerminalFD(h)) {
		return __SHORTF(PlatformNative_BadFD(), 32768);
	}
	*state = Platform_OSAllocate(PlatformNative_TerminalSize());
	if (*state == 0) {
		return __SHORTF(PlatformNative_NoMemory(), 32768);
	}
	if (PlatformNative_GetTerminal((INT32)h, *state) < 0) {
		error = PlatformNative_Error();
		Platform_OSFree(*state);
		*state = 0;
		return __SHORT(error, 32768);
	}
	return 0;
}

INT16 Platform_RestoreTerminalState (INT32 h, INT64 state)
{
	__ASSERT(state != 0, 0);
	if (!Platform_TerminalFD(h)) {
		return __SHORTF(PlatformNative_BadFD(), 32768);
	}
	if (PlatformNative_SetTerminal((INT32)h, state) < 0) {
		return __SHORTF(PlatformNative_Error(), 32768);
	} else {
		return 0;
	}
	__RETCHK;
}

void Platform_ReleaseTerminalState (INT64 *state)
{
	INT64 address;
	address = *state;
	*state = 0;
	if (address != 0) {
		Platform_OSFree(address);
	}
}

INT16 Platform_CopyTerminalState (INT64 source, INT64 *copy)
{
	__ASSERT(source != 0, 0);
	*copy = Platform_OSAllocate(PlatformNative_TerminalSize());
	if (*copy == 0) {
		return __SHORTF(PlatformNative_NoMemory(), 32768);
	}
	__MOVE(source, *copy, PlatformNative_TerminalSize());
	return 0;
}

void Platform_MakeTerminalRaw (INT64 state)
{
	__ASSERT(state != 0, 0);
	PlatformNative_SetLocalFlags(state, (PlatformNative_LocalFlags(state) & ~PlatformNative_LocalRawMask()));
	PlatformNative_SetInputFlags(state, (PlatformNative_InputFlags(state) & ~PlatformNative_InputRawMask()));
	PlatformNative_SetControl(state, PlatformNative_MinIndex(), 1);
	PlatformNative_SetControl(state, PlatformNative_TimeIndex(), 0);
}

void Platform_SetTerminalTimeout (INT64 state, INT16 tenths)
{
	__ASSERT((((state != 0 && tenths >= 0)) && tenths <= 255), 0);
	PlatformNative_SetControl(state, PlatformNative_MinIndex(), 0);
	PlatformNative_SetControl(state, PlatformNative_TimeIndex(), tenths);
}

INT16 Platform_SetTerminalEcho (INT32 h, BOOLEAN enabled)
{
	INT16 value;
	if (enabled) {
		value = 1;
	} else {
		value = 0;
	}
	if (Platform_setTerminalEcho(h, value) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_SetTerminalInputMode (INT32 h, BOOLEAN raw)
{
	INT16 result;
	if (raw) {
		result = Platform_setTerminalInputRaw(h);
	} else {
		result = Platform_setTerminalInputCooked(h);
	}
	if (result < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_SetTerminalOutputMode (INT32 h, BOOLEAN raw)
{
	INT16 value;
	if (raw) {
		value = 1;
	} else {
		value = 0;
	}
	if (Platform_setTerminalOutputMode(h, value) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_GetTerminalSize (INT32 h, INT16 *lines, INT16 *columns)
{
	INT32 rows, cols, error;
	if (!Platform_TerminalFD(h)) {
		return __SHORTF(PlatformNative_BadFD(), 32768);
	}
	error = PlatformNative_WindowSize((INT32)h, &rows, &cols);
	if (error != 0) {
		return __SHORT(error, 32768);
	}
	if (rows > 32767 || cols > 32767) {
		return __SHORTF(PlatformNative_Overflow(), 32768);
	}
	*lines = __VAL(INT16, rows);
	*columns = __VAL(INT16, cols);
	return 0;
}

INT16 Platform_GetTerminalDimensions (INT32 h, INT32 *lines, INT32 *columns)
{
	INT32 rows, cols, error;
	if (!Platform_TerminalFD(h)) {
		return __SHORTF(PlatformNative_BadFD(), 32768);
	}
	error = PlatformNative_WindowSize((INT32)h, &rows, &cols);
	if (error != 0) {
		return __SHORT(error, 32768);
	}
	if (rows > 2147483647 || cols > 2147483647) {
		return __SHORTF(PlatformNative_Overflow(), 32768);
	}
	*lines = rows;
	*columns = cols;
	return 0;
}

BOOLEAN Platform_SameTerminal (INT32 first, INT32 second)
{
	return Platform_sameTerminal(first, second) != 0;
}

INT16 Platform_Identify (INT32 h, Platform_FileIdentity *identity, ADDRESS *identity__typ)
{
	Platform_structstats();
	if (Platform_fstat(h) < 0) {
		return Platform_err();
	}
	(*identity).volume = Platform_statdev();
	(*identity).index = Platform_statino();
	(*identity).mtime = Platform_statmtime();
	return 0;
}

INT16 Platform_IdentifyByName (CHAR *n, ADDRESS n__len, Platform_FileIdentity *identity, ADDRESS *identity__typ)
{
	__DUP(n, n__len, CHAR);
	Platform_structstats();
	if (Platform_stat(n, n__len) < 0) {
		__DEL(n);
		return Platform_err();
	}
	(*identity).volume = Platform_statdev();
	(*identity).index = Platform_statino();
	(*identity).mtime = Platform_statmtime();
	__DEL(n);
	return 0;
}

BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	return (i1.index == i2.index && i1.volume == i2.volume);
}

BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	return i1.mtime == i2.mtime;
}

void Platform_SetMTime (Platform_FileIdentity *target, ADDRESS *target__typ, Platform_FileIdentity source)
{
	(*target).mtime = source.mtime;
}

void Platform_MTimeAsClock (Platform_FileIdentity i, INT32 *t, INT32 *d)
{
	Platform_sectotm(i.mtime);
	Platform_YMDHMStoClock(Platform_tmyear(), Platform_tmmon(), Platform_tmmday(), Platform_tmhour(), Platform_tmmin(), Platform_tmsec(), &*t, &*d);
}

INT16 Platform_Size (INT32 h, INT32 *l)
{
	Platform_structstats();
	if (Platform_fstat(h) < 0) {
		return Platform_err();
	}
	*l = Platform_statsize();
	return 0;
}

INT16 Platform_Read (INT32 h, INT64 p, INT32 l, INT32 *n)
{
	*n = Platform_readfile(h, p, l);
	if (*n < 0) {
		*n = 0;
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_ReadBuf (INT32 h, SYSTEM_BYTE *b, ADDRESS b__len, INT32 *n)
{
	*n = Platform_readfile(h, (ADDRESS)b, b__len);
	if (*n < 0) {
		*n = 0;
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_WriteCount (INT32 h, INT64 p, INT32 l, INT32 *n)
{
	INT64 written;
	written = Platform_writefile(h, p, l);
	if (written < 0) {
		*n = 0;
		return Platform_err();
	}
	*n = Platform_writecount(written);
	return 0;
}

INT16 Platform_Write (INT32 h, INT64 p, INT32 l)
{
	INT64 written;
	INT16 e;
	if (l < 0) {
		return Platform_EINVAL();
	}
	while (l > 0) {
		written = Platform_writefile(h, p, l);
		if (written < 0) {
			e = Platform_err();
			if (!Platform_Interrupted(e)) {
				return e;
			}
		} else if (written == 0) {
			return Platform_EIO();
		} else {
			p += written;
			l -= Platform_writecount(written);
		}
	}
	return 0;
}

INT16 Platform_Sync (INT32 h)
{
	if (Platform_fsync(h) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Seek (INT32 h, INT32 offset, INT16 whence)
{
	if (Platform_lseek(h, offset, whence) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Tell (INT32 h, INT32 *offset)
{
	*offset = Platform_lseek(h, 0, Platform_seekcur());
	if (*offset < 0) {
		*offset = 0;
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Truncate (INT32 h, INT32 l)
{
	if (Platform_ftruncate(h, l) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Unlink (CHAR *n, ADDRESS n__len)
{
	if (Platform_unlink(n, n__len) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

INT16 Platform_Chdir (CHAR *n, ADDRESS n__len)
{
	INT16 r;
	if ((Platform_chdir(n, n__len) >= 0 && Platform_getcwd((void*)Platform_CWD, 256) != NIL)) {
		return 0;
	} else {
		return Platform_err();
	}
	__RETCHK;
}

INT16 Platform_Rename (CHAR *o, ADDRESS o__len, CHAR *n, ADDRESS n__len)
{
	if (Platform_rename(o, o__len, n, n__len) < 0) {
		return Platform_err();
	} else {
		return 0;
	}
	__RETCHK;
}

void Platform_Exit (INT32 code)
{
	Platform_exit(code);
}

static void Platform_TestLittleEndian (void)
{
	INT16 i;
	i = 1;
	__GET((ADDRESS)&i, Platform_LittleEndian, BOOLEAN);
}

__TDESC(Platform_FileIdentity, 1, 0) = {__TDFLDS("FileIdentity", 12), {-8}};

export void *Platform__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(PlatformNative);
	__REGMOD("Platform", 0);
	__INITYP(Platform_FileIdentity, Platform_FileIdentity, 0);
/* BEGIN */
	Platform_TestLittleEndian();
	Platform_TimeStart = 0;
	Platform_TimeStart = Platform_Time();
	Platform_PID = Platform_getpid();
	if (Platform_getcwd((void*)Platform_CWD, 256) == NIL) {
		Platform_CWD[0] = 0x00;
	}
	Platform_SeekSet = Platform_seekset();
	Platform_SeekCur = Platform_seekcur();
	Platform_SeekEnd = Platform_seekend();
	Platform_NL[0] = 0x0a;
	Platform_NL[1] = 0x00;
	__ENDMOD;
}
