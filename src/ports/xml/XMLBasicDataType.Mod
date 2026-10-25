MODULE XMLBasicDataType;

IMPORT
  LongStrings, IntStr, Msg, URI, Parser := URIParser,
  DTD := XMLDTD, EntityResolver := XMLEntityResolver, Element := XMLBasicElement;


PROCEDURE GetIntAttr* (value: Element.AttValue; VAR number: LONGINT): BOOLEAN;
  VAR
    str: Element.String;
    str8: POINTER TO ARRAY OF CHAR;
    res: IntStr.ConvResults;
  BEGIN
    str := value. Flatten (NIL);
    NEW (str8, LongStrings.Length (str^)+1);
    LongStrings.Short (str^, "?", str8^);
    IntStr.StrToInt (str8^, number, res);
    RETURN (res = IntStr.strAllRight)
  END GetIntAttr;
  
PROCEDURE GetStringLatin1Attr* (value: Element.AttValue; VAR str: ARRAY OF CHAR): BOOLEAN;
  VAR
    v: Element.String;
    i: LONGINT;
  BEGIN
    v := value. Flatten (NIL);
    IF (LongStrings.Length (v^) >= LEN (str)) THEN
      RETURN FALSE
    ELSE
      i := -1;
      REPEAT
        INC (i);
        IF (v[i] < 0) OR (v[i] > ORD (MAX (CHAR))) THEN
          RETURN FALSE
        END
      UNTIL (v[i] = 0);
      FOR i := 0 TO LongStrings.Length (v^) DO str[i] := CHR (v[i]) END;
      RETURN TRUE
    END
  END GetStringLatin1Attr;
  
PROCEDURE GetURIAttr* (value: Element.AttValue; baseURI: URI.URI;
                       VAR uri: URI.URI): BOOLEAN;
  VAR
    str8: DTD.StringURI;
    v: Element.String;
    res: Msg.Msg;
  BEGIN
    v := value. Flatten (NIL);
    str8 := EntityResolver.NormalizeURI (v);
    IF str8 = NIL THEN uri := NIL; RETURN FALSE END;
    IF (baseURI # NIL) & (baseURI IS URI.HierarchicalURI) THEN
      uri := Parser.NewURI (str8^, baseURI(URI.HierarchicalURI), res)
    ELSE
      uri := Parser.NewURI (str8^, NIL, res)
    END;
    RETURN (res = NIL)
  END GetURIAttr;
  
END XMLBasicDataType.
