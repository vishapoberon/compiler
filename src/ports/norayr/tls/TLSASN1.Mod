MODULE TLSASN1;
IMPORT TLSBytes;

CONST
  Boolean*          = 01H;
  Integer*          = 02H;
  BitString*        = 03H;
  OctetString*      = 04H;
  Null*             = 05H;
  ObjectIdentifier* = 06H;
  UTF8String*       = 0CH;
  PrintableString*  = 13H;
  IA5String*        = 16H;
  UTCTime*          = 17H;
  GeneralizedTime*  = 18H;
  Sequence*         = 30H;
  Set*              = 31H;
  Ctx0*             = 0A0H;
  Ctx1*             = 0A1H;
  Ctx2*             = 0A2H;
  Ctx3*             = 0A3H;

TYPE
  TLV* = RECORD
    tag*: LONGINT;
    hdr*: LONGINT;
    val*: LONGINT;
    len*: LONGINT;
    next*: LONGINT
  END;

PROCEDURE IsConstructed*(tag: LONGINT): BOOLEAN;
BEGIN
  RETURN (tag MOD 64) >= 32
END IsConstructed;

PROCEDURE ReadLength(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR len: LONGINT): BOOLEAN;
VAR b, n, i: LONGINT;
BEGIN
  len := 0;
  IF pos >= limit THEN RETURN FALSE END;
  b := ORD(der.data[pos]); INC(pos);
  IF b < 128 THEN
    len := b;
    RETURN TRUE
  END;
  n := b - 128;
  IF (n <= 0) OR (n > 4) THEN RETURN FALSE END;
  IF pos + n > limit THEN RETURN FALSE END;
  i := 0;
  WHILE i < n DO
    len := len * 256 + ORD(der.data[pos]);
    INC(pos); INC(i)
  END;
  RETURN TRUE
END ReadLength;

PROCEDURE ReadTLV*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR t: TLV): BOOLEAN;
VAR p, l: LONGINT;
BEGIN
  t.tag := 0; t.hdr := pos; t.val := pos; t.len := 0; t.next := pos;
  IF (pos < 0) OR (pos >= limit) OR (limit > der.len) THEN RETURN FALSE END;
  p := pos;
  t.hdr := p;
  t.tag := ORD(der.data[p]); INC(p);
  IF ~ReadLength(der, p, limit, l) THEN RETURN FALSE END;
  IF (l < 0) OR (p + l > limit) THEN RETURN FALSE END;
  t.val := p;
  t.len := l;
  t.next := p + l;
  pos := t.next;
  RETURN TRUE
END ReadTLV;

PROCEDURE PeekTLV*(VAR der: TLSBytes.Buffer; pos: LONGINT; limit: LONGINT; VAR t: TLV): BOOLEAN;
VAR p: LONGINT;
BEGIN
  p := pos;
  RETURN ReadTLV(der, p, limit, t)
END PeekTLV;

PROCEDURE ExpectTag*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit, want: LONGINT; VAR t: TLV): BOOLEAN;
VAR old: LONGINT; ok: BOOLEAN;
BEGIN
  old := pos;
  ok := ReadTLV(der, pos, limit, t);
  IF ok THEN
    IF t.tag # want THEN
      pos := old;
      ok := FALSE
    END
  END;
  RETURN ok
END ExpectTag;

PROCEDURE EnterSequence*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR contentPos, contentLimit: LONGINT): BOOLEAN;
VAR t: TLV;
BEGIN
  IF ~ExpectTag(der, pos, limit, Sequence, t) THEN RETURN FALSE END;
  contentPos := t.val;
  contentLimit := t.next;
  RETURN TRUE
END EnterSequence;

PROCEDURE EnterSet*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR contentPos, contentLimit: LONGINT): BOOLEAN;
VAR t: TLV;
BEGIN
  IF ~ExpectTag(der, pos, limit, Set, t) THEN RETURN FALSE END;
  contentPos := t.val;
  contentLimit := t.next;
  RETURN TRUE
END EnterSet;

PROCEDURE EnterExplicit*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit, tag: LONGINT; VAR contentPos, contentLimit: LONGINT): BOOLEAN;
VAR t: TLV;
BEGIN
  IF ~ExpectTag(der, pos, limit, tag, t) THEN RETURN FALSE END;
  contentPos := t.val;
  contentLimit := t.next;
  RETURN TRUE
END EnterExplicit;

PROCEDURE CopyValue*(VAR der: TLSBytes.Buffer; VAR t: TLV; VAR out: TLSBytes.Buffer): BOOLEAN;
BEGIN
  IF (t.val < 0) OR (t.len < 0) OR (t.val + t.len > der.len) THEN RETURN FALSE END;
  TLSBytes.Slice(der, t.val, t.len, out);
  RETURN TRUE
END CopyValue;

PROCEDURE EqualValue*(VAR der: TLSBytes.Buffer; VAR t: TLV; bytes: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT; ok: BOOLEAN;
BEGIN
  ok := TRUE;
  i := 0;
  WHILE (i < LEN(bytes)) & (bytes[i] # 0X) DO INC(i) END;
  IF i # t.len THEN ok := FALSE END;
  i := 0;
  WHILE ok & (i < t.len) DO
    IF der.data[t.val + i] # bytes[i] THEN ok := FALSE END;
    INC(i)
  END;
  RETURN ok
END EqualValue;

PROCEDURE OIDToText*(VAR der: TLSBytes.Buffer; VAR t: TLV; VAR out: ARRAY OF CHAR);
(* Small helper for debug. It writes dotted decimal if it fits OUT. *)
VAR
  i, j, v, first, second: LONGINT;

  PROCEDURE PutCh(ch: CHAR);
  BEGIN
    IF j < LEN(out)-1 THEN out[j] := ch; INC(j) END
  END PutCh;

  PROCEDURE PutInt(x: LONGINT);
  VAR div, d: LONGINT; started: BOOLEAN;
  BEGIN
    IF x = 0 THEN PutCh("0")
    ELSE
      div := 1000000000; started := FALSE;
      WHILE div > 0 DO
        d := x DIV div;
        IF (d # 0) OR started THEN
          PutCh(CHR(ORD("0") + d));
          started := TRUE
        END;
        x := x MOD div;
        div := div DIV 10
      END
    END
  END PutInt;

BEGIN
  j := 0;
  IF (t.tag # ObjectIdentifier) OR (t.len <= 0) THEN
    out[0] := 0X;
    RETURN
  END;
  v := ORD(der.data[t.val]);
  first := v DIV 40;
  second := v MOD 40;
  PutInt(first); PutCh("."); PutInt(second);
  i := 1;
  WHILE i < t.len DO
    v := 0;
    REPEAT
      v := v * 128 + (ORD(der.data[t.val + i]) MOD 128);
      INC(i)
    UNTIL (i >= t.len) OR (ORD(der.data[t.val + i - 1]) < 128);
    PutCh("."); PutInt(v)
  END;
  out[j] := 0X
END OIDToText;

END TLSASN1.
