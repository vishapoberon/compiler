MODULE TestDTDResolver;

IMPORT Out, S := LongStrings, U := oocUnicode, Msg, URI, URIString, URIParser,
  URISchemeFile, D := XMLDTD, B := XMLUnicodeBuffer,
  R := XMLEntityResolver;

VAR
  builder: D.Builder;
  name, other, replacement, value, source, result, large: D.String;
  entity: D.Entity;
  declaration: D.Declaration;
  external: D.ExternalEntity;
  chars: D.Characters;
  att: D.AttValue;
  attr, second: D.AttrDecl;
  element: D.ElementDecl;
  enumeration: D.Enumeration;
  cp: D.CP;
  normalized: BOOLEAN;
  resolver: R.Resolver;
  base, uri: URI.URI;
  res: Msg.Msg;
  encoded: D.StringURI;
  text: ARRAY 1024 OF CHAR;
  i: LONGINT;

PROCEDURE Wide(text: ARRAY OF CHAR): D.String;
  VAR string: D.String;
BEGIN
  NEW(string, S.Length8(text)+1); S.Long(text, string^); RETURN string
END Wide;

BEGIN
  builder := D.New();
  name := Wide("lt"); declaration := builder.geNamespace.Get(name);
  entity := declaration(D.Entity);
  ASSERT((entity # NIL) & (entity.entityValue[0] = ORD("&")), 1);
  ASSERT(entity.entityValue[LEN(entity.entityValue^)-2] = B.markerEOD, 2);
  ASSERT(builder.IsValidEntityDecl(name, Wide("&#60;")), 3);
  ASSERT(~builder.IsValidEntityDecl(name, Wide("<")), 4);
  ASSERT(builder.IsValidEntityDecl(Wide("quot"), Wide('"')), 5);

  NEW(name, 3); name[0] := 531H; name[1] := 0FFFFH; name[2] := 0;
  other := D.GetStringValue(name^); ASSERT(S.Equal(other^, name^), 6);
  element := builder.NewElementDecl(name, builder.NewNameCP(D.cpOnce, Wide("EMPTY")), FALSE);
  ASSERT(element.IsEmpty() & ~element.IsElementContent(), 7);
  ASSERT(builder.elementNamespace.Add(element), 8);
  ASSERT(builder.elementNamespace.Get(other) = element, 9);
  ASSERT(~builder.elementNamespace.Add(builder.NewElementDecl(other, NIL, FALSE)), 10);
  builder.SetRootName(name); ASSERT(builder.rootName = name, 11);

  enumeration := builder.NewEnumeration(); enumeration.Append(name);
  ASSERT(enumeration.Matches(other^), 12);
  other[1] := 0FFFEH; ASSERT(~enumeration.Matches(other^), 13);
  attr := builder.NewAttrDecl(name, Wide("id"), D.attrID, NIL, D.attrRequired, NIL, FALSE);
  second := builder.NewAttrDecl(name, Wide("id2"), D.attrID, NIL, D.attrImplied, NIL, FALSE);
  builder.AddAttribute(attr); builder.AddAttribute(second); builder.AttachAttributes;
  ASSERT((element.attrNamespace.Get(attr.name) = attr) & (element.idAttr = D.undefAttr), 14);

  cp := builder.NewNameCP(D.cpOnce, Wide("#PCDATA"));
  element := builder.NewElementDecl(Wide("mixed"), builder.NewChoiceCP(D.cpRepeat0, cp), FALSE);
  ASSERT(element.contentType = D.contentMixed, 15);
  element := builder.NewElementDecl(Wide("children"), builder.NewSeqCP(D.cpOnce, cp), FALSE);
  ASSERT(element.IsElementContent(), 16);

  source := Wide("  a  b  "); chars := builder.NewCharacters(source, 0, 8, TRUE);
  source[2] := ORD("X"); ASSERT(chars.source[2] = ORD("a"), 17);
  att := builder.NewAttValue(); att.Append(chars);
  result := att.FlattenValue(TRUE, normalized);
  ASSERT(normalized & S.Equal8(result^, "a b"), 18);
  result := att.FlattenValue(FALSE, normalized);
  ASSERT(~normalized & S.Equal8(result^, "  a  b  "), 19);
  att.Clear; att.Append(builder.NewEntityRef(Wide("unknown"), NIL));
  result := att.FlattenValue(TRUE, normalized);
  ASSERT(S.Equal8(result^, "&unknown;") & (att.Length() = 9), 20);
  replacement := Wide("nested");
  entity := builder.NewInternalEntity(Wide("entity"), D.entityInternalGeneral, replacement, FALSE);
  entity.attValue := builder.NewAttValue();
  entity.attValue.Append(builder.NewCharacters(replacement, 0, 6, FALSE));
  att.Clear; att.Append(builder.NewEntityRef(entity.name, entity));
  result := att.FlattenValue(FALSE, normalized); ASSERT(S.Equal8(result^, "nested"), 21);

  base := URIParser.NewURI("file:/base/sub/document.xml", NIL, res); ASSERT(res = NIL, 22);
  external := builder.NewDocumentEntity(base);
  ASSERT(external.IsDocumentEntity() & (external.baseURI = base), 23);
  resolver := R.New();
  resolver.GetURI(NIL, NIL, base, uri, res); ASSERT((uri = NIL) & (res = NIL), 24);
  resolver.GetURI(NIL, Wide("../data file.xml"), base, uri, res);
  ASSERT((uri # NIL) & (res = NIL), 25); uri.GetString(text);
  ASSERT(text = "file:/base/data%20file.xml", 26);
  resolver.GetURI(NIL, Wide("relative.xml"), NIL, uri, res);
  ASSERT((uri = NIL) & (res # NIL), 27);

  NEW(value, 7);
  value[0] := 531H; value[1] := 0D83DH; value[2] := 0DE42H;
  value[3] := 32; value[4] := ORD("%"); value[5] := ORD("2"); value[6] := 0;
  encoded := R.NormalizeURI(value);
  ASSERT((encoded # NIL) & (encoded^ = "%D4%B1%F0%9F%99%82%20%2"), 28);
  resolver.GetURI(NIL, value, base, uri, res);
  ASSERT((uri = NIL) & (res # NIL), 29);
  value[4] := 0;
  resolver.GetURI(NIL, value, base, uri, res);
  ASSERT((uri # NIL) & (res = NIL), 30); uri.GetString(text);
  IF text # "file:/base/sub/%D4%B1%F0%9F%99%82%20" THEN Out.String(text); Out.Ln END;
  ASSERT(text = "file:/base/sub/%D4%B1%F0%9F%99%82%20", 31);
  value[0] := 0D800H; value[1] := 0;
  ASSERT(R.NormalizeURI(value) = NIL, 32);
  resolver.GetURI(NIL, value, base, uri, res);
  ASSERT((uri = NIL) & (res # NIL), 33);
  res.GetText(text); ASSERT(text = "Malformed or oversized UTF-16 system identifier", 34);
  value[0] := -1; ASSERT(R.NormalizeURI(value) = NIL, 35);
  value[0] := 10000H; ASSERT(R.NormalizeURI(value) = NIL, 36);
  value[0] := 0; encoded := R.NormalizeURI(value); ASSERT(encoded^ = "", 37);

  NEW(large, 40001);
  FOR i := 0 TO 39999 DO large[i] := 531H END; large[40000] := 0;
  encoded := R.NormalizeURI(large);
  ASSERT((encoded # NIL) & (URIString.Length(encoded^) = 240000), 38);
  FOR i := 0 TO 39999 DO
    ASSERT((encoded[6*i] = "%") & (encoded[6*i+1] = "D") &
      (encoded[6*i+2] = "4") & (encoded[6*i+3] = "%") &
      (encoded[6*i+4] = "B") & (encoded[6*i+5] = "1"), 39)
  END;
  Out.String("DTD and entity resolver checks passed"); Out.Ln
END TestDTDResolver.
