MODULE testReader;

IMPORT oocFiles, oocTextRider, Out;

VAR f: oocFiles.File;
    r: oocTextRider.Reader;
    b: BOOLEAN;
    ch: CHAR;
    size: LONGINT;
    res: oocFiles.Result;
BEGIN
  b := oocFiles.Exists("test.Mod");
  IF b THEN
    f := oocFiles.Old("test.Mod", {oocFiles.read}, res);
    IF res # oocFiles.done THEN
      Out.String("cannot open file"); Out.Ln
    ELSE
      size := f.Length();
      Out.String("file size: "); Out.Int(size, 0); Out.Ln;
      r := oocTextRider.ConnectReader(f);
      IF r = NIL THEN
        Out.String("connecting reader failed"); Out.Ln
      ELSE
        WHILE (r.res = oocTextRider.done) & (r.Pos() < size) DO
          r.ReadChar(ch);
          IF r.res = oocTextRider.done THEN Out.Char(ch) END
        END
      END;
      f.Close
    END
  ELSE
    Out.String("file does not exist"); Out.Ln
  END

END testReader.
