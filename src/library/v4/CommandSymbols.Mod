MODULE CommandSymbols;

  (* Read-only command discovery from VOC .sym files (OPM/OPT format F7 84).
     Like showdef, select exported XProc objects with no result/parameters.
     Unlike OPT.Import, this reader builds no compiler symbol table and never
     rewrites imported symbols. Keep the tags in sync with compiler/OPT.Mod. *)

  IMPORT SYSTEM, Files;

  TYPE
    Visitor* = PROCEDURE(name: ARRAY OF CHAR);
    Reader = RECORD
      rider: Files.Rider;
      length: LONGINT;
      valid: BOOLEAN;
      depth, refs: INTEGER
    END;
    Name = ARRAY 256 OF CHAR;
    Entry = POINTER TO EntryDesc;
    EntryDesc = RECORD next: Entry; name: Name END;

  PROCEDURE Byte(VAR r: Reader): CHAR;
    VAR ch: CHAR;
  BEGIN
    IF ~r.valid OR (Files.Pos(r.rider) >= r.length) THEN
      r.valid := FALSE; RETURN 0X
    END;
    Files.Read(r.rider, ch);
    IF r.rider.eof THEN r.valid := FALSE END;
    RETURN ch
  END Byte;

  PROCEDURE Number(VAR r: Reader): SYSTEM.INT64;
    VAR n, wide: SYSTEM.INT64; shift, b: INTEGER;
  BEGIN
    n := 0; shift := 0;
    LOOP
      b := ORD(Byte(r));
      IF ~r.valid THEN RETURN 0 END;
      IF b < 128 THEN
        IF (shift = 63) & (b # 0) & (b # 127) THEN r.valid := FALSE; RETURN 0 END;
        wide := b MOD 64 - b DIV 64 * 64;
        RETURN n + ASH(wide, shift)
      END;
      IF shift >= 63 THEN r.valid := FALSE; RETURN 0 END;
      wide := b - 128; n := n + ASH(wide, shift);
      INC(shift, 7)
    END
  END Number;

  PROCEDURE ReadName(VAR r: Reader; VAR name: Name);
    VAR i: INTEGER; ch: CHAR;
  BEGIN
    i := 0;
    REPEAT
      ch := Byte(r);
      IF i >= LEN(name) - 1 THEN r.valid := FALSE; name[0] := 0X; RETURN END;
      name[i] := ch; INC(i)
    UNTIL ~r.valid OR (ch = 0X)
  END ReadName;

  PROCEDURE Skip(VAR r: Reader; count: SYSTEM.INT64);
  BEGIN
    IF (count < 0) OR (count > r.length - Files.Pos(r.rider)) THEN r.valid := FALSE
    ELSE Files.Set(r.rider, Files.Base(r.rider), Files.Pos(r.rider) + SHORT(count))
    END
  END Skip;

  PROCEDURE ^Structure(VAR r: Reader): BOOLEAN;

  PROCEDURE Signature(VAR r: Reader): BOOLEAN;
    VAR noResult, noParams, ignored: BOOLEAN; tag, n: SYSTEM.INT64; name: Name;
  BEGIN
    noResult := Structure(r); tag := Number(r); noParams := tag = 18;
    WHILE r.valid & (tag # 18) DO
      IF (tag # 23) & (tag # 24) & (tag # 42) THEN r.valid := FALSE; RETURN FALSE END;
      ignored := Structure(r); n := Number(r); ReadName(r, name); tag := Number(r)
    END;
    RETURN r.valid & noResult & noParams
  END Signature;

  PROCEDURE Structure(VAR r: Reader): BOOLEAN;
    VAR tag, n: SYSTEM.INT64; ignored: BOOLEAN; name: Name;
  BEGIN
    tag := Number(r);
    IF tag # 34 THEN
      IF (tag >= 0) OR (-tag >= r.refs) THEN r.valid := FALSE END;
      IF (tag = -4) OR (tag = -7) THEN n := Number(r) END;
      RETURN r.valid & (tag = -10) (* OPT.NoTyp *)
    END;
    INC(r.depth); INC(r.refs);
    IF (r.depth > 128) OR (r.refs > 16384) THEN r.valid := FALSE; RETURN FALSE END;
    tag := Number(r); (* module index or Smname *)
    IF tag = 16 THEN ReadName(r, name)
    ELSIF tag > 0 THEN r.valid := FALSE
    END;
    ReadName(r, name); tag := Number(r);
    IF tag = 35 THEN n := Number(r); tag := Number(r) END; (* Ssys *)
    CASE SHORT(tag) OF
    | 36, 38: ignored := Structure(r) (* pointer, dynamic array *)
    | 37: ignored := Structure(r); n := Number(r) (* fixed array *)
    | 40: ignored := Signature(r) (* procedure type *)
    | 39: (* record: base, size, alignment, method count, fields/methods *)
      ignored := Structure(r);
      n := Number(r); n := Number(r); n := Number(r); tag := Number(r);
      WHILE r.valid & (tag # 18) DO
        CASE SHORT(tag) OF
        | 25, 26: ignored := Structure(r); ReadName(r, name); n := Number(r)
        | 27, 28, 30: n := Number(r)
        | 29: ignored := Signature(r); ReadName(r, name); n := Number(r)
        ELSE r.valid := FALSE
        END;
        tag := Number(r)
      END
    ELSE r.valid := FALSE
    END;
    DEC(r.depth);
    RETURN FALSE
  END Structure;

  PROCEDURE Enumerate*(filename, module: ARRAY OF CHAR; visit: Visitor): BOOLEAN;
    VAR f: Files.File; r: Reader; name: Name; tag, n: SYSTEM.INT64;
      command, ignored: BOOLEAN; first, last, entry: Entry; ch: CHAR;
  BEGIN
    f := Files.Old(filename);
    IF f = NIL THEN RETURN FALSE END;
    Files.Set(r.rider, f, 0); r.length := Files.Length(f);
    r.valid := TRUE; r.depth := 0; r.refs := 14; first := NIL; last := NIL;
    ch := Byte(r); IF ch # 0F7X THEN r.valid := FALSE END;
    ch := Byte(r); IF ch # 084X THEN r.valid := FALSE END;
    tag := Number(r); IF tag # 16 THEN r.valid := FALSE END;
    ReadName(r, name); IF name # module THEN r.valid := FALSE END;
    (* Link names precede the exported objects. *)
    REPEAT ReadName(r, name) UNTIL ~r.valid OR (name = "");
    WHILE r.valid & (Files.Pos(r.rider) < r.length) DO
      tag := Number(r); command := FALSE;
      WHILE r.valid & (tag = 41) DO (* exported documentation *)
        n := Number(r); Skip(r, n); tag := Number(r)
      END;
      IF (tag >= 1) & (tag <= 9) THEN
        CASE SHORT(tag) OF
        | 1, 2, 3: ch := Byte(r)
        | 4, 7: n := Number(r); n := Number(r)
        | 5: Skip(r, 4)
        | 6: Skip(r, 8)
        | 8: ReadName(r, name)
        | 9: (* NIL *)
        ELSE r.valid := FALSE
        END;
        ReadName(r, name)
      ELSIF tag = 19 THEN ignored := Structure(r)
      ELSIF (tag = 20) OR (tag = 21) OR (tag = 22) THEN
        ignored := Structure(r); ReadName(r, name)
      ELSIF (tag >= 31) & (tag <= 33) THEN
        command := Signature(r) & (tag = 31);
        IF tag = 33 THEN n := Number(r); Skip(r, n) END;
        ReadName(r, name);
        IF command & r.valid THEN
          NEW(entry); entry.name := name;
          IF last = NIL THEN first := entry ELSE last.next := entry END;
          last := entry
        END
      ELSE r.valid := FALSE
      END
    END;
    Files.Close(f);
    (* No partial results from an unsupported or corrupt symbol file. *)
    IF r.valid THEN
      entry := first;
      WHILE entry # NIL DO visit(entry.name); entry := entry.next END
    END;
    RETURN r.valid
  END Enumerate;

END CommandSymbols.
