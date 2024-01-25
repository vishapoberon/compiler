MODULE md5test;
  IMPORT MD5 := ethMD5, Out, Files, Strings;
PROCEDURE dump(VAR arr: ARRAY OF CHAR);
VAR
  i: INTEGER;
  ch: CHAR;
BEGIN
  i := 0;
  REPEAT
    Out.String("arr["); Out.Int(i, 0); Out.String("]="); Out.Int(ORD(arr[i]), 0);Out.Ln;
  INC(i)
  UNTIL i = Strings.Length(arr)+2
END dump;

PROCEDURE main;
  VAR
    context: MD5.Context;
    digest: MD5.Digest;
    hexDigest: ARRAY 33 OF CHAR;
    F: Files.File;
    R: Files.Rider;
    input: ARRAY 512 OF CHAR;
    ch: CHAR;
    i: INTEGER;
BEGIN
  F := Files.Old("hello.txt");
  IF F # NIL THEN
    Files.Set(R, F, 0);
    i := 0;
    REPEAT
      Files.Read(R, ch);
      input[i] := ch;
      INC(i)
    UNTIL R.eof;
    dump(input);
  END;

  context := MD5.New(); (* Initialize MD5 context *)

  MD5.WriteBytes(context, input, Strings.Length(input)); (* Process input string *)
  MD5.Close(context, digest); (* Finalize and get digest *)

  MD5.ToString(digest, hexDigest); (* Convert digest to hex string *)
  Out.String("MD5 Hash: "); Out.String(hexDigest); Out.Ln;
END main;

BEGIN
  main;
END md5test.

