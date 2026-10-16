MODULE Char;   (* :file: Char.Mod  --  Function procedures about ASCII characters. *)
(* VOC adaptation, 2026-10-16: retain upstream's 32-bit integer contract. *)
IMPORT ssqTypes;
TYPE INTEGER = ssqTypes.Integer;
        

PROCEDURE IsDigit*(c: CHAR): BOOLEAN;
(** Return true, if '0' <= c <= '9' *)
BEGIN
  RETURN (c >= "0") & (c <= "9")
END IsDigit;

PROCEDURE IsAlpha*(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "a") & (c <= "z") OR (c >= "A") & (c <= "Z")
END IsAlpha;

PROCEDURE IsAlphaNum*(c: CHAR): BOOLEAN;
BEGIN
  RETURN     (c >= "a") & (c <= "z")
          OR (c >= "0") & (c <= "9")
          OR (c >= "A") & (c <= "Z")
END IsAlphaNum;

PROCEDURE IsAlphaNumUs*(c: CHAR): BOOLEAN;      (** a..zA..Z0..9_ underscore *)
BEGIN
  RETURN     (c >= "a") & (c <= "z")
          OR (c >= "0") & (c <= "9")
          OR (c >= "A") & (c <= "Z")
          OR (c = '_')
END IsAlphaNumUs;

PROCEDURE IsUppercase*(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "A") & (c <= "Z")
END IsUppercase;

PROCEDURE IsLowercase*(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "a") & (c <= "z")
END IsLowercase;

PROCEDURE IsWhitespace*(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c = " ") OR (c = 9X) OR (c = 0AX) OR (c = 0DX)
END IsWhitespace;

PROCEDURE IsPrintable*(c: CHAR): BOOLEAN;
BEGIN
  RETURN     ((c >= " ") & (c <= "~"))
           OR (c = 0AX)
           OR (c = 0DX)
           OR (c = 09X)
END IsPrintable;

PROCEDURE IsMember*(s: ARRAY OF CHAR; c: CHAR): BOOLEAN;
VAR
  i: INTEGER;
  cc: CHAR;
BEGIN
  i := 0;
  LOOP
    IF i = LEN (s) THEN RETURN FALSE END;
    cc := s[i];
    IF cc = c THEN RETURN TRUE END;
    IF cc = 0X THEN RETURN FALSE END;
    INC(i)
  END
END IsMember;

(*---------------------------------------------------------------------------*)
END Char.   :file: (c) sts-q 2022-Mrz,Nov
