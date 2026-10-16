MODULE StringList;
(* Oberon implementation without methods *)
IMPORT Files, Out, Strings, List, strTypes, strUtils;

TYPE

      TObject* = List.TObject;
  TObjectDesc* = List.TObjectDesc;
       pstring* = strTypes.pstring;
       pstrings* = strTypes.pstrings;

  TString* = POINTER TO TStringDesc;

  TStringDesc =RECORD (TObjectDesc)
      str* : pstring
  END;

     Node* = List.Node;
 NodeDesc* = List.NodeDesc;

      TList* = List.TList;

      TStringList* = POINTER TO TStringListDesc;

      TStringListDesc* = RECORD (List.TListDesc)
   IndexOf* : PROCEDURE (VAR l : TStringList; s : ARRAY OF CHAR) : LONGINT;
       AddString* : PROCEDURE (l : TStringList; s : ARRAY OF CHAR) : LONGINT;
    AppendString* : PROCEDURE (l : TStringList; s : ARRAY OF CHAR);
       GetString* : PROCEDURE (l : TStringList; i: LONGINT): pstring;
       Dump*      : PROCEDURE (l : TStringList; name: ARRAY OF CHAR);
      END;

 PROCEDURE Copy*(VAR s, d: TString);
 BEGIN
   IF s.str # NIL THEN
     NEW(d);
     NEW(d.str, Strings.Length(s.str^)+1);
     COPY(s.str^, d.str^)
   END
 END Copy;

 PROCEDURE pstringFromString*(s: ARRAY OF CHAR; VAR p: pstring);
 VAR
   l: LONGINT;
 BEGIN
   l := Strings.Length(s)+1;
   NEW(p, l);
   COPY(s, p^);
 END pstringFromString;

 PROCEDURE TStringFromString*(s: ARRAY OF CHAR; VAR d: TString);
 BEGIN
   NEW(d);
   NEW(d.str, Strings.Length(s)+1);
   COPY(s, d.str^)
 END TStringFromString;

PROCEDURE IndexOf*(VAR l: TStringList; s: ARRAY OF CHAR): LONGINT;
VAR
  i: LONGINT;
  found: BOOLEAN;
  e: Node;
  tagStr: pstring;
BEGIN
  found := FALSE;
  e := l.First;
  i := 0;

  WHILE (e # NIL) & (i < l.Count) & ~found DO
    IF e.obj # NIL THEN
      tagStr := e.obj(TString).str;

      (* Debugging output to see the comparison process *)
      (*
      Out.String("Traversing node ["); Out.Int(i, 0); Out.String("]: '");
      Out.String(tagStr^);
      Out.String("'. Comparing with '"); Out.String(s); Out.String("': ");
      *)
      IF strUtils.Compare(tagStr^, s) = strUtils.equal THEN
        (*Out.String("Equal"); Out.Ln;*)
        found := TRUE;
      (*
      ELSE
        Out.String("Not Equal"); Out.Ln;
      *)
      END;
    ELSE
      Out.String("Node object is NIL, skipping comparison."); Out.Ln;
    END;

    e := e.next;
    INC(i);
  END;

  IF found THEN
    (*Out.String("IndexOf returned index: "); Out.Int(i-1, 0); Out.Ln; *)  (* Adjust to return 0-based index *)
    RETURN i-1;
  ELSE
    RETURN -1;
  END;
END IndexOf;

PROCEDURE DeleteNode*(l: TList; n: Node): BOOLEAN;
BEGIN
  RETURN List.DeleteNode(l, n)
END DeleteNode;

 PROCEDURE GetString*(l : TStringList; i: LONGINT ): pstring;
 VAR
   e: Node;
   p: pstring;
 BEGIN
    e := l.Get(l, i);
    IF (e = NIL) OR (e.obj = NIL) THEN RETURN NIL END;
   p := e.obj(TString).str;
   RETURN p
 END GetString;

 PROCEDURE AddString*(l: TStringList; s: ARRAY OF CHAR): LONGINT;
 VAR
   str: TString;
   i: LONGINT;
 BEGIN
   NEW(str);
   NEW(str.str, Strings.Length(s)+1);
   COPY(s, str^.str^);

   i := l.Add(l, str);  (* Add the tag as a new node in the list *)

   (* Debugging: Output the added string and the list node info *)
   (*Out.String("Added string to TStringList: '"); Out.String(s); Out.String("' at index "); Out.Int(i, 0); Out.Ln;*)

   RETURN i;
 END AddString;

 PROCEDURE AppendString*(l : TStringList; s : ARRAY OF CHAR);
 VAR
   str : TString;
 BEGIN
    NEW(str);
    NEW(str.str, Strings.Length(s)+1);
    COPY (s, str^.str^); (*str^.str^ := s;*)
    l.Append (l, str);
 END AppendString;

PROCEDURE DumpOut*(VAR s : TStringList);
VAR e : Node;
    i : LONGINT;
BEGIN
   NEW(e);
   i := 0;
   WHILE i < s.Count DO
      e := s.Get(s, i);
      IF e # NIL THEN Out.String (e.obj(TString).str^); Out.Ln END;
      (*Out.String (e.string); Out.Ln;*)
      INC(i);
   END;
END DumpOut;

 PROCEDURE Dump*(l: TStringList; name: ARRAY OF CHAR);
 VAR
   F : Files.File;
   R : Files.Rider;
   e : Node;
   i : LONGINT;
   eol: ARRAY 1 OF CHAR;
 BEGIN
   eol[0] := 0AX;
   F := Files.New(name);
   Files.Set(R, F, 0);
   NEW(e);
   i := 0;
   WHILE i < l.Count DO
     e := l.Get(l, i);
     IF e # NIL THEN
       Files.WriteBytes(R, e.obj(TString).str^, Strings.Length(e.obj(TString).str^));
       Files.WriteBytes(R, eol, 1);
     END;
     INC(i)
   END;
   Files.Register(F);
 END Dump;

 PROCEDURE Create* () : TStringList;
    VAR l : TStringList;
 BEGIN
    NEW(l);
    l.First   := NIL;
    l.Last    := NIL;
    l.Count   := 0;
    l.Add     := List.Add;
    l.Append  := List.Append;
    l.AppendList  := List.AppendList;
    l.Dump    := Dump;
    l.Clear   := List.Clear;
    l.Free    := List.Free;
    l.Insert  := List.Insert;
    l.Delete  := List.Delete;
l.DeleteNode  := DeleteNode;
    l.Empty   := List.Empty;
    l.Get     := List.Get;
    l.res     := TRUE;
  l.AddString := AddString;
l.AppendString:= AppendString;
  l.GetString := GetString;
    l.IndexOf := IndexOf;
    RETURN(l);
 END Create;

PROCEDURE StringListTopstrings*(VAR s: TStringList; VAR d: pstrings);
VAR
  e  : Node;
  i  : LONGINT;
BEGIN
  IF s.Count = 0 THEN d := NIL; RETURN END;
  NEW(d, s.Count);
  i := 0;
  WHILE i < s.Count DO
    e := s.Get(s, i);
    d[i] := e.obj(TString).str;
    INC(i)
  END;
END StringListTopstrings;

PROCEDURE list*(VAR s : TStringList);
VAR e : Node;
    i : LONGINT;
BEGIN
   NEW(e);
   i := 0;
   WHILE i < s.Count DO
      e := s.Get(s, i);
      IF e # NIL THEN Out.String (e.obj(TString).str^); Out.Ln END;
      (*Out.String (e.string); Out.Ln;*)
      INC(i);
   END;
END list;


END StringList.
