MODULE ZlibTest;  (** loksh ZlibTest.Run: ZlibDeflate.Compress and ZlibInflate.Uncompress, each in one call *)

(* Data of runs and noise from 1 byte to 1 MB, compressed at the levels 0 (stored blocks), 1, 2, 6 and 9,
  uncompressed into a buffer of exactly its size. Before 2026-10-28 Uncompress stopped after 32 KB (the
  space left in the window was not computed again after it was emptied, nor after a compressed block,
  as zlib does), and Compress at level 0 stopped at ASSERT 113 for 65532 bytes and more (FillWindow
  can give twice the window, a stored block is cut at the size of the pending buffer in zlib). *)

IMPORT ZlibDeflate, ZlibInflate, out := Out;

VAR checks, failed: LONGINT;

PROCEDURE Case(n: LONGINT; level: SHORTINT; seed: LONGINT);
VAR src, comp, dst: POINTER TO ARRAY OF CHAR; i, clen, len, x, cres: LONGINT; res: ZlibInflate.Result; ok: BOOLEAN;
BEGIN
  NEW(src, n); NEW(comp, n + n DIV 100 + 1000); NEW(dst, n);
  x := seed; i := 0;
  WHILE i < n DO
    x := (x * 75 + 74) MOD 65537;
    IF ODD(i DIV 997) THEN src[i] := CHR(x MOD 256) ELSE src[i] := CHR(i DIV 31 MOD 7 + 65) END;
    INC(i)
  END;
  ZlibDeflate.Compress(src^, comp^, 0, n, 0, LEN(comp^), level, ZlibDeflate.DefaultStrategy, clen, cres);
  len := -1; ZlibInflate.Uncompress(comp^, dst^, 0, clen, 0, n, len, res);
  ok := (cres = ZlibDeflate.Ok) & (res.code = ZlibInflate.Ok) & (len = n); i := 0;
  WHILE ok & (i < n) DO ok := src[i] = dst[i]; INC(i) END;
  INC(checks);
  IF ~ok THEN
    INC(failed); out.String("FAIL "); out.Int(n, 0); out.String(" bytes at level "); out.Int(level, 0);
    out.String(": Compress "); out.Int(cres, 0); out.String(", Uncompress "); out.Int(res.code, 0);
    out.String(", length "); out.Int(len, 0); out.Ln
  END
END Case;

PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0;
  Case(1, 6, 1); Case(100, 6, 2); Case(32767, 6, 3); Case(32768, 6, 4); Case(65536, 6, 5);
  Case(196864, 6, 6); Case(196864, 2, 7); Case(500000, 9, 8); Case(1000000, 1, 9);
  Case(1000, 0, 10); Case(65531, 0, 11); Case(65532, 0, 12); Case(65536, 0, 13); Case(300000, 0, 14);
  out.String("ZlibTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END ZlibTest.
