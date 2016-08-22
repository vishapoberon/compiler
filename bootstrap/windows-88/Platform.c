/* voc 1.95 [2016/08/22] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
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
		LONGINT volume, indexhigh, indexlow, mtimehigh, mtimelow;
	} Platform_FileIdentity;

typedef
	void (*Platform_HaltProcedure)(LONGINT);

typedef
	void (*Platform_SignalHandler)(INTEGER);


export BOOLEAN Platform_LittleEndian;
export LONGINT Platform_MainStackFrame, Platform_HaltCode;
export INTEGER Platform_PID;
export CHAR Platform_CWD[4096];
export INTEGER Platform_ArgCount;
export LONGINT Platform_ArgVector;
static Platform_HaltProcedure Platform_HaltHandler;
static LONGINT Platform_TimeStart;
export INTEGER Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
export LONGINT Platform_StdIn, Platform_StdOut, Platform_StdErr;
static Platform_SignalHandler Platform_InterruptHandler;
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
export INTEGER Platform_Seek (LONGINT h, LONGINT o, INTEGER r);
export void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
export void Platform_SetHalt (Platform_HaltProcedure p);
export void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source);
export INTEGER Platform_Size (LONGINT h, LONGINT *l);
export INTEGER Platform_Sync (LONGINT h);
export INTEGER Platform_System (CHAR *cmd, LONGINT cmd__len);
static void Platform_TestLittleEndian (void);
export LONGINT Platform_Time (void);
export BOOLEAN Platform_TimedOut (INTEGER e);
export BOOLEAN Platform_TooManyFiles (INTEGER e);
export INTEGER Platform_Truncate (LONGINT h, LONGINT limit);
export INTEGER Platform_Unlink (CHAR *n, LONGINT n__len);
export INTEGER Platform_Write (LONGINT h, LONGINT p, LONGINT l);
static void Platform_YMDHMStoClock (INTEGER ye, INTEGER mo, INTEGER da, INTEGER ho, INTEGER mi, INTEGER se, LONGINT *t, LONGINT *d);
static void Platform_errch (CHAR c);
static void Platform_errint (LONGINT l);
static void Platform_errln (void);
static void Platform_errposint (LONGINT l);
export BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);

#include "WindowsWrapper.h"
#define Platform_ECONNABORTED()	WSAECONNABORTED
#define Platform_ECONNREFUSED()	WSAECONNREFUSED
#define Platform_EHOSTUNREACH()	WSAEHOSTUNREACH
#define Platform_ENETUNREACH()	WSAENETUNREACH
#define Platform_ERRORACCESSDENIED()	ERROR_ACCESS_DENIED
#define Platform_ERRORFILENOTFOUND()	ERROR_FILE_NOT_FOUND
#define Platform_ERRORNOTREADY()	ERROR_NOT_READY
#define Platform_ERRORNOTSAMEDEVICE()	ERROR_NOT_SAME_DEVICE
#define Platform_ERRORPATHNOTFOUND()	ERROR_PATH_NOT_FOUND
#define Platform_ERRORSHARINGVIOLATION()	ERROR_SHARING_VIOLATION
#define Platform_ERRORTOOMANYOPENFILES()	ERROR_TOO_MANY_OPEN_FILES
#define Platform_ERRORWRITEPROTECT()	ERROR_WRITE_PROTECT
#define Platform_ETIMEDOUT()	WSAETIMEDOUT
extern void Heap_InitHeap();
#define Platform_GetTickCount()	(LONGINT)(SYSTEM_CARD32)GetTickCount()
#define Platform_HeapInitHeap()	Heap_InitHeap()
#define Platform_SetInterruptHandler(h)	SystemSetInterruptHandler((uintptr_t)h)
#define Platform_SetQuitHandler(h)	SystemSetQuitHandler((uintptr_t)h)
#define Platform_allocate(size)	(LONGINT)(uintptr_t)((void*)HeapAlloc(GetProcessHeap(), 0, (size_t)size))
#define Platform_bhfiIndexHigh()	(LONGINT)bhfi.nFileIndexHigh
#define Platform_bhfiIndexLow()	(LONGINT)bhfi.nFileIndexLow
#define Platform_bhfiMtimeHigh()	(LONGINT)bhfi.ftLastWriteTime.dwHighDateTime
#define Platform_bhfiMtimeLow()	(LONGINT)bhfi.ftLastWriteTime.dwLowDateTime
#define Platform_bhfiVsn()	(LONGINT)bhfi.dwVolumeSerialNumber
#define Platform_byHandleFileInformation()	BY_HANDLE_FILE_INFORMATION bhfi
#define Platform_cleanupProcess()	CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
#define Platform_closeHandle(h)	(INTEGER)CloseHandle((HANDLE)(uintptr_t)h)
#define Platform_createProcess(str, str__len)	(INTEGER)CreateProcess(0, (char*)str, 0,0,0,0,0,0,&si,&pi)
#define Platform_deleteFile(n, n__len)	(INTEGER)DeleteFile((char*)n)
#define Platform_err()	(INTEGER)GetLastError()
#define Platform_errc(c)	WriteFile((HANDLE)(uintptr_t)Platform_StdOut, &c, 1, 0,0)
#define Platform_errstring(s, s__len)	WriteFile((HANDLE)(uintptr_t)Platform_StdOut, s, s__len-1, 0,0)
#define Platform_exit(code)	ExitProcess((UINT)code)
#define Platform_fileTimeToSysTime()	SYSTEMTIME st; FileTimeToSystemTime(&ft, &st)
#define Platform_flushFileBuffers(h)	(INTEGER)FlushFileBuffers((HANDLE)(uintptr_t)h)
#define Platform_free(address)	HeapFree(GetProcessHeap(), 0, (void*)(uintptr_t)address)
#define Platform_ftToUli()	ULARGE_INTEGER ul; ul.LowPart=ft.dwLowDateTime; ul.HighPart=ft.dwHighDateTime
#define Platform_getCurrentDirectory(n, n__len)	GetCurrentDirectory(n__len, (char*)n)
#define Platform_getExitCodeProcess(exitcode)	GetExitCodeProcess(pi.hProcess, (DWORD*)exitcode);
#define Platform_getFileInformationByHandle(h)	(INTEGER)GetFileInformationByHandle((HANDLE)(uintptr_t)h, &bhfi)
#define Platform_getFilePos(h, r, rc)	LARGE_INTEGER liz = {0}; *rc = (INTEGER)SetFilePointerEx((HANDLE)(uintptr_t)h, liz, &li, FILE_CURRENT); *r = (LONGINT)li.QuadPart
#define Platform_getFileSize(h)	(INTEGER)GetFileSizeEx((HANDLE)(uintptr_t)h, &li)
#define Platform_getLocalTime()	SYSTEMTIME st; GetLocalTime(&st)
#define Platform_getenv(name, name__len, buf, buf__len)	(INTEGER)GetEnvironmentVariable((char*)name, (char*)buf, buf__len)
#define Platform_getpid()	(INTEGER)GetCurrentProcessId()
#define Platform_getstderrhandle()	(uintptr_t)GetStdHandle(STD_ERROR_HANDLE)
#define Platform_getstdinhandle()	(uintptr_t)GetStdHandle(STD_INPUT_HANDLE)
#define Platform_getstdouthandle()	(uintptr_t)GetStdHandle(STD_OUTPUT_HANDLE)
#define Platform_identityToFileTime(i)	FILETIME ft; ft.dwHighDateTime = i.mtimehigh; ft.dwLowDateTime = i.mtimelow
#define Platform_invalidHandleValue()	((LONGINT)(uintptr_t)INVALID_HANDLE_VALUE)
#define Platform_largeInteger()	LARGE_INTEGER li
#define Platform_liLongint()	(LONGINT)li.QuadPart
#define Platform_moveFile(o, o__len, n, n__len)	(INTEGER)MoveFileEx((char*)o, (char*)n, MOVEFILE_REPLACE_EXISTING)
#define Platform_opennew(n, n__len)	(LONGINT)(uintptr_t)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_openro(n, n__len)	(LONGINT)(uintptr_t)CreateFile((char*)n, GENERIC_READ              , FILE_SHARE_READ|FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_openrw(n, n__len)	(LONGINT)(uintptr_t)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_processInfo()	PROCESS_INFORMATION pi = {0};
#define Platform_readfile(fd, p, l, n)	(INTEGER)ReadFile ((HANDLE)(uintptr_t)fd, (void*)(uintptr_t)(p), (DWORD)l, (DWORD*)n, 0)
#define Platform_seekcur()	FILE_CURRENT
#define Platform_seekend()	FILE_END
#define Platform_seekset()	FILE_BEGIN
#define Platform_setCurrentDirectory(n, n__len)	(INTEGER)SetCurrentDirectory((char*)n)
#define Platform_setEndOfFile(h)	(INTEGER)SetEndOfFile((HANDLE)(uintptr_t)h)
#define Platform_setFilePointerEx(h, o, r, rc)	li.QuadPart=o; *rc = (INTEGER)SetFilePointerEx((HANDLE)(uintptr_t)h, li, 0, (DWORD)r)
#define Platform_sleep(ms)	Sleep((DWORD)ms)
#define Platform_stToFt()	FILETIME ft; SystemTimeToFileTime(&st, &ft)
#define Platform_startupInfo()	STARTUPINFO si = {0}; si.cb = sizeof(si);
#define Platform_sthour()	(INTEGER)st.wHour
#define Platform_stmday()	(INTEGER)st.wDay
#define Platform_stmin()	(INTEGER)st.wMinute
#define Platform_stmon()	(INTEGER)st.wMonth
#define Platform_stmsec()	(INTEGER)st.wMilliseconds
#define Platform_stsec()	(INTEGER)st.wSecond
#define Platform_styear()	(INTEGER)st.wYear
#define Platform_tous1970()	ul.QuadPart = (ul.QuadPart - 116444736000000000ULL)/10LL
#define Platform_ulSec()	(LONGINT)(ul.QuadPart / 1000000LL)
#define Platform_uluSec()	(LONGINT)(ul.QuadPart % 1000000LL)
#define Platform_waitForProcess()	(INTEGER)WaitForSingleObject(pi.hProcess, INFINITE)
#define Platform_writefile(fd, p, l)	(INTEGER)WriteFile((HANDLE)(uintptr_t)fd, (void*)(uintptr_t)(p), (DWORD)l, 0,0)

BOOLEAN Platform_TooManyFiles (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORTOOMANYOPENFILES();
	return _o_result;
}

BOOLEAN Platform_NoSuchDirectory (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORPATHNOTFOUND();
	return _o_result;
}

BOOLEAN Platform_DifferentFilesystems (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORNOTSAMEDEVICE();
	return _o_result;
}

BOOLEAN Platform_Inaccessible (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = ((e == Platform_ERRORACCESSDENIED() || e == Platform_ERRORWRITEPROTECT()) || e == Platform_ERRORNOTREADY()) || e == Platform_ERRORSHARINGVIOLATION();
	return _o_result;
}

BOOLEAN Platform_Absent (INTEGER e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORFILENOTFOUND() || e == Platform_ERRORPATHNOTFOUND();
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
	CHAR buf[4096];
	INTEGER res;
	__DUP(var, var__len, CHAR);
	res = Platform_getenv(var, var__len, (void*)buf, ((LONGINT)(4096)));
	if ((res > 0 && res < 4096)) {
		__COPY(buf, val, val__len);
		_o_result = 1;
		__DEL(var);
		return _o_result;
	} else {
		_o_result = 0;
		__DEL(var);
		return _o_result;
	}
	__RETCHK;
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

void Platform_SetBadInstructionHandler (Platform_SignalHandler handler)
{
}

static void Platform_YMDHMStoClock (INTEGER ye, INTEGER mo, INTEGER da, INTEGER ho, INTEGER mi, INTEGER se, LONGINT *t, LONGINT *d)
{
	*d = (__ASHL((SYSTEM_INT64)(int)__MOD(ye, 100), 9) + __ASHL((SYSTEM_INT64)(mo + 1), 5)) + (SYSTEM_INT64)da;
	*t = (__ASHL((SYSTEM_INT64)ho, 12) + __ASHL((SYSTEM_INT64)mi, 6)) + (SYSTEM_INT64)se;
}

void Platform_GetClock (LONGINT *t, LONGINT *d)
{
	Platform_getLocalTime();
	Platform_YMDHMStoClock(Platform_styear(), Platform_stmon(), Platform_stmday(), Platform_sthour(), Platform_stmin(), Platform_stsec(), &*t, &*d);
}

LONGINT Platform_Time (void)
{
	LONGINT _o_result;
	LONGINT ms;
	ms = Platform_GetTickCount();
	_o_result = __MOD(ms - Platform_TimeStart, 2147483647);
	return _o_result;
}

void Platform_Delay (LONGINT ms)
{
	while (ms > 30000) {
		Platform_sleep(((LONGINT)(30000)));
		ms = ms - 30000;
	}
	if (ms > 0) {
		Platform_sleep(ms);
	}
}

void Platform_GetTimeOfDay (LONGINT *sec, LONGINT *usec)
{
	Platform_getLocalTime();
	Platform_stToFt();
	Platform_ftToUli();
	Platform_tous1970();
	*sec = Platform_ulSec();
	*usec = Platform_uluSec();
}

INTEGER Platform_System (CHAR *cmd, LONGINT cmd__len)
{
	INTEGER _o_result;
	INTEGER result;
	__DUP(cmd, cmd__len, CHAR);
	result = 127;
	Platform_startupInfo();
	Platform_processInfo();
	if (Platform_createProcess(cmd, cmd__len) != 0) {
		if (Platform_waitForProcess() == 0) {
			Platform_getExitCodeProcess(&result);
		}
		Platform_cleanupProcess();
	}
	_o_result = __ASHL(result, 8);
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
	LONGINT fd;
	fd = Platform_openro(n, n__len);
	if (fd == Platform_invalidHandleValue()) {
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
	LONGINT fd;
	fd = Platform_openrw(n, n__len);
	if (fd == Platform_invalidHandleValue()) {
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
	LONGINT fd;
	fd = Platform_opennew(n, n__len);
	if (fd == Platform_invalidHandleValue()) {
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
	if (Platform_closeHandle(h) == 0) {
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
	Platform_byHandleFileInformation();
	if (Platform_getFileInformationByHandle(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	(*identity).volume = Platform_bhfiVsn();
	(*identity).indexhigh = Platform_bhfiIndexHigh();
	(*identity).indexlow = Platform_bhfiIndexLow();
	(*identity).mtimehigh = Platform_bhfiMtimeHigh();
	(*identity).mtimelow = Platform_bhfiMtimeLow();
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, LONGINT *identity__typ)
{
	INTEGER _o_result;
	LONGINT h;
	INTEGER e, i;
	__DUP(n, n__len, CHAR);
	e = Platform_OldRO((void*)n, n__len, &h);
	if (e != 0) {
		_o_result = e;
		__DEL(n);
		return _o_result;
	}
	e = Platform_Identify(h, &*identity, identity__typ);
	i = Platform_Close(h);
	_o_result = e;
	__DEL(n);
	return _o_result;
}

BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	BOOLEAN _o_result;
	_o_result = (((i1.indexhigh == i2.indexhigh && i1.indexlow == i2.indexlow)) && i1.volume == i2.volume);
	return _o_result;
}

BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2)
{
	BOOLEAN _o_result;
	_o_result = (i1.mtimehigh == i2.mtimehigh && i1.mtimelow == i2.mtimelow);
	return _o_result;
}

void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source)
{
	(*target).mtimehigh = source.mtimehigh;
	(*target).mtimelow = source.mtimelow;
}

void Platform_MTimeAsClock (Platform_FileIdentity i, LONGINT *t, LONGINT *d)
{
	Platform_identityToFileTime(i);
	Platform_fileTimeToSysTime();
	Platform_YMDHMStoClock(Platform_styear(), Platform_stmon(), Platform_stmday(), Platform_sthour(), Platform_stmin(), Platform_stsec(), &*t, &*d);
}

INTEGER Platform_Size (LONGINT h, LONGINT *l)
{
	INTEGER _o_result;
	Platform_largeInteger();
	if (Platform_getFileSize(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	*l = Platform_liLongint();
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_Read (LONGINT h, LONGINT p, LONGINT l, LONGINT *n)
{
	INTEGER _o_result;
	INTEGER result;
	*n = 0;
	result = Platform_readfile(h, p, l, &*n);
	if (result == 0) {
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
	INTEGER result;
	*n = 0;
	result = Platform_readfile(h, (LONGINT)(uintptr_t)b, b__len, &*n);
	if (result == 0) {
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
	if (Platform_writefile(h, p, l) == 0) {
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
	if (Platform_flushFileBuffers(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Seek (LONGINT h, LONGINT o, INTEGER r)
{
	INTEGER _o_result;
	INTEGER rc;
	Platform_largeInteger();
	Platform_setFilePointerEx(h, o, r, &rc);
	if (rc == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

INTEGER Platform_Truncate (LONGINT h, LONGINT limit)
{
	INTEGER _o_result;
	INTEGER rc;
	LONGINT oldpos;
	Platform_largeInteger();
	Platform_getFilePos(h, &oldpos, &rc);
	if (rc == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	Platform_setFilePointerEx(h, limit, Platform_seekset(), &rc);
	if (rc == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	if (Platform_setEndOfFile(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	Platform_setFilePointerEx(h, oldpos, Platform_seekset(), &rc);
	if (rc == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_Unlink (CHAR *n, LONGINT n__len)
{
	INTEGER _o_result;
	if (Platform_deleteFile(n, n__len) == 0) {
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
	r = Platform_setCurrentDirectory(n, n__len);
	if (r == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	Platform_getCurrentDirectory((void*)Platform_CWD, ((LONGINT)(4096)));
	_o_result = 0;
	return _o_result;
}

INTEGER Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len)
{
	INTEGER _o_result;
	if (Platform_moveFile(o, o__len, n, n__len) == 0) {
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
			Platform_errstring((CHAR*)"Rider ReadBuf/WriteBuf transfer size longer than buffer.", (LONGINT)57);
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
			Platform_errstring((CHAR*)"Type equality failed.", (LONGINT)22);
			break;
		case -7: 
			Platform_errstring((CHAR*)"WITH statement type guard failed.", (LONGINT)34);
			break;
		case -8: 
			Platform_errstring((CHAR*)"SHORT: Value too large for shorter type.", (LONGINT)41);
			break;
		case -9: 
			Platform_errstring((CHAR*)"Heap interrupted while locked, but lockdepth = 0 at unlock.", (LONGINT)60);
			break;
		case -15: 
			Platform_errstring((CHAR*)"Type descriptor size mismatch.", (LONGINT)31);
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

__TDESC(Platform_FileIdentity, 1, 0) = {__TDFLDS("FileIdentity", 40), {-8}};

export void *Platform__init(void)
{
	__DEFMOD;
	__REGMOD("Platform", 0);
	__INITYP(Platform_FileIdentity, Platform_FileIdentity, 0);
/* BEGIN */
	Platform_TestLittleEndian();
	Platform_HaltCode = -128;
	Platform_HaltHandler = NIL;
	Platform_TimeStart = 0;
	Platform_TimeStart = Platform_Time();
	Platform_CWD[0] = 0x00;
	Platform_getCurrentDirectory((void*)Platform_CWD, ((LONGINT)(4096)));
	Platform_PID = Platform_getpid();
	Platform_SeekSet = Platform_seekset();
	Platform_SeekCur = Platform_seekcur();
	Platform_SeekEnd = Platform_seekend();
	Platform_StdIn = Platform_getstdinhandle();
	Platform_StdOut = Platform_getstdouthandle();
	Platform_StdErr = Platform_getstderrhandle();
	Platform_nl[0] = 0x0d;
	Platform_nl[1] = 0x0a;
	Platform_nl[2] = 0x00;
	__ENDMOD;
}
