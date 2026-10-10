MODULE TestArrayParameters;
  IMPORT Heap, Out;
  TYPE
    Name = ARRAY 16 OF CHAR;
    Vector = ARRAY 3 OF LONGINT;
    Matrix = ARRAY 2 OF Vector;
    Cube = ARRAY 2 OF ARRAY 2 OF ARRAY 3 OF LONGINT;
    MatrixOperation = PROCEDURE(VAR matrix: Matrix);
    Command = PROCEDURE;
    Commands = ARRAY 2 OF Command;
    Item = RECORD value: LONGINT END;
    Items = ARRAY 2 OF Item;
    ItemPtr = POINTER TO Item;
    Pointers = ARRAY 2 OF ItemPtr;
    Root = RECORD item: ItemPtr END;
  VAR
    name: Name; vector: Vector; matrix: Matrix; cube: Cube;
    operation: MatrixOperation; commands: Commands;
    items: Items; pointers: Pointers; calls: LONGINT;
    roots: ARRAY 2 OF Root;

  PROCEDURE ValueName(text: Name);
  BEGIN
    ASSERT(LEN(text) = 16);
    ASSERT(text = "name"); text[0] := "N"
  END ValueName;

  PROCEDURE ValueVector(vector: Vector);
  BEGIN
    ASSERT(LEN(vector) = 3);
    vector[2] := 99; ASSERT(vector[2] = 99)
  END ValueVector;

  PROCEDURE CapturedVector(VAR vector: ARRAY OF LONGINT);
    PROCEDURE Bump;
    BEGIN INC(vector[1]) END Bump;
  BEGIN Bump END CapturedVector;

  PROCEDURE ChangeMatrix(VAR matrix: Matrix);
  BEGIN
    ASSERT(LEN(matrix) = 2); ASSERT(LEN(matrix, 1) = 3);
    matrix[1, 2] := 42
  END ChangeMatrix;

  PROCEDURE ValueMatrix(matrix: Matrix);
  BEGIN
    matrix[1, 2] := 99; ASSERT(matrix[1, 2] = 99)
  END ValueMatrix;

  PROCEDURE ChangeCube(VAR cube: Cube);
  BEGIN
    ASSERT(LEN(cube) = 2); ASSERT(LEN(cube, 1) = 2);
    ASSERT(LEN(cube, 2) = 3);
    cube[1, 1, 2] := 43
  END ChangeCube;

  PROCEDURE Count;
  BEGIN INC(calls) END Count;

  PROCEDURE Invoke(VAR commands: Commands);
  BEGIN commands[0]; commands[1] END Invoke;

  PROCEDURE ChangeItems(VAR items: Items);
  BEGIN items[1].value := 44 END ChangeItems;

  PROCEDURE ChangePointers(VAR pointers: Pointers);
  BEGIN pointers[1].value := 45 END ChangePointers;

BEGIN
  name := "name"; ValueName(name); ASSERT(name = "name");
  vector[0] := 1; vector[1] := 2; vector[2] := 3;
  ValueVector(vector); ASSERT(vector[2] = 3);
  CapturedVector(vector); ASSERT(vector[1] = 3);
  operation := ChangeMatrix; operation(matrix);
  ASSERT(matrix[1, 2] = 42);
  ValueMatrix(matrix); ASSERT(matrix[1, 2] = 42);
  ChangeCube(cube); ASSERT(cube[1, 1, 2] = 43);
  calls := 0; commands[0] := Count; commands[1] := Count;
  Invoke(commands); ASSERT(calls = 2);
  ChangeItems(items); ASSERT(items[1].value = 44);
  NEW(pointers[0]); NEW(pointers[1]);
  ChangePointers(pointers); ASSERT(pointers[1].value = 45);
  NEW(roots[1].item); roots[1].item.value := 46;
  (* Exercise the runtime's typed pointer and record enumeration callbacks. *)
  Heap.GC(FALSE);
  ASSERT(pointers[1].value = 45); ASSERT(roots[1].item.value = 46);
  Out.String("array parameter tests passed"); Out.Ln
END TestArrayParameters.
