MODULE TestTerminalNative;
  IMPORT SYSTEM, Platform, PlatformNative, Out;
  VAR master: SYSTEM.INT32; original: Platform.TerminalState;

  PROCEDURE -A0Feature '#ifndef _XOPEN_SOURCE';
  PROCEDURE -A0Feature1 '#define _XOPEN_SOURCE 700';
  PROCEDURE -A0Feature2 '#endif';
  (* Expose host terminal extensions so PENDIN can be identified by name.
     NetBSD uses _NETBSD_SOURCE; glibc uses _DEFAULT_SOURCE. *)
  PROCEDURE -A0Native '#ifndef _DEFAULT_SOURCE';
  PROCEDURE -A0Native1 '#define _DEFAULT_SOURCE 1';
  PROCEDURE -A0Native2 '#endif';
  PROCEDURE -A0Native3 '#ifndef _NETBSD_SOURCE';
  PROCEDURE -A0Native4 '#define _NETBSD_SOURCE 1';
  PROCEDURE -A0Native5 '#endif';
  PROCEDURE -AInclude '#include <fcntl.h>';
  PROCEDURE -AInclude1 '#include <stdlib.h>';
  PROCEDURE -AInclude2 '#include <unistd.h>';
  PROCEDURE -AInclude3 '#include <sys/ioctl.h>';
  PROCEDURE -AInclude4 '#ifdef __TINYC__';
  PROCEDURE -AInclude5 '#include_next <termios.h>';
  PROCEDURE -AInclude6 '#else';
  PROCEDURE -AInclude7 '#include <termios.h>';
  PROCEDURE -AInclude8 '#endif';
  PROCEDURE -AStatus '#ifndef PENDIN';
  PROCEDURE -AStatus1 '#define PENDIN 0';
  PROCEDURE -AStatus2 '#endif';
  PROCEDURE -openMaster(): SYSTEM.INT32 'posix_openpt(O_RDWR | O_NOCTTY)';
  PROCEDURE -grant(fd: SYSTEM.INT32): SYSTEM.INT32 'grantpt(fd)';
  PROCEDURE -unlock(fd: SYSTEM.INT32): SYSTEM.INT32 'unlockpt(fd)';
  PROCEDURE -slaveName(fd: SYSTEM.INT32): SYSTEM.ADDRESS '(ADDRESS)ptsname(fd)';
  PROCEDURE -openSlave(name: SYSTEM.ADDRESS): SYSTEM.INT32 'open((char*)name, O_RDWR | O_NOCTTY)';
  PROCEDURE -close(fd: SYSTEM.INT32) 'close(fd)';
  PROCEDURE -outputFlags(state: SYSTEM.ADDRESS): SYSTEM.SET64 '(UINT64)((struct termios*)state)->c_oflag';
  PROCEDURE -controlFlags(state: SYSTEM.ADDRESS): SYSTEM.SET64 '(UINT64)((struct termios*)state)->c_cflag';
  PROCEDURE -inputSpeed(state: SYSTEM.ADDRESS): SYSTEM.INT64 '(INT64)cfgetispeed((struct termios*)state)';
  PROCEDURE -outputSpeed(state: SYSTEM.ADDRESS): SYSTEM.INT64 '(INT64)cfgetospeed((struct termios*)state)';
  PROCEDURE -control(state: SYSTEM.ADDRESS; i: INTEGER): INTEGER '((struct termios*)state)->c_cc[i]';
  PROCEDURE -count(): INTEGER 'NCCS';
  PROCEDURE -localMask(): SYSTEM.SET64 '(UINT64)(ICANON | ECHO | ISIG | IEXTEN)';
  PROCEDURE -pendingMask(): SYSTEM.SET64 '(UINT64)PENDIN';
  PROCEDURE -inputMask(): SYSTEM.SET64 '(UINT64)(ICRNL | IXON)';
  PROCEDURE -windowBuffer 'struct winsize window = {0}';
  PROCEDURE -setDimensions(fd: SYSTEM.INT32): SYSTEM.INT32
    '(window.ws_row = 40000, window.ws_col = 65535, ioctl(fd, TIOCSWINSZ, &window))';

  PROCEDURE Open*(): SYSTEM.INT32;
    VAR slave: SYSTEM.INT32; name: SYSTEM.ADDRESS;
  BEGIN
    master := openMaster(); IF master < 0 THEN RETURN -1 END;
    slave := -1;
    IF (grant(master) = 0) & (unlock(master) = 0) THEN
      name := slaveName(master); IF name # 0 THEN slave := openSlave(name) END
    END;
    IF (slave < 0) OR (Platform.CaptureTerminalState(slave, original) # 0) THEN
      IF slave >= 0 THEN close(slave) END;
      close(master); master := -1; RETURN -1
    END;
    RETURN slave
  END Open;

  PROCEDURE Close*(fd: SYSTEM.INT32);
  BEGIN close(fd); close(master); master := -1; Platform.ReleaseTerminalState(original)
  END Close;

  PROCEDURE SameLocal(actual, expected: SYSTEM.SET64): BOOLEAN;
  BEGIN
    (* A canonical-mode transition may set PENDIN until the next read.
       Compare settings while allowing that kernel-managed status bit. *)
    RETURN actual - pendingMask() = expected - pendingMask()
  END SameLocal;

  PROCEDURE CheckLocalComparison;
    VAR flags: SYSTEM.SET64;
  BEGIN
    flags := localMask();
    ASSERT(SameLocal(flags + pendingMask(), flags));
    ASSERT(SameLocal(flags, flags + pendingMask()));
    ASSERT(~SameLocal(flags, flags - localMask()))
  END CheckLocalComparison;

  PROCEDURE Settings*(fd, raw, timed: SYSTEM.INT32): BOOLEAN;
    VAR actual: Platform.TerminalState; local, input: SYSTEM.SET64;
      i, expected: INTEGER; valid: BOOLEAN;
  BEGIN
    IF Platform.CaptureTerminalState(fd, actual) # 0 THEN RETURN FALSE END;
    local := PlatformNative.LocalFlags(original); input := PlatformNative.InputFlags(original);
    IF raw # 0 THEN local := local - localMask(); input := input - inputMask() END;
    valid := SameLocal(PlatformNative.LocalFlags(actual), local) & (PlatformNative.InputFlags(actual) = input) &
      (outputFlags(actual) = outputFlags(original)) & (controlFlags(actual) = controlFlags(original)) &
      (inputSpeed(actual) = inputSpeed(original)) & (outputSpeed(actual) = outputSpeed(original));
    i := 0;
    WHILE (i < count()) & valid DO
      expected := control(original, i);
      IF raw # 0 THEN
        IF i = PlatformNative.MinIndex() THEN IF timed # 0 THEN expected := 0 ELSE expected := 1 END
        ELSIF i = PlatformNative.TimeIndex() THEN IF timed # 0 THEN expected := 1 ELSE expected := 0 END
        END
      END;
      valid := control(actual, i) = expected;
      IF ~valid THEN
        Out.String("terminal control character "); Out.Int(i, 0);
        Out.String(": actual "); Out.Int(control(actual, i), 0);
        Out.String(", expected "); Out.Int(expected, 0); Out.Ln
      END;
      INC(i)
    END;
    IF ~valid THEN
      Out.String("terminal local flags: actual ");
      Out.HexDigits(SYSTEM.VAL(SYSTEM.INT64, PlatformNative.LocalFlags(actual)), 0);
      Out.String(", expected "); Out.HexDigits(SYSTEM.VAL(SYSTEM.INT64, local), 0); Out.Ln;
      Out.String("terminal input flags: actual ");
      Out.HexDigits(SYSTEM.VAL(SYSTEM.INT64, PlatformNative.InputFlags(actual)), 0);
      Out.String(", expected "); Out.HexDigits(SYSTEM.VAL(SYSTEM.INT64, input), 0); Out.Ln
    END;
    Platform.ReleaseTerminalState(actual); RETURN valid
  END Settings;

  PROCEDURE Dimensions*(fd: SYSTEM.INT32): SYSTEM.INT32;
  BEGIN windowBuffer; RETURN setDimensions(fd) END Dimensions;

BEGIN master := -1; CheckLocalComparison
END TestTerminalNative.
