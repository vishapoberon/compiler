MODULE OakFiles;  (* J. Templ 1.12. 89/12.4.95 Oberon files mapped onto Unix files *)
(* modified version of Files, which opens only the file provided and does not scan any path in any environment variable, also ReadLine procedure added; -- noch *)
  IMPORT SYSTEM, Unix, Kernel, Args, Console;

  (* standard data type I/O 

    little endian,
    Sint:1, Int:2, Lint:4
    ORD({0}) = 1,
    false = 0, true =1
    IEEE real format,
    null terminated strings,
    compact numbers according to M.Odersky *)


  CONST
    nofbufs = 4;
    bufsize = 4096;
    fileTabSize = 64;
    noDesc = -1;
    notDone = -1;

    (* file states *)
    open = 0; create = 1; close = 2;


  TYPE
    FileName = ARRAY 101 OF CHAR;
    File* = POINTER TO Handle;
    Buffer = POINTER TO BufDesc;

    Handle = RECORD
      workName, registerName: FileName;
      tempFile: BOOLEAN;
      dev, ino, mtime: LONGINT;
      fd-, len, pos: LONGINT;
      bufs: ARRAY nofbufs OF Buffer;
      swapper, state: INTEGER
    END ;

    BufDesc = RECORD
      f: File;
      chg: BOOLEAN;
      org, size: LONGINT;
      data: ARRAY bufsize OF SYSTEM.BYTE
    END ;

    Rider* = RECORD 
      res*: LONGINT;
      eof*: BOOLEAN;
      buf: Buffer;
      org, offset: LONGINT
    END ;

    Time = POINTER TO TimeDesc;
    TimeDesc = RECORD
      sec*, min*, hour*, mday*, mon*, year*, wday*, isdst*, zone*, gmtoff*: LONGINT;
(*      sec*, min*, hour*, mday*, mon*, year*, wday*, isdst*, zone*, gmtoff*: INTEGER;*)
    END ;

  VAR
    fileTab: ARRAY fileTabSize OF LONGINT (*=File*);
    tempno: INTEGER;

(* for localtime *)
  PROCEDURE -includetime()
      '#include "time.h"';

  PROCEDURE -localtime(VAR clock: LONGINT): Time
    "(OakFiles_Time) localtime(clock)";

  PROCEDURE -getcwd(VAR cwd: Unix.Name)
    "getcwd(cwd, cwd__len)";

  PROCEDURE -IdxTrap "__HALT(-1)";

  PROCEDURE^ Finalize(o: SYSTEM.PTR);

  PROCEDURE Err(s: ARRAY OF CHAR; f: File; errno: LONGINT);
  BEGIN
    Console.Ln; Console.String("-- "); Console.String(s); Console.String(": "); 
    IF f # NIL THEN
      IF f.registerName # "" THEN Console.String(f.registerName) ELSE Console.String(f.workName) END
    END ;
    IF errno # 0 THEN Console.String(" errno = "); Console.Int(errno, 1) END ;
    Console.Ln;
    HALT(99)
  END Err;

  PROCEDURE MakeFileName(dir, name: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;
    WHILE dir[i] # 0X DO dest[i] := dir[i]; INC(i) END ;
    IF dest[i-1] # "/" THEN dest[i] := "/"; INC(i) END ;
    WHILE name[j] # 0X DO dest[i] := name[j]; INC(i); INC(j) END ;
    dest[i] := 0X
  END MakeFileName;

  PROCEDURE GetTempName(finalName: ARRAY OF CHAR; VAR name: ARRAY OF CHAR);
    VAR n, i, j: LONGINT;
  BEGIN
    INC(tempno); n := tempno; i := 0;
    IF finalName[0] # "/" THEN  (* relative pathname *)
      WHILE Kernel.CWD[i] # 0X DO name[i] := Kernel.CWD[i]; INC(i) END;
      IF Kernel.CWD[i-1] # "/" THEN name[i] := "/"; INC(i) END
    END;
    j := 0;
    WHILE finalName[j] # 0X DO name[i] := finalName[j]; INC(i); INC(j) END;
    DEC(i);
    WHILE name[i] # "/" DO DEC(i) END;
    name[i+1] := "."; name[i+2] := "t"; name[i+3] := "m"; name[i+4] := "p"; name[i+5] := "."; INC(i, 6);
    WHILE n > 0 DO name[i] := CHR(n MOD 10 + ORD("0")); n := n DIV 10; INC(i) END;
    name[i] := "."; INC(i); n := SHORT(Unix.Getpid());
    WHILE n > 0 DO name[i] := CHR(n MOD 10 + ORD("0"));  n := n DIV 10; INC(i) END;
    name[i] := 0X
  END GetTempName;

  PROCEDURE Create(f: File);
    VAR stat: Unix.Status; done: BOOLEAN;
      errno: LONGINT; err: ARRAY 32 OF CHAR;
  BEGIN
    IF f.fd = noDesc THEN
      IF f.state = create THEN GetTempName(f.registerName, f.workName); f.tempFile := TRUE
      ELSIF f.state = close THEN
        f.workName := f.registerName; f.registerName := ""; f.tempFile := FALSE
      END ;
      errno := Unix.Unlink(f.workName);  (*unlink first to avoid stale NFS handles and to avoid reuse of inodes*)
      f.fd := Unix.Open(f.workName, Unix.rdwr + Unix.creat + Unix.trunc, {2, 4,5, 7,8});
      done := f.fd >= 0; errno := Unix.errno();
      IF (~done & ((errno = Unix.ENFILE) OR (errno = Unix.EMFILE))) OR (done & (f.fd >= fileTabSize)) THEN
        IF done & (f.fd >= fileTabSize) THEN errno := Unix.Close(f.fd) END ;
        Kernel.GC(TRUE);
        f.fd := Unix.Open(f.workName, Unix.rdwr + Unix.creat + Unix.trunc, {2, 4,5, 7,8});
        done := f.fd >= 0
      END ;
      IF done THEN
        IF f.fd >= fileTabSize THEN errno := Unix.Close(f.fd); Err("too many files open", f, 0)
        ELSE fileTab[f.fd] := SYSTEM.VAL(LONGINT, f); INC(Kernel.nofiles); Kernel.RegisterObject(f, Finalize);
          f.state := open; f.pos := 0; errno := Unix.Fstat(f.fd, stat);
          f.dev := stat.dev; f.ino := stat.ino; f.mtime := stat.mtime
        END
      ELSE errno := Unix.errno();
        IF errno = Unix.ENOENT THEN err := "no such directory"
        ELSIF (errno = Unix.ENFILE) OR (errno = Unix.EMFILE) THEN err := "too many files open"
        ELSE err := "file not created"
        END ;
        Err(err, f, errno)
      END
    END
  END Create;

  PROCEDURE Flush(buf: Buffer);
    VAR res: LONGINT; f: File; stat: Unix.Status;
  BEGIN
    IF buf.chg THEN f := buf.f; Create(f);
      IF buf.org # f.pos THEN res := Unix.Lseek(f.fd, buf.org, 0) END ;
      res := Unix.Write(f.fd, SYSTEM.ADR(buf.data), buf.size);
      IF res < 0 THEN Err("error in writing file", f, Unix.errno()) END ;
      f.pos := buf.org + buf.size;
      buf.chg := FALSE;
      res := Unix.Fstat(f.fd, stat);
      f.mtime := stat.mtime
    END
  END Flush;

  PROCEDURE Close* (f: File);
    VAR i, res: LONGINT;
  BEGIN
    IF (f.state # create) OR (f.registerName # "") THEN
      Create(f); i := 0;
      WHILE (i < nofbufs) & (f.bufs[i] # NIL) DO Flush(f.bufs[i]); INC(i) END ;
      res := Unix.Fsync(f.fd);
      IF res < 0 THEN Err("error in writing file", f, Unix.errno()) END
    END
  END Close;

  PROCEDURE Length* (f: File): LONGINT;
  BEGIN RETURN f.len
  END Length;

  PROCEDURE New* (name: ARRAY OF CHAR): File;
    VAR f: File;
  BEGIN
    NEW(f); f.workName := ""; COPY(name, f.registerName);
    f.fd := noDesc; f.state := create; f.len := 0; f.pos := 0; f.swapper := -1; (*all f.buf[i] = NIL*)
    RETURN f
  END New;
(*
  PROCEDURE ScanPath(VAR pos: INTEGER; VAR dir: ARRAY OF CHAR);  (* supports ~, ~user and blanks inside path *)
    VAR i: INTEGER; ch: CHAR; home: ARRAY 256 OF CHAR;
  BEGIN
    i := 0; ch := Kernel.OBERON[pos];
    WHILE (ch = " ") OR (ch = ":") DO INC(pos); ch := Kernel.OBERON[pos] END ;
    IF ch = "~" THEN
      INC(pos); ch := Kernel.OBERON[pos];
      home := ""; Args.GetEnv("HOME", home);
      WHILE home[i] # 0X DO dir[i] := home[i]; INC(i) END ;
      IF (ch # "/") & (ch # 0X) & (ch # ":") & (ch # " ") THEN
        WHILE (i > 0) & (dir[i-1] # "/") DO DEC(i) END
      END
    END ;
    WHILE (ch # 0X) & (ch # ":") DO dir[i] := ch; INC(i); INC(pos); ch := Kernel.OBERON[pos] END ;
    WHILE (i > 0) & (dir[i-1] = " ") DO DEC(i) END ;
    dir[i] := 0X
  END ScanPath;
*)
  PROCEDURE HasDir(VAR name: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0; ch := name[0];
    WHILE (ch # 0X) & (ch # "/") DO INC(i); ch := name[i] END ;
    RETURN ch = "/"
  END HasDir;

  PROCEDURE CacheEntry(dev, ino: LONGINT; mtime: LONGINT): File;
    VAR f: File; i: INTEGER; stat: Unix.Status; res: LONGINT;
  BEGIN i := 0;
    WHILE i < fileTabSize DO
      f := SYSTEM.VAL(File, fileTab[i]);
      IF (f # NIL) & (ino = f.ino) & (dev = f.dev) THEN 
        IF mtime # f.mtime THEN i := 0;
          WHILE i < nofbufs DO
            IF f.bufs[i] # NIL THEN f.bufs[i].org := -1; f.bufs[i] := NIL END ;
            INC(i)
          END ;
          f.swapper := -1; f.mtime := mtime;
          res := Unix.Fstat(f.fd, stat); f.len := stat.size
        END ;
        RETURN f
      END ;
      INC(i)
    END ;
    RETURN NIL
  END CacheEntry;

  PROCEDURE Old* (name: ARRAY OF CHAR): File;
    VAR f: File; fd, res, errno: LONGINT; pos: INTEGER; done: BOOLEAN;
      dir, path: ARRAY 256 OF CHAR;
      stat: Unix.Status;
  BEGIN
    IF name # "" THEN
      IF HasDir(name) THEN dir := ""; COPY(name, path)
      ELSE 
         pos := 0;
	 COPY(name, path); (* -- noch *)
	 (*ScanPath(pos, dir);*) (*MakeFileName(dir, name, path);*) (*ScanPath(pos, dir)*)
      END ;
      LOOP
        fd := Unix.Open(path, Unix.rdwr, {}); done := fd >= 0; errno := Unix.errno();
        IF (~done & ((errno = Unix.ENFILE) OR (errno = Unix.EMFILE))) OR (done & (fd >= fileTabSize)) THEN
          IF done & (fd >= fileTabSize) THEN res := Unix.Close(fd) END ;
          Kernel.GC(TRUE);
          fd := Unix.Open(path, Unix.rdwr, {});
          done := fd >= 0; errno := Unix.errno();
          IF ~done & ((errno = Unix.ENFILE) OR (errno = Unix.EMFILE)) THEN Err("too many files open", f, errno) END
        END ;
        IF ~done & ((errno = Unix.EACCES) OR (errno = Unix.EROFS) OR (errno = Unix.EAGAIN)) THEN
          (* errno EAGAIN observed on Solaris 2.4 *)
          fd := Unix.Open(path, Unix.rdonly, {}); done :=  fd >= 0; errno := Unix.errno()
        END ;
IF (~done) & (errno # Unix.ENOENT) THEN 
  Console.String("warning Files.Old "); Console.String(name); 
  Console.String(" errno = "); Console.Int(errno, 0); Console.Ln;
END ;
        IF done THEN
          res := Unix.Fstat(fd, stat);
          f := CacheEntry(stat.dev, stat.ino, stat.mtime);
          IF f # NIL THEN res := Unix.Close(fd); RETURN f
          ELSIF fd >= fileTabSize THEN res := Unix.Close(fd); Err("too many files open", f, 0)
          ELSE NEW(f); fileTab[fd] := SYSTEM.VAL(LONGINT, f); INC(Kernel.nofiles); Kernel.RegisterObject(f, Finalize);
            f.fd := fd; f.state := open; f.len := stat.size; f.pos := 0; f.swapper := -1; (*all f.buf[i] = NIL*)
            COPY(name, f.workName); f.registerName := ""; f.tempFile := FALSE;
            f.dev := stat.dev; f.ino := stat.ino; f.mtime := stat.mtime;
            RETURN f
          END
        ELSIF dir = "" THEN RETURN NIL
        ELSE (*MakeFileName(dir, name, path);*) (*ScanPath(pos, dir)*)
	RETURN NIL
        END
      END
    ELSE RETURN NIL
    END
  END Old;

  PROCEDURE Purge* (f: File);
    VAR i: INTEGER; stat: Unix.Status; res: LONGINT;
  BEGIN i := 0;
    WHILE i < nofbufs DO
      IF f.bufs[i] # NIL THEN f.bufs[i].org := -1; f.bufs[i] := NIL END ;
      INC(i)
    END ;
    IF f.fd # noDesc THEN res := Unix.Ftruncate(f.fd, 0); res := Unix.Lseek(f.fd, 0, 0) END ;
    f.pos := 0; f.len := 0; f.swapper := -1;
    res := Unix.Fstat(f.fd, stat); f.mtime := stat.mtime
  END Purge;

  PROCEDURE GetDate* (f: File; VAR t, d: LONGINT);
    VAR stat: Unix.Status; clock, res: LONGINT; time: Time;
  BEGIN
    Create(f); res := Unix.Fstat(f.fd, stat);
    time := localtime(stat.mtime);
    t := time.sec + ASH(time.min, 6) + ASH(time.hour, 12);
    d := time.mday + ASH(time.mon+1, 5) + ASH(time.year MOD 100, 9)
  END GetDate;

  PROCEDURE Pos* (VAR r: Rider): LONGINT;
  BEGIN RETURN r.org + r.offset
  END Pos;

  PROCEDURE Set* (VAR r: Rider; f: File; pos: LONGINT);
    VAR org, offset, i, n, res: LONGINT; buf: Buffer;
  BEGIN
    IF f # NIL THEN
      IF pos > f.len THEN pos := f.len ELSIF pos < 0 THEN pos := 0 END ;
      offset := pos MOD bufsize; org := pos - offset; i := 0;
      WHILE (i < nofbufs) & (f.bufs[i] # NIL) & (org # f.bufs[i].org) DO INC(i) END ;
      IF i < nofbufs THEN
        IF f.bufs[i] = NIL THEN NEW(buf); buf.chg := FALSE; buf.org := -1; buf.f := f; f.bufs[i] := buf
        ELSE buf := f.bufs[i]
        END
      ELSE
        f.swapper := (f.swapper + 1) MOD nofbufs;
        buf := f.bufs[f.swapper];
        Flush(buf)
      END ;
      IF buf.org # org THEN
        IF org = f.len THEN buf.size := 0
        ELSE Create(f);
          IF f.pos # org THEN res := Unix.Lseek(f.fd, org, 0) END ;
          n := Unix.ReadBlk(f.fd, buf.data);
          IF n < 0 THEN Err("read from file not done", f, Unix.errno()) END ;
          f.pos := org + n;
          buf.size := n
        END ;
        buf.org := org; buf.chg := FALSE
      END
    ELSE buf := NIL; org := 0; offset := 0
    END ;
    r.buf := buf; r.org := org; r.offset := offset; r.eof := FALSE; r.res := 0
  END Set;

  PROCEDURE Read* (VAR r: Rider; VAR x: SYSTEM.BYTE);
    VAR offset: LONGINT; buf: Buffer;
  BEGIN
    buf := r.buf; offset := r.offset;
    IF r.org # buf.org THEN Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset END ;
    IF (offset < buf.size) THEN
      x := buf.data[offset]; r.offset := offset + 1
    ELSIF r.org + offset < buf.f.len THEN
      Set(r, r.buf.f, r.org + offset);
      x := r.buf.data[0]; r.offset := 1
    ELSE
      x := 0X; r.eof := TRUE 
    END
  END Read;

  PROCEDURE ReadBytes* (VAR r: Rider; VAR x: ARRAY OF SYSTEM.BYTE; n: LONGINT);
    VAR xpos, min, restInBuf, offset: LONGINT; buf: Buffer;
  BEGIN
    IF n > LEN(x) THEN IdxTrap END ;
    xpos := 0; buf := r.buf; offset := r.offset;
    WHILE n > 0 DO
      IF (r.org # buf.org) OR (offset >= bufsize) THEN
        Set(r, buf.f, r.org + offset);
        buf := r.buf; offset := r.offset
      END ;
      restInBuf := buf.size - offset; 
      IF restInBuf = 0 THEN r.res := n; r.eof := TRUE; RETURN
      ELSIF n > restInBuf THEN min := restInBuf ELSE min := n END ;
      SYSTEM.MOVE(SYSTEM.ADR(buf.data) + offset, SYSTEM.ADR(x) + xpos, min);
      INC(offset, min); r.offset := offset; INC(xpos, min); DEC(n, min)
    END ;
    r.res := 0; r.eof := FALSE
  END ReadBytes;

  PROCEDURE Base* (VAR r: Rider): File;
  BEGIN RETURN r.buf.f
  END Base;

  PROCEDURE Write* (VAR r: Rider; x: SYSTEM.BYTE);
    VAR buf: Buffer; offset: LONGINT;
  BEGIN
    buf := r.buf; offset := r.offset;
    IF (r.org # buf.org) OR (offset >= bufsize) THEN
      Set(r, buf.f, r.org + offset);
      buf := r.buf; offset := r.offset
    END ;
    buf.data[offset] := x;
    buf.chg := TRUE;
    IF offset = buf.size THEN
      INC(buf.size); INC(buf.f.len)
    END ;
    r.offset := offset + 1; r.res := 0
  END Write;

  PROCEDURE WriteBytes* (VAR r: Rider; VAR x: ARRAY OF SYSTEM.BYTE; n: LONGINT);
    VAR xpos, min, restInBuf, offset: LONGINT; buf: Buffer;
  BEGIN
    IF n > LEN(x) THEN IdxTrap END ;
    xpos := 0; buf := r.buf; offset := r.offset;
    WHILE n > 0 DO
      IF (r.org # buf.org) OR (offset >= bufsize) THEN
        Set(r, buf.f, r.org + offset);
        buf := r.buf; offset := r.offset
      END ;
      restInBuf := bufsize - offset;
      IF n > restInBuf THEN min := restInBuf ELSE min := n END ;
      SYSTEM.MOVE(SYSTEM.ADR(x) + xpos, SYSTEM.ADR(buf.data) + offset, min);
      INC(offset, min); r.offset := offset;
      IF offset > buf.size THEN INC(buf.f.len, offset - buf.size); buf.size := offset END ;
      INC(xpos, min); DEC(n, min); buf.chg := TRUE
    END ;
    r.res := 0
  END WriteBytes;

(* another solution would be one that is similar to ReadBytes, WriteBytes.
No code duplication, more symmetric, only two ifs for
Read and Write in buffer, buf.size replaced by bufsize in Write ops, buf.size and len
must be made consistent with offset (if offset > buf.size) in a lazy way.

PROCEDURE Write* (VAR r: Rider; x: SYSTEM.BYTE);
  VAR buf: Buffer; offset: LONGINT;
BEGIN
  buf := r.buf; offset := r.offset;
  IF (offset >= bufsize) OR (r.org # buf.org) THEN 
    Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset;
  END ;
  buf.data[offset] := x; r.offset := offset + 1; buf.chg := TRUE
END Write;

PROCEDURE WriteBytes ...

PROCEDURE Read* (VAR r: Rider; VAR x: SYSTEM.BYTE);
  VAR offset: LONGINT; buf: Buffer;
BEGIN
  buf := r.buf; offset := r.offset;
  IF (offset >= buf.size) OR (r.org # buf.org) THEN
    IF r.org + offset >= buf.f.len THEN x := 0X; r.eof := TRUE; RETURN
    ELSE Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset
    END
  END ;
  x := buf.data[offset]; r.offset := offset + 1
END Read;

but this would also affect Set, Length, and Flush.
Especially Length would become fairly complex.
*)

  PROCEDURE Delete* (name: ARRAY OF CHAR; VAR res: INTEGER);
  BEGIN
    res := SHORT(Unix.Unlink(name));
    res := SHORT(Unix.errno())
  END Delete;

  PROCEDURE Rename* (old, new: ARRAY OF CHAR; VAR res: INTEGER);
    VAR fdold, fdnew, n, errno, r: LONGINT;
      ostat, nstat: Unix.Status;
      buf: ARRAY 4096 OF CHAR;
  BEGIN
    r := Unix.Stat(old, ostat);
    IF r >= 0 THEN
      r := Unix.Stat(new, nstat);
      IF (r >= 0) & ((ostat.dev # nstat.dev) OR (ostat.ino # nstat.ino)) THEN
        Delete(new, res);  (* work around stale nfs handles *)
      END ;
      r := Unix.Rename(old, new);
      IF r < 0 THEN res := SHORT(Unix.errno());
        IF res = Unix.EXDEV THEN (* cross device link, move the file *)
          fdold := Unix.Open(old, Unix.rdonly, {});
          IF fdold < 0 THEN res := 2; RETURN END ;
          fdnew := Unix.Open(new, Unix.rdwr + Unix.creat + Unix.trunc, {2,  4,5,  7,8});
          IF fdnew < 0 THEN r := Unix.Close(fdold); res := 3; RETURN END ;
          n := Unix.Read(fdold, SYSTEM.ADR(buf), bufsize);
          WHILE n > 0 DO
            r := Unix.Write(fdnew, SYSTEM.ADR(buf), n);
            IF r < 0 THEN errno := Unix.errno(); r := Unix.Close(fdold); r := Unix.Close(fdnew);
              Err("cannot move file", NIL, errno)
            END ;
            n := Unix.Read(fdold, SYSTEM.ADR(buf), bufsize)
          END ;
          errno := Unix.errno();
          r := Unix.Close(fdold); r := Unix.Close(fdnew);
          IF n = 0 THEN r := Unix.Unlink(old); res := 0
          ELSE Err("cannot move file", NIL, errno)
          END ;
        ELSE RETURN (* res is Unix.Rename return code *)
        END
      END ;
      res := 0
    ELSE res := 2 (* old file not found *)
    END
  END Rename;

  PROCEDURE Register* (f: File);
    VAR idx, errno: INTEGER; f1: File; file: ARRAY 104 OF CHAR;
  BEGIN
    IF (f.state = create) & (f.registerName # "") THEN f.state := close (* shortcut renaming *) END ;
    Close(f);
    IF f.registerName # "" THEN
      Rename(f.workName, f.registerName, errno);
      IF errno # 0 THEN COPY(f.registerName, file); HALT(99) END ;
      f.workName := f.registerName; f.registerName := ""; f.tempFile := FALSE
    END
  END Register;

  PROCEDURE ChangeDirectory*(path: ARRAY OF CHAR; VAR res: INTEGER);
  BEGIN
    res := SHORT(Unix.Chdir(path));
    getcwd(Kernel.CWD)
  END ChangeDirectory;

  PROCEDURE FlipBytes(VAR src, dest: ARRAY OF SYSTEM.BYTE);
    VAR i, j: LONGINT;
  BEGIN
    IF ~Kernel.littleEndian THEN i := LEN(src); j := 0;
      WHILE i > 0 DO DEC(i); dest[j] := src[i]; INC(j) END
    ELSE SYSTEM.MOVE(SYSTEM.ADR(src), SYSTEM.ADR(dest), LEN(src))
    END
  END FlipBytes;

  PROCEDURE ReadBool* (VAR R: Rider; VAR x: BOOLEAN);
  BEGIN Read(R, SYSTEM.VAL(CHAR, x))
  END ReadBool;

  PROCEDURE ReadInt* (VAR R: Rider; VAR x: INTEGER);
    VAR b: ARRAY 2 OF CHAR;
  BEGIN ReadBytes(R, b, 2);
    x := ORD(b[0]) + ORD(b[1])*256
  END ReadInt;
  
  PROCEDURE ReadLInt* (VAR R: Rider; VAR x: LONGINT);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN ReadBytes(R, b, 4);
    x := ORD(b[0]) + ORD(b[1])*100H + ORD(b[2])*10000H + ORD(b[3])*1000000H
  END ReadLInt;
  
  PROCEDURE ReadSet* (VAR R: Rider; VAR x: SET);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN ReadBytes(R, b, 4);
    x := SYSTEM.VAL(SET, ORD(b[0]) + ORD(b[1])*100H + ORD(b[2])*10000H + ORD(b[3])*1000000H)
  END ReadSet;
  
  PROCEDURE ReadReal* (VAR R: Rider; VAR x: REAL);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN ReadBytes(R, b, 4); FlipBytes(b, x)
  END ReadReal;
  
  PROCEDURE ReadLReal* (VAR R: Rider; VAR x: LONGREAL);
    VAR b: ARRAY 8 OF CHAR;
  BEGIN ReadBytes(R, b, 8); FlipBytes(b, x)
  END ReadLReal;
  
  PROCEDURE ReadString* (VAR R: Rider; VAR x: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0;
    REPEAT Read(R, ch); x[i] := ch; INC(i) UNTIL ch = 0X
  END ReadString;

  (* need to read line; -- noch *)
  PROCEDURE ReadLine* (VAR R: Rider; VAR x: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR; b : BOOLEAN;
  BEGIN i := 0;
        b := FALSE;
    REPEAT 
       Read(R, ch); 
       IF ((ch = 0X) OR (ch = 0AX) OR (ch = 0DX)) THEN 
       b := TRUE
       ELSE
       x[i] := ch;
       INC(i);
       END;
    UNTIL b
  END ReadLine;
 
  PROCEDURE ReadNum* (VAR R: Rider; VAR x: LONGINT);
    VAR s: SHORTINT; ch: CHAR; n: LONGINT;
  BEGIN s := 0; n := 0; Read(R, ch);
    WHILE ORD(ch) >= 128 DO INC(n, ASH(ORD(ch) - 128, s) ); INC(s, 7); Read(R, ch) END;
    INC(n, ASH(ORD(ch) MOD 64 - ORD(ch) DIV 64 * 64, s) );
    x := n
  END ReadNum;
  
  PROCEDURE WriteBool* (VAR R: Rider; x: BOOLEAN);
  BEGIN Write(R, SYSTEM.VAL(CHAR, x))
  END WriteBool;
  
  PROCEDURE WriteInt* (VAR R: Rider; x: INTEGER);
    VAR b: ARRAY 2 OF CHAR;
  BEGIN b[0] := CHR(x); b[1] := CHR(x DIV 256);
    WriteBytes(R, b, 2);
  END WriteInt;
  
  PROCEDURE WriteLInt* (VAR R: Rider; x: LONGINT);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN
    b[0] := CHR(x); b[1] := CHR(x DIV 100H); b[2] := CHR(x DIV 10000H); b[3] := CHR(x DIV 1000000H);
    WriteBytes(R, b, 4);
  END WriteLInt;
  
  PROCEDURE WriteSet* (VAR R: Rider; x: SET);
    VAR b: ARRAY 4 OF CHAR; i: LONGINT;
  BEGIN i := SYSTEM.VAL(LONGINT, x);
    b[0] := CHR(i); b[1] := CHR(i DIV 100H); b[2] := CHR(i DIV 10000H); b[3] := CHR(i DIV 1000000H);
    WriteBytes(R, b, 4);
  END WriteSet;
  
  PROCEDURE WriteReal* (VAR R: Rider; x: REAL);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN FlipBytes(x, b); WriteBytes(R, b, 4)
  END WriteReal;
  
  PROCEDURE WriteLReal* (VAR R: Rider; x: LONGREAL);
    VAR b: ARRAY 8 OF CHAR;
  BEGIN FlipBytes(x, b); WriteBytes(R, b, 8)
  END WriteLReal;
  
  PROCEDURE WriteString* (VAR R: Rider; x: ARRAY [1] OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE x[i] # 0X DO INC(i) END ;
    WriteBytes(R, x, i+1)
  END WriteString;
  
  PROCEDURE WriteNum* (VAR R: Rider; x: LONGINT);
  BEGIN
    WHILE (x < - 64) OR (x > 63) DO Write(R, CHR(x MOD 128 + 128)); x := x DIV 128 END;
    Write(R, CHR(x MOD 128))
  END WriteNum;

  PROCEDURE GetName*(f: File; VAR name: ARRAY OF CHAR);
  BEGIN
     COPY (f.workName, name);
  END GetName;

  PROCEDURE Finalize(o: SYSTEM.PTR);
    VAR f: File; res: LONGINT;
  BEGIN
    f := SYSTEM.VAL(File, o);
    IF f.fd >= 0 THEN
      fileTab[f.fd] := 0; res := Unix.Close(f.fd); f.fd := -1; DEC(Kernel.nofiles);
      IF f.tempFile THEN res := Unix.Unlink(f.workName) END
    END
  END Finalize;

  PROCEDURE Init;
    VAR i: LONGINT;
  BEGIN
    i := 0; WHILE i < fileTabSize DO fileTab[i] := 0; INC(i) END ;
    tempno := -1; Kernel.nofiles := 0
  END Init;

BEGIN Init
END OakFiles.
