MODULE TestLineEditor;
  (* Standalone use through conventional libvoc, without hresh. Input is piped
     by test.sh so the batch reader can be checked without a user's terminal. *)
  IMPORT LineEditor, UnixTermios, Out;
  VAR line: ARRAY 32 OF CHAR; small: ARRAY 4 OF CHAR;
    invalid: ARRAY 1 OF CHAR; state: UnixTermios.State;
BEGIN
  state := 0; UnixTermios.Restore(state); ASSERT(state = 0);
  LineEditor.Init(NIL);
  ASSERT(LineEditor.ReadLine(invalid) = -2);
  ASSERT(LineEditor.ReadLine(line) = 1); ASSERT(line = "first");
  ASSERT(LineEditor.ReadLine(line) = 1); ASSERT(line = "second");
  ASSERT(LineEditor.ReadLine(small) = -1); ASSERT(small = "ove");
  ASSERT(LineEditor.ReadLine(line) = 1); ASSERT(line = "");
  ASSERT(LineEditor.ReadLine(line) = 1); ASSERT(line = "last");
  ASSERT(LineEditor.ReadLine(line) = 0); ASSERT(line = "");
  LineEditor.Stop;
  Out.String("standalone terminal library tests passed"); Out.Ln
END TestLineEditor.
