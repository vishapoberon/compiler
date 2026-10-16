MODULE TLSX509Names;
IMPORT TLSBytes, TLSASN1, TLSX509;

CONST
  DNSNameTag* = 82H;      (* [2] dNSName, IA5String, primitive *)
  IPAddressTag* = 87H;    (* [7] iPAddress, OCTET STRING: 4 or 16 bytes *)

PROCEDURE Lower(ch: CHAR): CHAR;
VAR o: LONGINT;
BEGIN
  o := ORD(ch);
  IF (o >= ORD("A")) & (o <= ORD("Z")) THEN ch := CHR(o + 32) END;
  RETURN ch
END Lower;

PROCEDURE HostLen(host: ARRAY OF CHAR): LONGINT;
VAR n: LONGINT;
BEGIN
  n := 0;
  WHILE (n < LEN(host)) & (host[n] # 0X) DO INC(n) END;
  RETURN n
END HostLen;

PROCEDURE OIDIsSubjectAltName(VAR oid: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (oid.len = 3) &
         (ORD(oid.data[0]) = 55H) &
         (ORD(oid.data[1]) = 1DH) &
         (ORD(oid.data[2]) = 11H)
END OIDIsSubjectAltName;

PROCEDURE MatchExact(VAR name: TLSBytes.Buffer; host: ARRAY OF CHAR): BOOLEAN;
VAR i, hn: LONGINT; ok: BOOLEAN;
BEGIN
  hn := HostLen(host);
  ok := name.len = hn;
  i := 0;
  WHILE ok & (i < name.len) DO
    IF Lower(name.data[i]) # Lower(host[i]) THEN ok := FALSE END;
    INC(i)
  END;
  RETURN ok
END MatchExact;

PROCEDURE MatchWildcard(VAR name: TLSBytes.Buffer; host: ARRAY OF CHAR): BOOLEAN;
VAR hn, dot, i, j: LONGINT; ok: BOOLEAN;
BEGIN
  hn := HostLen(host);
  ok := FALSE;
  IF (name.len > 2) & (name.data[0] = "*") & (name.data[1] = ".") THEN
    dot := 0;
    WHILE (dot < hn) & (host[dot] # ".") DO INC(dot) END;
    i := 2; WHILE (i < name.len) & (name.data[i] # ".") DO INC(i) END;
    (* the wildcard needs two labels after it (not *.com) *)
    IF (dot > 0) & (dot < hn - 1) & (i < name.len - 1) THEN
      (* Host suffix after first dot must equal pattern after "*.". *)
      ok := (hn - dot - 1) = (name.len - 2);
      i := 2; j := dot + 1;
      WHILE ok & (i < name.len) DO
        IF Lower(name.data[i]) # Lower(host[j]) THEN ok := FALSE END;
        INC(i); INC(j)
      END
    END
  END;
  RETURN ok
END MatchWildcard;

(* b[0..3] := the dotted IPv4 address s[pos..lim): four decimal numbers 0..255, no leading zeros *)
PROCEDURE IPv4At(VAR s: ARRAY OF CHAR; pos, lim: LONGINT; VAR b: TLSBytes.Buffer): BOOLEAN;
VAR parts, v, digits: LONGINT;
BEGIN
  TLSBytes.Init(b); parts := 0;
  LOOP
    v := 0; digits := 0;
    WHILE (pos < lim) & (s[pos] >= "0") & (s[pos] <= "9") DO
      IF (digits = 1) & (v = 0) THEN RETURN FALSE END;  (* a leading zero *)
      v := v * 10 + ORD(s[pos]) - ORD("0"); INC(digits); INC(pos);
      IF v > 255 THEN RETURN FALSE END
    END;
    IF digits = 0 THEN RETURN FALSE END;
    TLSBytes.AppendByte(b, v); INC(parts);
    IF pos = lim THEN EXIT END;
    IF (s[pos] # ".") OR (parts = 4) THEN RETURN FALSE END;
    INC(pos)
  END;
  RETURN parts = 4
END IPv4At;

PROCEDURE HexVal(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch) - ORD("0")
  ELSIF (ch >= "a") & (ch <= "f") THEN RETURN ORD(ch) - ORD("a") + 10
  ELSIF (ch >= "A") & (ch <= "F") THEN RETURN ORD(ch) - ORD("A") + 10
  END;
  RETURN -1
END HexVal;

(* b := the 16 bytes of the IPv6 address s[0..n) (RFC 4291 2.2: groups, one "::", an IPv4 tail) *)
PROCEDURE IPv6(VAR s: ARRAY OF CHAR; n: LONGINT; VAR b: TLSBytes.Buffer): BOOLEAN;
VAR
  head, tail: ARRAY 8 OF LONGINT; nh, nt, pos, e, v, i, k: LONGINT; dc, dot: BOOLEAN; v4: TLSBytes.Buffer;

  PROCEDURE Add(x: LONGINT): BOOLEAN;
  BEGIN
    IF nh + nt >= 8 THEN RETURN FALSE END;
    IF dc THEN tail[nt] := x; INC(nt) ELSE head[nh] := x; INC(nh) END;
    RETURN TRUE
  END Add;

BEGIN
  nh := 0; nt := 0; dc := FALSE; pos := 0;
  IF n < 2 THEN RETURN FALSE END;
  IF s[0] = ":" THEN
    IF s[1] # ":" THEN RETURN FALSE END;
    dc := TRUE; pos := 2
  END;
  WHILE pos < n DO
    e := pos; dot := FALSE;
    WHILE (e < n) & (s[e] # ":") DO IF s[e] = "." THEN dot := TRUE END; INC(e) END;
    IF dot THEN  (* the last 32 bits as IPv4 *)
      IF (e # n) OR ~IPv4At(s, pos, n, v4) THEN RETURN FALSE END;
      IF ~Add(ORD(v4.data[0]) * 256 + ORD(v4.data[1])) OR ~Add(ORD(v4.data[2]) * 256 + ORD(v4.data[3])) THEN RETURN FALSE END;
      pos := n
    ELSE
      IF (e = pos) OR (e - pos > 4) THEN RETURN FALSE END;
      v := 0; i := pos;
      WHILE i < e DO k := HexVal(s[i]); IF k < 0 THEN RETURN FALSE END; v := v * 16 + k; INC(i) END;
      IF ~Add(v) THEN RETURN FALSE END;
      pos := e;
      IF pos < n THEN  (* s[pos] = ":" *)
        INC(pos);
        IF pos = n THEN RETURN FALSE END;  (* a single ":" at the end *)
        IF s[pos] = ":" THEN
          IF dc THEN RETURN FALSE END;
          dc := TRUE; INC(pos)
        END
      END
    END
  END;
  IF dc & (nh + nt > 7) OR ~dc & (nh + nt # 8) THEN RETURN FALSE END;
  TLSBytes.Init(b);
  i := 0; WHILE i < nh DO TLSBytes.PutBE16(b, head[i]); INC(i) END;
  i := nh + nt; WHILE i < 8 DO TLSBytes.PutBE16(b, 0); INC(i) END;
  i := 0; WHILE i < nt DO TLSBytes.PutBE16(b, tail[i]); INC(i) END;
  RETURN TRUE
END IPv6;

(** host is an IP address (IPv4 dotted, or IPv6 without brackets): addr its 4 or 16 bytes *)
PROCEDURE ParseIP*(host: ARRAY OF CHAR; VAR addr: TLSBytes.Buffer): BOOLEAN;
VAR n, i: LONGINT; colon: BOOLEAN;
BEGIN
  TLSBytes.Init(addr);
  n := HostLen(host); colon := FALSE;
  i := 0; WHILE i < n DO IF host[i] = ":" THEN colon := TRUE END; INC(i) END;
  IF colon THEN RETURN IPv6(host, n, addr) END;
  RETURN (n > 0) & IPv4At(host, 0, n, addr)
END ParseIP;

PROCEDURE DNSNameMatches*(VAR name: TLSBytes.Buffer; host: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN MatchExact(name, host) OR MatchWildcard(name, host)
END DNSNameMatches;

PROCEDURE ExtractExtensionsFromTBS*(VAR tbs: TLSBytes.Buffer; VAR extensions: TLSBytes.Buffer): BOOLEAN;
VAR
  pos, lim, xp: LONGINT;
  t: TLSASN1.TLV;
  ok, found: BOOLEAN;
BEGIN
  TLSBytes.Init(extensions);
  pos := 0;
  ok := TLSASN1.EnterSequence(tbs, pos, tbs.len, pos, lim);

  IF ok THEN
    IF TLSASN1.PeekTLV(tbs, pos, lim, t) THEN
      IF t.tag = TLSASN1.Ctx0 THEN
        ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Ctx0, t)
      END
    ELSE
      ok := FALSE
    END
  END;

  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Integer, t) END;       (* serial *)
  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Sequence, t) END;      (* signature *)
  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Sequence, t) END;      (* issuer *)
  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Sequence, t) END;      (* validity *)
  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Sequence, t) END;      (* subject *)
  IF ok THEN ok := TLSASN1.ExpectTag(tbs, pos, lim, TLSASN1.Sequence, t) END;      (* spki *)

  found := FALSE;
  WHILE ok & (pos < lim) & ~found DO
    IF ~TLSASN1.ReadTLV(tbs, pos, lim, t) THEN
      ok := FALSE
    ELSE
      IF t.tag = TLSASN1.Ctx3 THEN
        (* Extensions is [3] EXPLICIT SEQUENCE OF Extension. *)
        xp := t.val;
        IF ~TLSASN1.ExpectTag(tbs, xp, t.next, TLSASN1.Sequence, t) THEN
          ok := FALSE
        ELSE
          TLSBytes.Slice(tbs, t.val, t.len, extensions);
          found := TRUE
        END
      END
    END
  END;
  RETURN ok & found
END ExtractExtensionsFromTBS;

PROCEDURE FindExtension*(VAR extensions: TLSBytes.Buffer; VAR wantOID: TLSBytes.Buffer; VAR extValue: TLSBytes.Buffer): BOOLEAN;
VAR
  pos, ep, elim: LONGINT;
  ext, oidTLV, valTLV: TLSASN1.TLV;
  oid: TLSBytes.Buffer;
  ok, found, dummy: BOOLEAN;
BEGIN
  TLSBytes.Init(extValue);
  pos := 0; found := FALSE; ok := TRUE;
  WHILE ok & (pos < extensions.len) & ~found DO
    IF ~TLSASN1.ExpectTag(extensions, pos, extensions.len, TLSASN1.Sequence, ext) THEN
      ok := FALSE
    ELSE
      ep := ext.val; elim := ext.next;
      IF ~TLSASN1.ExpectTag(extensions, ep, elim, TLSASN1.ObjectIdentifier, oidTLV) THEN
        ok := FALSE
      ELSE
        dummy := TLSASN1.CopyValue(extensions, oidTLV, oid);
        IF dummy & TLSBytes.EqualConstTime(oid, wantOID) THEN
          IF TLSASN1.PeekTLV(extensions, ep, elim, valTLV) THEN
            IF valTLV.tag = TLSASN1.Boolean THEN
              ok := TLSASN1.ExpectTag(extensions, ep, elim, TLSASN1.Boolean, valTLV)
            END
          ELSE
            ok := FALSE
          END;
          IF ok THEN
            IF ~TLSASN1.ExpectTag(extensions, ep, elim, TLSASN1.OctetString, valTLV) THEN
              ok := FALSE
            ELSE
              dummy := TLSASN1.CopyValue(extensions, valTLV, extValue);
              IF dummy THEN found := TRUE ELSE ok := FALSE END
            END
          END
        END
      END
    END
  END;
  RETURN ok & found
END FindExtension;

PROCEDURE SubjectAltNameValue*(VAR info: TLSX509.CertInfo; VAR sanValue: TLSBytes.Buffer): BOOLEAN;
VAR exts, oid: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(sanValue);
  TLSBytes.Init(oid);
  TLSBytes.AppendByte(oid, 55H); TLSBytes.AppendByte(oid, 1DH); TLSBytes.AppendByte(oid, 11H);
  IF ~ExtractExtensionsFromTBS(info.tbs, exts) THEN RETURN FALSE END;
  RETURN FindExtension(exts, oid, sanValue)
END SubjectAltNameValue;

(** a name of the subjectAltName sanValue is host: an iPAddress equal to it if host is an IP
  address, else a dNSName matching it (wildcards: DNSNameMatches); sawDNS: there is a dNSName *)
PROCEDURE SubjectAltNameMatches*(VAR sanValue: TLSBytes.Buffer; host: ARRAY OF CHAR; VAR sawDNS: BOOLEAN): BOOLEAN;
VAR
  pos, lim, n: LONGINT;
  t: TLSASN1.TLV;
  name, ip: TLSBytes.Buffer;
  ok, matched, isIP: BOOLEAN;
  h: ARRAY 256 OF CHAR;
BEGIN
  sawDNS := FALSE; matched := FALSE; pos := 0;
  COPY(host, h); n := HostLen(h);
  IF (n > 1) & (h[n - 1] = ".") THEN h[n - 1] := 0X END;  (* the root: example.com. *)
  isIP := ParseIP(h, ip);
  ok := TLSASN1.EnterSequence(sanValue, pos, sanValue.len, pos, lim);
  WHILE ok & (pos < lim) & ~matched DO
    IF ~TLSASN1.ReadTLV(sanValue, pos, lim, t) OR ~TLSASN1.CopyValue(sanValue, t, name) THEN
      ok := FALSE
    ELSIF t.tag = DNSNameTag THEN
      sawDNS := TRUE;
      IF ~isIP & DNSNameMatches(name, h) THEN matched := TRUE END
    ELSIF t.tag = IPAddressTag THEN
      IF isIP & TLSBytes.EqualConstTime(name, ip) THEN matched := TRUE END
    END
  END;
  RETURN ok & matched
END SubjectAltNameMatches;

PROCEDURE CertMatchesHostname*(VAR der: TLSBytes.Buffer; host: ARRAY OF CHAR): BOOLEAN;
VAR info: TLSX509.CertInfo; san: TLSBytes.Buffer; sawDNS: BOOLEAN; ok: BOOLEAN;
BEGIN
  ok := TLSX509.ParseCertificate(der, info);
  IF ok THEN ok := SubjectAltNameValue(info, san) END;
  IF ok THEN ok := SubjectAltNameMatches(san, host, sawDNS) END;
  RETURN ok
END CertMatchesHostname;

END TLSX509Names.
