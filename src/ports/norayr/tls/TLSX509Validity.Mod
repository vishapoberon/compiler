MODULE TLSX509Validity;
IMPORT TLSBytes, TLSASN1, TLSX509;

TYPE
  Time* = RECORD
    year*, month*, day*, hour*, minute*, second*: LONGINT
  END;

PROCEDURE Digit(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN RETURN ORD(ch) - ORD("0") END;
  RETURN -1
END Digit;

PROCEDURE Two(VAR der: TLSBytes.Buffer; pos: LONGINT; VAR x: LONGINT): BOOLEAN;
VAR a, b: LONGINT;
BEGIN
  a := Digit(der.data[pos]); b := Digit(der.data[pos+1]);
  IF (a < 0) OR (b < 0) THEN RETURN FALSE END;
  x := a*10 + b;
  RETURN TRUE
END Two;

PROCEDURE Four(VAR der: TLSBytes.Buffer; pos: LONGINT; VAR x: LONGINT): BOOLEAN;
VAR a, b, c, d: LONGINT;
BEGIN
  a := Digit(der.data[pos]); b := Digit(der.data[pos+1]);
  c := Digit(der.data[pos+2]); d := Digit(der.data[pos+3]);
  IF (a < 0) OR (b < 0) OR (c < 0) OR (d < 0) THEN RETURN FALSE END;
  x := a*1000 + b*100 + c*10 + d;
  RETURN TRUE
END Four;

PROCEDURE ParseUTCTimeValue*(VAR der: TLSBytes.Buffer; pos, len: LONGINT; VAR t: Time): BOOLEAN;
VAR yy: LONGINT; ok: BOOLEAN;
BEGIN
  ok := (len >= 13) & (pos + len <= der.len);
  IF ok THEN ok := Two(der, pos, yy) END;
  IF ok THEN
    IF yy >= 50 THEN t.year := 1900 + yy ELSE t.year := 2000 + yy END;
    ok := Two(der, pos+2, t.month)
  END;
  IF ok THEN ok := Two(der, pos+4, t.day) END;
  IF ok THEN ok := Two(der, pos+6, t.hour) END;
  IF ok THEN ok := Two(der, pos+8, t.minute) END;
  IF ok THEN ok := Two(der, pos+10, t.second) END;
  IF ok THEN ok := der.data[pos+12] = "Z" END;
  RETURN ok
END ParseUTCTimeValue;

PROCEDURE ParseGeneralizedTimeValue*(VAR der: TLSBytes.Buffer; pos, len: LONGINT; VAR t: Time): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := (len >= 15) & (pos + len <= der.len);
  IF ok THEN ok := Four(der, pos, t.year) END;
  IF ok THEN ok := Two(der, pos+4, t.month) END;
  IF ok THEN ok := Two(der, pos+6, t.day) END;
  IF ok THEN ok := Two(der, pos+8, t.hour) END;
  IF ok THEN ok := Two(der, pos+10, t.minute) END;
  IF ok THEN ok := Two(der, pos+12, t.second) END;
  IF ok THEN ok := der.data[pos+14] = "Z" END;
  RETURN ok
END ParseGeneralizedTimeValue;

PROCEDURE ParseTimeTLV*(VAR der: TLSBytes.Buffer; VAR tlv: TLSASN1.TLV; VAR t: Time): BOOLEAN;
BEGIN
  IF tlv.tag = TLSASN1.UTCTime THEN
    RETURN ParseUTCTimeValue(der, tlv.val, tlv.len, t)
  ELSIF tlv.tag = TLSASN1.GeneralizedTime THEN
    RETURN ParseGeneralizedTimeValue(der, tlv.val, tlv.len, t)
  END;
  RETURN FALSE
END ParseTimeTLV;

PROCEDURE Compare*(VAR a, b: Time): LONGINT;
BEGIN
  IF a.year # b.year THEN RETURN a.year - b.year END;
  IF a.month # b.month THEN RETURN a.month - b.month END;
  IF a.day # b.day THEN RETURN a.day - b.day END;
  IF a.hour # b.hour THEN RETURN a.hour - b.hour END;
  IF a.minute # b.minute THEN RETURN a.minute - b.minute END;
  RETURN a.second - b.second
END Compare;

PROCEDURE ExtractValidity*(VAR info: TLSX509.CertInfo; VAR notBefore, notAfter: Time): BOOLEAN;
VAR pos, lim: LONGINT; t: TLSASN1.TLV; ok: BOOLEAN;
BEGIN
  pos := 0;
  ok := TLSASN1.EnterSequence(info.validity, pos, info.validity.len, pos, lim);
  IF ok THEN ok := TLSASN1.ReadTLV(info.validity, pos, lim, t) END;
  IF ok THEN ok := ParseTimeTLV(info.validity, t, notBefore) END;
  IF ok THEN ok := TLSASN1.ReadTLV(info.validity, pos, lim, t) END;
  IF ok THEN ok := ParseTimeTLV(info.validity, t, notAfter) END;
  RETURN ok
END ExtractValidity;

PROCEDURE ValidAt*(VAR info: TLSX509.CertInfo; VAR now: Time): BOOLEAN;
VAR nb, na: Time; ok: BOOLEAN;
BEGIN
  ok := ExtractValidity(info, nb, na);
  IF ok THEN ok := (Compare(now, nb) >= 0) & (Compare(now, na) <= 0) END;
  RETURN ok
END ValidAt;

PROCEDURE SetTime*(VAR t: Time; y, mo, d, h, mi, s: LONGINT);
BEGIN
  t.year := y; t.month := mo; t.day := d; t.hour := h; t.minute := mi; t.second := s
END SetTime;

END TLSX509Validity.
