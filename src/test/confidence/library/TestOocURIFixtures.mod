MODULE TestOocURIFixtures;

IMPORT
  Args, Out, TextRider, Channel, IOMemory, Strings := URIString,
  URI, Error := URIError, String := URIString, Parser := URIParser,
  CurrentDoc := URISchemeCurrentDoc, Unparsed := URIFragmentUnparsed,
  File := URISchemeFile, URISchemeMailTo,
  Hierarchical := URISchemeHierarchical, ServerBased := URIAuthorityServerBased,
  Query := URIQueryUnparsed;

TYPE
  HTTP = POINTER TO HTTPDesc;
  HTTPDesc = RECORD (Hierarchical.GenericDesc) END;

VAR
  uriArg, baseArg, msgText, str: ARRAY 1024 OF CHAR;
  res: Error.Msg;
  uri: URI.URI;
  baseURI: URI.HierarchicalURI;
  relative: URI.URI;
  ref: URI.Reference;
  w: TextRider.Writer;
  fragmentPrototype: URI.Fragment;
  abs2rel: BOOLEAN;
  http: HTTP;
  output: IOMemory.Channel;
  reader: Channel.Reader;
  byte: CHAR;
  i: LONGINT;

PROCEDURE (http: HTTP) NewAuthority(): URI.Authority;
BEGIN RETURN ServerBased.New(NIL, String.Copy(""), -1, 80) END NewAuthority;

PROCEDURE (http: HTTP) NewQuery(): URI.Query;
BEGIN RETURN Query.New(String.Copy("")) END NewQuery;

PROCEDURE (http: HTTP) Clone(): URI.URI;
  VAR copy: HTTP;
BEGIN NEW(copy); http.Copy(copy); RETURN copy END Clone;


PROCEDURE RegisterSchemes;
  BEGIN
    NEW(http); Hierarchical.Init(http, String.Copy("http"), NIL, NIL);
    URI.RegisterScheme(http)
  END RegisterSchemes;

PROCEDURE WriteQuotedI (w: TextRider.Writer; str: ARRAY OF CHAR; s, e: LONGINT);
  VAR
    last: LONGINT;
  BEGIN
    WHILE (s # e) DO
      last := s;
      WHILE (s # e) &
            (str[s] # "&") & (str[s] # "<") & (str[s] # ">") & 
            (str[s] # 09X) & (str[s] # 0AX) & (str[s] # 0DX) DO
        INC (s)
      END;
      w. byteWriter. WriteBytes (str, last, s-last);
      IF (s # e) THEN
        CASE str[s] OF
        | "&": w. WriteString ("&amp;")
        | "<": w. WriteString ("&lt;")
        | ">": w. WriteString ("&gt;")
        | 09X: w. WriteString ("&#9;")
        | 0AX: w. WriteString ("&#10;")
        | 0DX: w. WriteString ("&#13;")
        END;
        INC (s)
      END
    END
  END WriteQuotedI;

PROCEDURE WriteQuoted (w: TextRider.Writer; str: ARRAY OF CHAR);
  BEGIN
    WriteQuotedI (w, str, 0, Strings.Length (str))
  END WriteQuoted;

BEGIN
  RegisterSchemes;
  fragmentPrototype := Unparsed.New (String.Copy (""));
  
   IF (Args.argc = 1) OR (Args.argc > 4) THEN
    Out.String ("Usage: TestOocURIFixtures <uri> [<base-uri> [abs2rel]]"); Out.Ln;
    HALT (1)
  ELSE
    Args.Get(1, uriArg);
    
    res := NIL; baseURI := NIL;
    IF (Args.argc > 2) THEN
      Args.Get(2, baseArg);
      uri := Parser.NewURI (baseArg, NIL, res);
      IF (res # NIL) THEN
        (* oops, failed to create URI object *)
      ELSIF (uri IS CurrentDoc.CurrentDoc) THEN
        baseURI := NIL
      ELSIF ~(uri IS URI.HierarchicalURI) THEN
        Out.String ("Error: Base URI is not hierarchical"); Out.Ln;
        HALT (1)
      ELSE
        baseURI := uri(URI.HierarchicalURI)
      END
    END;
    abs2rel := (Args.argc > 3);
    
    IF (res = NIL) THEN
      ref := Parser.NewReference (uriArg, baseURI, fragmentPrototype, res)
    END;
    
    IF res # NIL THEN res.GetText(msgText); Out.String(msgText); Out.Ln; HALT(1) END;
    output := IOMemory.Tmp("", {IOMemory.read, IOMemory.write}, res); ASSERT(res = NIL);
    w := TextRider.ConnectWriter (output);
    w. WriteString ("<?xml version='1.0' encoding='ISO-8859-1' standalone='yes'?>"); w. WriteLn;
    
    IF (res = NIL) & abs2rel THEN
      relative := ref. uri(URI.HierarchicalURI). MakeRelative (baseURI);
      
      w. WriteString ("<test-absolute-to-relative>");
      relative. WriteXML (w);
      w. WriteLn;
      w. WriteString ("<uri-string>");
      relative. GetString (str);
      WriteQuoted (w, str);
      w. WriteString ("</uri-string>");
      w. WriteLn;
      w. WriteString ("</test-absolute-to-relative>");
      w. WriteLn
    ELSIF (res = NIL) THEN
      w. WriteString ("<test-parse-uri>");
      ref. WriteXML (w);
      w. WriteLn;
      w. WriteString ("<uri-string>");
      ref. GetString (str);
      WriteQuoted (w, str);
      w. WriteString ("</uri-string>");
      w. WriteLn;
      w. WriteString ("</test-parse-uri>");
      w. WriteLn
    END;
    
    IF (res # NIL) THEN
      res. GetText (msgText);
      Out.String ("Error: ");
      Out.String (msgText);
      Out.Ln;
      HALT (1)
    END;
    ASSERT((w.res = NIL) & (w.byteWriter.res = NIL));
    reader := output.NewReader();
    FOR i := 0 TO output.Length()-1 DO reader.ReadByte(byte); Out.Char(byte) END;
    output.Close
  END
END TestOocURIFixtures.
