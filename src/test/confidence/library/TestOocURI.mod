MODULE TestOocURI;

IMPORT Out, Msg, LongStrings, oocUnicode, Channel, IOMemory, oocFiles,
  FilesHost, IntStr, TextRider, URI, URIString, URICharClass,
  URIParser, URIError, URIFragmentUnparsed, URIAuthorityServerBased,
  URIAuthorityRegistryBased, URISchemeFile, URISchemeMemory, URISchemeMailTo;

VAR
  base: URI.HierarchicalURI;
  uri, copy, relative: URI.URI;
  ref: URI.Reference;
  res: Msg.Msg;
  fragment: URI.Fragment;
  auth, authCopy: URI.Authority;
  ch, old: Channel.Channel;
  writer: Channel.Writer;
  reader: Channel.Reader;
  tw: TextRider.Writer;
  bytes: ARRAY 4 OF CHAR;
  text: ARRAY 1024 OF CHAR;
  wide: ARRAY 1024 OF oocUnicode.LONGCHAR;
  path, number: ARRAY 64 OF CHAR;
  file: URISchemeFile.URI;
  large, output: URI.StringPtr;
  i, pos: LONGINT;
  error: FilesHost.Error;

PROCEDURE Check(source, expected: ARRAY OF CHAR);
BEGIN
  ref := URIParser.NewReference(source, base, fragment, res);
  IF res # NIL THEN res.GetText(text); Out.String(text); Out.Ln END;
  ASSERT((res = NIL) & (ref # NIL), 1);
  ref.GetString(text);
  IF text # expected THEN
    Out.String(source); Out.String(" -> "); Out.String(text); Out.Ln
  END;
  ASSERT(text = expected, 2)
END Check;

PROCEDURE Bad(source: ARRAY OF CHAR);
BEGIN
  uri := URIParser.NewURI(source, base, res);
  ASSERT((uri = NIL) & (res # NIL), 3);
  res.GetLText(wide); ASSERT(LongStrings.Length(wide) > 0, 4)
END Bad;

BEGIN
  fragment := URIFragmentUnparsed.New(URIString.Copy(""));
  uri := URIParser.NewURI("http://a/b/c/d;p?q", NIL, res);
  ASSERT((res = NIL) & (uri # NIL), 5); base := uri(URI.HierarchicalURI);
  Check("g:h", "g:h");
  Check("g", "http://a/b/c/g");
  Check("./g", "http://a/b/c/g");
  Check("g/", "http://a/b/c/g/");
  Check("/g", "http://a/g");
  Check("//g", "http://g");
  Check("?y", "http://a/b/c/d;p?y");
  Check("g?y", "http://a/b/c/g?y");
  Check("#s", "#s");
  Check("g#s", "http://a/b/c/g#s");
  Check("g?y#s", "http://a/b/c/g?y#s");
  Check(";x", "http://a/b/c/;x");
  Check("g;x", "http://a/b/c/g;x");
  Check("g;x?y#s", "http://a/b/c/g;x?y#s");
  Check(".", "http://a/b/c/");
  Check("./", "http://a/b/c/");
  Check("..", "http://a/b/");
  Check("../", "http://a/b/");
  Check("../g", "http://a/b/g");
  Check("../..", "http://a/");
  Check("../../", "http://a/");
  Check("../../g", "http://a/g");
  Check("g/./h", "http://a/b/c/g/h");
  Check("g/../h", "http://a/b/c/h");
  Check("%2e/g", "http://a/b/c/%2E/g");
  Check("%2e%2e/g", "http://a/b/c/%2E%2E/g");
  Check(".;x/g", "http://a/b/c/.;x/g");
  Check("g/..;x/h", "http://a/b/c/g/..;x/h");
  Check("", "");
  Check("MAILTO:user@example.org", "MAILTO:user@example.org");
  Bad("http:/bad%"); Bad("http:/bad%A"); Bad("http:/bad%Q0");
  Bad("1http:/bad"); Bad("http:/bad path");
  Bad("file:/bad%00name");
  FOR i := 128 TO 255 DO
    ASSERT(~URICharClass.IsAlpha(CHR(i)), 42);
    text[0] := "%"; text[1] := CHR(i); text[2] := "0"; text[3] := 0X; pos := 0;
    ASSERT(~URICharClass.SkipEscaped(text, pos) & (pos = 0), 43)
  END;
  FOR i := 0 TO LEN(bytes)-1 DO bytes[i] := "x" END;
  uri := URIParser.NewURI(bytes, NIL, res);
  ASSERT((uri = NIL) & (res # NIL), 40);
  ref := URIParser.NewReference(bytes, base, fragment, res);
  ASSERT((ref = NIL) & (res # NIL), 41);
  bytes[0] := 0X;
  pos := 0; text := "%";
  ASSERT(~URICharClass.SkipEscaped(text, pos) & (pos = 0), 6);
  uri := URIParser.NewURI("relative", NIL, res);
  ASSERT((uri = NIL) & (res # NIL), 7);
  uri := URIParser.NewURI("http://a/b/c/g", NIL, res);
  relative := uri.MakeRelative(base); relative.GetString(text);
  ASSERT(text = "g", 8);
  copy := uri.Clone(); copy.GetString(text);
  ASSERT((copy # uri) & (text = "http://a/b/c/g"), 9);

  auth := URIAuthorityServerBased.New(NIL, URIString.Copy(""), -1, 80);
  res := auth.ParseAuthority(URIString.Copy("user@host.example:8080"), 10);
  ASSERT(res = NIL, 10); authCopy := auth.Clone();
  text := ""; authCopy.Append(text);
  ASSERT(text = "//user@host.example:8080", 11);
  ASSERT(authCopy(URIAuthorityServerBased.Authority).host #
         auth(URIAuthorityServerBased.Authority).host, 12);
  res := auth.ParseAuthority(URIString.Copy("1.2.3.4.5"), 0);
  ASSERT(res # NIL, 13);
  res := auth.ParseAuthority(URIString.Copy("host:65536"), 0);
  ASSERT(res # NIL, 14);
  auth := URIAuthorityRegistryBased.New(URIString.Copy(""));
  res := auth.ParseAuthority(URIString.Copy("registry%20name"), 0);
  ASSERT(res = NIL, 15); text := ""; auth.Append(text);
  ASSERT(text = "//registry%20name", 16);

  NEW(large, 40008); large[0] := "x"; large[1] := ":";
  FOR i := 2 TO 40005 DO large[i] := "a" END; large[40006] := 0X;
  uri := URIParser.NewURI(large^, NIL, res); ASSERT(res = NIL, 17);
  NEW(output, LEN(large^)); uri.GetString(output^);
  ASSERT(output^ = large^, 18);
  URIString.AppendEscaped("abc", "", bytes); ASSERT(bytes = "abc", 19);
  URIString.AppendEscaped(" ", "", bytes); ASSERT(bytes = "abc", 20);

  file := URISchemeFile.ToURI("uri space#%:name"); ASSERT(file # NIL, 21);
  file.GetString(text);
  ASSERT(URIString.Length(text) > 20, 22);
  file.GetPath(text); ASSERT(URIString.Length(text) > 15, 23);
  uri := URIParser.NewURI("file:///test%20file", NIL, res);
  ASSERT((res = NIL) & (uri # NIL), 24);
  uri(URISchemeFile.URI).GetPath(text); ASSERT(text = "/test file", 25);
  uri := URIParser.NewURI("file://remote.example/test", NIL, res);
  ASSERT(res = NIL, 26); ch := uri.GetChannel(URI.channelOld, res);
  ASSERT((ch = NIL) & (res # NIL), 27);

  path := "TestOocURI-"; IntStr.IntToStr(FilesHost.ProcessId(), number);
  URIString.Append(number, path);
  file := URISchemeFile.ToURI(path); ASSERT(file # NIL, 28);
  ch := file.GetChannel(URI.channelTmp, res); ASSERT(res = NIL, 29);
  writer := ch.NewWriter(); writer.WriteByte("A"); ch.Flush;
  ASSERT((writer.res = NIL) & (ch.res = NIL), 30);
  ch(oocFiles.File).Register; ASSERT(ch.res = NIL, 31);
  old := file.GetChannel(URI.channelOld, res); ASSERT(res = NIL, 32);
  reader := old.NewReader(); reader.ReadBytes(bytes, 0, 1);
  ASSERT((reader.res = NIL) & (bytes[0] = "A"), 33);
  old.Close; ch.Close; error := FilesHost.Remove(path); ASSERT(error = 0, 34);

  uri := URISchemeMemory.ToURI("/uri-memory"); ASSERT(uri # NIL, 35);
  ch := uri.GetChannel(URI.channelNew, res); ASSERT(res = NIL, 36);
  writer := ch.NewWriter(); writer.WriteByte("B");
  old := uri.GetChannel(URI.channelOld, res); ASSERT(res = NIL, 37);
  reader := old.NewReader(); reader.ReadBytes(bytes, 0, 1);
  ASSERT((reader.res = NIL) & (bytes[0] = "B"), 38);
  old.Close; ch.Close;

  ch := IOMemory.Tmp("", {IOMemory.read, IOMemory.write}, res);
  tw := TextRider.ConnectWriter(ch); base.WriteXML(tw); ch.Flush;
  ASSERT((tw.res = NIL) & (ch.res = NIL), 39); ch.Close;
  Out.String("URI checks passed"); Out.Ln
END TestOocURI.
