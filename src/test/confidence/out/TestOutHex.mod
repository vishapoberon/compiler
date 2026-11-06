MODULE TestOutHex;
IMPORT Out, SYSTEM;
VAR wide: HUGEINT;

PROCEDURE End;
BEGIN Out.String("|"); Out.Ln END End;

BEGIN
  Out.String("Hex(0)=|"); Out.Hex(0); End;
  Out.String("Hex(10)=|"); Out.Hex(10); End;
  Out.String("Hex(255)=|"); Out.Hex(255); End;
  Out.String("Hex(-1)=|"); Out.Hex(-1); End;
  Out.String("Hex(-2147483648)=|"); Out.Hex(-2147483648); End;
  Out.String("Hex(2147483647)=|"); Out.Hex(2147483647); End;
  Out.String("Hex(low32)=|"); wide := 10000000AH;
  IF SIZE(LONGINT) > 4 THEN Out.Hex(SYSTEM.VAL(LONGINT, wide)) ELSE Out.Hex(10) END;
  End;
  Out.String("HexDigits(10,2)=|"); Out.HexDigits(10, 2); End;
  Out.String("HexDigits(255,2)=|"); Out.HexDigits(255, 2); End;
  Out.String("HexDigits(4096,2)=|"); Out.HexDigits(4096, 2); End;
  Out.String("HexDigits(10,0)=|"); Out.HexDigits(10, 0); End;
  Out.String("HexDigits(10,-2)=|"); Out.HexDigits(10, -2); End;
  Out.String("HexDigits(0,0)=|"); Out.HexDigits(0, 0); End;
  Out.String("HexDigits(10,16)=|"); Out.HexDigits(10, 16); End;
  Out.String("HexDigits(10,20)=|"); Out.HexDigits(10, 20); End;
  Out.String("HexDigits(10,33)=|"); Out.HexDigits(10, 33); End;
  Out.String("HexDigits(-1,2)=|"); Out.HexDigits(-1, 2); End;
  Out.String("HexDigits(-1,0)=|"); Out.HexDigits(-1, 0); End;
  Out.String("HexDigits(-1,20)=|"); Out.HexDigits(-1, 20); End;
  Out.String("HexDigits(-16,2)=|"); Out.HexDigits(-16, 2); End;
  Out.String("HexDigits(min,1)=|"); Out.HexDigits(MIN(HUGEINT), 1); End;
  Out.String("HexDigits(max,1)=|"); Out.HexDigits(MAX(HUGEINT), 1); End;
  Out.String("HexDigits(10,minwidth)=|"); Out.HexDigits(10, MIN(HUGEINT)); End;
  Out.String("bytes=|");
  Out.HexDigits(0, 2); Out.HexDigits(15, 2); Out.HexDigits(16, 2); Out.HexDigits(255, 2); End
END TestOutHex.
