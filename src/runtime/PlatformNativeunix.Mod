MODULE PlatformNative;

(* Native Unix types stay opaque. This module only calls libc or accesses its
   fields and constants; Platform owns allocation, iteration and error policy. *)
IMPORT SYSTEM;

PROCEDURE -A0Feature '#ifndef _POSIX_C_SOURCE';
PROCEDURE -A0Feature1 '#define _POSIX_C_SOURCE 200809L';
PROCEDURE -A0Feature2 '#endif';
PROCEDURE -AInclude '#include <dirent.h>';
PROCEDURE -AInclude1 '#include <errno.h>';
PROCEDURE -AInclude2 '#include <limits.h>';
PROCEDURE -AInclude3 '#include <sys/stat.h>';
PROCEDURE -AInclude4 '#include <sys/ioctl.h>';
(* TCC searches -I directories for angle includes too. *)
PROCEDURE -AInclude5 '#ifdef __TINYC__';
PROCEDURE -AInclude6 '#include_next <termios.h>';
PROCEDURE -AInclude7 '#else';
PROCEDURE -AInclude8 '#include <termios.h>';
PROCEDURE -AInclude9 '#endif';
PROCEDURE -AIncludeTime '#include <time.h>';

PROCEDURE -error(): SYSTEM.INT32 'errno';
PROCEDURE Error*(): SYSTEM.INT32;
BEGIN RETURN error() END Error;
PROCEDURE -clearError 'errno = 0';
PROCEDURE ClearError*;
BEGIN clearError END ClearError;
PROCEDURE -nameTooLong(): SYSTEM.INT32 'ENAMETOOLONG';
PROCEDURE NameTooLong*(): SYSTEM.INT32;
BEGIN RETURN nameTooLong() END NameTooLong;
PROCEDURE -noMemory(): SYSTEM.INT32 'ENOMEM';
PROCEDURE NoMemory*(): SYSTEM.INT32;
BEGIN RETURN noMemory() END NoMemory;
PROCEDURE -badFD(): SYSTEM.INT32 'EBADF';
PROCEDURE BadFD*(): SYSTEM.INT32;
BEGIN RETURN badFD() END BadFD;
PROCEDURE -overflow(): SYSTEM.INT32 'EOVERFLOW';
PROCEDURE Overflow*(): SYSTEM.INT32;
BEGIN RETURN overflow() END Overflow;

(* Convert the value, never reinterpret an Oberon LONGINT as time_t: their
   sizes can differ. Keep both libc structures in this native stack frame. *)
PROCEDURE -timeBuffer 'time_t value; struct tm local';
PROCEDURE -setTime(seconds: SYSTEM.INT64) 'value = (time_t)seconds';
PROCEDURE -timeFits(seconds: SYSTEM.INT64): BOOLEAN '((INT64)value == seconds)';
PROCEDURE -localTime(): BOOLEAN '(localtime_r(&value, &local) != NULL)';
PROCEDURE -year(): LONGINT 'local.tm_year';
PROCEDURE -month(): LONGINT 'local.tm_mon';
PROCEDURE -day(): LONGINT 'local.tm_mday';
PROCEDURE -hour(): LONGINT 'local.tm_hour';
PROCEDURE -minute(): LONGINT 'local.tm_min';
PROCEDURE -second(): LONGINT 'local.tm_sec';

(* year and month retain struct tm's origins: 1900 and zero, respectively.
   Outputs are unchanged when time_t cannot represent seconds or libc fails. *)
PROCEDURE LocalTime*(seconds: SYSTEM.INT64;
                     VAR ye, mo, da, ho, mi, se: LONGINT): BOOLEAN;
BEGIN
  timeBuffer; setTime(seconds);
  IF ~timeFits(seconds) OR ~localTime() THEN RETURN FALSE END;
  ye := year(); mo := month(); da := day();
  ho := hour(); mi := minute(); se := second(); RETURN TRUE
END LocalTime;

PROCEDURE -openDirectory(path: ARRAY OF CHAR): SYSTEM.ADDRESS '(ADDRESS)opendir((char*)path)';
PROCEDURE OpenDirectory*(path: ARRAY OF CHAR): SYSTEM.ADDRESS;
BEGIN RETURN openDirectory(path) END OpenDirectory;
PROCEDURE -readDirectory(handle: SYSTEM.ADDRESS): SYSTEM.ADDRESS '(ADDRESS)readdir((DIR*)handle)';
PROCEDURE ReadDirectory*(handle: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
BEGIN RETURN readDirectory(handle) END ReadDirectory;
PROCEDURE -entryName(entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS '(ADDRESS)((struct dirent*)entry)->d_name';
PROCEDURE EntryName*(entry: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
BEGIN RETURN entryName(entry) END EntryName;
PROCEDURE -closeDirectory(handle: SYSTEM.ADDRESS): SYSTEM.INT32 'closedir((DIR*)handle)';
PROCEDURE CloseDirectory*(handle: SYSTEM.ADDRESS): SYSTEM.INT32;
BEGIN RETURN closeDirectory(handle) END CloseDirectory;

PROCEDURE -statBuffer 'struct stat info';
PROCEDURE -stat(path: ARRAY OF CHAR): SYSTEM.INT32 'stat((char*)path, &info)';
PROCEDURE -lstat(path: ARRAY OF CHAR): SYSTEM.INT32 'lstat((char*)path, &info)';
PROCEDURE -isDirectory(): BOOLEAN 'S_ISDIR(info.st_mode)';
PROCEDURE -isRegular(): BOOLEAN 'S_ISREG(info.st_mode)';
(* kind: 1 directory, 2 regular file, 0 any other kind, including symlinks
   when follow is FALSE. The return value is an errno value, or zero. *)
PROCEDURE PathKind*(path: ARRAY OF CHAR; follow: BOOLEAN; VAR kind: INTEGER): SYSTEM.INT32;
  VAR result: SYSTEM.INT32;
BEGIN
  statBuffer; kind := 0;
  IF follow THEN result := stat(path) ELSE result := lstat(path) END;
  IF result < 0 THEN RETURN error() END;
  IF isDirectory() THEN kind := 1 ELSIF isRegular() THEN kind := 2 END;
  RETURN 0
END PathKind;
PROCEDURE -mkdir(path: ARRAY OF CHAR): SYSTEM.INT32 'mkdir((char*)path, 0777)';
PROCEDURE MakeDirectory*(path: ARRAY OF CHAR): SYSTEM.INT32;
BEGIN IF mkdir(path) < 0 THEN RETURN error() ELSE RETURN 0 END
END MakeDirectory;

PROCEDURE -terminalSize(): SYSTEM.ADDRESS 'sizeof(struct termios)';
PROCEDURE TerminalSize*(): SYSTEM.ADDRESS;
BEGIN RETURN terminalSize() END TerminalSize;
PROCEDURE -getTerminal(fd: SYSTEM.INT32; state: SYSTEM.ADDRESS): SYSTEM.INT32
  'tcgetattr(fd, (struct termios*)state)';
PROCEDURE GetTerminal*(fd: SYSTEM.INT32; state: SYSTEM.ADDRESS): SYSTEM.INT32;
BEGIN RETURN getTerminal(fd, state) END GetTerminal;
PROCEDURE -setTerminal(fd: SYSTEM.INT32; state: SYSTEM.ADDRESS): SYSTEM.INT32
  'tcsetattr(fd, TCSANOW, (const struct termios*)state)';
PROCEDURE SetTerminal*(fd: SYSTEM.INT32; state: SYSTEM.ADDRESS): SYSTEM.INT32;
BEGIN RETURN setTerminal(fd, state) END SetTerminal;
PROCEDURE -localFlags(state: SYSTEM.ADDRESS): SYSTEM.SET64 '(UINT64)((struct termios*)state)->c_lflag';
PROCEDURE LocalFlags*(state: SYSTEM.ADDRESS): SYSTEM.SET64;
BEGIN RETURN localFlags(state) END LocalFlags;
PROCEDURE -inputFlags(state: SYSTEM.ADDRESS): SYSTEM.SET64 '(UINT64)((struct termios*)state)->c_iflag';
PROCEDURE InputFlags*(state: SYSTEM.ADDRESS): SYSTEM.SET64;
BEGIN RETURN inputFlags(state) END InputFlags;
PROCEDURE -setLocalFlags(state: SYSTEM.ADDRESS; flags: SYSTEM.SET64)
  '((struct termios*)state)->c_lflag = (tcflag_t)flags';
PROCEDURE SetLocalFlags*(state: SYSTEM.ADDRESS; flags: SYSTEM.SET64);
BEGIN setLocalFlags(state, flags) END SetLocalFlags;
PROCEDURE -setInputFlags(state: SYSTEM.ADDRESS; flags: SYSTEM.SET64)
  '((struct termios*)state)->c_iflag = (tcflag_t)flags';
PROCEDURE SetInputFlags*(state: SYSTEM.ADDRESS; flags: SYSTEM.SET64);
BEGIN setInputFlags(state, flags) END SetInputFlags;
PROCEDURE -localRawMask(): SYSTEM.SET64 '(UINT64)(ICANON | ECHO | ISIG | IEXTEN)';
PROCEDURE LocalRawMask*(): SYSTEM.SET64;
BEGIN RETURN localRawMask() END LocalRawMask;
PROCEDURE -inputRawMask(): SYSTEM.SET64 '(UINT64)(ICRNL | IXON)';
PROCEDURE InputRawMask*(): SYSTEM.SET64;
BEGIN RETURN inputRawMask() END InputRawMask;
PROCEDURE -minIndex(): SYSTEM.INT32 'VMIN';
PROCEDURE MinIndex*(): SYSTEM.INT32;
BEGIN RETURN minIndex() END MinIndex;
PROCEDURE -timeIndex(): SYSTEM.INT32 'VTIME';
PROCEDURE TimeIndex*(): SYSTEM.INT32;
BEGIN RETURN timeIndex() END TimeIndex;
PROCEDURE -setControl(state: SYSTEM.ADDRESS; index, value: SYSTEM.INT32)
  '((struct termios*)state)->c_cc[index] = (cc_t)value';
PROCEDURE SetControl*(state: SYSTEM.ADDRESS; index, value: SYSTEM.INT32);
BEGIN setControl(state, index, value) END SetControl;

PROCEDURE -windowBuffer 'struct winsize window';
PROCEDURE -getWindow(fd: SYSTEM.INT32): SYSTEM.INT32 'ioctl(fd, TIOCGWINSZ, &window)';
PROCEDURE -rows(): SYSTEM.INT32 'window.ws_row';
PROCEDURE -columns(): SYSTEM.INT32 'window.ws_col';
PROCEDURE WindowSize*(fd: SYSTEM.INT32; VAR lines, cols: SYSTEM.INT32): SYSTEM.INT32;
BEGIN
  windowBuffer;
  IF getWindow(fd) < 0 THEN RETURN error() END;
  lines := rows(); cols := columns(); RETURN 0
END WindowSize;

END PlatformNative.
