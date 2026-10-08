MODULE SharedProvider;
  IMPORT Out;
  TYPE Token* = RECORD value*: LONGINT END;
  VAR count: LONGINT;
  PROCEDURE Next*(): LONGINT;
  BEGIN INC(count); RETURN count END Next;
BEGIN Out.String("provider initialized"); Out.Ln
END SharedProvider.
