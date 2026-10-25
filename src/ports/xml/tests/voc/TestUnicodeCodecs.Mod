MODULE TestUnicodeCodecs;

IMPORT Out, Unicode := oocUnicode, UC := XMLUnicodeCodec, XMLUnicodeCodecImportAll;

VAR
	bytes, encoded: ARRAY 64 OF CHAR;
	units: ARRAY 32 OF Unicode.LONGCHAR;
	oneByte: ARRAY 1 OF CHAR;
	oneUnit: ARRAY 1 OF Unicode.LONGCHAR;
	encodings: ARRAY 4 OF ARRAY 16 OF CHAR;
	c: UC.Codec; f: UC.Factory;
	i, n, count, bad: LONGINT;

PROCEDURE DecodeAt(codec: UC.Codec; first, length: LONGINT): LONGINT;
	VAR start, done, dest, written: LONGINT;
BEGIN
	start := first; dest := 0;
	WHILE start < length DO
		codec.Decode(bytes, start, length, units, dest, LEN(units), done, written);
		IF (done <= start) OR (done > length) THEN
			Out.String("decode progress: start/done/end = ");
			Out.Int(start, 0); Out.Char("/"); Out.Int(done, 0);
			Out.Char("/"); Out.Int(length, 0); Out.Ln
		END;
		ASSERT((done > start) & (done <= length), 1);
		ASSERT((written > dest) & (written <= LEN(units)), 2);
		start := done; dest := written
	END;
	RETURN dest
END DecodeAt;

PROCEDURE Decode(codec: UC.Codec; length: LONGINT): LONGINT;
BEGIN
	RETURN DecodeAt(codec, 0, length)
END Decode;

PROCEDURE Encode(codec: UC.Codec; length: LONGINT): LONGINT;
	VAR start, done, dest, written: LONGINT;
BEGIN
	start := 0; dest := 0;
	WHILE start < length DO
		codec.Encode(units, start, length, encoded, dest, LEN(encoded), done, written);
		ASSERT((done > start) & (done <= length), 3);
		ASSERT((written > dest) & (written <= LEN(encoded)), 4);
		start := done; dest := written
	END;
	RETURN dest
END Encode;

PROCEDURE BadUTF8(length: LONGINT);
BEGIN
	c := f.NewCodec();
	n := Decode(c, length);
	ASSERT((n = 1) & (units[0] = UC.decodeError) & (c.invalidChars = 1), 5);
	INC(count)
END BadUTF8;

BEGIN
	ASSERT((MIN(LONGINT) = -2147483647-1) & (MAX(INTEGER) = 32767), 6);
	f := UC.GetFactory("utf-8"); ASSERT(f # NIL, 7);
	(* NUL, ASCII, Armenian U+0531, euro, emoji U+1F642, U+10FFFF. *)
	bytes[0] := 0X; bytes[1] := "A";
	bytes[2] := 0D4X; bytes[3] := 0B1X;
	bytes[4] := 0E2X; bytes[5] := 82X; bytes[6] := 0ACX;
	bytes[7] := 0F0X; bytes[8] := 9FX; bytes[9] := 99X; bytes[10] := 82X;
	bytes[11] := 0F4X; bytes[12] := 8FX; bytes[13] := 0BFX; bytes[14] := 0BFX;
	c := f.NewCodec(); n := Decode(c, 15);
	ASSERT((n = 8) & (c.invalidChars = 0), 8);
	ASSERT((units[0] = 0) & (units[1] = 41H) & (units[2] = 531H), 9);
	ASSERT((units[3] = 20ACH) & (units[4] = 0D83DH) & (units[5] = 0DE42H), 10);
	ASSERT((units[6] = 0DBFFH) & (units[7] = 0DFFFH), 11);
	ASSERT(Encode(c, n) = 15, 12);
	FOR i := 0 TO 14 DO ASSERT(encoded[i] = bytes[i], 13) END;
	INC(count);
	(* Short input, invalid/overlong encodings, lone continuation, surrogate. *)
	bytes[0] := 0C0X; bytes[1] := 80X; BadUTF8(2);
	bytes[0] := 0E2X; bytes[1] := 82X; BadUTF8(2);
	bytes[0] := 80X; BadUTF8(1);
	bytes[0] := 0EDX; bytes[1] := 0A0X; bytes[2] := 80X; BadUTF8(3);
	bytes[0] := 0F4X; bytes[1] := 90X; bytes[2] := 80X; bytes[3] := 80X; BadUTF8(4);
	(* A high surrogate at the end is an encoding error, not an array access. *)
	units[0] := 0D800H; c := f.NewCodec();
	ASSERT((Encode(c, 1) = 1) & (encoded[0] = "?") & (c.invalidChars = 1), 14);
	INC(count);
	(* UTF-16 BOM detection, both byte orders, supplementary characters. *)
	f := UC.GetFactory("UTF-16"); ASSERT(f # NIL, 15);
	FOR i := 0 TO 1 DO
		IF i = 0 THEN
			bytes[0] := 0FEX; bytes[1] := 0FFX;
			bytes[2] := 05X; bytes[3] := 31X;
			bytes[4] := 0D8X; bytes[5] := 3DX; bytes[6] := 0DEX; bytes[7] := 42X
		ELSE
			bytes[0] := 0FFX; bytes[1] := 0FEX;
			bytes[2] := 31X; bytes[3] := 05X;
			bytes[4] := 3DX; bytes[5] := 0D8X; bytes[6] := 42X; bytes[7] := 0DEX
		END;
		c := f.NewCodecBOM(bytes, 0, 8, n); ASSERT(n = 2, 16);
		count := DecodeAt(c, n, 8);
		ASSERT((count = 3) & (c.invalidChars = 0), 17);
		ASSERT((units[0] = 531H) & (units[1] = 0D83DH) & (units[2] = 0DE42H), 18);
		ASSERT(Encode(c, 3) = 6, 19);
		FOR n := 0 TO 5 DO ASSERT(encoded[n] = bytes[n+2], 20) END
	END;
	(* Odd final byte in UTF-16; no reading beyond the logical end. *)
	c := f.NewCodec(); bytes[0] := 05X;
	ASSERT((Decode(c, 1) = 1) & (units[0] = UC.decodeError) & (c.invalidChars = 1), 21);
	(* The registry is case-insensitive and an unknown encoding is absent. *)
	ASSERT(UC.GetFactory("UtF-16lE") # NIL, 22);
	ASSERT(UC.GetFactory("unknown-encoding") = NIL, 23);
	(* A one-byte logical range must ignore continuation bytes after it. *)
	f := UC.GetFactory("UTF-8"); c := f.NewCodec();
	bytes[0] := 80X; bytes[1] := 81X; bytes[2] := 82X;
	ASSERT((Decode(c, 1) = 1) & (c.invalidChars = 1), 24);
	(* Latin-1 preserves the whole octet range, including unsigned 0xFF. *)
	f := UC.GetFactory("latin1"); ASSERT(f # NIL, 25); c := f.NewCodec();
	bytes[0] := 0FFX;
	ASSERT((Decode(c, 1) = 1) & (units[0] = 255) & (c.invalidChars = 0), 26);
	ASSERT((Encode(c, 1) = 1) & (encoded[0] = 0FFX), 27);
	(* ASCII rejects Latin-1 and both single-byte codecs reject Unicode
	   outside their repertoire, counting a surrogate pair as one error. *)
	f := UC.GetFactory("ascii"); ASSERT(f # NIL, 28); c := f.NewCodec();
	ASSERT((Decode(c, 1) = 1) & (units[0] = UC.decodeError) & (c.invalidChars = 1), 29);
	FOR i := 0 TO 1 DO
		IF i = 0 THEN f := UC.GetFactory("ASCII") ELSE f := UC.GetFactory("LATIN1") END;
		c := f.NewCodec(); units[0] := 0D83DH; units[1] := 0DE42H;
		ASSERT((Encode(c, 2) = 1) & (encoded[0] = "?") & (c.invalidChars = 1), 30)
	END;
	(* Exact-sized input arrays exercise the fallback with index checks on. *)
	f := UC.GetFactory("UTF-8"); c := f.NewCodec(); oneByte[0] := 80X;
	c.Decode(oneByte, 0, 1, units, 0, LEN(units), n, count);
	ASSERT((n = 1) & (count = 1) & (c.invalidChars = 1), 31);
	c := f.NewCodec(); oneUnit[0] := 0D800H;
	c.Encode(oneUnit, 0, 1, encoded, 0, LEN(encoded), n, count);
	ASSERT((n = 1) & (count = 1) & (c.invalidChars = 1), 32);
	(* Widened storage must not turn invalid code-unit values into octets. *)
	COPY("UTF-8", encodings[0]); COPY("UTF-16", encodings[1]);
	COPY("ASCII", encodings[2]); COPY("LATIN1", encodings[3]);
	FOR i := 0 TO 3 DO
		FOR bad := 0 TO 1 DO
			f := UC.GetFactory(encodings[i]); c := f.NewCodec();
			IF bad = 0 THEN units[0] := -1 ELSE units[0] := 10000H END;
			n := Encode(c, 1);
			ASSERT(c.invalidChars = 1, 33);
			IF i = 1 THEN ASSERT((n = 2) & (encoded[0] = 0X) & (encoded[1] = "?"), 34)
			ELSE ASSERT((n = 1) & (encoded[0] = "?"), 35)
			END
		END
	END;
	Out.String("Unicode codec checks passed (-O2)"); Out.Ln
END TestUnicodeCodecs.
