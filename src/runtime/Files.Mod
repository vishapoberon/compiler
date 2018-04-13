MODULE Files;  (* J. Templ 1.12. 89/12.4.95 Oberon files mapped onto Unix files *)

  IMPORT SYSTEM, Platform, Heap, Strings, Out;

  (* standard data type I/O

    little endian,
    Sint:1, Int:2, Lint:4
    ORD({0}) = 1,
    false = 0, true =1
    IEEE real format,
    null terminated strings,
    compact numbers according to M.Odersky *)


  CONST
    NumBufs = 4;
    BufSize = 4096;
    NoDesc = -1;

    (* No file states, used when FileDesc.fd = NoDesc *)
    open   = 0;    (* OS File has been opened *)
    create = 1;    (* OS file needs to be created *)
    close  = 2;    (* Flag used by Files.Register to tell Create to create the
                      file using it's registerName directly, rather than to
                      create a temporary file: i.e. since we're closing and all
                      data is still in buffers bypass writing to temp file and
                      then renaming and just write directly to final register
                      name *)

  TYPE
    FileName = ARRAY SYSTEM.MAXPATHLEN + 1 OF CHAR;
    File*    = POINTER TO FileDesc;
    Buffer   = POINTER TO BufDesc;

    FileDesc = RECORD
      workName:     FileName;
      registerName: FileName;
      tempFile:     BOOLEAN;
      identity:     Platform.FileIdentity;
      fd:           Platform.FileHandle;
      len, pos:     LONGINT;
      bufs:         ARRAY NumBufs OF Buffer;
      swapper:      INTEGER;
      state:        INTEGER;
      next:         POINTER [1] TO FileDesc;
    END;

    BufDesc = RECORD
      f:    File;
      chg:  BOOLEAN;
      org:  LONGINT;
      size: LONGINT;
      data: ARRAY BufSize OF SYSTEM.BYTE
    END;

    Rider* =  RECORD
      res*:   LONGINT;  (* Residue (byte count not read) at eof of ReadBytes *)
      eof*:   BOOLEAN;
      buf:    Buffer;
      org:    LONGINT;  (* File offset of block containing current position *)
      offset: LONGINT   (* Current position offset within block at org. *)
    END;


  VAR
    files:      POINTER [1] TO FileDesc;   (* List of files backed by an OS file, whether open, registered or temporary. *)
    tempno:     INTEGER;
    HOME:       ARRAY 1024 OF CHAR;
    SearchPath: POINTER TO ARRAY OF CHAR;


  PROCEDURE -IdxTrap "__HALT(-1)";

  PROCEDURE^ Finalize(o: SYSTEM.PTR);

  PROCEDURE Assert(truth: BOOLEAN);
  BEGIN
    IF ~truth THEN Out.Ln; ASSERT(truth) END
  END Assert;

  PROCEDURE Err(s: ARRAY OF CHAR; f: File; errcode: Platform.ErrorCode);
  BEGIN
    Out.Ln; Out.String("-- "); Out.String(s); Out.String(": ");
    IF f # NIL THEN
      IF f.registerName # "" THEN Out.String(f.registerName) ELSE Out.String(f.workName) END;
      IF f.fd # 0 THEN Out.String("f.fd = "); Out.Int(f.fd,1) END
    END;
    IF errcode # 0 THEN Out.String(" errcode = "); Out.Int(errcode, 1) END;
    Out.Ln;
    HALT(99)
  END Err;

(* ************************************************************************* **
** Some helper procedures to be used in the modified versions of             **
** 'MakeFileName()', 'GetTempName()' and 'ScanPath()', 'ReadString()' and    **
** 'ReadLine()'. These should simplify the implementation of the named       **
** procedures and help reducing buffer overflow problems ...                 **
** ************************************************************************* **
*)

  (* Write a buffer overflow message to "stdout" and terminate ... *)
  PROCEDURE ErrBO(where, culprit: ARRAY OF CHAR);
    VAR ix: LONGINT;
  BEGIN
    Out.Ln; Out.String("-- Files."); Out.String(where);
    Out.String(": Buffer overflow ("); Out.String(culprit);
    Out.String("|<"); Out.String(")"); Out.Ln;
    HALT(99)
  END ErrBO;

  (* Append a string (from a given position until its end) to the content of
  ** a file buffer. This procedure returns TRUE through its last argument
  ** if appending the string was successful (i.e., if the remaining buffer's
  ** size was long enough for the string - including a 0X), and FALSE otherwise.
  ** This procedure counts the ending 0X, but doesn't include it into the
  ** output, meaning the terminating 0X must be appended manually after the
  ** string was successfully completely.
  *)
  PROCEDURE AppendStr(src: ARRAY OF CHAR;
                      VAR dest: ARRAY OF CHAR; VAR dx: LONGINT;
		      VAR done: BOOLEAN);
    VAR sx: LONGINT;
  BEGIN
    sx := 0;
    WHILE src[sx] # 0X DO
      IF dx >= LEN(dest) - 1 THEN done := FALSE; RETURN END;
      dest[dx] := src[sx]; INC(dx); INC(sx);
    END;
    done := TRUE
  END AppendStr;

(* Small helper procedure for dumping a part of a string buffer ...
  PROCEDURE DumpPath(tag, name, path: ARRAY OF CHAR; sx, px: LONGINT);
    VAR ix: LONGINT;
  BEGIN
    Out.String(tag); Out.String(": "); Out.String(name); Out.String(' = "');
    IF px = 0 THEN
	ix := sx; WHILE path[ix] # 0X DO Out.Char(path[ix]); INC(ix) END;
    ELSE
	FOR ix := sx TO px - 2 DO Out.Char(path[ix]) END
    END;
    Out.String('"'); Out.Ln
  END DumpPath;
*)

  (* Convert an integer (LONGINT) into a string in the supplied 'buffer'.
  ** 'buffer' must be big enough to hold the complete integer (including the
  ** string terminator (0X) after the conversion. (A buffer of 40 characters
  ** should be enough for even 128bit numbers ...)
  *)
  PROCEDURE IntToStr(n: LONGINT; VAR buffer: ARRAY OF CHAR);
    VAR bx: LONGINT; sign: BOOLEAN;
  BEGIN
    sign := FALSE; IF n < 0 THEN n := -n; sign := TRUE END;
    bx := LEN(buffer);
    DEC(bx); buffer[bx] := 0X;
    REPEAT
      IF bx > 0 THEN
        DEC(bx); buffer[bx] := CHR(n MOD 10 + ORD("0"));
        n := n DIV 10
      END
    UNTIL (n = 0);
    IF sign & (bx > 0) THEN DEC(bx); buffer[bx] := "-" END;
    SYSTEM.MOVE(SYSTEM.ADR(buffer) + bx, SYSTEM.ADR(buffer), LEN(buffer) - bx)
  END IntToStr;

  (* Reimplemented version of 'MakeFileName()', which makes use of
  ** 'AppendStr()'. The status variable 'done' which is returned by
  ** 'AppendStr()' is passed through the complete implementation, skipping
  ** further appends after the first failure ...
  *)
  PROCEDURE MakeFileName(dir, name: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
    VAR i: LONGINT; done: BOOLEAN;
  BEGIN i := 0;
    AppendStr(dir, dest, i, done);
    IF done & (dest[i-1] # "/") THEN
      AppendStr("/", dest, i, done)
    END;
    IF done THEN AppendStr(name, dest, i, done); END;
    dest[i] := 0X;
    (* Generate an error message and terminate on failure *)
    IF ~ done THEN ErrBO("MakeFileName", dest) END
  END MakeFileName;

  (* Reimplemented version of 'GetTempName()'. The errorneous appending of
  ** sequence number and process id was rewritten (using 'IntToStr()' and
  ** 'AppendStr()').
  *)
  PROCEDURE GetTempName(finalName: ARRAY OF CHAR; VAR name: ARRAY OF CHAR);
    VAR n, i, j: LONGINT; numBuffer: ARRAY 40 OF CHAR; done: BOOLEAN;
  BEGIN
    INC(tempno); n := tempno; i := 0; done := TRUE;
    IF finalName[0] # "/" THEN  (* relative pathname *)
      (* Prepend the current working directory *)
      AppendStr(Platform.CWD, name, i, done);
      IF done & (name[i - 1] # "/") THEN AppendStr("/", name, i, done) END
    END;
    (* Append the "final" pathname, but only for the directory *)
    IF done THEN AppendStr(finalName, name, i, done) END;
    IF done THEN
      DEC(i); WHILE name[i] # "/" DO DEC(i) END; INC(i);
      AppendStr(".tmp.", name, i, done)
    END;
    IF done THEN
      IntToStr(tempno, numBuffer);
      AppendStr(numBuffer, name, i, done);
    END;
    IF done THEN
      IntToStr(Platform.PID, numBuffer);
      AppendStr(numBuffer, name, i, done)
    END;
    name[i] := 0X;
    IF ~ done THEN ErrBO("GetTempName", name) END
  END GetTempName;

  (* When registering a file, it may turn out that the name we want to use
     is aready in use by another File. E.g. the compiler opens and reads
     an existing symbol file if present before creating an updated one.
     When this happens on Windows, creation of the new file will be blocked
     by the presence of the old one because it is in a open state. Further,
     on both Unix and Windows systems we want behaviour to match that of
     a real Oberon system, where registering the new file has the effect of
     unregistering the old file. To simulate this we need to change the old
     Files.File back to a temp file. *)
  PROCEDURE Deregister(name: ARRAY OF CHAR);
  VAR
    identity: Platform.FileIdentity;
    osfile:   File;
    error:    Platform.ErrorCode;
  BEGIN
    IF Platform.IdentifyByName(name, identity) = 0 THEN
      (* The name we are registering is an already existing file. *)
      osfile := files;
      WHILE (osfile # NIL) & ~Platform.SameFile(osfile.identity, identity) DO osfile := osfile.next END;
      IF osfile # NIL THEN
        (* osfile is the FileDesc corresponding to the file name we are hoping
           to register. Turn it into a temporary file. *)
        ASSERT(~osfile.tempFile); ASSERT(osfile.fd >= 0);
        osfile.registerName := osfile.workName;
        GetTempName(osfile.registerName, osfile.workName);
        osfile.tempFile := TRUE;
        osfile.state := open;
        error := Platform.Rename(osfile.registerName, osfile.workName);
        IF error # 0 THEN
          Err("Couldn't rename previous version of file being registered", osfile, error)
        END
      END
    END
  END Deregister;


  PROCEDURE Create(f: File);
  (* Makes sure there is an OS file backing this Oberon file.
     Used when more data has been written to an unregistered new file than
     buffers can hold, or when registering a new file whose data is all in
     buffers. *)
    VAR
      done:     BOOLEAN;
      error:    Platform.ErrorCode;
      err:      ARRAY 32 OF CHAR;
  BEGIN
    IF f.fd = NoDesc THEN
      IF f.state = create THEN
        (* New file with enough data written to exceed buffers, so we need to
           create a temporary file to back it. *)
        GetTempName(f.registerName, f.workName); f.tempFile := TRUE
      ELSE
        ASSERT(f.state = close);
        (* New file with all data in buffers being registered. No need for a
           temp file, will just write the buffers to the registerName. *)
        Deregister(f.registerName);
        f.workName := f.registerName; f.registerName := ""; f.tempFile := FALSE
      END;
      error := Platform.Unlink(f.workName);  (*unlink first to avoid stale NFS handles and to avoid reuse of inodes*)
      error := Platform.New(f.workName, f.fd);
      done := error = 0;
      IF done THEN
        f.next := files;  files := f;  (* Link this file into the list of OS bakced files. *)
        INC(Heap.FileCount);
        Heap.RegisterFinalizer(f, Finalize);
        f.state := open;
        f.pos   := 0;
        error   := Platform.Identify(f.fd, f.identity);
      ELSE
        IF    Platform.NoSuchDirectory(error) THEN err := "no such directory"
        ELSIF Platform.TooManyFiles(error)    THEN err := "too many files open"
        ELSE  err := "file not created"
        END;
        Err(err, f, error)
      END
    END
  END Create;

  PROCEDURE Flush(buf: Buffer);
    VAR
      error:     Platform.ErrorCode;
      f:         File;
      (* identity:  Platform.FileIdentity; *)
  BEGIN
    IF buf.chg THEN f := buf.f; Create(f);
      IF buf.org # f.pos THEN
        error := Platform.Seek(f.fd, buf.org, Platform.SeekSet);
      END;
      error := Platform.Write(f.fd, SYSTEM.ADR(buf.data), buf.size);
      IF error # 0 THEN Err("error writing file", f, error) END;
      f.pos := buf.org + buf.size;
      buf.chg := FALSE;
      error := Platform.Identify(f.fd, f.identity); (* Update identity with new modification time. *)
      IF error # 0 THEN Err("error identifying file", f, error) END;
    END
  END Flush;

  PROCEDURE Close* (f: File);
    VAR
      i: LONGINT;  error: Platform.ErrorCode;
  BEGIN
    IF (f.state # create) OR (f.registerName # "") THEN
      Create(f); i := 0;
      WHILE (i < NumBufs) & (f.bufs[i] # NIL) DO Flush(f.bufs[i]); INC(i) END;
    END
  END Close;

  PROCEDURE Length* (f: File): LONGINT;
  BEGIN RETURN f.len END Length;

  PROCEDURE New* (name: ARRAY OF CHAR): File;
    VAR f: File;
  BEGIN
    NEW(f); f.workName := ""; COPY(name, f.registerName);
    f.fd := NoDesc; f.state := create; f.len := 0; f.pos := 0; f.swapper := -1; (*all f.buf[i] = NIL*)
    RETURN f
  END New;

  PROCEDURE ScanPath(VAR pos: INTEGER; VAR dir: ARRAY OF CHAR);
  (* Extract next individual directory from searchpath starting at pos,
     updating pos and returning dir.
     Supports ~, ~user (???) and blanks inside path *)
  VAR i: LONGINT; pos1: INTEGER; ch: CHAR; done: BOOLEAN;
  BEGIN
    i := 0; done := TRUE;
    IF SearchPath = NIL THEN
      IF pos = 0 THEN
        (* Default search path is just the current directory *)
        AppendStr(".", dir, i, done); INC(pos)
      END
    ELSE
      ch := SearchPath[pos];
      WHILE (ch = " ") OR (ch = ";") DO INC(pos); ch := SearchPath[pos] END;
      IF ch = "~" THEN
        INC(pos); ch := SearchPath[pos];
        AppendStr(HOME, dir, i, done);
        IF done & (ch # "/") & (ch # 0X) & (ch # ";") & (ch # " ") THEN
          WHILE (i > 0) & (dir[i-1] # "/") DO DEC(i) END
        END
      END;
      IF done THEN
        WHILE done & (ch # 0X) & (ch # ";") DO
          IF i >= LEN(dir) - 1 THEN
            done := FALSE
          ELSE
            dir[i] := ch; INC(i); INC(pos); ch := SearchPath[pos]
          END
        END;
        IF done THEN
          WHILE (i > 0) & (dir[i - 1] = " ") DO DEC(i) END
        END
      END
    END;
    dir[i] := 0X;
    IF ~ done THEN ErrBO("ScanPath", dir) END
  END ScanPath;

  PROCEDURE HasDir(VAR name: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0; ch := name[0];
    WHILE (ch # 0X) & (ch # "/") DO INC(i); ch := name[i] END;
    RETURN ch = "/"
  END HasDir;

  PROCEDURE CacheEntry(identity: Platform.FileIdentity): File;
    VAR f: File;  i: INTEGER;  error: Platform.ErrorCode;
  BEGIN f := files;
    WHILE f # NIL DO
      IF Platform.SameFile(identity, f.identity) THEN
        IF ~Platform.SameFileTime(identity, f.identity) THEN i := 0;
          WHILE i < NumBufs DO
            IF f.bufs[i] # NIL THEN f.bufs[i].org := -1; f.bufs[i] := NIL END;
            INC(i)
          END;
          f.swapper := -1; f.identity := identity;
          error := Platform.Size(f.fd, f.len);
        END;
        RETURN f
      END;
      f := f.next
    END;
    RETURN NIL
  END CacheEntry;

  PROCEDURE Old*(name: ARRAY OF CHAR): File;
    VAR
      f:         File;
      fd:        Platform.FileHandle;
      pos:       INTEGER;
      done:      BOOLEAN;
      dir, path: ARRAY 256 OF CHAR;
      error:     Platform.ErrorCode;
      identity:  Platform.FileIdentity;
  BEGIN
    (* Out.String("Files.Old "); Out.String(name); Out.Ln; *)
    IF name # "" THEN
      IF HasDir(name) THEN dir := ""; COPY(name, path)
      ELSE pos := 0; ScanPath(pos, dir); MakeFileName(dir, name, path); ScanPath(pos, dir)
      END;
      LOOP
        error := Platform.OldRW(path, fd); done := error = 0;
        IF ~done & Platform.TooManyFiles(error) THEN Err("too many files open", f, error) END;
        IF ~done & Platform.Inaccessible(error) THEN
          error := Platform.OldRO(path, fd); done := error = 0;
        END;
        IF ~done & ~Platform.Absent(error) THEN
          Out.String("Warning: Files.Old "); Out.String(name);
          Out.String(" error = "); Out.Int(error, 0); Out.Ln;
        END;
        IF done THEN
          (* Out.String("  fd = "); Out.Int(fd,1); Out.Ln; *)
          error := Platform.Identify(fd, identity);
          f := CacheEntry(identity);
          IF f # NIL THEN
            error := Platform.Close(fd); (* fd not needed - we'll be using f.fd. *)
            RETURN f
          ELSE NEW(f); Heap.RegisterFinalizer(f, Finalize);
            f.fd := fd; f.state := open; f.pos := 0; f.swapper := -1; (*all f.buf[i] = NIL*)
            error := Platform.Size(fd, f.len);
            COPY(name, f.workName); f.registerName := ""; f.tempFile := FALSE;
            f.identity := identity;
            f.next := files;  files := f; INC(Heap.FileCount);
            RETURN f
          END
        ELSIF dir = "" THEN RETURN NIL
        ELSE MakeFileName(dir, name, path); ScanPath(pos, dir)
        END
      END
    ELSE RETURN NIL
    END
  END Old;

  PROCEDURE Purge* (f: File);
    VAR i: INTEGER;  identity: Platform.FileIdentity;  error: Platform.ErrorCode;
  BEGIN i := 0;
    WHILE i < NumBufs DO
      IF f.bufs[i] # NIL THEN f.bufs[i].org := -1; f.bufs[i] := NIL END;
      INC(i)
    END;
    IF f.fd # NoDesc THEN
      error := Platform.Truncate(f.fd, 0);
      error := Platform.Seek(f.fd, 0, Platform.SeekSet)
    END;
    f.pos := 0; f.len := 0; f.swapper := -1;
    error := Platform.Identify(f.fd, identity); Platform.SetMTime(f.identity, identity)
  END Purge;

  PROCEDURE GetDate* (f: File; VAR t, d: LONGINT);
    VAR
      identity: Platform.FileIdentity;  error: Platform.ErrorCode;
  BEGIN
    Create(f); error := Platform.Identify(f.fd, identity);
    Platform.MTimeAsClock(identity, t, d)
  END GetDate;

  PROCEDURE Pos* (VAR r: Rider): LONGINT;
  BEGIN
    Assert(r.offset <= BufSize);
    RETURN r.org + r.offset
  END Pos;

  PROCEDURE Set* (VAR r: Rider; f: File; pos: LONGINT);
    VAR org, offset, i, n: LONGINT;  buf: Buffer;  error: Platform.ErrorCode;
  BEGIN
    IF f # NIL THEN
      IF pos > f.len THEN pos := f.len ELSIF pos < 0 THEN pos := 0 END;
      offset := pos MOD BufSize; org := pos - offset; i := 0;
      WHILE (i < NumBufs) & (f.bufs[i] # NIL) & (org # f.bufs[i].org) DO INC(i) END;
      IF i < NumBufs THEN
        IF f.bufs[i] = NIL THEN
          NEW(buf); buf.chg := FALSE; buf.org := -1; buf.f := f; f.bufs[i] := buf
        ELSE buf := f.bufs[i]
        END
      ELSE
        f.swapper := (f.swapper + 1) MOD NumBufs;
        buf := f.bufs[f.swapper];
        Flush(buf)
      END;
      IF buf.org # org THEN
        IF org = f.len THEN buf.size := 0
        ELSE Create(f);
          IF f.pos # org THEN error := Platform.Seek(f.fd, org, Platform.SeekSet) END;
          error := Platform.ReadBuf(f.fd, buf.data, n);
          IF error # 0 THEN Err("read from file not done", f, error) END;
          f.pos := org + n;
          buf.size := n
        END;
        buf.org := org; buf.chg := FALSE
      END
    ELSE buf := NIL; org := 0; offset := 0
    END;
    Assert(offset <= BufSize);
    r.buf := buf; r.org := org; r.offset := offset; r.eof := FALSE; r.res := 0
  END Set;


  PROCEDURE Read* (VAR r: Rider; VAR x: SYSTEM.BYTE);
    VAR offset: LONGINT; buf: Buffer;
  BEGIN
    buf := r.buf; offset := r.offset;
    IF r.org # buf.org THEN
      Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset
    END;
    Assert(offset <= buf.size);
    IF (offset < buf.size) THEN
      x := buf.data[offset]; r.offset := offset + 1
    ELSIF r.org + offset < buf.f.len THEN
      Set(r, r.buf.f, r.org + offset);
      x := r.buf.data[0]; r.offset := 1
    ELSE
      x := 0X; r.eof := TRUE
    END
  END Read;


  (* Read the next character from the stream, but don't advance after it.
  ** This is a primitive 'look ahead' mechanism implemented especially for
  ** 'ReadLine()'. Maybe it could be exported, too ...
  *)
  PROCEDURE Peek(VAR r: Rider; VAR x: SYSTEM.BYTE);
    VAR offset: LONGINT; buf: Buffer;
  BEGIN
    buf := r.buf; offset := r.offset;
    IF r.org # buf.org THEN
      Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset
    END;
    Assert(offset <= buf.size);
    IF (offset < buf.size) THEN
      x := buf.data[offset]                     (*Don't advance the offset*)
    ELSIF r.org + offset < buf.f.len THEN
      Set(r, r.buf.f, r.org + offset);
      x := r.buf.data[0]; r.offset := 0         (*Same here - don't advance*)
    ELSE
      x := 0X; r.eof := TRUE
    END
  END Peek;


  PROCEDURE ReadBytes* (VAR r: Rider; VAR x: ARRAY OF SYSTEM.BYTE; n: LONGINT);
    VAR xpos, min, restInBuf, offset: LONGINT; buf: Buffer;
  BEGIN
    IF n > LEN(x) THEN IdxTrap END;
    xpos   := 0;
    buf    := r.buf;
    offset := r.offset;  (* Offset within buffer r.buf *)
    WHILE n > 0 DO
      IF (r.org # buf.org) OR (offset >= BufSize) THEN
        Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset
      END;
      restInBuf := buf.size - offset;
      IF restInBuf = 0 THEN r.res := n; r.eof := TRUE; RETURN
      ELSIF n > restInBuf THEN min := restInBuf ELSE min := n END;
      SYSTEM.MOVE(SYSTEM.ADR(buf.data[offset]), SYSTEM.ADR(x[xpos]), min);
      INC(offset, min); r.offset := offset; INC(xpos, min); DEC(n, min);
      Assert(offset <= BufSize)
    END;
    r.res := 0; r.eof := FALSE
  END ReadBytes;

  PROCEDURE Base* (VAR r: Rider): File;
  BEGIN RETURN r.buf.f
  END Base;

  PROCEDURE Write* (VAR r: Rider; x: SYSTEM.BYTE);
    VAR buf: Buffer; offset: LONGINT;
  BEGIN
    buf := r.buf; offset := r.offset;
    Assert(offset <= BufSize);
    IF (r.org # buf.org) OR (offset >= BufSize) THEN
      Set(r, buf.f, r.org + offset);
      buf := r.buf; offset := r.offset
    END;
    Assert(offset < BufSize);
    buf.data[offset] := x;
    buf.chg := TRUE;
    IF offset = buf.size THEN
      INC(buf.size); INC(buf.f.len)
    END;
    r.offset := offset + 1; r.res := 0
  END Write;

  PROCEDURE WriteBytes* (VAR r: Rider; VAR x: ARRAY OF SYSTEM.BYTE; n: LONGINT);
    VAR xpos, min, restInBuf, offset: LONGINT; buf: Buffer;
  BEGIN
    IF n > LEN(x) THEN IdxTrap END;
    xpos := 0; buf := r.buf; offset := r.offset;
    WHILE n > 0 DO
      Assert(offset <= BufSize);
      IF (r.org # buf.org) OR (offset >= BufSize) THEN
        Set(r, buf.f, r.org + offset);
        buf := r.buf; offset := r.offset
      END;
      Assert(offset <= BufSize);
      restInBuf := BufSize - offset;
      IF n > restInBuf THEN min := restInBuf ELSE min := n END;
      SYSTEM.MOVE(SYSTEM.ADR(x[xpos]), SYSTEM.ADR(buf.data[offset]), min);
      INC(offset, min); r.offset := offset;
      Assert(offset <= BufSize);
      IF offset > buf.size THEN INC(buf.f.len, offset - buf.size); buf.size := offset END;
      INC(xpos, min); DEC(n, min); buf.chg := TRUE
    END;
    r.res := 0
  END WriteBytes;

(* another solution would be one that is similar to ReadBytes, WriteBytes.
No code duplication, more symmetric, only two ifs for
Read and Write in buffer, buf.size replaced by BufSize in Write ops, buf.size and len
must be made consistent with offset (if offset > buf.size) in a lazy way.

PROCEDURE Write* (VAR r: Rider; x: SYSTEM.BYTE);
  VAR buf: Buffer; offset: LONGINT;
BEGIN
  buf := r.buf; offset := r.offset;
  IF (offset >= BufSize) OR (r.org # buf.org) THEN
    Set(r, buf.f, r.org + offset); buf := r.buf; offset := r.offset;
  END;
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
  END;
  x := buf.data[offset]; r.offset := offset + 1
END Read;

but this would also affect Set, Length, and Flush.
Especially Length would become fairly complex.
*)

  PROCEDURE Delete*(name: ARRAY OF CHAR; VAR res: INTEGER);
  BEGIN
    Deregister(name);
    res := Platform.Unlink(name)
  END Delete;

  PROCEDURE Rename* (old, new: ARRAY OF CHAR; VAR res: INTEGER);
    VAR
      fdold, fdnew: Platform.FileHandle;
      n: LONGINT;
      error, ignore: Platform.ErrorCode;
      oldidentity, newidentity: Platform.FileIdentity;
      buf: ARRAY 4096 OF CHAR;
  BEGIN
    error := Platform.IdentifyByName(old, oldidentity);
    IF error = 0 THEN
      error := Platform.IdentifyByName(new, newidentity);
      IF (error # 0) & ~Platform.SameFile(oldidentity, newidentity) THEN
        Delete(new, error);  (* work around stale nfs handles *)
      END;
      error := Platform.Rename(old, new);
      (* Out.String("Platform.Rename error code "); Out.Int(error,1); Out.Ln; *)
      (* TODO, if we already have a FileDesc for old, it ought to be updated
         with the new workname. *)
      IF ~Platform.DifferentFilesystems(error) THEN
        res := error; RETURN
      ELSE
        (* cross device link, move the file *)
        error := Platform.OldRO(old, fdold);
        IF error # 0 THEN res := 2; RETURN END;
        error := Platform.New(new, fdnew);
        IF error # 0 THEN error := Platform.Close(fdold); res := 3; RETURN END;
        error := Platform.Read(fdold, SYSTEM.ADR(buf), BufSize, n);
        WHILE n > 0 DO
          error := Platform.Write(fdnew, SYSTEM.ADR(buf), n);
          IF error # 0 THEN
            ignore := Platform.Close(fdold);
            ignore := Platform.Close(fdnew);
            Err("cannot move file", NIL, error)
          END;
          error := Platform.Read(fdold, SYSTEM.ADR(buf), BufSize, n);
        END;
        ignore := Platform.Close(fdold);
        ignore := Platform.Close(fdnew);
        IF n = 0 THEN
          error := Platform.Unlink(old); res := 0
        ELSE
          Err("cannot move file", NIL, error)
        END;
      END
    ELSE
      res := 2 (* old file not found *)
    END
  END Rename;

  PROCEDURE Register* (f: File);
    VAR idx, errcode: INTEGER; f1: File;
  BEGIN
    IF (f.state = create) & (f.registerName # "") THEN f.state := close (* shortcut renaming *) END;
    Close(f);
    IF f.registerName # "" THEN
      Deregister(f.registerName);
      Rename(f.workName, f.registerName, errcode);
      IF errcode # 0 THEN Err("Couldn't rename temp name as register name", f, errcode) END;
      f.workName := f.registerName; f.registerName := ""; f.tempFile := FALSE
    END
  END Register;

  PROCEDURE ChangeDirectory*(path: ARRAY OF CHAR; VAR res: INTEGER);
  BEGIN
    res := Platform.Chdir(path);
  END ChangeDirectory;

  PROCEDURE FlipBytes(VAR src, dest: ARRAY OF SYSTEM.BYTE);
    VAR i, j: LONGINT;
  BEGIN
    IF ~Platform.LittleEndian THEN i := LEN(src); j := 0;
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
  (* Reads 32 bits as a SET value (even on 64 bit systems. See Oakwood appendix 1.2.5.4 *)
    VAR b: ARRAY 4 OF CHAR; l: LONGINT;
  BEGIN ReadBytes(R, b, 4);
    (* Need to read via a LONGINT to provide correct behaviour for 64 bit sets. *)
    l := ORD(b[0]) + ORD(b[1])*100H + ORD(b[2])*10000H + ORD(b[3])*1000000H;
    x := SYSTEM.VAL(SET, l)
  END ReadSet;

  PROCEDURE ReadReal* (VAR R: Rider; VAR x: REAL);
    VAR b: ARRAY 4 OF CHAR;
  BEGIN ReadBytes(R, b, 4); FlipBytes(b, x)
  END ReadReal;

  PROCEDURE ReadLReal* (VAR R: Rider; VAR x: LONGREAL);
    VAR b: ARRAY 8 OF CHAR;
  BEGIN ReadBytes(R, b, 8); FlipBytes(b, x)
  END ReadLReal;

  (* Reimplemented version of 'ReadString()' which checks for a buffer overflow
  ** and terminates the program in this case.
  *)
  PROCEDURE ReadString* (VAR R: Rider; VAR x: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR; done: BOOLEAN;
  BEGIN i := 0; done := TRUE;
    Read(R, ch);
    REPEAT
      IF i >= LEN(x) - 1 THEN done := FALSE END;
      x[i] := ch; INC(i); Read(R, ch)
    UNTIL ~ done OR (ch = 0X);
    x[i] := 0X;
    IF ~ done THEN ErrBO("ReadString", x) END
  END ReadString;

  (* Buffer-overflow safe variant of 'ReadLine()'.
  ** This variant read as much characters of a line as fit in the output
  ** variable 'x' (excluding the terminating 0X). The terminating 0X will be
  ** inserted manually after the read-loop. If the line has been read
  ** incompletely (meaning there was no 0AX before the end of the buffer was
  ** reached), the length of the resulting string is LEN(x) - 1. Otherwise, it
  ** is always shorter.
  ** In order to keep this procedure's semantics consistent in the case of a
  ** CR/LF sequence being read partially into the buffer (due to a buffer
  ** overflow), the procedure 'Peek()' (see above) was introduced.
  *)
  PROCEDURE ReadLine* (VAR R: Rider; VAR x: ARRAY OF CHAR);
  VAR i: INTEGER; ch: CHAR;
  BEGIN
    i := 0;
    IF LEN(x) < 2 THEN ErrBO("ReadLine", "*buffer too short*") END;
    REPEAT
      Read(R, ch); x[i] := ch; INC(i)
    UNTIL (i >= LEN(x) - 1) OR (ch = 0X) OR (ch = 0AX);

    IF x[i-1] = 0DX THEN
      (* Handle the two cases which may occur if the last valid character in the
      ** buffer is 0DX ...
      *)
      (* Handle the special situation that the buffer overflowed, the last valid
      ** character in the buffer is a 0DX and the next character in the stream
      ** is 0AX ...
      *)
      IF (i >= LEN(x) - 1) THEN
        (* The buffer overflowed. IF the next character in the input stream is
        ** a LF, a CR/LF sequence was found. This means that the 0DX must be
        ** removed from the buffer and the LF must be consumed. Otherwise, the
        ** next character must remain in the input stream. Here, 'Peek()' is
        ** used for getting the next character from the input stream, but *not*
        ** consuming it. For consuming the character from the input stream,
        ** 'Read()' is used ...
        *)
        Peek(R, ch); IF (ch = 0AX) THEN DEC(i); Read(R, ch) END
      ELSE
        DEC(i)
      END
    END;
    x[i] := 0X
  END ReadLine;

  PROCEDURE ReadNum*(VAR R: Rider; VAR x: ARRAY OF SYSTEM.BYTE);
    VAR s, b: SYSTEM.INT8; q: SYSTEM.INT64;
  BEGIN s := 0; q := 0; Read(R, b);
    WHILE b < 0 DO INC(q, ASH(b+128, s)); INC(s, 7); Read(R, b) END;
    INC(q, ASH(b MOD 64 - b DIV 64 * 64, s));
    Assert(LEN(x) <= 8);
    SYSTEM.MOVE(SYSTEM.ADR(q), SYSTEM.ADR(x), LEN(x))  (* Assumes little endian representation of q and x. *)
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
    WHILE x[i] # 0X DO INC(i) END;
    WriteBytes(R, x, i+1)
  END WriteString;

  PROCEDURE WriteNum* (VAR R: Rider; x: SYSTEM.INT64);
  BEGIN
    WHILE (x < - 64) OR (x > 63) DO Write(R, CHR(x MOD 128 + 128)); x := x DIV 128 END;
    Write(R, CHR(x MOD 128))
  END WriteNum;

  PROCEDURE GetName*(f: File; VAR name: ARRAY OF CHAR);
  BEGIN
     COPY (f.workName, name);
  END GetName;

  PROCEDURE CloseOSFile(f: File);
  (* Close the OS file handle and remove f from 'files' *)
    VAR prev: File; error: Platform.ErrorCode;
  BEGIN
    IF files = f THEN files := f.next
    ELSE
      prev := files;
      WHILE (prev # NIL) & (prev.next # f) DO prev := prev.next END;
      IF prev.next # NIL THEN prev.next := f.next END
    END;
    error := Platform.Close(f.fd);
    f.fd := NoDesc; f.state := create; DEC(Heap.FileCount);
  END CloseOSFile;

  PROCEDURE Finalize(o: SYSTEM.PTR);
    VAR f: File; res: LONGINT;
  BEGIN
    f := SYSTEM.VAL(File, o);
    IF f.fd >= 0 THEN
      CloseOSFile(f);
      IF f.tempFile THEN res := Platform.Unlink(f.workName) END
    END
  END Finalize;

  PROCEDURE SetSearchPath*(path: ARRAY OF CHAR);
  BEGIN
    IF Strings.Length(path) # 0 THEN
      NEW(SearchPath, Strings.Length(path)+1);
      COPY(path, SearchPath^)
    ELSE
      SearchPath := NIL
    END
  END SetSearchPath;


BEGIN
  tempno := -1;
  Heap.FileCount := 0;
  HOME := "";  Platform.GetEnv("HOME", HOME);
END Files.
