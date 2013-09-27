Coco/R - the Oberon scanner and parser generator

For a complete documentation see the postscript file Coco.Report.ps.

Compiler.Compile
	Sets.Mod CRS.Mod CRT.Mod CRA.Mod CRX.Mod CRP.Mod Coco.Mod ~

NOTE: the option character should be changed to "\" in Coco.Mod for Unix implementations.


Coco.Compile *
Coco.Compile ~
Coco.Compile ^
Coco.Compile @

(*________________________ usage ________________________*)

Coco.Compile <filename> [options]

The file CR.ATG is an example of an input file to Coco. If the grammar in the input file has the name X
the generated scanner has the name XS.Mod and the generated parser has the name XP.Mod.

Options:

	/X	generates a cross reference list of all syntax symbols
	/S	generates a list of all terminal start symbols and successors of nonterminal symbols.

Interface of the generated scanner:

	DEFINITION XS;
		IMPORT Texts;
		TYPE
			ErrorProc = PROCEDURE (n: INTEGER; pos: LONGINT);
		VAR
			Error: ErrorProc;
			col, errors, len, line, nextCol, nextLen, nextLine: INTEGER;
			nextPos, pos: LONGINT;
			src: Texts.Text;
		PROCEDURE Reset (t: Texts.Text; pos: LONGINT; errProc: ErrorProc);
		PROCEDURE Get(VAR sym: INTEGER);
		PROCEDURE GetName(pos: LONGINT; len: INTEGER; VAR name: ARRAY OF CHAR);
		PROCEDURE StdErrorProc (n: INTEGER; pos: LONGINT);
	END XS.

Interface of the generated parser:

	DEFINITION XP;
		PROCEDURE Parse;
	END XP.

Example how to use the generated parts;

	Texts.OpenScanner(s, Oberon.Par.Text, Oberon.Par.Pos); Texts.Scan(s);
	IF s.class = Texts.Name THEN
		NEW(text); Texts.Open(text, s.s);
		XS.Reset(text, 0, MyErrorHandler);
		XP.Parse;
	END


Error handling in the generated parser:

The grammar has to contain hints, from which Coco can generate appropriate error handling.
The hints can be placed arbitrarily on the right-hand side of a production:

	SYNC		Denotes a synchronisation point. At such points symbols are skipped until a symbol
					is found which is a legal continuation symbol at that point (or eof). SYNC is usually
					placed at points where particularly "safe" symbols are expected, i.e., symbols that
					are rarely missing or misspelled.
	
	WEAK s	s is an arbitrary terminal symbol (e.g., ";") which is considered "weak", because it is
					frequently missing or misspelled (e.g., a semicolon between statements).

Example:

	Statement =
		SYNC
		( ident WEAK ":=" Expression
		| "IF" Expression "THEN" StatSeq ["ELSE" StatSeq] "END"
		| "WHILE" Expression "DO" StatSeq "END"
		).
	StatSeq =
		Statement { WEAK ";" Statement}.þ
