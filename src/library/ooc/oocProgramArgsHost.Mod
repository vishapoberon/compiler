(* Raw command-line access used by oocProgramArgs. *)
MODULE oocProgramArgsHost;

IMPORT SYSTEM, Modules;

TYPE
  Byte* = SYSTEM.BYTE;

PROCEDURE Count* (): LONGINT;
BEGIN
  RETURN Modules.ArgCount
END Count;

PROCEDURE Address(index: LONGINT): SYSTEM.ADDRESS;
  VAR address: SYSTEM.ADDRESS;
BEGIN
  ASSERT((index >= 0) & (index < Modules.ArgCount));
  SYSTEM.GET(Modules.ArgVector + index*SIZE(SYSTEM.ADDRESS), address);
  RETURN address
END Address;

PROCEDURE Length* (index: LONGINT): LONGINT;
  VAR address: SYSTEM.ADDRESS; ch: Byte; length: LONGINT;
BEGIN
  address := Address(index);
  length := 0;
  SYSTEM.GET(address, ch);
  WHILE SYSTEM.VAL(CHAR, ch) # 0X DO
    INC(length);
    SYSTEM.GET(address+length, ch)
  END;
  RETURN length
END Length;

PROCEDURE Get* (index, offset: LONGINT; VAR ch: Byte);
BEGIN
  SYSTEM.GET(Address(index)+offset, ch)
END Get;

PROCEDURE IsEol* (ch: Byte): BOOLEAN;
BEGIN
  RETURN SYSTEM.VAL(CHAR, ch) = 0AX
END IsEol;

END oocProgramArgsHost.
