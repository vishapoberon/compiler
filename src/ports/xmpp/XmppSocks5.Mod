MODULE XmppSocks5;

(* XEP-0065 destination identifiers and incremental no-auth SOCKS5 framing. *)

IMPORT SYSTEM, S := LongStrings, T := XmppTypes, Items := XmppItems, IQ := XmppIQ, I := XmppIbb;

CONST
  greeting* = 0; method* = 1; connect* = 2; reply* = 3; ready* = 4; failed* = 5;
  packetBytes* = 47;

TYPE
  Handshake* = POINTER TO HandshakeDesc;
  HandshakeDesc* = RECORD
    state-: SHORTINT;
    output: ARRAY packetBytes OF CHAR;
    input: ARRAY packetBytes OF CHAR;
    position, have: LONGINT
  END;

PROCEDURE Add(a, b: SET): SET;
  VAR low, high: LONGINT;
BEGIN
  low := SYSTEM.VAL(LONGINT, a*{0..15})+SYSTEM.VAL(LONGINT, b*{0..15});
  high := SYSTEM.VAL(LONGINT, SYSTEM.LSH(a, -16))+SYSTEM.VAL(LONGINT, SYSTEM.LSH(b, -16))+low DIV 65536;
  RETURN SYSTEM.VAL(SET, low MOD 65536)+SYSTEM.LSH(SYSTEM.VAL(SET, high MOD 65536), 16)
END Add;

PROCEDURE Rotate(word: SET; n: LONGINT): SET;
BEGIN RETURN SYSTEM.LSH(word, n)+SYSTEM.LSH(word, n-32) END Rotate;

PROCEDURE Block(VAR bytes: ARRAY OF CHAR; at: LONGINT; VAR h: ARRAY OF SET);
  VAR w: ARRAY 80 OF SET; a, b, c, d, e, f, k, t: SET; i, j: LONGINT;
BEGIN
  FOR i := 0 TO 15 DO
    w[i] := {};
    FOR j := 0 TO 3 DO w[i] := w[i]+SYSTEM.LSH(SYSTEM.VAL(SET, LONG(ORD(bytes[at+4*i+j]))), 8*(3-j)) END
  END;
  FOR i := 16 TO 79 DO w[i] := Rotate(w[i-3]/w[i-8]/w[i-14]/w[i-16], 1) END;
  a := h[0]; b := h[1]; c := h[2]; d := h[3]; e := h[4];
  FOR i := 0 TO 79 DO
    IF i < 20 THEN f := b*c+(-b)*d; k := SYSTEM.VAL(SET, 5A827999H)
    ELSIF i < 40 THEN f := b/c/d; k := SYSTEM.VAL(SET, 6ED9EBA1H)
    ELSIF i < 60 THEN f := b*c+b*d+c*d; k := SYSTEM.VAL(SET, 08F1BBCDCH)
    ELSE f := b/c/d; k := SYSTEM.VAL(SET, 0CA62C1D6H)
    END;
    t := Add(Add(Add(Add(Rotate(a, 5), f), e), k), w[i]);
    e := d; d := c; c := Rotate(b, 30); b := a; a := t
  END;
  h[0] := Add(h[0], a); h[1] := Add(h[1], b); h[2] := Add(h[2], c); h[3] := Add(h[3], d); h[4] := Add(h[4], e)
END Block;

PROCEDURE Destination*(sid, requester, target: ARRAY OF T.CodeUnit): Items.Bytes;
  VAR a, b, c, input, result: Items.Bytes; h: ARRAY 5 OF SET;
    length, padded, i, at, bits, byte: LONGINT; hex: ARRAY 17 OF CHAR;
BEGIN
  IF ~I.SID(sid) OR (IQ.CanonicalJID(requester) = NIL) OR (IQ.CanonicalJID(target) = NIL) THEN RETURN NIL END;
  a := Items.UTF8Bytes(sid); b := Items.UTF8Bytes(requester); c := Items.UTF8Bytes(target);
  IF (a = NIL) OR (b = NIL) OR (c = NIL) THEN RETURN NIL END;
  length := S.Length8(a^)+S.Length8(b^)+S.Length8(c^); IF length > 32768 THEN RETURN NIL END;
  padded := ((length+9+63) DIV 64)*64; NEW(input, padded); at := 0;
  FOR i := 0 TO S.Length8(a^)-1 DO input[at] := a[i]; INC(at) END;
  FOR i := 0 TO S.Length8(b^)-1 DO input[at] := b[i]; INC(at) END;
  FOR i := 0 TO S.Length8(c^)-1 DO input[at] := c[i]; INC(at) END;
  FOR i := length TO padded-1 DO input[i] := 0X END;
  input[length] := 80X; bits := length*8;
  FOR i := 0 TO 3 DO input[padded-1-i] := CHR(bits MOD 256); bits := bits DIV 256 END;
  h[0] := SYSTEM.VAL(SET, 67452301H); h[1] := SYSTEM.VAL(SET, 0EFCDAB89H);
  h[2] := SYSTEM.VAL(SET, 098BADCFEH); h[3] := SYSTEM.VAL(SET, 10325476H); h[4] := SYSTEM.VAL(SET, 0C3D2E1F0H);
  at := 0; WHILE at < padded DO Block(input^, at, h); INC(at, 64) END;
  hex := "0123456789abcdef"; NEW(result, 41);
  FOR i := 0 TO 19 DO
    byte := SYSTEM.VAL(LONGINT, SYSTEM.LSH(h[i DIV 4], -8*(3-i MOD 4))*{0..7});
    result[2*i] := hex[byte DIV 16]; result[2*i+1] := hex[byte MOD 16]
  END;
  result[40] := 0X; RETURN result
END Destination;

PROCEDURE Valid*(destination: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF S.Length8(destination) # 40 THEN RETURN FALSE END;
  FOR i := 0 TO 39 DO
    IF ~(((destination[i] >= "0") & (destination[i] <= "9")) OR ((destination[i] >= "a") & (destination[i] <= "f"))) THEN RETURN FALSE END
  END;
  RETURN TRUE
END Valid;

PROCEDURE New*(destination: ARRAY OF CHAR): Handshake;
  VAR h: Handshake; i: LONGINT;
BEGIN
  IF ~Valid(destination) THEN RETURN NIL END;
  NEW(h); h.output[0] := 5X; h.output[1] := 1X; h.output[2] := 0X; h.output[3] := 3X; h.output[4] := CHR(40);
  FOR i := 0 TO 39 DO h.output[i+5] := destination[i] END;
  h.output[45] := 0X; h.output[46] := 0X; RETURN h
END New;

PROCEDURE (h: Handshake) Pending*(): LONGINT;
BEGIN
  IF h.state = greeting THEN RETURN 3-h.position ELSIF h.state = connect THEN RETURN packetBytes-h.position ELSE RETURN 0 END
END Pending;

PROCEDURE (h: Handshake) Output*(VAR bytes: ARRAY OF CHAR; start, count: LONGINT): LONGINT;
  VAR i, n: LONGINT;
BEGIN
  IF (start < 0) OR (count < 0) OR (start > LEN(bytes)) OR (count > LEN(bytes)-start) THEN RETURN -1 END;
  n := h.Pending(); IF n > count THEN n := count END;
  FOR i := 0 TO n-1 DO
    IF h.state = greeting THEN
      CASE h.position+i OF 0: bytes[start+i] := 5X | 1: bytes[start+i] := 1X ELSE bytes[start+i] := 0X END
    ELSE bytes[start+i] := h.output[h.position+i]
    END
  END;
  RETURN n
END Output;

PROCEDURE (h: Handshake) Sent*(count: LONGINT): BOOLEAN;
BEGIN
  IF (count < 0) OR (count > h.Pending()) OR ((h.state # greeting) & (h.state # connect)) THEN RETURN FALSE END;
  INC(h.position, count);
  IF h.Pending() = 0 THEN
    IF h.state = greeting THEN h.state := method ELSE h.state := reply END;
    h.position := 0; h.have := 0
  END;
  RETURN TRUE
END Sent;

PROCEDURE (h: Handshake) Needed*(): LONGINT;
BEGIN
  IF h.state = method THEN RETURN 2-h.have ELSIF h.state = reply THEN RETURN packetBytes-h.have ELSE RETURN 0 END
END Needed;

PROCEDURE (h: Handshake) Feed*(bytes: ARRAY OF CHAR; start, count: LONGINT; VAR consumed: LONGINT): SHORTINT;
  VAR n, i: LONGINT;
BEGIN
  consumed := 0;
  IF (start < 0) OR (count < 0) OR (start > LEN(bytes)) OR (count > LEN(bytes)-start) THEN h.state := failed; RETURN h.state END;
  n := h.Needed(); IF n = 0 THEN RETURN h.state END;
  IF n > count THEN n := count END;
  FOR i := 0 TO n-1 DO h.input[h.have+i] := bytes[start+i] END;
  INC(h.have, n); consumed := n;
  IF h.Needed() = 0 THEN
    IF h.state = method THEN
      IF (h.input[0] = 5X) & (h.input[1] = 0X) THEN h.state := connect; h.position := 0 ELSE h.state := failed END
    ELSE
      h.state := ready;
      IF (h.input[0] # 5X) OR (h.input[1] # 0X) OR (h.input[2] # 0X) OR (h.input[3] # 3X) THEN h.state := failed END;
      FOR i := 4 TO packetBytes-1 DO IF h.input[i] # h.output[i] THEN h.state := failed END END
    END
  END;
  RETURN h.state
END Feed;

PROCEDURE (h: Handshake) End*;
BEGIN IF h.state # ready THEN h.state := failed END END End;

END XmppSocks5.
