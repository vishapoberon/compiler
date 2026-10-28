MODULE PNG0;  (** PNG pictures: decoding and encoding, on Files and the zlib of ETH Oberon *)

(** PNG 1.2 (ISO/IEC 15948): Decode reads every kind of PNG picture (grey, grey with alpha,
  RGB, RGB with alpha, palette; 1, 2, 4, 8 and 16 bits per sample; interlaced or not; with a
  tRNS chunk) into an Image of 8-bit red, green, blue and alpha; Encode writes an Image as an
  8-bit RGB or RGBA PNG picture, filtering each row with the filter that suits it best.
  Written for polpo after the PNG decoders of TF (AosPNGImages, back-ported to Oberon System 3
  as PNG.Mod) and the specification; it imports only Files and the zlib modules, so it can be
  used in the console and in other Oberon systems that have them. *)

IMPORT SYSTEM, Files, Zlib, ZlibBuffers, ZlibInflate, ZlibDeflate;

CONST
  (** results *)
  ok* = 0;
  notPNG* = 1;  (** not a PNG file (no PNG signature) *)
  badFormat* = 2;  (** a chunk or a header is malformed *)
  unsupported* = 3;  (** a feature the specification defines but this module does not read *)
  badCRC* = 4;  (** a chunk was damaged (its CRC differs) *)
  badData* = 5;  (** the compressed picture data cannot be inflated *)
  tooLarge* = 6;  (** the picture is too large for MaxPixels *)
  noImage* = 7;  (** Encode: no image, or an empty one *)

  MaxPixels* = 64 * 1024 * 1024;  (** the most pixels a picture may have *)
  MaxChunk = 7FFFFFFFH;

  (* colour types *)
  Grey = 0; RGB = 2; Palette = 3; GreyAlpha = 4; RGBAlpha = 6;

TYPE
  Image* = POINTER TO ImageDesc;
  ImageDesc* = RECORD
    width*, height*: LONGINT;
    alpha*: BOOLEAN;  (** the picture has transparency: alpha below 255 somewhere is possible *)
    pix*: POINTER TO ARRAY OF CHAR  (** the rows from the top, 4 bytes a pixel: red, green, blue, alpha *)
  END;

  Info* = RECORD
    width*, height*: LONGINT;
    depth*: LONGINT;  (** bits per sample: 1, 2, 4, 8, 16 *)
    colorType*: LONGINT;  (** 0 grey, 2 RGB, 3 palette, 4 grey and alpha, 6 RGB and alpha *)
    interlaced*: BOOLEAN
  END;

  Bytes = POINTER TO ARRAY OF CHAR;

VAR
  signature: ARRAY 8 OF CHAR;
  startRow, startCol, rowStep, colStep: ARRAY 7 OF LONGINT;  (* Adam7 *)

(** a new image of w by h pixels, all transparent black *)
PROCEDURE NewImage*(w, h: LONGINT): Image;
VAR img: Image; i: LONGINT;
BEGIN
  NEW(img); img.width := w; img.height := h; img.alpha := FALSE;
  IF (w > 0) & (h > 0) & (w <= MaxPixels DIV h) THEN
    NEW(img.pix, w * h * 4); i := 0; WHILE i < w * h * 4 DO img.pix[i] := 0X; INC(i) END
  ELSE img.pix := NIL
  END;
  RETURN img
END NewImage;

(** s := a description of the result res *)
PROCEDURE Message*(res: LONGINT; VAR s: ARRAY OF CHAR);
BEGIN
  CASE res OF
    ok: COPY("done", s)
  | notPNG: COPY("not a PNG file", s)
  | badFormat: COPY("malformed PNG file", s)
  | unsupported: COPY("a PNG feature that is not supported", s)
  | badCRC: COPY("damaged PNG file (CRC)", s)
  | badData: COPY("damaged picture data (zlib)", s)
  | tooLarge: COPY("picture too large", s)
  | noImage: COPY("no image", s)
  ELSE COPY("unknown error", s)
  END
END Message;

(* ----- reading ----- *)

(* a 32-bit number, the most significant byte first *)
PROCEDURE Get32(VAR b: ARRAY OF CHAR; i: LONGINT): LONGINT;
BEGIN
  RETURN SYSTEM.LSH(LONG(ORD(b[i])), 24) + SYSTEM.LSH(LONG(ORD(b[i + 1])), 16) + SYSTEM.LSH(LONG(ORD(b[i + 2])), 8) + ORD(b[i + 3])
END Get32;

PROCEDURE Read32(VAR R: Files.Rider): LONGINT;
VAR b: ARRAY 4 OF CHAR;
BEGIN
  Files.ReadBytes(R, b, 4); RETURN Get32(b, 0)
END Read32;

(* the bytes of a row of w pixels *)
PROCEDURE RowBytes(w, channels, depth: LONGINT): LONGINT;
BEGIN RETURN (w * channels * depth + 7) DIV 8
END RowBytes;

PROCEDURE Channels(colorType: LONGINT): LONGINT;
BEGIN
  CASE colorType OF Grey, Palette: RETURN 1 | GreyAlpha: RETURN 2 | RGB: RETURN 3 | RGBAlpha: RETURN 4 ELSE RETURN 0 END
END Channels;

PROCEDURE ValidDepth(colorType, depth: LONGINT): BOOLEAN;
BEGIN
  CASE colorType OF
    Grey: RETURN (depth = 1) OR (depth = 2) OR (depth = 4) OR (depth = 8) OR (depth = 16)
  | Palette: RETURN (depth = 1) OR (depth = 2) OR (depth = 4) OR (depth = 8)
  | RGB, GreyAlpha, RGBAlpha: RETURN (depth = 8) OR (depth = 16)
  ELSE RETURN FALSE
  END
END ValidDepth;

(* the size of a pass (Adam7) of a picture of w by h pixels *)
PROCEDURE PassSize(w, h, p: LONGINT; VAR pw, ph: LONGINT);
BEGIN
  IF w > startCol[p] THEN pw := (w - startCol[p] + colStep[p] - 1) DIV colStep[p] ELSE pw := 0 END;
  IF h > startRow[p] THEN ph := (h - startRow[p] + rowStep[p] - 1) DIV rowStep[p] ELSE ph := 0 END
END PassSize;

PROCEDURE Paeth(a, b, c: LONGINT): LONGINT;
VAR p, pa, pb, pc: LONGINT;
BEGIN
  p := a + b - c; pa := ABS(p - a); pb := ABS(p - b); pc := ABS(p - c);
  IF (pa <= pb) & (pa <= pc) THEN RETURN a ELSIF pb <= pc THEN RETURN b ELSE RETURN c END
END Paeth;

(* undo the filter of the row at raw[at] (its filter byte first, n bytes after it), prior the
  row before it (unfiltered, n bytes) or NIL; bpp the bytes of a pixel, at least 1 *)
PROCEDURE Unfilter(VAR raw: ARRAY OF CHAR; at, n, bpp: LONGINT; prior: Bytes; VAR cur: ARRAY OF CHAR): BOOLEAN;
VAR f, i, a, b, c, x: LONGINT;
BEGIN
  f := ORD(raw[at]); i := 0;
  WHILE i < n DO
    x := ORD(raw[at + 1 + i]);
    IF i >= bpp THEN a := ORD(cur[i - bpp]) ELSE a := 0 END;
    IF prior # NIL THEN b := ORD(prior[i]) ELSE b := 0 END;
    IF (prior # NIL) & (i >= bpp) THEN c := ORD(prior[i - bpp]) ELSE c := 0 END;
    CASE f OF
      0:
    | 1: x := x + a
    | 2: x := x + b
    | 3: x := x + (a + b) DIV 2
    | 4: x := x + Paeth(a, b, c)
    ELSE RETURN FALSE
    END;
    cur[i] := CHR(x MOD 256); INC(i)
  END;
  RETURN TRUE
END Unfilter;

(* sample k of the row cur (depth bits each), for depth 16 the more significant byte *)
PROCEDURE Sample(VAR cur: ARRAY OF CHAR; k, depth: LONGINT): LONGINT;
VAR bit: LONGINT;
BEGIN
  CASE depth OF
    8: RETURN ORD(cur[k])
  | 16: RETURN ORD(cur[2 * k])
  ELSE
    bit := k * depth;
    RETURN SYSTEM.LSH(LONG(ORD(cur[bit DIV 8])), bit MOD 8 + depth - 8) MOD SYSTEM.LSH(LONG(1), depth)
  END
END Sample;

(* the whole sample k (16 bits for depth 16), to compare with tRNS *)
PROCEDURE Full(VAR cur: ARRAY OF CHAR; k, depth: LONGINT): LONGINT;
BEGIN
  IF depth = 16 THEN RETURN ORD(cur[2 * k]) * 256 + ORD(cur[2 * k + 1]) ELSE RETURN Sample(cur, k, depth) END
END Full;

(* a grey sample of depth bits as 8 bits *)
PROCEDURE Scale(v, depth: LONGINT): LONGINT;
BEGIN
  CASE depth OF 1: RETURN v * 255 | 2: RETURN v * 85 | 4: RETURN v * 17 ELSE RETURN v END
END Scale;

(* inflate the zlib stream src[0..srcLen) into dst[0..dstLen); done the bytes produced.
  Inflate is given 4096 bytes at a time, as ZlibReaders does: in polpo 1.4.0 and before, a single
  Inflate with Finish (ZlibInflate.Uncompress) stopped after 32 KB of output *)
PROCEDURE Inflate(VAR src: ARRAY OF CHAR; srcLen: LONGINT; VAR dst: ARRAY OF CHAR; dstLen: LONGINT; VAR done: LONGINT): BOOLEAN;
CONST Piece = 4096;
VAR s: ZlibInflate.Stream; in: ARRAY Piece OF CHAR; pos, n, i, outBefore: LONGINT;
BEGIN
  done := 0; pos := 0;
  ZlibBuffers.Init(s.in, in, 0, Piece, 0); ZlibBuffers.Init(s.out, dst, 0, dstLen, dstLen);
  ZlibInflate.Open(s, TRUE);
  IF s.res.code # ZlibInflate.Ok THEN RETURN FALSE END;
  LOOP
    IF (s.in.avail = 0) & (pos < srcLen) THEN
      n := srcLen - pos; IF n > Piece THEN n := Piece END;
      i := 0; WHILE i < n DO in[i] := src[pos + i]; INC(i) END;
      INC(pos, n); ZlibBuffers.Rewind(s.in, n)
    END;
    outBefore := s.out.totalOut;
    ZlibInflate.Inflate(s, ZlibInflate.NoFlush);
    IF s.res.code = ZlibInflate.StreamEnd THEN EXIT END;
    IF (s.res.code # ZlibInflate.Ok) OR (s.in.avail = 0) & (pos >= srcLen) & (s.out.totalOut = outBefore) OR
      (s.out.avail = 0) THEN
      ZlibInflate.Close(s); RETURN FALSE
    END
  END;
  done := s.out.totalOut; ZlibInflate.Close(s);
  RETURN TRUE
END Inflate;

(** read the signature and the IHDR chunk from R *)
PROCEDURE ReadInfo*(VAR R: Files.Rider; VAR info: Info; VAR res: LONGINT);
VAR b: ARRAY 25 OF CHAR; i, crc: LONGINT;
BEGIN
  Files.ReadBytes(R, b, 8);
  i := 0; WHILE (i < 8) & (b[i] = signature[i]) DO INC(i) END;
  IF R.eof OR (i < 8) THEN res := notPNG; RETURN END;
  Files.ReadBytes(R, b, 25);  (* length, "IHDR", 13 bytes, CRC *)
  IF R.eof OR (Get32(b, 0) # 13) OR (b[4] # "I") OR (b[5] # "H") OR (b[6] # "D") OR (b[7] # "R") THEN
    res := badFormat; RETURN
  END;
  crc := Zlib.CRC32(0, b, 4, 17);
  IF crc # Get32(b, 21) THEN res := badCRC; RETURN END;
  info.width := Get32(b, 8); info.height := Get32(b, 12);
  info.depth := ORD(b[16]); info.colorType := ORD(b[17]); info.interlaced := b[20] = 1X;
  IF (info.width <= 0) OR (info.height <= 0) OR ~ValidDepth(info.colorType, info.depth) OR
    (b[18] # 0X) OR (b[19] # 0X) OR (ORD(b[20]) > 1) THEN res := badFormat
  ELSIF info.width > MaxPixels DIV info.height THEN res := tooLarge
  ELSE res := ok
  END
END ReadInfo;

(** decode the PNG picture read from R into img *)
PROCEDURE Decode*(VAR R: Files.Rider; VAR img: Image; VAR res: LONGINT);
VAR info: Info; len, crc, i, k, channels, bpp, rawLen, done, p, pw, ph, rb, at, y, x, dst, v, g: LONGINT;
  type: ARRAY 5 OF CHAR; data, raw, cur, buf: Bytes; prior: Bytes; size: LONGINT;
  pal: ARRAY 256 * 4 OF CHAR; palN: LONGINT; trns: BOOLEAN; tr, tg, tb: LONGINT;
  seenIDAT, endOfIDAT, plteSeen: BOOLEAN;
BEGIN
  img := NIL;
  ReadInfo(R, info, res); IF res # ok THEN RETURN END;
  channels := Channels(info.colorType);
  bpp := channels * info.depth DIV 8; IF bpp < 1 THEN bpp := 1 END;
  i := 0; WHILE i < 256 DO pal[4 * i] := 0X; pal[4 * i + 1] := 0X; pal[4 * i + 2] := 0X; pal[4 * i + 3] := 0FFX; INC(i) END;
  palN := 0; trns := FALSE; tr := -1; tg := -1; tb := -1; plteSeen := FALSE;
  NEW(data, 65536); size := 0; seenIDAT := FALSE; endOfIDAT := FALSE;
  LOOP  (* the chunks after IHDR *)
    len := Read32(R); Files.ReadBytes(R, type, 4); type[4] := 0X;  (* compared with strings *)
    IF R.eof OR (len < 0) OR (len > MaxChunk - 12) THEN res := badFormat; RETURN END;
    NEW(buf, len + 4);  (* the type and the data, for the CRC *)
    IF len > 0 THEN Files.ReadBytes(R, buf^, len); i := len - 1; WHILE i >= 0 DO buf[i + 4] := buf[i]; DEC(i) END END;
    i := 0; WHILE i < 4 DO buf[i] := type[i]; INC(i) END;
    crc := Read32(R);
    IF R.eof THEN res := badFormat; RETURN END;
    IF Zlib.CRC32(0, buf^, 0, len + 4) # crc THEN res := badCRC; RETURN END;
    IF type = "IDAT" THEN
      IF endOfIDAT THEN res := badFormat; RETURN END;
      seenIDAT := TRUE;
      IF size + len > LEN(data^) THEN  (* grow *)
        k := LEN(data^) * 2; WHILE k < size + len DO k := k * 2 END;
        NEW(raw, k); i := 0; WHILE i < size DO raw[i] := data[i]; INC(i) END; data := raw
      END;
      i := 0; WHILE i < len DO data[size + i] := buf[4 + i]; INC(i) END; INC(size, len)
    ELSE
      IF seenIDAT THEN endOfIDAT := TRUE END;
      IF type = "IEND" THEN EXIT
      ELSIF type = "PLTE" THEN
        IF (len MOD 3 # 0) OR (len > 768) OR (len = 0) OR seenIDAT THEN res := badFormat; RETURN END;
        palN := len DIV 3; i := 0;
        WHILE i < palN DO pal[4 * i] := buf[4 + 3 * i]; pal[4 * i + 1] := buf[5 + 3 * i]; pal[4 * i + 2] := buf[6 + 3 * i]; INC(i) END;
        plteSeen := TRUE
      ELSIF type = "tRNS" THEN
        trns := TRUE;
        IF info.colorType = Palette THEN
          i := 0; WHILE (i < len) & (i < 256) DO pal[4 * i + 3] := buf[4 + i]; INC(i) END
        ELSIF (info.colorType = Grey) & (len >= 2) THEN tr := ORD(buf[4]) * 256 + ORD(buf[5])
        ELSIF (info.colorType = RGB) & (len >= 6) THEN
          tr := ORD(buf[4]) * 256 + ORD(buf[5]); tg := ORD(buf[6]) * 256 + ORD(buf[7]); tb := ORD(buf[8]) * 256 + ORD(buf[9])
        ELSE trns := FALSE
        END
      ELSIF (CAP(type[0]) = type[0]) & (type # "IHDR") THEN res := unsupported; RETURN  (* an unknown critical chunk *)
      ELSIF type = "IHDR" THEN res := badFormat; RETURN
      END
    END
  END;
  IF ~seenIDAT OR (info.colorType = Palette) & ~plteSeen THEN res := badFormat; RETURN END;
  (* the size of the filtered data, all passes *)
  rawLen := 0;
  IF info.interlaced THEN
    p := 0;
    WHILE p < 7 DO
      PassSize(info.width, info.height, p, pw, ph);
      IF (pw > 0) & (ph > 0) THEN INC(rawLen, ph * (1 + RowBytes(pw, channels, info.depth))) END;
      INC(p)
    END
  ELSE rawLen := info.height * (1 + RowBytes(info.width, channels, info.depth))
  END;
  NEW(raw, rawLen + 1);  (* one byte more: with the output full, Inflate does not see the end of the stream *)
  IF ~Inflate(data^, size, raw^, rawLen + 1, done) OR (done # rawLen) THEN res := badData; RETURN END;
  data := NIL;
  img := NewImage(info.width, info.height);
  img.alpha := trns OR (info.colorType = GreyAlpha) OR (info.colorType = RGBAlpha);
  rb := RowBytes(info.width, channels, info.depth);
  NEW(cur, rb + 1); NEW(prior, rb + 1);
  at := 0; p := 0;
  LOOP
    IF info.interlaced THEN
      IF p = 7 THEN EXIT END;
      PassSize(info.width, info.height, p, pw, ph)
    ELSE
      IF p = 1 THEN EXIT END;
      pw := info.width; ph := info.height
    END;
    IF (pw > 0) & (ph > 0) THEN
      rb := RowBytes(pw, channels, info.depth); y := 0;
      WHILE y < ph DO
        IF y = 0 THEN
          IF ~Unfilter(raw^, at, rb, bpp, NIL, cur^) THEN res := badData; img := NIL; RETURN END
        ELSIF ~Unfilter(raw^, at, rb, bpp, prior, cur^) THEN res := badData; img := NIL; RETURN
        END;
        INC(at, rb + 1);
        x := 0;
        WHILE x < pw DO
          IF info.interlaced THEN
            dst := ((startRow[p] + y * rowStep[p]) * info.width + startCol[p] + x * colStep[p]) * 4
          ELSE dst := (y * info.width + x) * 4
          END;
          CASE info.colorType OF
            Grey:
              g := Scale(Sample(cur^, x, info.depth), info.depth);
              img.pix[dst] := CHR(g); img.pix[dst + 1] := CHR(g); img.pix[dst + 2] := CHR(g);
              IF trns & (Full(cur^, x, info.depth) = tr) THEN img.pix[dst + 3] := 0X ELSE img.pix[dst + 3] := 0FFX END
          | RGB:
              img.pix[dst] := CHR(Sample(cur^, 3 * x, info.depth));
              img.pix[dst + 1] := CHR(Sample(cur^, 3 * x + 1, info.depth));
              img.pix[dst + 2] := CHR(Sample(cur^, 3 * x + 2, info.depth));
              IF trns & (Full(cur^, 3 * x, info.depth) = tr) & (Full(cur^, 3 * x + 1, info.depth) = tg) &
                (Full(cur^, 3 * x + 2, info.depth) = tb) THEN img.pix[dst + 3] := 0X
              ELSE img.pix[dst + 3] := 0FFX
              END
          | Palette:
              v := Sample(cur^, x, info.depth);
              IF v >= palN THEN res := badData; img := NIL; RETURN END;
              img.pix[dst] := pal[4 * v]; img.pix[dst + 1] := pal[4 * v + 1]; img.pix[dst + 2] := pal[4 * v + 2];
              img.pix[dst + 3] := pal[4 * v + 3]
          | GreyAlpha:
              g := Sample(cur^, 2 * x, info.depth);
              img.pix[dst] := CHR(g); img.pix[dst + 1] := CHR(g); img.pix[dst + 2] := CHR(g);
              img.pix[dst + 3] := CHR(Sample(cur^, 2 * x + 1, info.depth))
          | RGBAlpha:
              img.pix[dst] := CHR(Sample(cur^, 4 * x, info.depth));
              img.pix[dst + 1] := CHR(Sample(cur^, 4 * x + 1, info.depth));
              img.pix[dst + 2] := CHR(Sample(cur^, 4 * x + 2, info.depth));
              img.pix[dst + 3] := CHR(Sample(cur^, 4 * x + 3, info.depth))
          END;
          INC(x)
        END;
        buf := prior; prior := cur; cur := buf;
        INC(y)
      END
    END;
    INC(p)
  END;
  res := ok
END Decode;

(* ----- writing ----- *)

PROCEDURE Put32(VAR b: ARRAY OF CHAR; i, x: LONGINT);
BEGIN
  b[i] := CHR(SYSTEM.LSH(x, -24) MOD 256); b[i + 1] := CHR(SYSTEM.LSH(x, -16) MOD 256);
  b[i + 2] := CHR(SYSTEM.LSH(x, -8) MOD 256); b[i + 3] := CHR(x MOD 256)
END Put32;

(* write a chunk: its length, the type and data in buf[0..4+len), its CRC *)
PROCEDURE Chunk(VAR W: Files.Rider; VAR buf: ARRAY OF CHAR; len: LONGINT);
VAR b: ARRAY 4 OF CHAR;
BEGIN
  Put32(b, 0, len); Files.WriteBytes(W, b, 4);
  Files.WriteBytes(W, buf, len + 4);
  Put32(b, 0, Zlib.CRC32(0, buf, 0, len + 4)); Files.WriteBytes(W, b, 4)
END Chunk;

(** write img to W as a PNG picture: RGB, or RGB and alpha if img.alpha; level the zlib
  compression level 0..9, or -1 for the default *)
PROCEDURE Encode*(VAR W: Files.Rider; img: Image; level: LONGINT; VAR res: LONGINT);
VAR hdr: ARRAY 17 OF CHAR; iend: ARRAY 4 OF CHAR; bpp, rb, rawLen, y, x, i, f, best, sum, bestSum, a, b, c, v, src, zlen, at: LONGINT;
  raw, out, row, prior, trial: Bytes; zres: LONGINT;
BEGIN
  IF (img = NIL) OR (img.pix = NIL) OR (img.width <= 0) OR (img.height <= 0) THEN res := noImage; RETURN END;
  IF img.alpha THEN bpp := 4 ELSE bpp := 3 END;
  rb := img.width * bpp; rawLen := img.height * (rb + 1);
  NEW(raw, rawLen); NEW(row, rb); NEW(prior, rb); NEW(trial, rb);
  i := 0; WHILE i < rb DO prior[i] := 0X; INC(i) END;
  y := 0;
  WHILE y < img.height DO
    x := 0; src := y * img.width * 4; i := 0;
    WHILE x < img.width DO
      row[i] := img.pix[src]; row[i + 1] := img.pix[src + 1]; row[i + 2] := img.pix[src + 2];
      IF bpp = 4 THEN row[i + 3] := img.pix[src + 3] END;
      INC(i, bpp); INC(src, 4); INC(x)
    END;
    (* the filter with the least sum of the bytes taken as signed numbers *)
    best := 0; bestSum := MAX(LONGINT); f := 0;
    WHILE f <= 4 DO
      sum := 0; i := 0;
      WHILE i < rb DO
        IF i >= bpp THEN a := ORD(row[i - bpp]) ELSE a := 0 END;
        IF y > 0 THEN b := ORD(prior[i]) ELSE b := 0 END;
        IF (y > 0) & (i >= bpp) THEN c := ORD(prior[i - bpp]) ELSE c := 0 END;
        CASE f OF
          0: v := ORD(row[i])
        | 1: v := ORD(row[i]) - a
        | 2: v := ORD(row[i]) - b
        | 3: v := ORD(row[i]) - (a + b) DIV 2
        | 4: v := ORD(row[i]) - Paeth(a, b, c)
        END;
        v := v MOD 256; IF v < 128 THEN INC(sum, v) ELSE INC(sum, 256 - v) END;
        INC(i)
      END;
      IF sum < bestSum THEN bestSum := sum; best := f END;
      INC(f)
    END;
    at := y * (rb + 1); raw[at] := CHR(best); i := 0;
    WHILE i < rb DO
      IF i >= bpp THEN a := ORD(row[i - bpp]) ELSE a := 0 END;
      IF y > 0 THEN b := ORD(prior[i]) ELSE b := 0 END;
      IF (y > 0) & (i >= bpp) THEN c := ORD(prior[i - bpp]) ELSE c := 0 END;
      CASE best OF
        0: v := ORD(row[i])
      | 1: v := ORD(row[i]) - a
      | 2: v := ORD(row[i]) - b
      | 3: v := ORD(row[i]) - (a + b) DIV 2
      | 4: v := ORD(row[i]) - Paeth(a, b, c)
      END;
      raw[at + 1 + i] := CHR(v MOD 256); INC(i)
    END;
    trial := prior; prior := row; row := trial;
    INC(y)
  END;
  NEW(out, 4 + rawLen + rawLen DIV 100 + 1024);
  out[0] := "I"; out[1] := "D"; out[2] := "A"; out[3] := "T";
  IF (level < -1) OR (level > 9) THEN level := -1 END;
  ZlibDeflate.Compress(raw^, out^, 0, rawLen, 4, LEN(out^) - 4, SHORT(SHORT(level)), Zlib.DefaultStrategy, zlen, zres);
  IF (zres # ZlibDeflate.Ok) & (zres # ZlibDeflate.StreamEnd) THEN res := badData; RETURN END;
  Files.WriteBytes(W, signature, 8);
  hdr[0] := "I"; hdr[1] := "H"; hdr[2] := "D"; hdr[3] := "R";
  Put32(hdr, 4, img.width); Put32(hdr, 8, img.height);
  hdr[12] := 8X; IF img.alpha THEN hdr[13] := 6X ELSE hdr[13] := 2X END;
  hdr[14] := 0X; hdr[15] := 0X; hdr[16] := 0X;
  Chunk(W, hdr, 13);
  Chunk(W, out^, zlen);
  iend[0] := "I"; iend[1] := "E"; iend[2] := "N"; iend[3] := "D";
  Chunk(W, iend, 0);
  res := ok
END Encode;

BEGIN
  signature[0] := 89X; signature[1] := "P"; signature[2] := "N"; signature[3] := "G";
  signature[4] := 0DX; signature[5] := 0AX; signature[6] := 1AX; signature[7] := 0AX;
  startRow[0] := 0; startRow[1] := 0; startRow[2] := 4; startRow[3] := 0; startRow[4] := 2; startRow[5] := 0; startRow[6] := 1;
  startCol[0] := 0; startCol[1] := 4; startCol[2] := 0; startCol[3] := 2; startCol[4] := 0; startCol[5] := 1; startCol[6] := 0;
  rowStep[0] := 8; rowStep[1] := 8; rowStep[2] := 8; rowStep[3] := 4; rowStep[4] := 4; rowStep[5] := 2; rowStep[6] := 2;
  colStep[0] := 8; colStep[1] := 8; colStep[2] := 4; colStep[3] := 4; colStep[4] := 2; colStep[5] := 2; colStep[6] := 1
END PNG0.
