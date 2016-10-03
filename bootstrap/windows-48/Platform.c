/* voc 1.95 [2016/10/03]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"

typedef
	CHAR (*Platform_ArgPtr)[1024];

typedef
	Platform_ArgPtr (*Platform_ArgVec)[1024];

typedef
	int32 (*Platform_ArgVecPtr)[1];

typedef
	CHAR (*Platform_EnvPtr)[1024];

typedef
	struct Platform_FileIdentity {
		int32 volume, indexhigh, indexlow, mtimehigh, mtimelow;
	} Platform_FileIdentity;

typedef
	void (*Platform_HaltProcedure)(int32);

typedef
	void (*Platform_SignalHandler)(int16);


export BOOLEAN Platform_LittleEndian;
export int32 Platform_MainStackFrame;
export int32 Platform_HaltCode;
export int16 Platform_PID;
export CHAR Platform_CWD[4096];
export int16 Platform_ArgCount;
export int32 Platform_ArgVector;
static Platform_HaltProcedure Platform_HaltHandler;
static int32 Platform_TimeStart;
export int16 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
export int32 Platform_StdIn, Platform_StdOut, Platform_StdErr;
static Platform_SignalHandler Platform_InterruptHandler;
export CHAR Platform_NL[3];

export address *Platform_FileIdentity__typ;

export BOOLEAN Platform_Absent (int16 e);
export int16 Platform_ArgPos (CHAR *s, LONGINT s__len);
export void Platform_AssertFail (int32 code);
export int16 Platform_Chdir (CHAR *n, LONGINT n__len);
export int16 Platform_Close (int32 h);
export BOOLEAN Platform_ConnectionFailed (int16 e);
export void Platform_Delay (int32 ms);
export BOOLEAN Platform_DifferentFilesystems (int16 e);
static void Platform_DisplayHaltCode (int32 code);
export int16 Platform_Error (void);
export void Platform_Exit (int16 code);
export void Platform_GetArg (int16 n, CHAR *val, LONGINT val__len);
export void Platform_GetClock (int32 *t, int32 *d);
export void Platform_GetEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
export void Platform_GetIntArg (int16 n, int32 *val);
export void Platform_GetTimeOfDay (int32 *sec, int32 *usec);
export void Platform_Halt (int32 code);
export int16 Platform_Identify (int32 h, Platform_FileIdentity *identity, address *identity__typ);
export int16 Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, address *identity__typ);
export BOOLEAN Platform_Inaccessible (int16 e);
export void Platform_Init (int16 argc, int32 argvadr);
export BOOLEAN Platform_Interrupted (int16 e);
export void Platform_MTimeAsClock (Platform_FileIdentity i, int32 *t, int32 *d);
export int16 Platform_New (CHAR *n, LONGINT n__len, int32 *h);
export BOOLEAN Platform_NoSuchDirectory (int16 e);
export int32 Platform_OSAllocate (int32 size);
export void Platform_OSFree (int32 address);
export int16 Platform_OldRO (CHAR *n, LONGINT n__len, int32 *h);
export int16 Platform_OldRW (CHAR *n, LONGINT n__len, int32 *h);
export int16 Platform_Read (int32 h, int32 p, int32 l, int32 *n);
export int16 Platform_ReadBuf (int32 h, SYSTEM_BYTE *b, LONGINT b__len, int32 *n);
export int16 Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len);
export BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
export BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
export int16 Platform_Seek (int32 h, int32 o, int16 r);
export void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
export void Platform_SetHalt (Platform_HaltProcedure p);
export void Platform_SetMTime (Platform_FileIdentity *target, address *target__typ, Platform_FileIdentity source);
export int16 Platform_Size (int32 h, int32 *l);
export int16 Platform_Sync (int32 h);
export int16 Platform_System (CHAR *cmd, LONGINT cmd__len);
static void Platform_TestLittleEndian (void);
export int32 Platform_Time (void);
export BOOLEAN Platform_TimedOut (int16 e);
export BOOLEAN Platform_TooManyFiles (int16 e);
export int16 Platform_Truncate (int32 h, int32 limit);
export int16 Platform_Unlink (CHAR *n, LONGINT n__len);
export int16 Platform_Write (int32 h, int32 p, int32 l);
static void Platform_YMDHMStoClock (int16 ye, int16 mo, int16 da, int16 ho, int16 mi, int16 se, int32 *t, int32 *d);
static void Platform_errch (CHAR c);
static void Platform_errint (int32 l);
static void Platform_errln (void);
static void Platform_errposint (int32 l);
export BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);

#include "WindowsWrapper.h"
#define Platform_ECONNABORTED()	WSAECONNABORTED
#define Platform_ECONNREFUSED()	WSAECONNREFUSED
#define Platform_EHOSTUNREACH()	WSAEHOSTUNREACH
#define Platform_EINTR()	WSAEINTR
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
#define Platform_GetTickCount()	(LONGINT)(uint32)GetTickCount()
#define Platform_HeapInitHeap()	Heap_InitHeap()
#define Platform_SetInterruptHandler(h)	SystemSetInterruptHandler((address)h)
#define Platform_SetQuitHandler(h)	SystemSetQuitHandler((address)h)
#define Platform_allocate(size)	(address)((void*)HeapAlloc(GetProcessHeap(), 0, (size_t)size))
#define Platform_bhfiIndexHigh()	(LONGINT)bhfi.nFileIndexHigh
#define Platform_bhfiIndexLow()	(LONGINT)bhfi.nFileIndexLow
#define Platform_bhfiMtimeHigh()	(LONGINT)bhfi.ftLastWriteTime.dwHighDateTime
#define Platform_bhfiMtimeLow()	(LONGINT)bhfi.ftLastWriteTime.dwLowDateTime
#define Platform_bhfiVsn()	(LONGINT)bhfi.dwVolumeSerialNumber
#define Platform_byHandleFileInformation()	BY_HANDLE_FILE_INFORMATION bhfi
#define Platform_cleanupProcess()	CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
#define Platform_closeHandle(h)	(INTEGER)CloseHandle((HANDLE)(address)h)
#define Platform_createProcess(str, str__len)	(INTEGER)CreateProcess(0, (char*)str, 0,0,0,0,0,0,&si,&pi)
#define Platform_deleteFile(n, n__len)	(INTEGER)DeleteFile((char*)n)
#define Platform_err()	(INTEGER)GetLastError()
#define Platform_errc(c)	WriteFile((HANDLE)(address)Platform_StdOut, &c, 1, 0,0)
#define Platform_errstring(s, s__len)	WriteFile((HANDLE)(address)Platform_StdOut, s, s__len-1, 0,0)
#define Platform_exit(code)	ExitProcess((UINT)code)
#define Platform_fileTimeToSysTime()	SYSTEMTIME st; FileTimeToSystemTime(&ft, &st)
#define Platform_flushFileBuffers(h)	(INTEGER)FlushFileBuffers((HANDLE)h)
#define Platform_free(address)	HeapFree(GetProcessHeap(), 0, (void*)address)
#define Platform_ftToUli()	ULARGE_INTEGER ul; ul.LowPart=ft.dwLowDateTime; ul.HighPart=ft.dwHighDateTime
#define Platform_getCurrentDirectory(n, n__len)	GetCurrentDirectory(n__len, (char*)n)
#define Platform_getExitCodeProcess(exitcode)	GetExitCodeProcess(pi.hProcess, (DWORD*)exitcode);
#define Platform_getFileInformationByHandle(h)	(INTEGER)GetFileInformationByHandle((HANDLE)(address)h, &bhfi)
#define Platform_getFilePos(h, r, rc)	LARGE_INTEGER liz = {0}; *rc = (INTEGER)SetFilePointerEx((HANDLE)(address)h, liz, &li, FILE_CURRENT); *r = (LONGINT)li.QuadPart
#define Platform_getFileSize(h)	(INTEGER)GetFileSizeEx((HANDLE)(address)h, &li)
#define Platform_getLocalTime()	SYSTEMTIME st; GetLocalTime(&st)
#define Platform_getenv(name, name__len, buf, buf__len)	(INTEGER)GetEnvironmentVariable((char*)name, (char*)buf, buf__len)
#define Platform_getpid()	(INTEGER)GetCurrentProcessId()
#define Platform_getstderrhandle()	(address)GetStdHandle(STD_ERROR_HANDLE)
#define Platform_getstdinhandle()	(address)GetStdHandle(STD_INPUT_HANDLE)
#define Platform_getstdouthandle()	(address)GetStdHandle(STD_OUTPUT_HANDLE)
#define Platform_identityToFileTime(i)	FILETIME ft; ft.dwHighDateTime = i.mtimehigh; ft.dwLowDateTime = i.mtimelow
#define Platform_invalidHandleValue()	((LONGINT)(address)INVALID_HANDLE_VALUE)
#define Platform_largeInteger()	LARGE_INTEGER li
#define Platform_liLongint()	(LONGINT)li.QuadPart
#define Platform_moveFile(o, o__len, n, n__len)	(INTEGER)MoveFileEx((char*)o, (char*)n, MOVEFILE_REPLACE_EXISTING)
#define Platform_opennew(n, n__len)	(LONGINT)(address)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_openro(n, n__len)	(LONGINT)(address)CreateFile((char*)n, GENERIC_READ              , FILE_SHARE_READ|FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_openrw(n, n__len)	(LONGINT)(address)CreateFile((char*)n, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)
#define Platform_processInfo()	PROCESS_INFORMATION pi = {0};
#define Platform_readfile(fd, p, l, n)	(INTEGER)ReadFile((HANDLE)fd, (void*)p, (DWORD)l, (DWORD*)n, 0)
#define Platform_seekcur()	FILE_CURRENT
#define Platform_seekend()	FILE_END
#define Platform_seekset()	FILE_BEGIN
#define Platform_setCurrentDirectory(n, n__len)	(INTEGER)SetCurrentDirectory((char*)n)
#define Platform_setEndOfFile(h)	(INTEGER)SetEndOfFile((HANDLE)(address)h)
#define Platform_setFilePointerEx(h, o, r, rc)	li.QuadPart=o; *rc = (INTEGER)SetFilePointerEx((HANDLE)(address)h, li, 0, (DWORD)r)
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
#define Platform_writefile(fd, p, l)	(INTEGER)WriteFile((HANDLE)fd, (void*)(p), (DWORD)l, 0,0)

BOOLEAN Platform_TooManyFiles (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORTOOMANYOPENFILES();
	return _o_result;
}

BOOLEAN Platform_NoSuchDirectory (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORPATHNOTFOUND();
	return _o_result;
}

BOOLEAN Platform_DifferentFilesystems (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORNOTSAMEDEVICE();
	return _o_result;
}

BOOLEAN Platform_Inaccessible (int16 e)
{
	BOOLEAN _o_result;
	_o_result = ((e == Platform_ERRORACCESSDENIED() || e == Platform_ERRORWRITEPROTECT()) || e == Platform_ERRORNOTREADY()) || e == Platform_ERRORSHARINGVIOLATION();
	return _o_result;
}

BOOLEAN Platform_Absent (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ERRORFILENOTFOUND() || e == Platform_ERRORPATHNOTFOUND();
	return _o_result;
}

BOOLEAN Platform_TimedOut (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_ETIMEDOUT();
	return _o_result;
}

BOOLEAN Platform_ConnectionFailed (int16 e)
{
	BOOLEAN _o_result;
	_o_result = ((e == Platform_ECONNREFUSED() || e == Platform_ECONNABORTED()) || e == Platform_ENETUNREACH()) || e == Platform_EHOSTUNREACH();
	return _o_result;
}

BOOLEAN Platform_Interrupted (int16 e)
{
	BOOLEAN _o_result;
	_o_result = e == Platform_EINTR();
	return _o_result;
}

int32 Platform_OSAllocate (int32 size)
{
	int32 _o_result;
	_o_result = Platform_allocate(size);
	return _o_result;
}

void Platform_OSFree (int32 address)
{
	Platform_free(address);
}

void Platform_Init (int16 argc, int32 argvadr)
{
	Platform_ArgVecPtr av = NIL;
	Platform_MainStackFrame = argvadr;
	Platform_ArgCount = argc;
	av = (Platform_ArgVecPtr)(address)argvadr;
	Platform_ArgVector = (*av)[0];
	Platform_HaltCode = -128;
	Platform_HeapInitHeap();
}

BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len)
{
	BOOLEAN _o_result;
	CHAR buf[4096];
	int16 res;
	__DUP(var, var__len, CHAR);
	res = Platform_getenv(var, var__len, (void*)buf, 4096);
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

void Platform_GetArg (int16 n, CHAR *val, LONGINT val__len)
{
	Platform_ArgVec av = NIL;
	if (n < Platform_ArgCount) {
		av = (Platform_ArgVec)(address)Platform_ArgVector;
		__COPY(*(*av)[__X(n, 1024)], val, val__len);
	}
}

void Platform_GetIntArg (int16 n, int32 *val)
{
	CHAR s[64];
	int32 k, d, i;
	s[0] = 0x00;
	Platform_GetArg(n, (void*)s, 64);
	i = 0;
	if (s[0] == '-') {
		i = 1;
	}
	k = 0;
	d = (int16)s[__X(i, 64)] - 48;
	while ((d >= 0 && d <= 9)) {
		k = k * 10 + d;
		i += 1;
		d = (int16)s[__X(i, 64)] - 48;
	}
	if (s[0] == '-') {
		k = -k;
		i -= 1;
	}
	if (i > 0) {
		*val = k;
	}
}

int16 Platform_ArgPos (CHAR *s, LONGINT s__len)
{
	int16 _o_result;
	int16 i;
	CHAR arg[256];
	__DUP(s, s__len, CHAR);
	i = 0;
	Platform_GetArg(i, (void*)arg, 256);
	while ((i < Platform_ArgCount && __STRCMP(s, arg) != 0)) {
		i += 1;
		Platform_GetArg(i, (void*)arg, 256);
	}
	_o_result = i;
	__DEL(s);
	return _o_result;
}

void Platform_SetBadInstructionHandler (Platform_SignalHandler handler)
{
}

static void Platform_YMDHMStoClock (int16 ye, int16 mo, int16 da, int16 ho, int16 mi, int16 se, int32 *t, int32 *d)
{
	*d = (__ASHL((int)__MOD(ye, 100), 9) + __ASHL((mo + 1), 5)) + da;
	*t = (__ASHL(ho, 12) + __ASHL(mi, 6)) + se;
}

void Platform_GetClock (int32 *t, int32 *d)
{
	Platform_getLocalTime();
	Platform_YMDHMStoClock(Platform_styear(), Platform_stmon(), Platform_stmday(), Platform_sthour(), Platform_stmin(), Platform_stsec(), &*t, &*d);
}

int32 Platform_Time (void)
{
	int32 _o_result;
	int32 ms;
	ms = Platform_GetTickCount();
	_o_result = (int)__MOD(ms - Platform_TimeStart, 2147483647);
	return _o_result;
}

void Platform_Delay (int32 ms)
{
	while (ms > 30000) {
		Platform_sleep(30000);
		ms = ms - 30000;
	}
	if (ms > 0) {
		Platform_sleep(ms);
	}
}

void Platform_GetTimeOfDay (int32 *sec, int32 *usec)
{
	Platform_getLocalTime();
	Platform_stToFt();
	Platform_ftToUli();
	Platform_tous1970();
	*sec = Platform_ulSec();
	*usec = Platform_uluSec();
}

int16 Platform_System (CHAR *cmd, LONGINT cmd__len)
{
	int16 _o_result;
	int16 result;
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

int16 Platform_Error (void)
{
	int16 _o_result;
	_o_result = Platform_err();
	return _o_result;
}

int16 Platform_OldRO (CHAR *n, LONGINT n__len, int32 *h)
{
	int16 _o_result;
	int32 fd;
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

int16 Platform_OldRW (CHAR *n, LONGINT n__len, int32 *h)
{
	int16 _o_result;
	int32 fd;
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

int16 Platform_New (CHAR *n, LONGINT n__len, int32 *h)
{
	int16 _o_result;
	int32 fd;
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

int16 Platform_Close (int32 h)
{
	int16 _o_result;
	if (Platform_closeHandle(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_Identify (int32 h, Platform_FileIdentity *identity, address *identity__typ)
{
	int16 _o_result;
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

int16 Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, address *identity__typ)
{
	int16 _o_result;
	int32 h;
	int16 e, i;
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

void Platform_SetMTime (Platform_FileIdentity *target, address *target__typ, Platform_FileIdentity source)
{
	(*target).mtimehigh = source.mtimehigh;
	(*target).mtimelow = source.mtimelow;
}

void Platform_MTimeAsClock (Platform_FileIdentity i, int32 *t, int32 *d)
{
	Platform_identityToFileTime(i);
	Platform_fileTimeToSysTime();
	Platform_YMDHMStoClock(Platform_styear(), Platform_stmon(), Platform_stmday(), Platform_sthour(), Platform_stmin(), Platform_stsec(), &*t, &*d);
}

int16 Platform_Size (int32 h, int32 *l)
{
	int16 _o_result;
	Platform_largeInteger();
	if (Platform_getFileSize(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	*l = Platform_liLongint();
	_o_result = 0;
	return _o_result;
}

int16 Platform_Read (int32 h, int32 p, int32 l, int32 *n)
{
	int16 _o_result;
	int16 result;
	int32 lengthread;
	result = Platform_readfile(h, p, l, &lengthread);
	if (result == 0) {
		*n = 0;
		_o_result = Platform_err();
		return _o_result;
	} else {
		*n = lengthread;
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_ReadBuf (int32 h, SYSTEM_BYTE *b, LONGINT b__len, int32 *n)
{
	int16 _o_result;
	int16 result;
	int32 lengthread;
	result = Platform_readfile(h, (address)b, b__len, &lengthread);
	if (result == 0) {
		*n = 0;
		_o_result = Platform_err();
		return _o_result;
	} else {
		*n = lengthread;
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_Write (int32 h, int32 p, int32 l)
{
	int16 _o_result;
	if (Platform_writefile(h, p, l) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_Sync (int32 h)
{
	int16 _o_result;
	if (Platform_flushFileBuffers(h) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_Seek (int32 h, int32 o, int16 r)
{
	int16 _o_result;
	int16 rc;
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

int16 Platform_Truncate (int32 h, int32 limit)
{
	int16 _o_result;
	int16 rc;
	int32 oldpos;
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

int16 Platform_Unlink (CHAR *n, LONGINT n__len)
{
	int16 _o_result;
	if (Platform_deleteFile(n, n__len) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

int16 Platform_Chdir (CHAR *n, LONGINT n__len)
{
	int16 _o_result;
	int16 r;
	r = Platform_setCurrentDirectory(n, n__len);
	if (r == 0) {
		_o_result = Platform_err();
		return _o_result;
	}
	Platform_getCurrentDirectory((void*)Platform_CWD, 4096);
	_o_result = 0;
	return _o_result;
}

int16 Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len)
{
	int16 _o_result;
	if (Platform_moveFile(o, o__len, n, n__len) == 0) {
		_o_result = Platform_err();
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

void Platform_Exit (int16 code)
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

static void Platform_errposint (int32 l)
{
	if (l > 10) {
		Platform_errposint(__DIV(l, 10));
	}
	Platform_errch((CHAR)(48 + (int)__MOD(l, 10)));
}

static void Platform_errint (int32 l)
{
	if (l < 0) {
		Platform_errch('-');
		l = -l;
	}
	Platform_errposint(l);
}

static void Platform_DisplayHaltCode (int32 code)
{
	switch (code) {
		case -1: 
			Platform_errstring((CHAR*)"Rider ReadBuf/WriteBuf transfer size longer than buffer.", 57);
			break;
		case -2: 
			Platform_errstring((CHAR*)"Index out of range.", 20);
			break;
		case -3: 
			Platform_errstring((CHAR*)"Reached end of function without reaching RETURN.", 49);
			break;
		case -4: 
			Platform_errstring((CHAR*)"CASE statement: no matching label and no ELSE.", 47);
			break;
		case -5: 
			Platform_errstring((CHAR*)"Type guard failed.", 19);
			break;
		case -6: 
			Platform_errstring((CHAR*)"Type equality failed.", 22);
			break;
		case -7: 
			Platform_errstring((CHAR*)"WITH statement type guard failed.", 34);
			break;
		case -8: 
			Platform_errstring((CHAR*)"SHORT: Value too large for shorter type.", 41);
			break;
		case -9: 
			Platform_errstring((CHAR*)"Heap interrupted while locked, but lockdepth = 0 at unlock.", 60);
			break;
		case -10: 
			Platform_errstring((CHAR*)"NIL access.", 12);
			break;
		case -11: 
			Platform_errstring((CHAR*)"Alignment error.", 17);
			break;
		case -12: 
			Platform_errstring((CHAR*)"Divide by zero.", 16);
			break;
		case -13: 
			Platform_errstring((CHAR*)"Arithmetic overflow/underflow.", 31);
			break;
		case -14: 
			Platform_errstring((CHAR*)"Invalid function argument.", 27);
			break;
		case -15: 
			Platform_errstring((CHAR*)"Internal error, e.g. Type descriptor size mismatch.", 52);
			break;
		case -20: 
			Platform_errstring((CHAR*)"Too many, or negative number of, elements in dynamic array.", 60);
			break;
		default: 
			break;
	}
}

void Platform_Halt (int32 code)
{
	Platform_HaltCode = code;
	if (Platform_HaltHandler != NIL) {
		(*Platform_HaltHandler)(code);
	}
	Platform_errstring((CHAR*)"Terminated by Halt(", 20);
	Platform_errint(code);
	Platform_errstring((CHAR*)"). ", 4);
	if (code < 0) {
		Platform_DisplayHaltCode(code);
	}
	Platform_errln();
	Platform_exit(__VAL(int16, code));
}

void Platform_AssertFail (int32 code)
{
	Platform_errstring((CHAR*)"Assertion failure.", 19);
	if (code != 0) {
		Platform_errstring((CHAR*)" ASSERT code ", 14);
		Platform_errint(code);
		Platform_errstring((CHAR*)".", 2);
	}
	Platform_errln();
	Platform_exit(__VAL(int16, code));
}

void Platform_SetHalt (Platform_HaltProcedure p)
{
	Platform_HaltHandler = p;
}

static void Platform_TestLittleEndian (void)
{
	int16 i;
	i = 1;
	__GET((address)&i, Platform_LittleEndian, BOOLEAN);
}

__TDESC(Platform_FileIdentity, 1, 0) = {__TDFLDS("FileIdentity", 20), {-4}};

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
	Platform_getCurrentDirectory((void*)Platform_CWD, 4096);
	Platform_PID = Platform_getpid();
	Platform_SeekSet = Platform_seekset();
	Platform_SeekCur = Platform_seekcur();
	Platform_SeekEnd = Platform_seekend();
	Platform_StdIn = Platform_getstdinhandle();
	Platform_StdOut = Platform_getstdouthandle();
	Platform_StdErr = Platform_getstderrhandle();
	Platform_NL[0] = 0x0d;
	Platform_NL[1] = 0x0a;
	Platform_NL[2] = 0x00;
	__ENDMOD;
}
