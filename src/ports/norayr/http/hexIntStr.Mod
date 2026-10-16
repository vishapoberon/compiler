MODULE hexIntStr;

IMPORT Conv := ConvTypes;

TYPE
  ConvResults*= Conv.ConvResults;
  (* possible values: strAllRight, strOutOfRange, strWrongFormat, strEmpty *)

CONST
  strAllRight*=Conv.strAllRight;
  strOutOfRange*=Conv.strOutOfRange;
  strWrongFormat*=Conv.strWrongFormat;
  strEmpty*=Conv.strEmpty;


(* Converts a single hexadecimal character to its integer value. Returns -1 if the character is not a valid hexadecimal digit. *)
PROCEDURE HexCharToInt(ch: CHAR): LONGINT;
BEGIN
  IF (ch >= "0") & (ch <= "9") THEN
    RETURN ORD(ch) - ORD("0")
  ELSIF (ch >= "A") & (ch <= "F") THEN
    RETURN 10 + ORD(ch) - ORD("A")
  ELSIF (ch >= "a") & (ch <= "f") THEN
    RETURN 10 + ORD(ch) - ORD("a")
  ELSE
    RETURN -1
  END
END HexCharToInt;

(* assumes that string contains hexadecimal number *)
PROCEDURE StrToInt*(str: ARRAY OF CHAR; VAR int: LONGINT; VAR res: ConvResults);
VAR
  i, digitValue: LONGINT;
BEGIN
  int := 0;
  res := strEmpty;
  i := 0;

  (* Skip leading spaces *)
  WHILE (i < LEN(str)) & (str[i] = ' ') DO INC(i) END;

  IF i < LEN(str) THEN
    res := strWrongFormat;
    WHILE (i < LEN(str)) & (str[i] # 0X) DO
      digitValue := HexCharToInt(str[i]);
      IF digitValue = -1 THEN
        RETURN
      END;
      int := int * 16 + digitValue;
      INC(i);
      res := strAllRight;
    END;
  END;
END StrToInt;

END hexIntStr.

