/* voc  1.2 [2016/06/15] for gcc LP64 on cygwin xtspkaSfF */
#include "SYSTEM.h"

typedef
	CHAR (*Platform_ArgPtr)[1024];

typedef
	Platform_ArgPtr (*Platform_ArgVec)[1024];

typedef
	LONGINT (*Platform_ArgVecPtr)[1];

typedef
	CHAR (*Platform_EnvPtr)[1024];

typedef
	struct Platform_FileIdentity {
		LONGINT volume, index, mtime;
	} Platform_FileIdentity;

typedef
	void (*Platform_HaltProcedure)(LONGINT);

typedef
	void (*Platform_SignalHandler)(INTEGER);


export BOOLEAN Platform_LittleEndian;
export LONGINT Platform_MainStackFrame, Platform_HaltCode;
export INTEGER Platform_PID;
export CHAR Platform_CWD[256];
export INTEGER Platform_ArgCount;
export LONGINT Platform_ArgVector;
static Platform_HaltProcedure Platform_HaltHandler;
static LONGINT Platform_TimeStart;
export INTEGER Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
export CHAR Platform_nl[3];

export LONGINT *Platform_FileIdentity__typ;

export BOOLEAN Platform_Absent (INTEGER e);
export INTEGER Platform_ArgPos (CHAR *s, LONGINT s__len);
export void Platform_AssertFail (LONGINT code);
export INTEGER Platform_Chdir (CHAR *n, LONGINT n__len);
export INTEGER Platform_Close (LONGINT h);
export BOOLEAN Platform_ConnectionFailed (INTEGER e);
export void Platform_Delay (LONGINT ms);
export BOOLEAN Platform_DifferentFilesystems (INTEGER e);
static void Platform_DisplayHaltCode (LONGINT code);
export INTEGER Platform_Error (void);
export void Platform_Exit (INTEGER code);
export void Platform_GetArg (INTEGER n, CHAR *val, LONGINT val__len);
export void Platform_GetClock (LONGINT *t, LONGINT *d);
export void Platform_GetEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
export void Platform_GetIntArg (INTEGER n, LONGINT *val);
export void Platform_GetTimeOfDay (LONGINT *sec, LONGINT *usec);
export void Platform_Halt (LONGINT code);
export INTEGER Platform_Identify (LONGINT h, Platform_FileIdentity *identity, LONGINT *identity__typ);
export INTEGER Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, LONGINT *identity__typ);
export BOOLEAN Platform_Inaccessible (INTEGER e);
export void Platform_Init (INTEGER argc, LONGINT argvadr);
export void Platform_MTimeAsClock (Platform_FileIdentity i, LONGINT *t, LONGINT *d);
export INTEGER Platform_New (CHAR *n, LONGINT n__len, LONGINT *h);
export BOOLEAN Platform_NoSuchDirectory (INTEGER e);
export LONGINT Platform_OSAllocate (LONGINT size);
export void Platform_OSFree (LONGINT address);
export INTEGER Platform_OldRO (CHAR *n, LONGINT n__len, LONGINT *h);
export INTEGER Platform_OldRW (CHAR *n, LONGINT n__len, LONGINT *h);
export INTEGER Platform_Read (LONGINT h, LONGINT p, LONGINT l, LONGINT *n);
export INTEGER Platform_ReadBuf (LONGINT h, SYSTEM_BYTE *b, LONGINT b__len, LONGINT *n);
export INTEGER Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len);
export BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
export BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
export INTEGER Platform_Seek (LONGINT h, LONGINT offset, INTEGER whence);
export void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
export void Platform_SetHalt (Platform_HaltProcedure p);
export void Platform_SetInterruptHandler (Platform_SignalHandler handler);
export void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source);
export void Platform_SetQuitHandler (Platform_SignalHandler handler);
export INTEGER Platform_Size (LONGINT h, LONGINT *l);
export INTEGER Platform_Sync (LONGINT h);
export INTEGER Platform_System (CHAR *cmd, LONGINT cmd__len);
static void Platform_TestLittleEndian (void);
export LONGINT Platform_Time (void);
export BOOLEAN Platform_TimedOut (INTEGER e);
export BOOLEAN Platform_TooManyFiles (INTEGER e);
export INTEGER Platform_Truncate (LONGINT h, LONGINT l);
export INTEGER Platform_Unlink (CHAR *n, LONGINT n__len);
export INTEGER Platform_Write (LONGINT h, LONGINT p, LONGINT l);
static void Platform_YMDHMStoClock (LONGINT ye, LONGINT mo, LONGINT da, LONGINT ho, LONGINT mi, LONGINT se, LONGINT *t, LONGINT *d);
static void Platform_errch (CHAR c);
static void Platform_errint (LONGINT l);
static void Platform_errln (void);
static void Platform_errposint (LONGINT l);
export BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);

#include <errno.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#define Platform_EACCES()	EACCES
#define Platform_EAGAIN()	EAGAIN
#define Platform_ECONNABORTED()	ECONNABORTED
#define Platform_ECONNREFUSED()	ECONNREFUSED
#define Platform_EHOSTUNREACH()	EHOSTUNREACH
#define Platform_EMFILE()	EMFILE
#define Platform_ENETUNREACH()	ENETUNREACH
#define Platform_ENFILE()	ENFILE
#define Platform_ENOENT()	ENOENT
#define Platform_EROFS()	EROFS
#define Platform_ETIMEDOUT()	ETIMEDOUT
#define Platform_EXDEV()	EXDEV
extern void Heap_InitHeap();
#define Platform_HeapInitHeap()	Heap_InitHeap()
#define Platform_allocate(size)	(LONGINT)(uintptr_t)((void*)malloc((size_t)size))
#define Platform_chdir(n, n__len)	chdir((char*)n)
#define Platform_closefile(fd)	close(fd)
#define Platform_err()	errno
#define Platform_errc(c)	write(1, &c, 1)
#define Platform_errstring(s, s__len)	write(1, s, s__len-1)
#define Platform_exit(code)	exit(code)
#define Platform_free(address)	free((void*)(uintptr_t)address)
#define Platform_fstat(fd)	fstat(fd, &s)
#define Platform_fsync(fd)	fsync(fd)
#define Platform_ftruncate(fd, l)	ftruncate(fd, l)
#define Platform_getcwd(cwd, cwd__len)	getcwd((char*)cwd, cwd__len)
#define Platform_getenv(var, var__len)	(Platform_EnvPtr)getenv((char*)var)
#define Platform_getpid()	(INTEGER)getpid()
#define Platform_gettimeval()	struct timeval tv; gettimeofday(&tv,0)
#define Platform_lseek(fd, o, w)	lseek(fd, o, w)
#define Platform_nanosleep(s, ns)	struct timespec req, rem; req.tv_sec = s; req.tv_nsec = ns; nanosleep(&req, &rem)
#define Platform_opennew(n, n__len)	open((char*)n, O_CREAT | O_TRUNC | O_RDWR, 0664)
#define Platform_openro(n, n__len)	open((char*)n, O_RDONLY)
#define Platform_openrw(n, n__len)	open((char*)n, O_RDWR)
#define Platform_readfile(fd, p, l)	read(fd, (void*)(uintptr_t)(p), l)
#define Platform_rename(o, o__len, n, n__len)	rename((char*)o, (char*)n)
#define Platform_sectotm(s)	struct tm *time = localtime((time_t*)&s)
#define Platform_seekcur()	SEEK_CUR
#define Platform_seekend()	SEEK_END
#define Platform_seekset()	SEEK_SET
#define Platform_sethandler(s, h)	SystemSetHandler(s, (uintptr_t)h)
#define Platform_stat(n, n__len)	stat((char*)n, &s)
#define Platform_statdev()	(LONGINT)s.st_dev
#define Platform_statino()	(LONGINT)s.st_ino
#define Platform_statmtime()	(LONGINT)s.st_mtime
#define Platform_statsize()	(LONGINT)s.st_size
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
#define Platform_writefile(fd, p, l)	write(fd, (void*)(uintptr_t)(p), l)

BOOLEAN Platform_TooManyFiles (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_EMFILE() || e == Platform_ENFILE();
	return _o_result;
}

BOOLEAN Platform_NoSuchDirectory (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ENOENT();
	return _o_result;
}

BOOLEAN Platform_DifferentFilesystems (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_EXDEV();
	return _o_result;
}

BOOLEAN Platform_Inaccessible (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = (e == Platform_EACCES() || e == Platform_EROFS()) || e == Platform_EAGAIN();
	return _o_result;
}

BOOLEAN Platform_Absent (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ENOENT();
	return _o_result;
}

BOOLEAN Platform_TimedOut (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ETIMEDOUT();
	return _o_result;
}

BOOLEAN Platform_ConnectionFailed (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = ((e == Platform_ECONNREFUSED() || e == Platform_ECONNABORTED()) || e == Platform_ENETUNREACH()) || e == Platform_EHOSTUNREACH();
	return _o_result;
}

LONGINT Platform_OSAllocate (LONGINT size)
{
	LONGINT _o_result;
	_o_result = Platform_allocate(size);
	return _o_result;
}

void Platform_OSFree (LONGINT address)
{
	Platform_free(address);
}

void Platform_Init (INTEGER argc, LONGINT argvadr)
{
	Platform_ArgVecPtr av = NIL;
	Platform_MainStackFrame = argvadr;
	Platform_ArgCount = argc;
	av = (Platform_ArgVecPtr)(uintptr_t)argvadr;
	Platform_ArgVector = (*av)[0];
	Platform_HaltCode = -128;
	Platform_HeapInitHeap();
}

BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len)
{
	BOOLEAN _o_result;
	Platform_EnvPtr p = NIL;
	__DUP(var, var__len, CHAR);
	p = Platform_getenv(var, var__len);
	if (p != NIL) {
		__COPY(*p, val, val__len);
	}
	_o_result = p != NIL;
	__DEL(var);
	return _o_result;
}

void Platform_GetEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len)
{
	__DUP(var, var__len, CHAR);
	if (!Platform_getEnv(var, var__len, (void*)val, val__len)) {
		val[0] = 0x00;
	}
	__DEL(var);
}

void Platform_GetArg (INTEGER n, CHAR *val, LONGINT val__len)
{
	Platform_ArgVec av = NIL;
	if (n < Platform_ArgCount) {
		av = (Platform_ArgVec)(uintptr_t)Platform_ArgVector;
		__COPY(*(*av)[__X(n, ((LONGINT)(1024)))], val, val__len);
	}
}

void Platform_GetIntArg (INTEGER n, LONGINT *val)
{
	CHAR s[64];
	LONGINT k, d, i;
	s[0] = 0x00;
	Platform_GetArg(n, (void*)s, ((LONGINT)(64)));
	i = 0;
	if (s[0] == '-') {
		i = 1;
	}
	k = 0;
	d = (int)s[__X(i, ((LONGINT)(64)))] - 48;
	while ((d >= 0 && d <= 9)) {
		k = k * 10 + d;
		i += 1;
		d = (int)s[__X(i, ((LONGINT)(64)))] - 48;
	}
	if (s[0] == '-') {
		k = -k;
		i -= 1;
	}
	if (i > 0) {
		*val = k;
	}
}

INTEGER Platform_ArgPos (CHAR *s, LONGINT s__len)
{
	INTEGER _o_result;
	INTEGER i;
	CHAR arg[256];
	__DUP(s, s__len, CHAR);
	i = 0;
	Platform_GetArg(i, (void*)arg, ((LONGINT)(256)));
	while ((i < Platform_ArgCount && __STRCMP(s, arg) != 0)) {
		i += 1;
		Platform_GetArg(i, (void*)arg, ((LONGINT)(256)));
	}
	_o_result = i;
	__DEL(s);
	return _o_result;
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

static void Platform_YMDHMStoClock (LONGINT ye, LONGINT mo, LONGINT da, LONGINT ho, LONGINT mi, LONGINT se, LONGINT *t, LONGINT *d)
{
	*d = (__ASHL(__MOD(ye, 100), 9) + __ASHL(mo + 1, 5)) + da;
	*t = (__ASHL(ho, 12) + __ASHL(mi, 6)) + se;
}

void Platform_GetClock (LONGINT *t, LONGINT *d)
{
	Platform_gettimeval();
	Platform_sectotm(Platform_tvsec());
	Platform_YMDHMStoClock(Platform_tmyear(), Platform_tmmon(), Platform_tmmday(), Platform_tmhour(), Platform_tmmin(), Platform_tmsec(), &*t, &*d);
}

void Platform_GetTimeOfDay (LONGINT *sec, LONGINT *usec)
{
	Platform_gettimeval();
	*sec = Platform_tvsec();
	*usec = Platform_tvusec();
}

LONGINT Platform_Time (void)
{
	LONGINT _o_result;
	LONGINT ms;
	Platform_gettimeval();
	ms = __DIVF(Platform_tvusec(), 1000) + Platform_tvsec() * 1000;
	_o_result = __MOD(ms - Platform_TimeStart, 2147483647);
	return _o_result;
}

void Platform_Delay (LONGINT ms)
{
	LONGINT s, ns;
	s = __DIV(ms, 1000);
	ns = __MOD(ms, 1000) * 1000000;
	Platform_nanosleep(s, ns);
}

INTEGER Platform_System (CHAR *cmd, LONGINT cmd__len)
{
	INTEGER _o_result;
	__DUP(cmd, cmd__len, CHAR);
	_o_result = Platform_system(cmd, cmd__len);
	__DEL(cmd);
	return _o_result;
}

INTEGER Platform_Error (void)
{
	INTEGER _o_result;
	_o_result = Platform_err();
	return _o_result;
}

INTEGER Platform_OldRO (CHAR *n, LONGINT n__len, LONGINT *h)
{
	INTEGER _o_result;
	INTEGER fd;
	fd = Platform_openro(n, n__len);
	if (fd < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		*h = fd;
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_OldRW (CHAR *n, LONGINT n__len, LONGINT *h)
{
	INTEGER _o_result;
	INTEGER fd;
	fd = Platform_openrw(n, n__len);
	if (fd < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		*h = fd;
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_New (CHAR *n, LONGINT n__len, LONGINT *h)
{
	INTEGER _o_result;
	INTEGER fd;
	fd = Platform_opennew(n, n__len);
	if (fd < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		*h = fd;
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Close (LONGINT h)
{
	INTEGER _o_result;
	if (Platform_closefile(h) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Identify (LONGINT h, Platform_FileIdentity *identity, LONGINT *identity__typ)
{
	INTEGER _o_result;
	Platform_structstats();
	if (Platform_fstat(h) < 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	(*identity).volume = Platform_statdev();
	(*identity).index = Platform_statino();
	(*identity).mtime = Platform_statmtime();
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, LONGINT *identity__typ)
{
	INTEGER _o_result;
	__DUP(n, n__len, CHAR);
	Platform_structstats();
	if (Platform_stat(n, n__len) < 0) {
		_o_result = Platform_err();
		__DEL(n);
		return _o_result;
	}
	(*identity).volume = Platform_statdev();
	(*identity).index = Platform_statino();
	(*identity).mtime = Platform_statmtime();
	_o_result = 0;
	__DEL(n);
	return _o_result;
}

BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	BOOLEAN _o_result;
	_o_result = (i1.index == i2.index && i1.volume == i2.volume);
	return _o_result;
}

BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	BOOLEAN _o_result;
	_o_result = i1.mtime == i2.mtime;
	return _o_result;
}

void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source)
{
	(*target).mtime = source.mtime;
}

void Platform_MTimeAsClock (Platform_FileIdentity i, LONGINT *t, LONGINT *d)
{
	Platform_sectotm(i.mtime);
	Platform_YMDHMStoClock(Platform_tmyear(), Platform_tmmon(), Platform_tmmday(), Platform_tmhour(), Platform_tmmin(), Platform_tmsec(), &*t, &*d);
}

INTEGER Platform_Size (LONGINT h, LONGINT *l)
{
	INTEGER _o_result;
	Platform_structstats();
	if (Platform_fstat(h) < 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	*l = Platform_statsize();
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_Read (LONGINT h, LONGINT p, LONGINT l, LONGINT *n)
{
	INTEGER _o_result;
	*n = Platform_readfile(h, p, l);
	if (*n < 0) {
		*n = 0;
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_ReadBuf (LONGINT h, SYSTEM_BYTE *b, LONGINT b__len, LONGINT *n)
{
	INTEGER _o_result;
	*n = Platform_readfile(h, (LONGINT)(uintptr_t)b, b__len);
	if (*n < 0) {
		*n = 0;
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Write (LONGINT h, LONGINT p, LONGINT l)
{
	INTEGER _o_result;
	LONGINT written;
	written = Platform_writefile(h, p, l);
	if (written < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Sync (LONGINT h)
{
	INTEGER _o_result;
	if (Platform_fsync(h) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Seek (LONGINT h, LONGINT offset, INTEGER whence)
{
	INTEGER _o_result;
	if (Platform_lseek(h, offset, whence) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Truncate (LONGINT h, LONGINT l)
{
	INTEGER _o_result;
	if (Platform_ftruncate(h, l) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Unlink (CHAR *n, LONGINT n__len)
{
	INTEGER _o_result;
	if (Platform_unlink(n, n__len) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Chdir (CHAR *n, LONGINT n__len)
{
	INTEGER _o_result;
	INTEGER r;
	r = Platform_chdir(n, n__len);
	Platform_getcwd((void*)Platform_CWD, ((LONGINT)(256)));
	if (r < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len)
{
	INTEGER _o_result;
	if (Platform_rename(o, o__len, n, n__len) < 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

void Platform_Exit (INTEGER code)
{
	Platform_exit(code);
}

static void Platform_errch (CHAR c)
{
	Platform_errc(c);
}

static void Platform_errln (void)
{
	Platform_errch(0x0d);
	Platform_errch(0x0a);
}

static void Platform_errposint (LONGINT l)
{
	if (l > 10) {
		Platform_errposint(__DIV(l, 10));
	}
	Platform_errch((CHAR)(48 + __MOD(l, 10)));
}

static void Platform_errint (LONGINT l)
{
	if (l < 0) {
		Platform_errch('-');
		l = -l;
	}
	Platform_errposint(l);
}

static void Platform_DisplayHaltCode (LONGINT code)
{
	switch (code) {
		case -1: 
			Platform_errstring((CHAR*)"Assertion failure.", (LONGINT)19);
			break;
		case -2: 
			Platform_errstring((CHAR*)"Index out of range.", (LONGINT)20);
			break;
		case -3: 
			Platform_errstring((CHAR*)"Reached end of function without reaching RETURN.", (LONGINT)49);
			break;
		case -4: 
			Platform_errstring((CHAR*)"CASE statement: no matching label and no ELSE.", (LONGINT)47);
			break;
		case -5: 
			Platform_errstring((CHAR*)"Type guard failed.", (LONGINT)19);
			break;
		case -6: 
			Platform_errstring((CHAR*)"Implicit type guard in record assignment failed.", (LONGINT)49);
			break;
		case -7: 
			Platform_errstring((CHAR*)"Invalid case in WITH statement.", (LONGINT)32);
			break;
		case -8: 
			Platform_errstring((CHAR*)"Value out of range.", (LONGINT)20);
			break;
		case -9: 
			Platform_errstring((CHAR*)"Heap interrupted while locked, but lockdepth = 0 at unlock.", (LONGINT)60);
			break;
		case -10: 
			Platform_errstring((CHAR*)"NIL access.", (LONGINT)12);
			break;
		case -11: 
			Platform_errstring((CHAR*)"Alignment error.", (LONGINT)17);
			break;
		case -12: 
			Platform_errstring((CHAR*)"Divide by zero.", (LONGINT)16);
			break;
		case -13: 
			Platform_errstring((CHAR*)"Arithmetic overflow/underflow.", (LONGINT)31);
			break;
		case -14: 
			Platform_errstring((CHAR*)"Invalid function argument.", (LONGINT)27);
			break;
		case -15: 
			Platform_errstring((CHAR*)"Internal error, e.g. Type descriptor size mismatch.", (LONGINT)52);
			break;
		case -20: 
			Platform_errstring((CHAR*)"Too many, or negative number of, elements in dynamic array.", (LONGINT)60);
			break;
		default: 
			break;
	}
}

void Platform_Halt (LONGINT code)
{
	INTEGER e;
	Platform_HaltCode = code;
	if (Platform_HaltHandler != NIL) {
		(*Platform_HaltHandler)(code);
	}
	Platform_errstring((CHAR*)"Terminated by Halt(", (LONGINT)20);
	Platform_errint(code);
	Platform_errstring((CHAR*)"). ", (LONGINT)4);
	if (code < 0) {
		Platform_DisplayHaltCode(code);
	}
	Platform_errln();
	Platform_exit(__VAL(INTEGER, code));
}

void Platform_AssertFail (LONGINT code)
{
	INTEGER e;
	Platform_errstring((CHAR*)"Assertion failure.", (LONGINT)19);
	if (code != 0) {
		Platform_errstring((CHAR*)" ASSERT code ", (LONGINT)14);
		Platform_errint(code);
		Platform_errstring((CHAR*)".", (LONGINT)2);
	}
	Platform_errln();
	Platform_exit(__VAL(INTEGER, code));
}

void Platform_SetHalt (Platform_HaltProcedure p)
{
	Platform_HaltHandler = p;
}

static void Platform_TestLittleEndian (void)
{
	INTEGER i;
	i = 1;
	__GET((LONGINT)(uintptr_t)&i, Platform_LittleEndian, BOOLEAN);
}

__TDESC(Platform_FileIdentity, 1, 0) = {__TDFLDS("FileIdentity", 12), {-4}};

export void *Platform__init(void)
{
	__DEFMOD;
	__REGMOD("Platform", 0);
	__INITYP(Platform_FileIdentity, Platform_FileIdentity, 0);
/* BEGIN */
	Platform_TestLittleEndian();
	Platform_HaltCode = -128;
	Platform_HaltHandler = NIL;
	Platform_TimeStart = Platform_Time();
	Platform_CWD[0] = 0x00;
	Platform_getcwd((void*)Platform_CWD, ((LONGINT)(256)));
	Platform_PID = Platform_getpid();
	Platform_SeekSet = Platform_seekset();
	Platform_SeekCur = Platform_seekcur();
	Platform_SeekEnd = Platform_seekend();
	Platform_nl[0] = 0x0a;
	Platform_nl[1] = 0x00;
	__ENDMOD;
}
