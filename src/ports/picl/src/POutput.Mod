MODULE POutput;
IMPORT Files, Strings;
TYPE Int32 = LONGINT;



  PROCEDURE DumpCode*(VAR name: ARRAY OF CHAR; VAR code: ARRAY OF Int32; pc: Int32);
  VAR 
    i : INTEGER;
    f : Files.File;
	  r : Files.Rider;
	  fname: ARRAY 64 OF CHAR;
  BEGIN
     i := 0;
	 COPY(name, fname);
	 Strings.Append(".bin", fname);
	 f := Files.New(fname);
	 Files.Set(r, f, 0);
     WHILE i < pc DO
        Files.WriteLInt(r, code[i]);
     INC(i)
     END;
	 Files.Register(f);
  END DumpCode;


BEGIN



END POutput.
