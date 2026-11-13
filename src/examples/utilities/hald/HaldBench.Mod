MODULE HaldBench;
IMPORT Args, Files, HaldClut, Out, Platform;
TYPE Buffer = POINTER TO ARRAY OF CHAR;
VAR source, lut, target: Buffer;
  inputName, lutName, outputName, text: ARRAY 4096 OF CHAR;
  range, repeats, pass, sample: LONGINT;
  start, elapsed: LONGREAL;

PROCEDURE Load(name: ARRAY OF CHAR): Buffer;
VAR f: Files.File; reader: Files.Rider; data: Buffer; size: LONGINT;
BEGIN
  f := Files.Old(name); ASSERT(f # NIL);
  size := Files.Length(f); ASSERT(size > 0);
  NEW(data, size);
  Files.Set(reader, f, 0); Files.ReadBytes(reader, data^, size);
  ASSERT(reader.res = 0); Files.Close(f);
  RETURN data
END Load;

PROCEDURE Save(name: ARRAY OF CHAR; data: Buffer);
VAR f: Files.File; writer: Files.Rider;
BEGIN
  f := Files.New(name); ASSERT(f # NIL);
  Files.Set(writer, f, 0); Files.WriteBytes(writer, data^, LEN(data^));
  ASSERT(writer.res = 0); Files.Register(f); Files.Close(f)
END Save;

PROCEDURE Number(value: ARRAY OF CHAR): LONGINT;
VAR i, result: LONGINT;
BEGIN
  i := 0; result := 0;
  WHILE (value[i] >= "0") & (value[i] <= "9") & (result < 1000000) DO
    result := result * 10 + ORD(value[i]) - ORD("0"); INC(i)
  END;
  ASSERT((i > 0) & (value[i] = 0X)); RETURN result
END Number;

PROCEDURE Now(): LONGREAL;
VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN sec * 1.0D6 + usec END Now;

BEGIN
  Args.Get(1, inputName); Args.Get(2, lutName); Args.Get(3, text);
  range := Number(text); Args.Get(4, outputName);
  source := Load(inputName); lut := Load(lutName); NEW(target, LEN(source^));
  start := Now(); HaldClut.Apply(source^, lut^, range, target^); elapsed := Now() - start;
  Out.String("cold_us "); Out.LongReal(elapsed, 0); Out.Ln; Out.Flush;
  Args.Get(5, text);
  IF text = "bench" THEN
    repeats := 1;
    LOOP
      start := Now();
      FOR pass := 1 TO repeats DO HaldClut.Apply(source^, lut^, range, target^) END;
      elapsed := Now() - start;
      IF (elapsed >= 150000) OR (repeats >= 4096) THEN EXIT END;
      repeats := repeats * 2
    END;
    FOR sample := 1 TO 5 DO
      start := Now();
      FOR pass := 1 TO repeats DO HaldClut.Apply(source^, lut^, range, target^) END;
      elapsed := Now() - start;
      Out.String("sample_us "); Out.LongReal(elapsed / repeats, 0); Out.Ln; Out.Flush
    END;
    Out.String("repeats "); Out.Int(repeats, 0); Out.Ln
  END;
  IF outputName # "-" THEN Save(outputName, target) END;
  Out.String("bytes "); Out.Int(LEN(source^), 0); Out.Ln
END HaldBench.
