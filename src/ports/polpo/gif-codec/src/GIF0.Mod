MODULE GIF0;  (** GIF pictures: decoding and encoding (one image), on Files *)

(* VOC adaptation, 2026-10-31: bounded memory-file entry points and buffer validation. *)

(** GIF87a and GIF89a. Decode reads the first image of a GIF file (of an animation, its first frame),
  with its global or local colour table, interlaced or not, with the transparent colour of its
  graphic control extension, into an Image of 8-bit red, green, blue and alpha of the size of the
  logical screen: pixels outside the image and transparent ones have alpha 0 (and red, green and
  blue 0). Data that ends early or a code that is not in the table ends the image there, as browsers
  show it; the pixels not decoded are transparent.
  Encode writes an Image as a GIF89a file of one image: with the colours of the image when it has at
  most 256 (255 when some pixels are transparent, alpha below 128), else with 256 colours chosen by
  median cut and Floyd-Steinberg dithering. Written for polpo after the GIF89a specification; it
  imports only Files, so it can be used in the console and in other Oberon systems. *)

IMPORT Files;

CONST
  (** results *)
  ok* = 0;
  notGIF* = 1;  (** not a GIF file (no GIF87a or GIF89a signature) *)
  badFormat* = 2;  (** a block is malformed, or the file has no image *)
  tooLarge* = 4;  (** the picture is too large for MaxPixels, or (Encode) wider or higher than 65535 *)
  noImage* = 5;  (** Encode: no image, or an empty one *)

  MaxPixels* = 64 * 1024 * 1024;  (** the most pixels a picture may have *)

  MaxCodes = 4096;
  HashSize = 8192;  (* the string table of the encoder *)
  Buckets = 1024;  (* the colours of a picture while they are counted *)
  Cells = 32768;  (* colours of 5 bits a component, for the median cut *)

TYPE
  Bytes* = Files.Bytes;
  Image* = POINTER TO ImageDesc;
  ImageDesc* = RECORD
    width*, height*: LONGINT;
    alpha*: BOOLEAN;  (** the picture has transparent pixels *)
    pix*: POINTER TO ARRAY OF CHAR  (** the rows from the top, 4 bytes a pixel: red, green, blue, alpha *)
  END;

  Info* = RECORD
    width*, height*: LONGINT;  (** of the logical screen *)
    colors*: LONGINT;  (** entries of the global colour table, 0 none *)
    images*: LONGINT;  (** images in the file (frames of an animation) *)
    interlaced*, transparent*: BOOLEAN  (** the first image *)
  END;

  Longs = POINTER TO ARRAY OF LONGINT;
  Totals = POINTER TO ARRAY OF HUGEINT;

  Palette = RECORD
    n: LONGINT;
    r, g, b: ARRAY 256 OF LONGINT
  END;

  Source = RECORD  (* the data sub-blocks of an image, read *)
    left: LONGINT;  (* bytes left in the sub-block *)
    done: BOOLEAN;  (* the block terminator or the end of the file was read *)
    acc, nbits: LONGINT
  END;

  Sink = RECORD  (* and written *)
    buf: ARRAY 255 OF CHAR;
    n, acc, nbits: LONGINT
  END;

  Box = RECORD lo, hi: ARRAY 3 OF LONGINT; count: LONGINT END;  (* of the median cut, 5 bits a component *)

(** a new image of w by h pixels, all transparent black *)
PROCEDURE NewImage*(w, h: LONGINT): Image;
VAR img: Image; i, n: LONGINT;
BEGIN
  NEW(img); img.width := w; img.height := h; img.alpha := FALSE; img.pix := NIL;
  IF (w > 0) & (h > 0) & (w <= MaxPixels DIV h) THEN
    n := w * h * 4; NEW(img.pix, n); i := 0; WHILE i < n DO img.pix[i] := 0X; INC(i) END
  END;
  RETURN img
END NewImage;

(** s := a description of the result res *)
PROCEDURE Message*(res: LONGINT; VAR s: ARRAY OF CHAR);
BEGIN
  CASE res OF
    ok: COPY("done", s)
  | notGIF: COPY("not a GIF file", s)
  | badFormat: COPY("malformed GIF file", s)
  | tooLarge: COPY("picture too large", s)
  | noImage: COPY("no image", s)
  ELSE COPY("unknown error", s)
  END
END Message;

(* reading *)

PROCEDURE Byte(VAR R: Files.Rider; VAR res: LONGINT): LONGINT;
VAR c: CHAR;
BEGIN
  Files.Read(R, c);
  IF R.eof THEN res := badFormat; RETURN 0 END;
  RETURN ORD(c)
END Byte;

PROCEDURE Word(VAR R: Files.Rider; VAR res: LONGINT): LONGINT;  (* least significant byte first *)
VAR lo: LONGINT;
BEGIN lo := Byte(R, res); RETURN lo + 256 * Byte(R, res)
END Word;

PROCEDURE ReadPalette(VAR R: Files.Rider; VAR p: Palette; n: LONGINT; VAR res: LONGINT);
VAR i: LONGINT;
BEGIN
  p.n := n; i := 0;
  WHILE i < n DO p.r[i] := Byte(R, res); p.g[i] := Byte(R, res); p.b[i] := Byte(R, res); INC(i) END
END ReadPalette;

(* skip data sub-blocks and the block terminator *)
PROCEDURE SkipBlocks(VAR R: Files.Rider; VAR res: LONGINT);
VAR n, b: LONGINT;
BEGIN
  n := Byte(R, res);
  WHILE (n > 0) & (res = ok) DO
    WHILE (n > 0) & (res = ok) DO b := Byte(R, res); DEC(n) END;
    n := Byte(R, res)
  END
END SkipBlocks;

(* the next byte of the image data; s.done after its end *)
PROCEDURE DataByte(VAR R: Files.Rider; VAR s: Source): LONGINT;
VAR c: CHAR;
BEGIN
  IF ~s.done & (s.left = 0) THEN
    Files.Read(R, c);
    IF R.eof OR (c = 0X) THEN s.done := TRUE ELSE s.left := ORD(c) END
  END;
  IF s.done THEN RETURN 0 END;
  Files.Read(R, c);
  IF R.eof THEN s.done := TRUE; RETURN 0 END;
  DEC(s.left);
  RETURN ORD(c)
END DataByte;

(* the next code of width bits, the least significant bit first; -1 after the end of the data *)
PROCEDURE Code(VAR R: Files.Rider; VAR s: Source; width: LONGINT): LONGINT;
VAR c, v: LONGINT;
BEGIN
  WHILE s.nbits < width DO
    c := DataByte(R, s);
    IF s.done THEN RETURN -1 END;
    INC(s.acc, ASH(c, s.nbits)); INC(s.nbits, 8)
  END;
  v := ASH(s.acc, -width); c := s.acc - ASH(v, width); s.acc := v; DEC(s.nbits, width);
  RETURN c
END Code;

(* decode the LZW data of an image into idx[0..n), and skip what is left of it; the pixels decoded *)
PROCEDURE Decompress(VAR R: Files.Rider; minSize: LONGINT; idx: Bytes; n: LONGINT; VAR res: LONGINT): LONGINT;
VAR prefix: ARRAY MaxCodes OF INTEGER; suffix, first: ARRAY MaxCodes OF CHAR; stack: ARRAY MaxCodes + 1 OF CHAR;
  s: Source; clear, eoi, next, width, code, prev, c, sp, out: LONGINT;
BEGIN
  clear := ASH(1, minSize); eoi := clear + 1;
  c := 0; WHILE c < clear DO suffix[c] := CHR(c); first[c] := CHR(c); prefix[c] := -1; INC(c) END;
  s.left := 0; s.done := FALSE; s.acc := 0; s.nbits := 0;
  next := clear + 2; width := minSize + 1; prev := -1; out := 0;
  LOOP
    IF out >= n THEN EXIT END;
    code := Code(R, s, width);
    IF (code < 0) OR (code = eoi) THEN EXIT END;
    IF code = clear THEN next := clear + 2; width := minSize + 1; prev := -1
    ELSIF prev < 0 THEN
      IF code > clear THEN EXIT END;  (* not a colour *)
      idx[out] := CHR(code); INC(out); prev := code
    ELSE
      IF code > next THEN EXIT END;  (* not in the table *)
      sp := 0;
      IF code = next THEN stack[0] := first[prev]; sp := 1; c := prev  (* the string of prev and its first byte *)
      ELSE c := code
      END;
      WHILE c >= clear DO stack[sp] := suffix[c]; INC(sp); c := prefix[c] END;
      stack[sp] := CHR(c); INC(sp);
      IF next < MaxCodes THEN
        prefix[next] := SHORT(prev); suffix[next] := stack[sp - 1]; first[next] := first[prev];
        INC(next);
        IF (next = ASH(1, width)) & (width < 12) THEN INC(width) END
      END;
      WHILE (sp > 0) & (out < n) DO DEC(sp); idx[out] := stack[sp]; INC(out) END;
      prev := code
    END
  END;
  IF ~s.done THEN  (* the rest of the data *)
    WHILE s.left > 0 DO c := Byte(R, res); DEC(s.left) END;
    SkipBlocks(R, res)
  END;
  RETURN out
END Decompress;

(* the rows of an interlaced image in the order they come: 0, 8, 16 ..., 4, 12 ..., 2, 6 ..., 1, 3 ... *)
PROCEDURE Rows(h: LONGINT; interlaced: BOOLEAN): Longs;
VAR rows: Longs; k, pass, start, step, y: LONGINT;
BEGIN
  NEW(rows, h + 1); k := 0;
  IF ~interlaced THEN WHILE k < h DO rows[k] := k; INC(k) END
  ELSE
    pass := 0;
    WHILE pass < 4 DO
      CASE pass OF 0: start := 0; step := 8 | 1: start := 4; step := 8 | 2: start := 2; step := 4 | 3: start := 1; step := 2 END;
      y := start; WHILE y < h DO rows[k] := y; INC(k); INC(y, step) END;
      INC(pass)
    END
  END;
  RETURN rows
END Rows;

(** the size and kind of the GIF picture at R (all its blocks are read) *)
PROCEDURE ReadInfo*(VAR R: Files.Rider; VAR info: Info; VAR res: LONGINT);
VAR sig: ARRAY 7 OF CHAR; i, b, n, flags: LONGINT; p: Palette; transparent: BOOLEAN;
BEGIN
  res := ok; i := 0; WHILE i < 6 DO sig[i] := CHR(Byte(R, res)); INC(i) END; sig[6] := 0X;
  IF (res # ok) OR (sig # "GIF87a") & (sig # "GIF89a") THEN res := notGIF; RETURN END;
  info.width := Word(R, res); info.height := Word(R, res); flags := Byte(R, res); b := Byte(R, res); b := Byte(R, res);
  info.colors := 0; info.images := 0; info.interlaced := FALSE; info.transparent := FALSE; transparent := FALSE;
  IF ODD(flags DIV 128) THEN info.colors := ASH(2, flags MOD 8); ReadPalette(R, p, info.colors, res) END;
  LOOP
    IF res # ok THEN EXIT END;
    b := Byte(R, res);
    IF res # ok THEN EXIT
    ELSIF b = 21H THEN
      b := Byte(R, res);
      IF b = 0F9H THEN
        n := Byte(R, res); flags := Byte(R, res); DEC(n);
        IF info.images = 0 THEN transparent := ODD(flags) END;
        WHILE (n > 0) & (res = ok) DO b := Byte(R, res); DEC(n) END
      END;
      SkipBlocks(R, res)
    ELSIF b = 2CH THEN
      b := Word(R, res); b := Word(R, res); b := Word(R, res); b := Word(R, res); flags := Byte(R, res);
      IF info.images = 0 THEN info.interlaced := ODD(flags DIV 64); info.transparent := transparent END;
      IF ODD(flags DIV 128) THEN ReadPalette(R, p, ASH(2, flags MOD 8), res) END;
      b := Byte(R, res); SkipBlocks(R, res);
      INC(info.images)
    ELSIF b = 3BH THEN EXIT
    ELSE res := badFormat
    END
  END;
  IF (res = ok) & (info.images = 0) THEN res := badFormat END
END ReadInfo;

PROCEDURE DecodeLimited(VAR R: Files.Rider; pixelLimit: LONGINT; VAR img: Image; VAR res: LONGINT);
VAR sig: ARRAY 7 OF CHAR; gct, lct: Palette; i, b, n, flags, sw, sh, left, top, w, h, cw, ch, transparent, minSize,
  got, x, y, k, p, ci: LONGINT; idx: Bytes; rows: Longs;
BEGIN
  img := NIL; res := ok; i := 0;
  WHILE i < 6 DO sig[i] := CHR(Byte(R, res)); INC(i) END;
  sig[6] := 0X;
  IF (res # ok) OR (sig # "GIF87a") & (sig # "GIF89a") THEN res := notGIF; RETURN END;
  sw := Word(R, res); sh := Word(R, res); flags := Byte(R, res); b := Byte(R, res); b := Byte(R, res);
  gct.n := 0; IF ODD(flags DIV 128) THEN ReadPalette(R, gct, ASH(2, flags MOD 8), res) END;
  transparent := -1;
  LOOP
    IF res # ok THEN RETURN END;
    b := Byte(R, res);
    IF res # ok THEN RETURN
    ELSIF b = 21H THEN  (* an extension *)
      b := Byte(R, res);
      IF b = 0F9H THEN  (* graphic control *)
        n := Byte(R, res); flags := Byte(R, res); b := Word(R, res); b := Byte(R, res); DEC(n, 4);
        IF ODD(flags) THEN transparent := b ELSE transparent := -1 END;
        WHILE (n > 0) & (res = ok) DO b := Byte(R, res); DEC(n) END
      END;
      SkipBlocks(R, res)
    ELSIF b = 2CH THEN EXIT  (* the first image *)
    ELSE res := badFormat; RETURN  (* the trailer before an image, or garbage *)
    END
  END;
  left := Word(R, res); top := Word(R, res); w := Word(R, res); h := Word(R, res); flags := Byte(R, res);
  IF ODD(flags DIV 128) THEN ReadPalette(R, lct, ASH(2, flags MOD 8), res) ELSE lct := gct END;
  minSize := Byte(R, res);
  IF res # ok THEN RETURN END;
  IF (minSize < 1) OR (minSize > 11) THEN res := badFormat; RETURN END;
  cw := sw; IF left + w > cw THEN cw := left + w END;
  ch := sh; IF top + h > ch THEN ch := top + h END;
  IF (cw = 0) OR (ch = 0) THEN res := badFormat; RETURN END;
  IF cw > pixelLimit DIV ch THEN res := tooLarge; RETURN END;
  img := NewImage(cw, ch); got := 0;
  IF (w > 0) & (h > 0) THEN
    NEW(idx, w * h); got := Decompress(R, minSize, idx, w * h, res);
    rows := Rows(h, ODD(flags DIV 64))
  END;
  img.alpha := (cw * ch > got);
  k := 0; i := 0;
  WHILE i < got DO  (* the pixels in the order they come *)
    y := rows[k]; x := 0; p := ((top + y) * cw + left) * 4;
    WHILE (x < w) & (i < got) DO
      ci := ORD(idx[i]);
      IF ci = transparent THEN img.alpha := TRUE
      ELSE
        IF ci < lct.n THEN img.pix[p] := CHR(lct.r[ci]); img.pix[p + 1] := CHR(lct.g[ci]); img.pix[p + 2] := CHR(lct.b[ci]) END;
        img.pix[p + 3] := 0FFX
      END;
      INC(p, 4); INC(x); INC(i)
    END;
    INC(k)
  END;
  res := ok
END DecodeLimited;

(** decode the first image of the GIF picture at R into img (NIL if res # ok) *)
PROCEDURE Decode*(VAR R: Files.Rider; VAR img: Image; VAR res: LONGINT);
BEGIN DecodeLimited(R, MaxPixels, img, res) END Decode;

(** inspect the logical prefix data[0..length), entirely in memory *)
PROCEDURE ReadInfoBytes*(data: ARRAY OF CHAR; length: LONGINT; VAR info: Info; VAR res: LONGINT);
VAR f: Files.File; R: Files.Rider;
BEGIN
  f := Files.FromBytes(data, length);
  IF f = NIL THEN res := badFormat; RETURN END;
  Files.Set(R, f, 0); ReadInfo(R, info, res)
END ReadInfoBytes;

(** decode an in-memory prefix, enforcing pixelLimit on the complete canvas, including
    frame offsets; pixelLimit must be in 1..MaxPixels. No temporary files are created. *)
PROCEDURE DecodeBytes*(data: ARRAY OF CHAR; length, pixelLimit: LONGINT; VAR img: Image; VAR res: LONGINT);
VAR f: Files.File; R: Files.Rider;
BEGIN
  img := NIL;
  IF (pixelLimit < 1) OR (pixelLimit > MaxPixels) THEN res := tooLarge; RETURN END;
  f := Files.FromBytes(data, length);
  IF f = NIL THEN res := badFormat; RETURN END;
  Files.Set(R, f, 0); DecodeLimited(R, pixelLimit, img, res)
END DecodeBytes;

(* writing *)

PROCEDURE PutWord(VAR W: Files.Rider; x: LONGINT);
BEGIN Files.Write(W, CHR(x MOD 256)); Files.Write(W, CHR(x DIV 256 MOD 256))
END PutWord;

PROCEDURE PutByte(VAR W: Files.Rider; VAR s: Sink; b: LONGINT);
BEGIN
  s.buf[s.n] := CHR(b); INC(s.n);
  IF s.n = 255 THEN Files.Write(W, CHR(255)); Files.WriteBytes(W, s.buf, 255); s.n := 0 END
END PutByte;

PROCEDURE PutCode(VAR W: Files.Rider; VAR s: Sink; code, width: LONGINT);
VAR v: LONGINT;
BEGIN
  INC(s.acc, ASH(code, s.nbits)); INC(s.nbits, width);
  WHILE s.nbits >= 8 DO
    v := ASH(s.acc, -8); PutByte(W, s, s.acc - ASH(v, 8)); s.acc := v; DEC(s.nbits, 8)
  END
END PutCode;

(* the LZW data of idx[0..n), in sub-blocks with the terminator (as the encoder of Go's compress/lzw) *)
PROCEDURE Compress(VAR W: Files.Rider; idx: Bytes; n, minSize: LONGINT);
VAR keys: ARRAY HashSize OF LONGINT; codes: ARRAY HashSize OF INTEGER; s: Sink;
  clear, eoi, width, hi, overflow, saved, c, key, h, i: LONGINT;

  PROCEDURE Reset;
  VAR j: LONGINT;
  BEGIN
    width := minSize + 1; hi := eoi; overflow := ASH(1, width);
    j := 0; WHILE j < HashSize DO keys[j] := -1; INC(j) END
  END Reset;

  (* the next code is taken; FALSE if the table was full and is cleared *)
  PROCEDURE NextHi(): BOOLEAN;
  BEGIN
    INC(hi);
    IF hi = overflow THEN INC(width); overflow := overflow * 2 END;
    IF hi = MaxCodes - 1 THEN PutCode(W, s, clear, width); Reset; RETURN FALSE END;
    RETURN TRUE
  END NextHi;

BEGIN
  clear := ASH(1, minSize); eoi := clear + 1; s.n := 0; s.acc := 0; s.nbits := 0;
  Files.Write(W, CHR(minSize));
  Reset; PutCode(W, s, clear, width);
  saved := ORD(idx[0]); i := 1;
  WHILE i < n DO
    c := ORD(idx[i]); key := saved * 256 + c; h := key * 7 MOD HashSize;
    WHILE (keys[h] # -1) & (keys[h] # key) DO h := (h + 1) MOD HashSize END;
    IF keys[h] = key THEN saved := codes[h]
    ELSE
      PutCode(W, s, saved, width); saved := c;
      IF NextHi() THEN keys[h] := key; codes[h] := SHORT(hi) END
    END;
    INC(i)
  END;
  PutCode(W, s, saved, width);
  IF NextHi() THEN END;
  PutCode(W, s, eoi, width);
  IF s.nbits > 0 THEN PutByte(W, s, s.acc) END;
  IF s.n > 0 THEN Files.Write(W, CHR(s.n)); Files.WriteBytes(W, s.buf, s.n) END;
  Files.Write(W, 0X)
END Compress;

(* the index of colour c in the table, entered if there is room; -1 if there is none *)
PROCEDURE Index(VAR table: ARRAY OF LONGINT; VAR hash: ARRAY OF LONGINT; VAR n: LONGINT; max, c: LONGINT): LONGINT;
VAR h: LONGINT;
BEGIN
  h := (c * 7 + c DIV 4096) MOD Buckets;
  WHILE (hash[h] # 0) & (table[hash[h] - 1] # c) DO h := (h + 1) MOD Buckets END;
  IF hash[h] # 0 THEN RETURN hash[h] - 1 END;
  IF n = max THEN RETURN -1 END;
  table[n] := c; INC(n); hash[h] := n;
  RETURN n - 1
END Index;

(* the index of the colour of p nearest to r, g, b *)
PROCEDURE Nearest(VAR p: Palette; r, g, b: LONGINT): LONGINT;
VAR i, d, best, bestD, dr, dg, db: LONGINT;
BEGIN
  best := 0; bestD := MAX(LONGINT); i := 0;
  WHILE i < p.n DO
    dr := r - p.r[i]; dg := g - p.g[i]; db := b - p.b[i];
    d := 3 * dr * dr + 4 * dg * dg + 2 * db * db;
    IF d < bestD THEN bestD := d; best := i END;
    INC(i)
  END;
  RETURN best
END Nearest;

(* the cells of box between its bounds: the count, and the bounds shrunk to the cells used *)
PROCEDURE Shrink(VAR box: Box; hist: Longs);
VAR r, g, b, k, lo0, lo1, lo2, hi0, hi1, hi2: LONGINT;
BEGIN
  box.count := 0; lo0 := 32; lo1 := 32; lo2 := 32; hi0 := -1; hi1 := -1; hi2 := -1;
  r := box.lo[0];
  WHILE r <= box.hi[0] DO
    g := box.lo[1];
    WHILE g <= box.hi[1] DO
      b := box.lo[2];
      WHILE b <= box.hi[2] DO
        k := (r * 32 + g) * 32 + b;
        IF hist[k] > 0 THEN
          INC(box.count, hist[k]);
          IF r < lo0 THEN lo0 := r END; IF r > hi0 THEN hi0 := r END;
          IF g < lo1 THEN lo1 := g END; IF g > hi1 THEN hi1 := g END;
          IF b < lo2 THEN lo2 := b END; IF b > hi2 THEN hi2 := b END
        END;
        INC(b)
      END;
      INC(g)
    END;
    INC(r)
  END;
  IF box.count > 0 THEN
    box.lo[0] := lo0; box.lo[1] := lo1; box.lo[2] := lo2; box.hi[0] := hi0; box.hi[1] := hi1; box.hi[2] := hi2
  END
END Shrink;

(* the count of the slice v of box along axis a *)
PROCEDURE Slice(VAR box: Box; hist: Longs; a, v: LONGINT): LONGINT;
VAR lo, hi: ARRAY 3 OF LONGINT; r, g, b, sum: LONGINT;
BEGIN
  lo[0] := box.lo[0]; lo[1] := box.lo[1]; lo[2] := box.lo[2]; hi[0] := box.hi[0]; hi[1] := box.hi[1]; hi[2] := box.hi[2];
  lo[a] := v; hi[a] := v; sum := 0; r := lo[0];
  WHILE r <= hi[0] DO
    g := lo[1];
    WHILE g <= hi[1] DO
      b := lo[2]; WHILE b <= hi[2] DO INC(sum, hist[(r * 32 + g) * 32 + b]); INC(b) END;
      INC(g)
    END;
    INC(r)
  END;
  RETURN sum
END Slice;

(* max colours for the opaque pixels of img by median cut: the box of the most pixels split at the median of
  its longest side, until there are max boxes; each colour the mean of the pixels of its box *)
PROCEDURE MedianCut(img: Image; max: LONGINT; VAR p: Palette);
VAR hist: Longs; sr, sg, sb: Totals; boxes: ARRAY 256 OF Box;
  nb, i, j, k, n, a, len, best, m, sum, half, r, g, b: LONGINT; rt, gt, bt: HUGEINT;
BEGIN
  NEW(hist, Cells); NEW(sr, Cells); NEW(sg, Cells); NEW(sb, Cells);
  i := 0; WHILE i < Cells DO hist[i] := 0; sr[i] := 0; sg[i] := 0; sb[i] := 0; INC(i) END;
  n := img.width * img.height; i := 0;
  WHILE i < n DO
    IF img.pix[4 * i + 3] >= 80X THEN
      r := ORD(img.pix[4 * i]); g := ORD(img.pix[4 * i + 1]); b := ORD(img.pix[4 * i + 2]);
      k := (r DIV 8 * 32 + g DIV 8) * 32 + b DIV 8;
      INC(hist[k]); INC(sr[k], r); INC(sg[k], g); INC(sb[k], b)
    END;
    INC(i)
  END;
  boxes[0].lo[0] := 0; boxes[0].lo[1] := 0; boxes[0].lo[2] := 0;
  boxes[0].hi[0] := 31; boxes[0].hi[1] := 31; boxes[0].hi[2] := 31; Shrink(boxes[0], hist); nb := 1;
  LOOP
    IF nb >= max THEN EXIT END;
    best := -1; j := 0;
    WHILE j < nb DO  (* the box of the most pixels that has more than one cell *)
      IF ((boxes[j].hi[0] > boxes[j].lo[0]) OR (boxes[j].hi[1] > boxes[j].lo[1]) OR (boxes[j].hi[2] > boxes[j].lo[2]))
        & ((best < 0) OR (boxes[j].count > boxes[best].count)) THEN best := j
      END;
      INC(j)
    END;
    IF best < 0 THEN EXIT END;
    a := 0; len := -1; k := 0;
    WHILE k < 3 DO IF boxes[best].hi[k] - boxes[best].lo[k] > len THEN len := boxes[best].hi[k] - boxes[best].lo[k]; a := k END; INC(k) END;
    half := boxes[best].count DIV 2; m := boxes[best].lo[a]; sum := Slice(boxes[best], hist, a, m);
    WHILE (m < boxes[best].hi[a] - 1) & (sum < half) DO INC(m); INC(sum, Slice(boxes[best], hist, a, m)) END;
    boxes[nb] := boxes[best]; boxes[nb].lo[a] := m + 1; boxes[best].hi[a] := m;
    Shrink(boxes[best], hist); Shrink(boxes[nb], hist); INC(nb)
  END;
  p.n := nb; j := 0;
  WHILE j < nb DO
    sum := 0; rt := 0; gt := 0; bt := 0; i := boxes[j].lo[0];
    WHILE i <= boxes[j].hi[0] DO
      k := boxes[j].lo[1];
      WHILE k <= boxes[j].hi[1] DO
        m := boxes[j].lo[2];
        WHILE m <= boxes[j].hi[2] DO
          a := (i * 32 + k) * 32 + m; INC(sum, hist[a]); INC(rt, sr[a]); INC(gt, sg[a]); INC(bt, sb[a]); INC(m)
        END;
        INC(k)
      END;
      INC(i)
    END;
    IF sum > 0 THEN
      p.r[j] := SHORT((rt + sum DIV 2) DIV sum);
      p.g[j] := SHORT((gt + sum DIV 2) DIV sum);
      p.b[j] := SHORT((bt + sum DIV 2) DIV sum)
    ELSE p.r[j] := 0; p.g[j] := 0; p.b[j] := 0
    END;
    INC(j)
  END
END MedianCut;

PROCEDURE Clamp(x: LONGINT): LONGINT;
BEGIN IF x < 0 THEN RETURN 0 ELSIF x > 255 THEN RETURN 255 ELSE RETURN x END
END Clamp;

(* idx := the opaque pixels of img in the nearest colours of p, with Floyd-Steinberg dithering; the transparent
  ones t *)
PROCEDURE Dither(img: Image; VAR p: Palette; idx: Bytes; t: LONGINT);
VAR cache: POINTER TO ARRAY OF INTEGER; cur, next, tmp: Longs; w, x, y, i, s, r, g, b, k, er, eg, eb, key: LONGINT;
BEGIN
  w := img.width; NEW(cache, Cells); i := 0; WHILE i < Cells DO cache[i] := 0; INC(i) END;
  NEW(cur, 3 * (w + 2)); NEW(next, 3 * (w + 2));
  i := 0; WHILE i < 3 * (w + 2) DO cur[i] := 0; next[i] := 0; INC(i) END;
  y := 0;
  WHILE y < img.height DO
    x := 0;
    WHILE x < w DO
      i := y * w + x; s := 4 * i;
      IF img.pix[s + 3] < 80X THEN idx[i] := CHR(t)
      ELSE  (* the errors are 16 times too large *)
        r := Clamp(ORD(img.pix[s]) + cur[3 * (x + 1)] DIV 16); g := Clamp(ORD(img.pix[s + 1]) + cur[3 * (x + 1) + 1] DIV 16);
        b := Clamp(ORD(img.pix[s + 2]) + cur[3 * (x + 1) + 2] DIV 16);
        key := (r DIV 8 * 32 + g DIV 8) * 32 + b DIV 8;
        IF cache[key] = 0 THEN cache[key] := SHORT(Nearest(p, r, g, b) + 1) END;
        k := cache[key] - 1; idx[i] := CHR(k);
        er := r - p.r[k]; eg := g - p.g[k]; eb := b - p.b[k];
        INC(cur[3 * (x + 2)], er * 7); INC(cur[3 * (x + 2) + 1], eg * 7); INC(cur[3 * (x + 2) + 2], eb * 7);
        INC(next[3 * x], er * 3); INC(next[3 * x + 1], eg * 3); INC(next[3 * x + 2], eb * 3);
        INC(next[3 * (x + 1)], er * 5); INC(next[3 * (x + 1) + 1], eg * 5); INC(next[3 * (x + 1) + 2], eb * 5);
        INC(next[3 * (x + 2)], er); INC(next[3 * (x + 2) + 1], eg); INC(next[3 * (x + 2) + 2], eb)
      END;
      INC(x)
    END;
    tmp := cur; cur := next; next := tmp;
    i := 0; WHILE i < 3 * (w + 2) DO next[i] := 0; INC(i) END;
    INC(y)
  END
END Dither;

(** write img at W as a GIF89a file of one image *)
PROCEDURE Encode*(VAR W: Files.Rider; img: Image; VAR res: LONGINT);
VAR table: ARRAY 256 OF LONGINT; hash: ARRAY Buckets OF LONGINT; p: Palette; idx: Bytes;
  transparent: BOOLEAN; i, n, max, count, c, k, s, t, bits, size: LONGINT;
BEGIN
  IF (img = NIL) OR (img.pix = NIL) OR (img.width <= 0) OR (img.height <= 0) THEN res := noImage; RETURN END;
  IF (img.width > 65535) OR (img.height > 65535) THEN res := tooLarge; RETURN END;
  IF img.width > MaxPixels DIV img.height THEN res := tooLarge; RETURN END;
  IF img.width * img.height > LEN(img.pix^) DIV 4 THEN res := noImage; RETURN END;
  n := img.width * img.height; transparent := FALSE; i := 0;
  WHILE ~transparent & (i < n) DO transparent := img.pix[4 * i + 3] < 80X; INC(i) END;
  IF transparent THEN max := 255 ELSE max := 256 END;
  i := 0; WHILE i < Buckets DO hash[i] := 0; INC(i) END;
  NEW(idx, n); count := 0; i := 0;
  WHILE (i < n) & (count >= 0) DO  (* the colours, while there are at most max *)
    s := 4 * i;
    IF img.pix[s + 3] >= 80X THEN
      c := (LONG(ORD(img.pix[s])) * 256 + ORD(img.pix[s + 1])) * 256 + ORD(img.pix[s + 2]);
      k := Index(table, hash, count, max, c);
      IF k < 0 THEN count := -1 ELSE idx[i] := CHR(k) END
    END;
    INC(i)
  END;
  IF count >= 0 THEN
    p.n := count; i := 0;
    WHILE i < count DO p.r[i] := table[i] DIV 10000H; p.g[i] := table[i] DIV 100H MOD 100H; p.b[i] := table[i] MOD 100H; INC(i) END;
    t := count; i := 0;
    WHILE i < n DO IF img.pix[4 * i + 3] < 80X THEN idx[i] := CHR(t) END; INC(i) END
  ELSE
    MedianCut(img, max, p); t := p.n; Dither(img, p, idx, t)
  END;
  size := p.n; IF transparent THEN INC(size) END;
  bits := 1; WHILE ASH(1, bits) < size DO INC(bits) END;
  Files.Write(W, "G"); Files.Write(W, "I"); Files.Write(W, "F"); Files.Write(W, "8"); Files.Write(W, "9"); Files.Write(W, "a");
  PutWord(W, img.width); PutWord(W, img.height);
  Files.Write(W, CHR(80H + 70H + bits - 1)); Files.Write(W, 0X); Files.Write(W, 0X);  (* global table, 8 bits a colour *)
  i := 0;
  WHILE i < ASH(1, bits) DO
    IF i < p.n THEN Files.Write(W, CHR(p.r[i])); Files.Write(W, CHR(p.g[i])); Files.Write(W, CHR(p.b[i]))
    ELSE Files.Write(W, 0X); Files.Write(W, 0X); Files.Write(W, 0X)
    END;
    INC(i)
  END;
  IF transparent THEN  (* graphic control: the transparent colour *)
    Files.Write(W, 21X); Files.Write(W, 0F9X); Files.Write(W, 4X); Files.Write(W, 1X); PutWord(W, 0);
    Files.Write(W, CHR(t)); Files.Write(W, 0X)
  END;
  Files.Write(W, 2CX); PutWord(W, 0); PutWord(W, 0); PutWord(W, img.width); PutWord(W, img.height); Files.Write(W, 0X);
  IF bits < 2 THEN bits := 2 END;
  Compress(W, idx, n, bits);
  Files.Write(W, 3BX);
  res := ok
END Encode;

(** encode into a memory-only buffer of at most maxBytes bytes. Only data[0..length)
    is valid; data is NIL and length is 0 on failure, including an output-capacity failure. *)
PROCEDURE EncodeBytes*(img: Image; maxBytes: LONGINT; VAR data: Bytes; VAR length, res: LONGINT);
VAR f: Files.File; W: Files.Rider;
BEGIN
  data := NIL; length := 0;
  IF maxBytes < 1 THEN res := tooLarge; RETURN END;
  f := Files.NewMemory(maxBytes); Files.Set(W, f, 0); Encode(W, img, res);
  IF Files.MemoryFailed(f) THEN res := tooLarge END;
  IF res = ok THEN data := Files.MemoryData(f, length) END
END EncodeBytes;

END GIF0.
