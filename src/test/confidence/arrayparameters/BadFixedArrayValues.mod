MODULE BadFixedArrayValues;
  TYPE Name = ARRAY 8 OF CHAR; Vector = ARRAY 3 OF LONGINT;
  VAR short: ARRAY 4 OF CHAR; same: ARRAY 8 OF CHAR;
    vector: ARRAY 2 OF LONGINT; operation: PROCEDURE(value: Name);
  PROCEDURE Take(value: Name); END Take;
  PROCEDURE TakeVector(value: Vector); END TakeVector;
  PROCEDURE Pass(VAR value: ARRAY OF CHAR);
  BEGIN Take(value) END Pass;
  PROCEDURE PassValue(value: ARRAY OF CHAR);
  BEGIN Take(value) END PassValue;
BEGIN
  Take(short); Take(same); TakeVector(vector);
  operation := Take; operation(short)
END BadFixedArrayValues.
