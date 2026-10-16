MODULE bdStrings;
CONST
  nullChar* = 0X;
  escVal*   = 0FFX;

TYPE
  chararr = ARRAY 2 OF CHAR;

(* Set null terminator at position e and update encoding *)
PROCEDURE terminate*(VAR s: ARRAY OF CHAR; e: LONGINT);
VAR
  upb, d: LONGINT;
BEGIN
  upb := LEN(s) - 1;
  IF (upb < 0) OR (e < 0) OR (e > upb) THEN RETURN END;

  s[e] := nullChar;  (* Set terminator *)
  (* The upstream metadata encodes positions in 16 bits. Larger containers
     retain ordinary termination and use a bounded scan in eos. *)
  IF upb > 65535 THEN RETURN END;
  d := upb - e;

  IF d <= 254 THEN
    (* One-byte encoding *)
    s[upb] := CHR(d)
  ELSIF (upb >= 2) & (e <= 65535) THEN
    (* Two-byte encoding - only if position <= 65535 *)
    s[upb] := escVal;
    s[upb-2] := CHR(e DIV 256);
    s[upb-1] := CHR(e MOD 256)
  END
  (* Else: container too small or position too large, leave as-is *)
END terminate;

(* Returns index of null terminator or LEN(s) if full *)
PROCEDURE eos*(VAR s: ARRAY OF CHAR): LONGINT;
VAR
  upb, pos, d: LONGINT;
BEGIN
  upb := LEN(s) - 1;
  IF upb < 0 THEN RETURN 0 END;  (* Empty container *)
  IF upb > 65535 THEN
    pos := 0;
    WHILE (pos <= upb) & (s[pos] # nullChar) DO INC(pos) END;
    RETURN pos
  END;

  IF s[upb] = escVal THEN
    (* Two-byte encoding *)
    IF upb >= 2 THEN
      pos := ORD(s[upb-2]) * 256 + ORD(s[upb-1]);
      IF (pos >= 0) & (pos <= upb) & (s[pos] = nullChar) THEN
        RETURN pos
      END;
    END;
    RETURN upb + 1  (* Invalid encoding -> full string *)
  ELSE
    (* One-byte encoding *)
    d := ORD(s[upb]);
    pos := upb - d;
    IF (pos >= 0) & (pos <= upb) & (s[pos] = nullChar) THEN
      RETURN pos
    END;
    RETURN upb + 1  (* Not properly terminated -> full *)
  END
END eos;

PROCEDURE length*(VAR s: ARRAY OF CHAR): LONGINT;
BEGIN
  RETURN eos(s)
END length;

(* Initialize as empty string *)
PROCEDURE init*(VAR s: ARRAY OF CHAR);
BEGIN
  IF LEN(s) > 0 THEN
    s[0] := nullChar;
    terminate(s, 0)
  END
END init;

PROCEDURE isEmpty*(VAR s: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN (LEN(s) = 0) OR (s[0] = nullChar)
END isEmpty;


(* Convert standard null-term string to BD encoding *)
PROCEDURE accept*(VAR s: ARRAY OF CHAR);
VAR
  i, upb: LONGINT;
BEGIN
  upb := LEN(s) - 1;
  i := 0;
  WHILE (i <= upb) & (s[i] # nullChar) DO
    INC(i)
  END;
  IF (i <= upb) & (s[i] = nullChar) THEN
    terminate(s, i)
  END
END accept;

(* Copy sr to sl with truncation if needed *)
PROCEDURE assign*(VAR sl: ARRAY OF CHAR; sr: ARRAY OF CHAR);
VAR
  i, upb: LONGINT;
BEGIN
  upb := LEN(sl) - 1;
  i := 0;
  WHILE (i <= upb) & (i < LEN(sr)) & (sr[i] # nullChar) DO
    sl[i] := sr[i];
    INC(i)
  END;

  IF i <= upb THEN
    sl[i] := nullChar;
    terminate(sl, i)
  ELSIF upb >= 0 THEN
    (* Full string, no terminator *)
    terminate(sl, upb + 1)  (* Invalidate encoding *)
  END
END assign;

(* Append sr to sl *)
PROCEDURE append*(VAR sl: ARRAY OF CHAR; sr: ARRAY OF CHAR);
VAR
  start, i, upb: LONGINT;
BEGIN
  upb := LEN(sl) - 1;
  IF upb < 0 THEN RETURN END;

  start := eos(sl);
  IF start > upb THEN RETURN END;  (* Full string *)

  i := 0;
  WHILE (start <= upb) & (i < LEN(sr)) & (sr[i] # nullChar) DO
    sl[start] := sr[i];
    INC(start);
    INC(i)
  END;

  IF start <= upb THEN
    sl[start] := nullChar;
    terminate(sl, start)
  END
END append;

(* Append single character *)
PROCEDURE appendChar*(VAR s: ARRAY OF CHAR; ch: CHAR);
VAR
  pos, upb: LONGINT;
BEGIN
  upb := LEN(s) - 1;
  IF upb < 0 THEN RETURN END;

  pos := eos(s);
  IF pos > upb THEN RETURN END;  (* Full *)

  s[pos] := ch;
  IF pos < upb THEN
    s[pos+1] := nullChar;
    terminate(s, pos+1)
  END
END appendChar;

(* Get next character with position counter *)
PROCEDURE nextChar*(VAR s: ARRAY OF CHAR; VAR pos: LONGINT): CHAR;
VAR
  e: LONGINT;
BEGIN
  e := eos(s);
  IF pos < 0 THEN RETURN nullChar END;
  IF pos < e THEN
    INC(pos);
    RETURN s[pos-1]
  ELSIF pos = e THEN
    INC(pos);
    RETURN nullChar
  ELSE
    RETURN nullChar
  END
END nextChar;

(* Append until specific character *)
PROCEDURE appendUpTo*(
  VAR sl: ARRAY OF CHAR;
  sr: ARRAY OF CHAR;
  VAR pos: LONGINT;
  ch: CHAR
);
VAR
  start, i, upb: LONGINT;
BEGIN
  upb := LEN(sl) - 1;
  start := eos(sl);
  IF start > upb THEN RETURN END;  (* Full *)

  i := pos;
  IF i < 0 THEN RETURN END;
  WHILE (i < LEN(sr)) & (sr[i] # nullChar) & (sr[i] # ch) DO
    IF start <= upb THEN
      sl[start] := sr[i];
      INC(start)
    END;
    INC(i)
  END;

  pos := i;  (* Update position *)
  IF start <= upb THEN
    sl[start] := nullChar;
    terminate(sl, start)
  END
END appendUpTo;


END bdStrings.
