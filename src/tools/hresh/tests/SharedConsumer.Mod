MODULE SharedConsumer;
  IMPORT SharedProvider, Out, Oberon, Texts, Heap;
  CONST A* = 1234567890; B* = {1, 3}; C* = "string"; D* = 1.5; E* = NIL;
  TYPE Node* = POINTER TO NodeDesc;
    NodeDesc* = RECORD next*: Node; n*: LONGINT END;
    Handler* = PROCEDURE(VAR node: Node): Node;
    Grid* = ARRAY 3, 4 OF Node;
  VAR kept*: Node; handler*: Handler;
  PROCEDURE (node: Node) Touch*;
  BEGIN INC(node.n) END Touch;
  PROCEDURE Function*(): LONGINT;
  BEGIN RETURN 17 END Function;
  PROCEDURE WithArg*(n: LONGINT);
  BEGIN Out.Int(n, 0) END WithArg;
  (** A command documented in the symbol file. *)
  PROCEDURE Run*;
  BEGIN
    IF kept = NIL THEN NEW(kept); kept.n := 40 END;
    kept.Touch; Heap.GC(TRUE);
    Out.String("run "); Out.Int(SharedProvider.Next(), 0);
    Out.String(" kept "); Out.Int(kept.n, 0); Out.Ln
  END Run;
  PROCEDURE Echo*;
    VAR r: Texts.Reader; ch: CHAR;
  BEGIN
    Texts.OpenReader(r, Oberon.Par.text, Oberon.Par.pos);
    WHILE ~r.eot DO Texts.Read(r, ch); IF ~r.eot THEN Out.Char(ch) END END;
    Out.Ln
  END Echo;
BEGIN Out.String("consumer initialized"); Out.Ln
END SharedConsumer.
