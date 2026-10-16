MODULE TLSPEM;
IMPORT Base64 := TLSBase64, TLSBytes;

PROCEDURE MatchAt(VAR s: ARRAY OF CHAR; pos: LONGINT; pat: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(pat)) & (pat[i] # 0X) DO
    IF (pos + i >= LEN(s)) OR (s[pos + i] # pat[i]) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END MatchAt;

PROCEDURE Find(VAR s: ARRAY OF CHAR; pat: ARRAY OF CHAR; from: LONGINT): LONGINT;  (* VAR: s is a whole CA bundle *)
VAR p: LONGINT;
BEGIN
  p := from;
  WHILE (p < LEN(s)) & (s[p] # 0X) DO
    IF MatchAt(s, p, pat) THEN RETURN p END;
    INC(p)
  END;
  RETURN -1
END Find;

PROCEDURE StrLen(s: ARRAY OF CHAR): LONGINT;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  RETURN i
END StrLen;

PROCEDURE IsWhite(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = 0AX) OR (ch = 0DX) OR (ch = " ") OR (ch = 09X)
END IsWhite;

(* line := a label b "-----" *)
PROCEDURE Line(a, b: ARRAY OF CHAR; VAR line: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  COPY(a, line); i := StrLen(line); j := 0;
  WHILE (j < LEN(b)) & (b[j] # 0X) & (i < LEN(line) - 6) DO line[i] := b[j]; INC(i); INC(j) END;
  j := 0; WHILE j < 5 DO line[i] := "-"; INC(i); INC(j) END;
  line[i] := 0X
END Line;

(** the next PEM block with the label (as "CERTIFICATE", "EC PRIVATE KEY") in pem, from FROM on,
  decoded into der; FROM is advanced past its END line *)
PROCEDURE NextBlockDER*(VAR pem: ARRAY OF CHAR; label: ARRAY OF CHAR; VAR from: LONGINT; VAR der: TLSBytes.Buffer): BOOLEAN;
VAR
  p, q, i, j: LONGINT;
  b64: ARRAY TLSBytes.MaxLen OF CHAR;
  begin, end: ARRAY 64 OF CHAR;
BEGIN
  TLSBytes.Init(der);
  Line("-----BEGIN ", label, begin); Line("-----END ", label, end);
  p := Find(pem, begin, from);
  IF p < 0 THEN RETURN FALSE END;
  p := p + StrLen(begin);
  q := Find(pem, end, p);
  IF q < 0 THEN RETURN FALSE END;

  i := p; j := 0;
  WHILE i < q DO
    IF ~IsWhite(pem[i]) THEN
      IF j >= LEN(b64)-1 THEN RETURN FALSE END;
      b64[j] := pem[i]; INC(j)
    END;
    INC(i)
  END;
  b64[j] := 0X;
  from := q + StrLen(end);
  RETURN Base64.DecodeToBuffer(b64, der)
END NextBlockDER;

(* Extracts and decodes the next PEM certificate in text, starting at FROM.
   On success FROM is advanced past the END CERTIFICATE line. *)
PROCEDURE NextCertificateDER*(VAR pem: ARRAY OF CHAR; VAR from: LONGINT; VAR der: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN NextBlockDER(pem, "CERTIFICATE", from, der)
END NextCertificateDER;

PROCEDURE FirstCertificateDER*(VAR pem: ARRAY OF CHAR; VAR der: TLSBytes.Buffer): BOOLEAN;
VAR from: LONGINT;
BEGIN
  from := 0;
  RETURN NextCertificateDER(pem, from, der)
END FirstCertificateDER;

(** appends to text the PEM block with the label of the bytes der: "-----BEGIN label-----", the
  Base64 of der in lines of 64 characters, "-----END label-----", each line ending with LF *)
PROCEDURE Append*(label: ARRAY OF CHAR; VAR der: TLSBytes.Buffer; VAR text: ARRAY OF CHAR);
VAR line, alphabet: ARRAY 72 OF CHAR; i, j, n, v, col: LONGINT;

  PROCEDURE Put(c: CHAR);
  BEGIN IF j < LEN(text) - 1 THEN text[j] := c; INC(j) END
  END Put;

  PROCEDURE PutLine(VAR s: ARRAY OF CHAR);
  VAR k: LONGINT;
  BEGIN k := 0; WHILE s[k] # 0X DO Put(s[k]); INC(k) END; Put(0AX)
  END PutLine;

BEGIN
  alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  j := StrLen(text);
  Line("-----BEGIN ", label, line); PutLine(line);
  i := 0; col := 0; n := der.len;
  WHILE i < n DO
    v := LONG(ORD(der.data[i])) * 65536;
    IF i + 1 < n THEN v := v + LONG(ORD(der.data[i + 1])) * 256 END;
    IF i + 2 < n THEN v := v + LONG(ORD(der.data[i + 2])) END;
    Put(alphabet[v DIV 262144]); Put(alphabet[v DIV 4096 MOD 64]);
    IF i + 1 < n THEN Put(alphabet[v DIV 64 MOD 64]) ELSE Put("=") END;
    IF i + 2 < n THEN Put(alphabet[v MOD 64]) ELSE Put("=") END;
    INC(i, 3); INC(col, 4);
    IF (col = 64) OR (i >= n) THEN Put(0AX); col := 0 END
  END;
  Line("-----END ", label, line); PutLine(line);
  text[j] := 0X
END Append;

END TLSPEM.
