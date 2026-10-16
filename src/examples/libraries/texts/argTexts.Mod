MODULE argTexts; (* example how to get arguments by using Texts module *)
IMPORT Texts, Oberon;

VAR
  S: Texts.Scanner; (* we'll read program arguments with it *)

  W : Texts.Writer; (* to write to console *)
  T : Texts.Text;

BEGIN
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
  Texts.Scan(S);
  (*Out.String(S.s); Out.Ln;*)

Texts.OpenWriter (W);

Texts.WriteString(W, "aaa");
Texts.WriteLn(W);
Texts.WriteString(W, S.s);
Texts.WriteLn(W);
Texts.Append(Oberon.Log, W.buf);


END argTexts.
