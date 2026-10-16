MODULE List;
(* Oberon implementation without methods *)
IMPORT Out;
TYPE
     TObject* = POINTER TO TObjectDesc;
 TObjectDesc* = RECORD
   END;

        Node* = POINTER TO NodeDesc;
    NodeDesc* = RECORD
         obj* : TObject;
        next* : Node;
        prev* : Node;
    END;

       TList* = POINTER TO TListDesc;

   TListDesc* = RECORD (TObjectDesc)
      Create* : PROCEDURE () : TList;
        Free* : PROCEDURE (l : TList);
       Clear* : PROCEDURE (l : TList);
         Add* : PROCEDURE (l : TList; s : TObject) : LONGINT;
      Append* : PROCEDURE (l : TList; s : TObject);
  AppendList* : PROCEDURE (src, dst : TList);
      Insert* : PROCEDURE (l : TList; i : LONGINT; s : TObject);
      Delete* : PROCEDURE (l : TList; i : LONGINT);
  DeleteNode* : PROCEDURE (l : TList; n : Node): BOOLEAN;
       Empty* : PROCEDURE (l : TList) : BOOLEAN;
         Get* : PROCEDURE (l : TList; k : LONGINT) : Node;
First*, Last* : Node;
         res* : BOOLEAN;
       Count* : LONGINT;
   END;

 PROCEDURE Add* ( l : TList; s : TObject) : LONGINT;
 VAR
   e : Node;
 BEGIN
    l.res := FALSE;
    NEW(e);
    e.obj := s;
    e.prev := NIL;
    e.next := NIL;
    IF l.First = NIL THEN
       l.First := e;
       e.prev  := NIL
    ELSE
       e.prev := l.Last;
       l.Last.next := e;
    END;
    l.Last := e;
    l.Last.next := NIL;
    INC(l.Count);
    l.res := TRUE;
    RETURN (l.Count - 1);
 END Add;

 PROCEDURE Append* (l : TList; s : TObject);
 VAR e : Node;
 BEGIN
    l.res := FALSE;
    NEW(e);
    e.obj := s;
    e.prev := NIL;
    e.next := NIL;
    IF l.First = NIL THEN
       l.First := e;
       e.prev  := NIL;
    ELSE
       e.prev := l.Last;
       l.Last.next := e;
    END;
    l.Last := e;
    l.Last.next := NIL;
    INC(l.Count);
    l.res := TRUE
 END Append;

  PROCEDURE AppendList* (s, l : TList);
  VAR e : Node;
      i, count : LONGINT;
 BEGIN
   l.res := FALSE;
    IF s # NIL THEN
      count := s.Count;
      i := 0;
      WHILE i < count DO
       e := s.Get(s, i);
       IF e # NIL THEN
         l.Append(l, e.obj);
       END;
       INC(i);
      END;
   END
 END AppendList;



  PROCEDURE ^Get*(l : TList; k : LONGINT) : Node;

  PROCEDURE Insert*(l : TList; i : LONGINT; s : TObject);
 VAR
    e, u : Node;
 BEGIN
     l.res := FALSE;
     IF (i < 0) OR (i > l.Count) THEN RETURN END;
     IF i = l.Count THEN Append(l, s); RETURN END;
     u := Get(l, i);
     NEW(e);
     e.obj := s;
     e.next := u;
     e.prev := u.prev;
     IF u.prev = NIL THEN
        l.First := e;
     ELSE
        u.prev.next := e;
     END;
     u.prev := e;
    l.res := TRUE;
    INC(l.Count);
 END Insert;

 PROCEDURE Clear*(l : TList);
 BEGIN
    l.First   := NIL;
    l.Last    := NIL;
    l.Count   := 0;
 END Clear;

 PROCEDURE Free*(l : TList);

 BEGIN

 END Free;

 PROCEDURE Get*(l : TList; k : LONGINT) : Node;
 VAR i : LONGINT;
     e : Node;
 BEGIN
    e := NIL;
    l.res := FALSE;
    IF (k < l.Count) & (k >= 0)  THEN
       i := 0;
       e := l.First;
       WHILE i # k DO
          IF e # NIL THEN e := e.next END;
    INC(i);
       END;
       l.res := TRUE
    END;
    RETURN e;
 END Get;

  PROCEDURE Delete* (l : TList; k : LONGINT);
  VAR e : Node;
 BEGIN
     l.res := FALSE;
     IF (k >= 0) & (k < l.Count) THEN
        e := Get(l, k);
        IF e.prev = NIL THEN l.First := e.next ELSE e.prev.next := e.next END;
        IF e.next = NIL THEN l.Last := e.prev ELSE e.next.prev := e.prev END;
       DEC(l.Count);
       l.res := TRUE;
    END;
 END Delete;
(* same as next but with debug messages 
PROCEDURE DeleteNode*(l: TList; n: Node): BOOLEAN;
VAR
  current: Node;
  result: BOOLEAN;
BEGIN
  result := FALSE;
  l.res := FALSE;
  current := l.First;

  WHILE current # NIL DO
    IF current = n THEN
      (* Debugging: Print node to be removed *)
      Out.String("Deleting node: ");
      IF current.obj # NIL THEN
        Out.String("Node found and deleted.");
      ELSE
        Out.String("NIL node");
      END;
      Out.Ln;

      (* Adjust pointers to remove the node *)
      IF current.prev = NIL THEN
        l.First := current.next;  (* Handle first node case *)
      ELSE
        current.prev.next := current.next;
      END;

      IF current.next = NIL THEN
        l.Last := current.prev;  (* Handle last node case *)
      ELSE
        current.next.prev := current.prev;
      END;

      DEC(l.Count);  (* Decrement the count after deletion *)
      result := TRUE;
      l.res := TRUE;
      RETURN result;
    END;
    current := current.next;
  END;

  RETURN result;  (* Return FALSE if no node was found/deleted *)
END DeleteNode;
*)

PROCEDURE DeleteNode*(l: TList; n: Node): BOOLEAN;
VAR
  current: Node;
  result: BOOLEAN;
BEGIN
  result := FALSE;
  current := l.First;

  WHILE current # NIL DO
    IF current = n THEN

      (* Adjust pointers to remove the node *)
      IF current.prev = NIL THEN
        l.First := current.next  (* Handle first node case *)
      ELSE
        current.prev.next := current.next;
      END;

      IF current.next = NIL THEN
        l.Last := current.prev  (* Handle last node case *)
      ELSE
        current.next.prev := current.prev;
      END;

      DEC(l.Count);  (* Decrement the count after deletion *)
      result := TRUE;
      RETURN result;
    END;
    current := current.next;
  END;

  RETURN result;  (* Return FALSE if no node was found/deleted *)
END DeleteNode;

PROCEDURE Empty* (l : TList) : BOOLEAN;
 BEGIN
    RETURN l.First = NIL
 END Empty;

 PROCEDURE Create* () : TList;
 VAR l : TList;
 BEGIN
    NEW(l);
    l.First   := NIL;
    l.Last    := NIL;
    l.Count   := 0;
    l.Add     := Add;
    l.Append  := Append;
    l.AppendList  := AppendList;
    l.Clear   := Clear;
    l.Free    := Free;
    l.Insert  := Insert;
    l.Delete  := Delete;
l.DeleteNode  := DeleteNode;
    l.Empty   := Empty;
    l.Get     := Get;
    l.res     := TRUE;
    RETURN(l);
 END Create;

(* PROCEDURE Delete* (VAR l : StringList; VAR e : Str);
 BEGIN
    e := l.First;
    l.First := l.First.next;
    IF l.First = NIL THEN l.Last := NIL END;
 END Delete;
*)

END List.
