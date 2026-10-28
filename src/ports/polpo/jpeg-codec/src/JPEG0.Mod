MODULE JPEG0;  (** JPEG pictures: decoding (baseline and progressive) and encoding (baseline), on Files *)

(** ITU-T T.81 (ISO/IEC 10918-1) with JFIF. Decode reads JPEG pictures with Huffman coding and 8 bits
  a sample, baseline or progressive: grey, YCbCr, RGB, CMYK or YCCK, any sampling factors that divide
  the largest ones, with or without restart intervals, into an Image of 8-bit red, green, blue and
  alpha (always 255). Encode writes an Image as a baseline JFIF picture of a quality from 1 to 100:
  YCbCr with the colours halved in both directions, or grey when every pixel is grey, with the tables
  of the specification (annex K).
  The inverse DCT (the integer one of libjpeg, "islow"), the upsampling of the colours (libjpeg's
  "fancy upsampling") and the colour conversion compute as those of libjpeg, so a picture decodes to
  the pixels djpeg gives. Written for polpo after the specification and libjpeg of the Independent
  JPEG Group; it imports only Files, so it can be used in the console and in other Oberon systems. *)

IMPORT Files;

CONST
  (** results *)
  ok* = 0;
  notJPEG* = 1;  (** not a JPEG file (no SOI marker) *)
  badFormat* = 2;  (** a marker segment or the coded data is malformed *)
  unsupported* = 3;  (** arithmetic coding, lossless, hierarchical or 12-bit pictures *)
  tooLarge* = 4;  (** the picture is too large for MaxPixels, or (Encode) wider or higher than 65535 *)
  noImage* = 5;  (** Encode: no image, or an empty one *)

  MaxPixels* = 64 * 1024 * 1024;  (** the most pixels a picture may have *)

  (* markers *)
  SOF0 = 0C0H; SOF1 = 0C1H; SOF2 = 0C2H; DHT = 0C4H; JPG = 0C8H; DAC = 0CCH;
  RST0 = 0D0H; RST7 = 0D7H; SOI = 0D8H; EOI = 0D9H; SOS = 0DAH; DQT = 0DBH; DRI = 0DDH;
  APP0 = 0E0H; APP14 = 0EEH; TEM = 01H;

  (* colour spaces of the decoded components *)
  Grey = 0; YCbCr = 1; RGB = 2; CMYK = 3; YCCK = 4;

TYPE
  Image* = POINTER TO ImageDesc;
  ImageDesc* = RECORD
    width*, height*: LONGINT;
    pix*: POINTER TO ARRAY OF CHAR  (** the rows from the top, 4 bytes a pixel: red, green, blue, alpha *)
  END;

  Info* = RECORD
    width*, height*: LONGINT;
    components*: LONGINT;  (** 1 grey, 3 colour, 4 CMYK or YCCK *)
    progressive*: BOOLEAN
  END;

  Bytes = POINTER TO ARRAY OF CHAR;
  Coefs = POINTER TO ARRAY OF INTEGER;

  Huff = POINTER TO HuffDesc;
  HuffDesc = RECORD
    look: ARRAY 512 OF INTEGER;  (* the next 9 bits: length * 256 + symbol of a code of at most 9 bits, 0 *)
    maxcode: ARRAY 18 OF LONGINT;  (* the largest code of each length, -1 none *)
    valptr, mincode: ARRAY 17 OF LONGINT;
    vals: ARRAY 256 OF CHAR
  END;

  Comp = RECORD
    id, h, v, tq, td, ta: LONGINT;
    w, ht: LONGINT;  (* samples: the picture scaled by h / hmax and v / vmax *)
    bw, bh: LONGINT;  (* blocks a row and a column, whole MCUs *)
    pred: LONGINT;  (* the DC of the last block *)
    plane: Bytes;  (* bw * 8 by bh * 8 samples *)
    coef: Coefs  (* progressive: 64 coefficients a block, in natural order *)
  END;

  Decoder = POINTER TO DecoderDesc;
  DecoderDesc = RECORD
    R: Files.Rider;
    acc, nbits: LONGINT;  (* the bits not used yet, acc < 2^nbits *)
    marker: LONGINT;  (* a marker met in the coded data, 0 none *)
    fake: LONGINT;  (* the last bits of acc are 0 bits put after the marker *)
    short: BOOLEAN;  (* bits after the marker were used: the MCUs that follow are left 0, as libjpeg *)
    res: LONGINT;
    width, height, ncomp, hmax, vmax, mcux, mcuy, restart, eobrun: LONGINT;
    progressive, frame, jfif, adobe: BOOLEAN;
    transform: LONGINT;  (* of the Adobe marker *)
    comp: ARRAY 4 OF Comp;
    q: ARRAY 4, 64 OF LONGINT;  (* quantization tables, natural order *)
    qok: ARRAY 4 OF BOOLEAN;
    dc, ac: ARRAY 4 OF Huff;
    ns, ss, se, ah, al: LONGINT;  (* the scan *)
    sc: ARRAY 4 OF LONGINT  (* components of the scan *)
  END;

  Encoder = RECORD
    acc, nbits: LONGINT;
    q: ARRAY 2, 64 OF LONGINT;  (* luminance, chrominance; natural order *)
    code, size: ARRAY 4, 256 OF LONGINT  (* DC and AC of the luminance, DC and AC of the chrominance *)
  END;

VAR
  zz: ARRAY 80 OF LONGINT;  (* the natural index of the k-th coefficient in zigzag order; 63 after 63 *)
  idctLimit: ARRAY 1024 OF CHAR;  (* x + 128 limited to 0..255, for x MOD 1024, as libjpeg *)
  limit: ARRAY 1024 OF CHAR;  (* x - 384 limited to 0..255 *)
  crR, cbB, crG, cbG: ARRAY 256 OF LONGINT;  (* YCbCr to RGB, as libjpeg *)
  stdBits: ARRAY 4, 17 OF LONGINT;  (* the Huffman tables of annex K: codes of each length *)
  stdVals: ARRAY 4, 162 OF LONGINT;
  stdN: ARRAY 4 OF LONGINT;
  stdQ: ARRAY 2, 64 OF LONGINT;  (* the quantization tables of annex K, natural order *)

(** a new image of w by h pixels, all black *)
PROCEDURE NewImage*(w, h: LONGINT): Image;
VAR img: Image; i, n: LONGINT;
BEGIN
  NEW(img); img.width := w; img.height := h; img.pix := NIL;
  IF (w > 0) & (h > 0) & (w <= MaxPixels DIV h) THEN
    n := w * h * 4; NEW(img.pix, n); i := 0;
    WHILE i < n DO img.pix[i] := 0X; img.pix[i + 1] := 0X; img.pix[i + 2] := 0X; img.pix[i + 3] := 0FFX; INC(i, 4) END
  END;
  RETURN img
END NewImage;

(** s := a description of the result res *)
PROCEDURE Message*(res: LONGINT; VAR s: ARRAY OF CHAR);
BEGIN
  CASE res OF
    ok: COPY("done", s)
  | notJPEG: COPY("not a JPEG file", s)
  | badFormat: COPY("malformed JPEG file", s)
  | unsupported: COPY("a JPEG feature that is not supported", s)
  | tooLarge: COPY("picture too large", s)
  | noImage: COPY("no image", s)
  ELSE COPY("unknown error", s)
  END
END Message;

(* reading marker segments *)

PROCEDURE Byte(d: Decoder): LONGINT;
VAR c: CHAR;
BEGIN
  Files.Read(d.R, c);
  IF d.R.eof THEN d.res := badFormat; RETURN 0 END;
  RETURN ORD(c)
END Byte;

PROCEDURE Word(d: Decoder): LONGINT;
VAR hi: LONGINT;
BEGIN hi := Byte(d); RETURN hi * 256 + Byte(d)
END Word;

(* skip a segment of which the length comes next *)
PROCEDURE Skip(d: Decoder);
VAR n, b: LONGINT;
BEGIN
  n := Word(d) - 2;
  IF n < 0 THEN d.res := badFormat END;
  WHILE (n > 0) & (d.res = ok) DO b := Byte(d); DEC(n) END
END Skip;

(* the next marker: FF and a byte other than 0 and FF; -1 at the end of the file *)
PROCEDURE NextMarker(d: Decoder): LONGINT;
VAR c: CHAR; m: LONGINT;
BEGIN
  IF d.marker # 0 THEN m := d.marker; d.marker := 0; RETURN m END;
  LOOP
    Files.Read(d.R, c);
    IF d.R.eof THEN RETURN -1 END;
    IF c = 0FFX THEN
      REPEAT Files.Read(d.R, c) UNTIL d.R.eof OR (c # 0FFX);
      IF d.R.eof THEN RETURN -1 END;
      IF c # 0X THEN RETURN ORD(c) END
    END
  END
END NextMarker;

(* APP0 (JFIF) and APP14 (Adobe) *)
PROCEDURE ReadApp(d: Decoder; m: LONGINT);
VAR n, i, b: LONGINT; s: ARRAY 12 OF CHAR;
BEGIN
  n := Word(d) - 2; i := 0;
  WHILE (i < n) & (d.res = ok) DO b := Byte(d); IF i < 12 THEN s[i] := CHR(b) END; INC(i) END;
  IF d.res # ok THEN RETURN END;
  IF (m = APP0) & (n >= 5) & (s[0] = "J") & (s[1] = "F") & (s[2] = "I") & (s[3] = "F") & (s[4] = 0X) THEN d.jfif := TRUE
  ELSIF (m = APP14) & (n >= 12) & (s[0] = "A") & (s[1] = "d") & (s[2] = "o") & (s[3] = "b") & (s[4] = "e") THEN
    d.adobe := TRUE; d.transform := ORD(s[11])
  END
END ReadApp;

(* the decoding tables of the codes of each length (annex C and F.2.2.3) *)
PROCEDURE Build(h: Huff; VAR counts: ARRAY OF LONGINT): BOOLEAN;
VAR l, code, k, i, c, j, n: LONGINT;
BEGIN
  i := 0; WHILE i < 512 DO h.look[i] := 0; INC(i) END;
  code := 0; k := 0; l := 1;
  WHILE l <= 16 DO
    h.valptr[l] := k; h.mincode[l] := code;
    IF counts[l] > 0 THEN
      IF code + counts[l] > ASH(1, l) THEN RETURN FALSE END;  (* more codes than this length has *)
      IF l <= 9 THEN
        i := 0;
        WHILE i < counts[l] DO  (* every 9 bits beginning with this code *)
          c := ASH(code + i, 9 - l); n := ASH(1, 9 - l); j := 0;
          WHILE j < n DO h.look[c + j] := SHORT(l * 256 + ORD(h.vals[k + i])); INC(j) END;
          INC(i)
        END
      END;
      INC(code, counts[l]); INC(k, counts[l]); h.maxcode[l] := code - 1
    ELSE h.maxcode[l] := -1
    END;
    code := code * 2; INC(l)
  END;
  h.maxcode[17] := MAX(LONGINT);
  RETURN TRUE
END Build;

PROCEDURE ReadDHT(d: Decoder);
VAR len, k, tc, th, n, i: LONGINT; counts: ARRAY 17 OF LONGINT; h: Huff;
BEGIN
  len := Word(d) - 2;
  WHILE (len > 0) & (d.res = ok) DO
    k := Byte(d); tc := k DIV 16; th := k MOD 16;
    IF (tc > 1) OR (th > 3) THEN d.res := badFormat; RETURN END;
    n := 0; i := 1;
    WHILE i <= 16 DO counts[i] := Byte(d); INC(n, counts[i]); INC(i) END;
    IF n > 256 THEN d.res := badFormat; RETURN END;
    NEW(h); i := 0;
    WHILE i < n DO h.vals[i] := CHR(Byte(d)); INC(i) END;
    IF (d.res = ok) & ~Build(h, counts) THEN d.res := badFormat END;
    IF tc = 0 THEN d.dc[th] := h ELSE d.ac[th] := h END;
    DEC(len, 17 + n)
  END
END ReadDHT;

PROCEDURE ReadDQT(d: Decoder);
VAR len, k, pq, tq, i: LONGINT;
BEGIN
  len := Word(d) - 2;
  WHILE (len > 0) & (d.res = ok) DO
    k := Byte(d); pq := k DIV 16; tq := k MOD 16;
    IF (pq > 1) OR (tq > 3) THEN d.res := badFormat; RETURN END;
    i := 0;
    WHILE i < 64 DO
      IF pq = 0 THEN d.q[tq, zz[i]] := Byte(d) ELSE d.q[tq, zz[i]] := Word(d) END;
      INC(i)
    END;
    d.qok[tq] := TRUE;
    DEC(len, 65 + 64 * pq)
  END
END ReadDQT;

PROCEDURE ReadFrame(d: Decoder; progressive: BOOLEAN);
VAR len, p, i, k, n: LONGINT;
BEGIN
  IF d.frame THEN d.res := badFormat; RETURN END;
  len := Word(d); p := Byte(d); d.height := Word(d); d.width := Word(d); d.ncomp := Byte(d);
  IF d.res # ok THEN RETURN END;
  IF (p # 8) OR (d.height = 0) THEN d.res := unsupported; RETURN END;  (* 12 bits; the height in a DNL marker *)
  IF (d.width = 0) OR (d.ncomp # 1) & (d.ncomp # 3) & (d.ncomp # 4) OR (len # 8 + 3 * d.ncomp) THEN
    d.res := badFormat; RETURN
  END;
  IF d.width > MaxPixels DIV d.height THEN d.res := tooLarge; RETURN END;
  d.hmax := 1; d.vmax := 1; i := 0;
  WHILE i < d.ncomp DO
    d.comp[i].id := Byte(d); k := Byte(d); d.comp[i].h := k DIV 16; d.comp[i].v := k MOD 16; d.comp[i].tq := Byte(d);
    IF (d.comp[i].h < 1) OR (d.comp[i].h > 4) OR (d.comp[i].v < 1) OR (d.comp[i].v > 4) OR (d.comp[i].tq > 3) THEN
      d.res := badFormat; RETURN
    END;
    IF d.comp[i].h > d.hmax THEN d.hmax := d.comp[i].h END;
    IF d.comp[i].v > d.vmax THEN d.vmax := d.comp[i].v END;
    INC(i)
  END;
  IF d.res # ok THEN RETURN END;
  d.mcux := (d.width + 8 * d.hmax - 1) DIV (8 * d.hmax); d.mcuy := (d.height + 8 * d.vmax - 1) DIV (8 * d.vmax);
  i := 0;
  WHILE i < d.ncomp DO
    IF (d.hmax MOD d.comp[i].h # 0) OR (d.vmax MOD d.comp[i].v # 0) THEN d.res := unsupported; RETURN END;
    d.comp[i].w := (d.width * d.comp[i].h + d.hmax - 1) DIV d.hmax;
    d.comp[i].ht := (d.height * d.comp[i].v + d.vmax - 1) DIV d.vmax;
    d.comp[i].bw := d.mcux * d.comp[i].h; d.comp[i].bh := d.mcuy * d.comp[i].v;
    n := d.comp[i].bw * d.comp[i].bh * 64;
    NEW(d.comp[i].plane, n); d.comp[i].coef := NIL;
    IF progressive THEN
      NEW(d.comp[i].coef, n); k := 0;
      WHILE k < n DO d.comp[i].coef[k] := 0; INC(k) END
    END;
    INC(i)
  END;
  d.progressive := progressive; d.frame := TRUE
END ReadFrame;

(* the coded data *)

(* fill the bits to more than 16; after a marker or the end of the file, zeros *)
PROCEDURE Fill(d: Decoder);
VAR c: CHAR; b: LONGINT;
BEGIN
  WHILE d.nbits <= 16 DO
    b := 0;
    IF d.marker = 0 THEN
      Files.Read(d.R, c);
      IF d.R.eof THEN d.marker := EOI
      ELSIF c = 0FFX THEN
        REPEAT Files.Read(d.R, c) UNTIL d.R.eof OR (c # 0FFX);
        IF d.R.eof THEN d.marker := EOI ELSIF c = 0X THEN b := 255 ELSE d.marker := ORD(c) END
      ELSE b := ORD(c)
      END
    END;
    IF d.marker # 0 THEN INC(d.fake, 8) END;
    d.acc := d.acc * 256 + b; INC(d.nbits, 8)
  END
END Fill;

(* after bits were taken: were some of them put after the marker *)
PROCEDURE Used(d: Decoder);
BEGIN
  IF d.nbits < d.fake THEN d.short := TRUE; d.fake := d.nbits END
END Used;

(* the next n bits (n <= 16) *)
PROCEDURE Bits(d: Decoder; n: LONGINT): LONGINT;
VAR v: LONGINT;
BEGIN
  IF n = 0 THEN RETURN 0 END;
  IF d.nbits < n THEN Fill(d) END;
  DEC(d.nbits, n); v := ASH(d.acc, -d.nbits); d.acc := d.acc - ASH(v, d.nbits); Used(d);
  RETURN v
END Bits;

(* the value of the s bits v (F.2.2.1) *)
PROCEDURE Extend(v, s: LONGINT): LONGINT;
BEGIN
  IF (s > 0) & (v < ASH(1, s - 1)) THEN RETURN v - ASH(1, s) + 1 END;
  RETURN v
END Extend;

(* the next symbol coded with h; for a code that is not in h, 0, as libjpeg *)
PROCEDURE Huffman(d: Decoder; h: Huff): LONGINT;
VAR look, l, code: LONGINT;
BEGIN
  IF d.nbits <= 16 THEN Fill(d) END;
  look := h.look[ASH(d.acc, 9 - d.nbits)];
  IF look # 0 THEN
    l := look DIV 256; DEC(d.nbits, l); d.acc := d.acc - ASH(ASH(d.acc, -d.nbits), d.nbits); Used(d);
    RETURN look MOD 256
  END;
  l := 10; code := ASH(d.acc, 10 - d.nbits);
  WHILE (l <= 16) & (code > h.maxcode[l]) DO INC(l); code := ASH(d.acc, l - d.nbits) END;
  IF l > 16 THEN DEC(d.nbits, 16); d.acc := d.acc - ASH(ASH(d.acc, -d.nbits), d.nbits); Used(d); RETURN 0 END;
  DEC(d.nbits, l); d.acc := d.acc - ASH(code, d.nbits); Used(d);
  RETURN ORD(h.vals[h.valptr[l] + code - h.mincode[l]])
END Huffman;

(* at a restart marker: the bits left go, the predictions start again *)
PROCEDURE Restart(d: Decoder);
VAR c: CHAR; i: LONGINT;
BEGIN
  d.acc := 0; d.nbits := 0; d.fake := 0;
  IF d.marker = 0 THEN
    LOOP
      Files.Read(d.R, c);
      IF d.R.eof THEN d.marker := EOI; EXIT END;
      IF c = 0FFX THEN
        REPEAT Files.Read(d.R, c) UNTIL d.R.eof OR (c # 0FFX);
        IF d.R.eof THEN d.marker := EOI; EXIT ELSIF c # 0X THEN d.marker := ORD(c); EXIT END
      END
    END
  END;
  IF (d.marker >= RST0) & (d.marker <= RST7) THEN d.marker := 0; d.short := FALSE END;
  i := 0; WHILE i < d.ncomp DO d.comp[i].pred := 0; INC(i) END;
  d.eobrun := 0
END Restart;

(* the inverse DCT of the coefficients blk (natural order) quantized with q, into out at at: that of
  libjpeg (jidctint.c, "islow"; Loeffler, Ligtenberg and Moschytz), with its rounding *)
PROCEDURE IDCT(VAR blk, q: ARRAY OF LONGINT; out: Bytes; at, stride: LONGINT);
VAR ws: ARRAY 64 OF LONGINT; i, p: LONGINT;
  tmp0, tmp1, tmp2, tmp3, tmp10, tmp11, tmp12, tmp13, z1, z2, z3, z4, z5: LONGINT;
BEGIN
  i := 0;
  WHILE i < 8 DO  (* columns *)
    IF (blk[8 + i] = 0) & (blk[16 + i] = 0) & (blk[24 + i] = 0) & (blk[32 + i] = 0) & (blk[40 + i] = 0)
      & (blk[48 + i] = 0) & (blk[56 + i] = 0) THEN
      z1 := blk[i] * q[i] * 4;
      ws[i] := z1; ws[8 + i] := z1; ws[16 + i] := z1; ws[24 + i] := z1;
      ws[32 + i] := z1; ws[40 + i] := z1; ws[48 + i] := z1; ws[56 + i] := z1
    ELSE
      z2 := blk[16 + i] * q[16 + i]; z3 := blk[48 + i] * q[48 + i];
      z1 := (z2 + z3) * 4433; tmp2 := z1 - z3 * 15137; tmp3 := z1 + z2 * 6270;
      z2 := blk[i] * q[i]; z3 := blk[32 + i] * q[32 + i];
      tmp0 := (z2 + z3) * 8192; tmp1 := (z2 - z3) * 8192;
      tmp10 := tmp0 + tmp3; tmp13 := tmp0 - tmp3; tmp11 := tmp1 + tmp2; tmp12 := tmp1 - tmp2;
      tmp0 := blk[56 + i] * q[56 + i]; tmp1 := blk[40 + i] * q[40 + i];
      tmp2 := blk[24 + i] * q[24 + i]; tmp3 := blk[8 + i] * q[8 + i];
      z1 := tmp0 + tmp3; z2 := tmp1 + tmp2; z3 := tmp0 + tmp2; z4 := tmp1 + tmp3;
      z5 := (z3 + z4) * 9633;
      tmp0 := tmp0 * 2446; tmp1 := tmp1 * 16819; tmp2 := tmp2 * 25172; tmp3 := tmp3 * 12299;
      z1 := -z1 * 7373; z2 := -z2 * 20995; z3 := -z3 * 16069 + z5; z4 := -z4 * 3196 + z5;
      tmp0 := tmp0 + z1 + z3; tmp1 := tmp1 + z2 + z4; tmp2 := tmp2 + z2 + z3; tmp3 := tmp3 + z1 + z4;
      ws[i] := ASH(tmp10 + tmp3 + 1024, -11); ws[56 + i] := ASH(tmp10 - tmp3 + 1024, -11);
      ws[8 + i] := ASH(tmp11 + tmp2 + 1024, -11); ws[48 + i] := ASH(tmp11 - tmp2 + 1024, -11);
      ws[16 + i] := ASH(tmp12 + tmp1 + 1024, -11); ws[40 + i] := ASH(tmp12 - tmp1 + 1024, -11);
      ws[24 + i] := ASH(tmp13 + tmp0 + 1024, -11); ws[32 + i] := ASH(tmp13 - tmp0 + 1024, -11)
    END;
    INC(i)
  END;
  i := 0;
  WHILE i < 8 DO  (* rows *)
    p := 8 * i;
    z2 := ws[p + 2]; z3 := ws[p + 6];
    z1 := (z2 + z3) * 4433; tmp2 := z1 - z3 * 15137; tmp3 := z1 + z2 * 6270;
    tmp0 := (ws[p] + ws[p + 4]) * 8192; tmp1 := (ws[p] - ws[p + 4]) * 8192;
    tmp10 := tmp0 + tmp3; tmp13 := tmp0 - tmp3; tmp11 := tmp1 + tmp2; tmp12 := tmp1 - tmp2;
    tmp0 := ws[p + 7]; tmp1 := ws[p + 5]; tmp2 := ws[p + 3]; tmp3 := ws[p + 1];
    z1 := tmp0 + tmp3; z2 := tmp1 + tmp2; z3 := tmp0 + tmp2; z4 := tmp1 + tmp3;
    z5 := (z3 + z4) * 9633;
    tmp0 := tmp0 * 2446; tmp1 := tmp1 * 16819; tmp2 := tmp2 * 25172; tmp3 := tmp3 * 12299;
    z1 := -z1 * 7373; z2 := -z2 * 20995; z3 := -z3 * 16069 + z5; z4 := -z4 * 3196 + z5;
    tmp0 := tmp0 + z1 + z3; tmp1 := tmp1 + z2 + z4; tmp2 := tmp2 + z2 + z3; tmp3 := tmp3 + z1 + z4;
    p := at + i * stride;
    out[p] := idctLimit[ASH(tmp10 + tmp3 + 131072, -18) MOD 1024];
    out[p + 7] := idctLimit[ASH(tmp10 - tmp3 + 131072, -18) MOD 1024];
    out[p + 1] := idctLimit[ASH(tmp11 + tmp2 + 131072, -18) MOD 1024];
    out[p + 6] := idctLimit[ASH(tmp11 - tmp2 + 131072, -18) MOD 1024];
    out[p + 2] := idctLimit[ASH(tmp12 + tmp1 + 131072, -18) MOD 1024];
    out[p + 5] := idctLimit[ASH(tmp12 - tmp1 + 131072, -18) MOD 1024];
    out[p + 3] := idctLimit[ASH(tmp13 + tmp0 + 131072, -18) MOD 1024];
    out[p + 4] := idctLimit[ASH(tmp13 - tmp0 + 131072, -18) MOD 1024];
    INC(i)
  END
END IDCT;

(* a correction bit of the coefficient at i of an AC refinement scan *)
PROCEDURE Correct(d: Decoder; c: Coefs; i, p1: LONGINT);
VAR t: LONGINT;
BEGIN
  t := c[i];
  IF (Bits(d, 1) = 1) & ~ODD(ASH(t, -d.al)) THEN
    IF t >= 0 THEN c[i] := SHORT(t + p1) ELSE c[i] := SHORT(t - p1) END
  END
END Correct;

(* the block bx, by of component ci; baseline: decoded and transformed into the plane, progressive:
  the coefficients of this scan (G.1.2, as libjpeg's jdphuff.c) *)
PROCEDURE Block(d: Decoder; ci, bx, by: LONGINT);
VAR blk: ARRAY 64 OF LONGINT; i, k, r, s, t, base, p1: LONGINT; ac: Huff; c: Coefs;
BEGIN
  IF ~d.progressive THEN
    i := 0; WHILE i < 64 DO blk[i] := 0; INC(i) END;
    t := Huffman(d, d.dc[d.comp[ci].td]); s := Bits(d, t);
    INC(d.comp[ci].pred, Extend(s, t)); blk[0] := d.comp[ci].pred;
    ac := d.ac[d.comp[ci].ta]; k := 1;
    WHILE k < 64 DO
      t := Huffman(d, ac); r := t DIV 16; s := t MOD 16;
      IF s # 0 THEN INC(k, r); t := Bits(d, s); blk[zz[k]] := Extend(t, s); INC(k)
      ELSIF r = 15 THEN INC(k, 16)
      ELSE k := 64
      END
    END;
    IDCT(blk, d.q[d.comp[ci].tq], d.comp[ci].plane, (by * d.comp[ci].bw * 8 + bx) * 8, d.comp[ci].bw * 8)
  ELSE
    c := d.comp[ci].coef; base := (by * d.comp[ci].bw + bx) * 64;
    IF d.ss = 0 THEN
      IF d.ah = 0 THEN  (* DC, first scan *)
        t := Huffman(d, d.dc[d.comp[ci].td]); s := Bits(d, t);
        INC(d.comp[ci].pred, Extend(s, t)); c[base] := SHORT(ASH(d.comp[ci].pred, d.al))
      ELSIF (Bits(d, 1) = 1) & ~ODD(ASH(LONG(c[base]), -d.al)) THEN  (* DC, refinement *)
        c[base] := SHORT(c[base] + ASH(1, d.al))
      END
    ELSIF d.ah = 0 THEN  (* AC, first scan *)
      IF d.eobrun > 0 THEN DEC(d.eobrun)
      ELSE
        ac := d.ac[d.comp[ci].ta]; k := d.ss;
        WHILE k <= d.se DO
          t := Huffman(d, ac); r := t DIV 16; s := t MOD 16;
          IF s # 0 THEN INC(k, r); t := Bits(d, s); c[base + zz[k]] := SHORT(ASH(Extend(t, s), d.al)); INC(k)
          ELSIF r = 15 THEN INC(k, 16)
          ELSE
            d.eobrun := ASH(1, r); IF r > 0 THEN INC(d.eobrun, Bits(d, r)) END;
            DEC(d.eobrun); k := 64
          END
        END
      END
    ELSE  (* AC, refinement *)
      ac := d.ac[d.comp[ci].ta]; p1 := ASH(1, d.al); k := d.ss;
      IF d.eobrun = 0 THEN
        LOOP
          IF k > d.se THEN EXIT END;
          t := Huffman(d, ac); r := t DIV 16; s := t MOD 16;
          IF s # 0 THEN
            IF Bits(d, 1) = 1 THEN s := p1 ELSE s := -p1 END
          ELSIF r # 15 THEN
            d.eobrun := ASH(1, r); IF r > 0 THEN INC(d.eobrun, Bits(d, r)) END;
            EXIT
          END;
          LOOP  (* past the coefficients not 0 (each with a correction bit) and r that are 0 *)
            IF c[base + zz[k]] # 0 THEN Correct(d, c, base + zz[k], p1)
            ELSE DEC(r); IF r < 0 THEN EXIT END
            END;
            INC(k);
            IF k > d.se THEN EXIT END
          END;
          IF s # 0 THEN c[base + zz[k]] := SHORT(s) END;
          INC(k)
        END
      END;
      IF d.eobrun > 0 THEN
        WHILE k <= d.se DO
          IF c[base + zz[k]] # 0 THEN Correct(d, c, base + zz[k], p1) END;
          INC(k)
        END;
        DEC(d.eobrun)
      END
    END
  END
END Block;

(* an MCU after the data ran short: its blocks stay 0 *)
PROCEDURE Zero(d: Decoder; ci, bx, by: LONGINT);
VAR blk: ARRAY 64 OF LONGINT; i: LONGINT;
BEGIN
  IF ~d.progressive THEN
    i := 0; WHILE i < 64 DO blk[i] := 0; INC(i) END;
    IDCT(blk, d.q[d.comp[ci].tq], d.comp[ci].plane, (by * d.comp[ci].bw * 8 + bx) * 8, d.comp[ci].bw * 8)
  END
END Zero;

PROCEDURE DecodeScan(d: Decoder);
VAR i, ci, mx, my, bpl, lines, left, h, v, x, y: LONGINT; skip: BOOLEAN;
BEGIN
  d.acc := 0; d.nbits := 0; d.marker := 0; d.eobrun := 0; d.fake := 0; d.short := FALSE;
  i := 0; WHILE i < d.ncomp DO d.comp[i].pred := 0; INC(i) END;
  left := d.restart;
  IF d.ns = 1 THEN  (* the blocks of one component, row by row *)
    ci := d.sc[0]; bpl := (d.comp[ci].w + 7) DIV 8; lines := (d.comp[ci].ht + 7) DIV 8; my := 0;
    WHILE my < lines DO
      mx := 0;
      WHILE mx < bpl DO
        IF d.restart > 0 THEN
          IF left = 0 THEN Restart(d); left := d.restart END;
          DEC(left)
        END;
        IF d.short THEN Zero(d, ci, mx, my) ELSE Block(d, ci, mx, my) END;
        INC(mx)
      END;
      INC(my)
    END
  ELSE  (* MCUs of h by v blocks of each component *)
    my := 0;
    WHILE my < d.mcuy DO
      mx := 0;
      WHILE mx < d.mcux DO
        IF d.restart > 0 THEN
          IF left = 0 THEN Restart(d); left := d.restart END;
          DEC(left)
        END;
        skip := d.short; i := 0;
        WHILE i < d.ns DO
          ci := d.sc[i]; h := d.comp[ci].h; v := d.comp[ci].v; y := 0;
          WHILE y < v DO
            x := 0;
            WHILE x < h DO
              IF skip THEN Zero(d, ci, mx * h + x, my * v + y) ELSE Block(d, ci, mx * h + x, my * v + y) END;
              INC(x)
            END;
            INC(y)
          END;
          INC(i)
        END;
        INC(mx)
      END;
      INC(my)
    END
  END
END DecodeScan;

PROCEDURE ReadScan(d: Decoder);
VAR len, i, j, k, id: LONGINT;
BEGIN
  IF ~d.frame THEN d.res := badFormat; RETURN END;
  len := Word(d); d.ns := Byte(d);
  IF (d.ns < 1) OR (d.ns > 4) OR (len # 6 + 2 * d.ns) THEN d.res := badFormat; RETURN END;
  i := 0;
  WHILE i < d.ns DO
    id := Byte(d); k := Byte(d); j := 0;
    WHILE (j < d.ncomp) & (d.comp[j].id # id) DO INC(j) END;
    IF (j = d.ncomp) OR (k DIV 16 > 3) OR (k MOD 16 > 3) THEN d.res := badFormat; RETURN END;
    d.sc[i] := j; d.comp[j].td := k DIV 16; d.comp[j].ta := k MOD 16;
    INC(i)
  END;
  d.ss := Byte(d); d.se := Byte(d); k := Byte(d); d.ah := k DIV 16; d.al := k MOD 16;
  IF d.res # ok THEN RETURN END;
  IF ~d.progressive THEN d.ss := 0; d.se := 63; d.ah := 0; d.al := 0
  ELSIF (d.ss = 0) & (d.se # 0) OR (d.ss > 0) & ((d.ns # 1) OR (d.se < d.ss) OR (d.se > 63)) OR (d.al > 13) THEN
    d.res := badFormat; RETURN
  END;
  i := 0;
  WHILE i < d.ns DO
    j := d.sc[i];
    IF (d.ss = 0) & (d.ah = 0) & (d.dc[d.comp[j].td] = NIL) OR ((d.ss > 0) OR ~d.progressive) & (d.ac[d.comp[j].ta] = NIL)
      OR ~d.progressive & ~d.qok[d.comp[j].tq] THEN
      d.res := badFormat; RETURN
    END;
    INC(i)
  END;
  DecodeScan(d)
END ReadScan;

(* progressive: the planes from the coefficients *)
PROCEDURE Transform(d: Decoder);
VAR blk: ARRAY 64 OF LONGINT; ci, bx, by, i, base: LONGINT; c: Coefs;
BEGIN
  ci := 0;
  WHILE ci < d.ncomp DO
    IF ~d.qok[d.comp[ci].tq] THEN d.res := badFormat; RETURN END;
    c := d.comp[ci].coef; by := 0;
    WHILE by < d.comp[ci].bh DO
      bx := 0;
      WHILE bx < d.comp[ci].bw DO
        base := (by * d.comp[ci].bw + bx) * 64; i := 0;
        WHILE i < 64 DO blk[i] := c[base + i]; INC(i) END;
        IDCT(blk, d.q[d.comp[ci].tq], d.comp[ci].plane, (by * d.comp[ci].bw * 8 + bx) * 8, d.comp[ci].bw * 8);
        INC(bx)
      END;
      INC(by)
    END;
    d.comp[ci].coef := NIL;
    INC(ci)
  END
END Transform;

(* row y of component ci at the size of the picture: libjpeg's fancy upsampling (a triangle filter) for
  samples halved in one or both directions, else the samples repeated *)
PROCEDURE Upsample(d: Decoder; ci, y: LONGINT; row: Bytes);
VAR pl: Bytes; fh, fv, w, ht, stride, x, j, k, a, b, near, far, bias, s0, s1: LONGINT;
BEGIN
  pl := d.comp[ci].plane; stride := d.comp[ci].bw * 8; w := d.comp[ci].w; ht := d.comp[ci].ht;
  fh := d.hmax DIV d.comp[ci].h; fv := d.vmax DIV d.comp[ci].v;
  near := y DIV fv;
  IF ODD(y) THEN far := near + 1; bias := 2; IF far > ht - 1 THEN far := ht - 1 END
  ELSE far := near - 1; bias := 1; IF far < 0 THEN far := 0 END
  END;
  a := near * stride; b := far * stride; x := 0;
  IF (fh = 1) & (fv = 1) THEN
    WHILE x < d.width DO row[x] := pl[a + x]; INC(x) END
  ELSIF (fh = 2) & (fv = 1) & (w > 2) THEN
    WHILE x < d.width DO
      j := x DIV 2;
      IF ODD(x) THEN
        k := j + 1; IF k > w - 1 THEN k := w - 1 END;
        row[x] := CHR((3 * ORD(pl[a + j]) + ORD(pl[a + k]) + 2) DIV 4)
      ELSE
        k := j - 1; IF k < 0 THEN k := 0 END;
        row[x] := CHR((3 * ORD(pl[a + j]) + ORD(pl[a + k]) + 1) DIV 4)
      END;
      INC(x)
    END
  ELSIF (fh = 1) & (fv = 2) THEN
    WHILE x < d.width DO row[x] := CHR((3 * ORD(pl[a + x]) + ORD(pl[b + x]) + bias) DIV 4); INC(x) END
  ELSIF (fh = 2) & (fv = 2) & (w > 2) THEN
    WHILE x < d.width DO
      j := x DIV 2; s0 := 3 * ORD(pl[a + j]) + ORD(pl[b + j]);
      IF ODD(x) THEN
        k := j + 1; IF k > w - 1 THEN k := w - 1 END;
        s1 := 3 * ORD(pl[a + k]) + ORD(pl[b + k]); row[x] := CHR((3 * s0 + s1 + 7) DIV 16)
      ELSE
        k := j - 1; IF k < 0 THEN k := 0 END;
        s1 := 3 * ORD(pl[a + k]) + ORD(pl[b + k]); row[x] := CHR((3 * s0 + s1 + 8) DIV 16)
      END;
      INC(x)
    END
  ELSE
    WHILE x < d.width DO row[x] := pl[a + x DIV fh]; INC(x) END
  END
END Upsample;

(* the colour space of the components, as libjpeg decides it *)
PROCEDURE ColorSpace(d: Decoder): LONGINT;
BEGIN
  IF d.ncomp = 1 THEN RETURN Grey
  ELSIF d.ncomp = 3 THEN
    IF d.jfif THEN RETURN YCbCr
    ELSIF d.adobe THEN IF d.transform = 0 THEN RETURN RGB ELSE RETURN YCbCr END
    ELSIF (d.comp[0].id = ORD("R")) & (d.comp[1].id = ORD("G")) & (d.comp[2].id = ORD("B")) THEN RETURN RGB
    ELSE RETURN YCbCr
    END
  ELSIF d.adobe & (d.transform # 0) THEN RETURN YCCK
  ELSE RETURN CMYK
  END
END ColorSpace;

(* the pixels of img from the planes *)
PROCEDURE Output(d: Decoder; img: Image);
VAR rows: ARRAY 4 OF Bytes; r0, r1, r2, r3: Bytes; cs, ci, x, y, p, yy, cb, cr, k, c, m, ye: LONGINT;
BEGIN
  cs := ColorSpace(d); ci := 0;
  WHILE ci < d.ncomp DO NEW(rows[ci], d.width); INC(ci) END;
  r0 := rows[0]; r1 := rows[1]; r2 := rows[2]; r3 := rows[3];
  y := 0;
  WHILE y < d.height DO
    ci := 0; WHILE ci < d.ncomp DO Upsample(d, ci, y, rows[ci]); INC(ci) END;
    p := y * d.width * 4; x := 0;
    WHILE x < d.width DO
      IF cs = Grey THEN img.pix[p] := r0[x]; img.pix[p + 1] := r0[x]; img.pix[p + 2] := r0[x]
      ELSIF cs = RGB THEN img.pix[p] := r0[x]; img.pix[p + 1] := r1[x]; img.pix[p + 2] := r2[x]
      ELSE
        yy := ORD(r0[x]); cb := ORD(r1[x]); cr := ORD(r2[x]);
        IF cs = YCbCr THEN
          img.pix[p] := limit[yy + crR[cr] + 384];
          img.pix[p + 1] := limit[yy + ASH(cbG[cb] + crG[cr], -16) + 384];
          img.pix[p + 2] := limit[yy + cbB[cb] + 384]
        ELSE  (* CMYK of Adobe (inverted), or YCCK: YCbCr of the inverted CMY *)
          IF cs = YCCK THEN
            c := ORD(limit[639 - yy - crR[cr]]); m := ORD(limit[639 - yy - ASH(cbG[cb] + crG[cr], -16)]);
            ye := ORD(limit[639 - yy - cbB[cb]])
          ELSE c := yy; m := cb; ye := cr
          END;
          k := ORD(r3[x]);
          img.pix[p] := CHR((c * k + 127) DIV 255); img.pix[p + 1] := CHR((m * k + 127) DIV 255);
          img.pix[p + 2] := CHR((ye * k + 127) DIV 255)
        END
      END;
      INC(p, 4); INC(x)
    END;
    INC(y)
  END
END Output;

PROCEDURE NewDecoder(VAR R: Files.Rider): Decoder;
VAR d: Decoder; i: LONGINT;
BEGIN
  NEW(d); d.R := R; d.res := ok; d.acc := 0; d.nbits := 0; d.marker := 0; d.fake := 0; d.short := FALSE;
  d.frame := FALSE; d.progressive := FALSE; d.jfif := FALSE; d.adobe := FALSE; d.transform := 0;
  d.restart := 0; d.eobrun := 0; d.ncomp := 0;
  i := 0; WHILE i < 4 DO d.qok[i] := FALSE; d.dc[i] := NIL; d.ac[i] := NIL; INC(i) END;
  RETURN d
END NewDecoder;

(** the size and kind of the picture at R, from its frame header *)
PROCEDURE ReadInfo*(VAR R: Files.Rider; VAR info: Info; VAR res: LONGINT);
VAR d: Decoder; m, len, p: LONGINT;
BEGIN
  d := NewDecoder(R);
  IF (Byte(d) # 0FFH) OR (Byte(d) # SOI) THEN res := notJPEG; RETURN END;
  LOOP
    m := NextMarker(d);
    IF (m < 0) OR (m = EOI) OR (m = SOS) THEN d.res := badFormat; EXIT
    ELSIF (m >= SOF0) & (m <= 0CFH) & (m # DHT) & (m # JPG) & (m # DAC) THEN
      len := Word(d); m := m - SOF0; info.progressive := (m = 2) OR (m = 6) OR (m = 10) OR (m = 14);
      p := Byte(d); info.height := Word(d); info.width := Word(d); info.components := Byte(d);
      IF (d.res = ok) & ((m > 2) OR (p # 8)) THEN d.res := unsupported END;
      EXIT
    ELSIF (m < RST0) OR (m > RST7) & (m # TEM) THEN Skip(d)
    END;
    IF d.res # ok THEN EXIT END
  END;
  res := d.res
END ReadInfo;

(** decode the picture at R into img (NIL if res # ok) *)
PROCEDURE Decode*(VAR R: Files.Rider; VAR img: Image; VAR res: LONGINT);
VAR d: Decoder; m, scans: LONGINT;
BEGIN
  img := NIL; d := NewDecoder(R);
  IF (Byte(d) # 0FFH) OR (Byte(d) # SOI) THEN res := notJPEG; RETURN END;
  scans := 0;
  LOOP
    m := NextMarker(d);
    IF (m < 0) OR (m = EOI) THEN EXIT
    ELSIF (m = SOF0) OR (m = SOF1) THEN ReadFrame(d, FALSE)
    ELSIF m = SOF2 THEN ReadFrame(d, TRUE)
    ELSIF (m > SOF2) & (m <= 0CFH) & (m # DHT) & (m # JPG) & (m # DAC) THEN d.res := unsupported
    ELSIF m = DHT THEN ReadDHT(d)
    ELSIF m = DQT THEN ReadDQT(d)
    ELSIF m = DRI THEN
      IF Word(d) = 4 THEN d.restart := Word(d) ELSE d.res := badFormat END
    ELSIF m = SOS THEN ReadScan(d); INC(scans)
    ELSIF (m = APP0) OR (m = APP14) THEN ReadApp(d, m)
    ELSIF (m < RST0) OR (m > RST7) & (m # TEM) THEN Skip(d)
    END;
    IF d.res # ok THEN EXIT END
  END;
  IF (d.res = ok) & (~d.frame OR (scans = 0)) THEN d.res := badFormat END;
  IF (d.res = ok) & d.progressive THEN Transform(d) END;
  IF d.res = ok THEN img := NewImage(d.width, d.height); Output(d, img) END;
  R := d.R; res := d.res
END Decode;

(* encoding *)

PROCEDURE Put(VAR W: Files.Rider; VAR e: Encoder; v, n: LONGINT);  (* n <= 16 bits *)
VAR b: LONGINT;
BEGIN
  e.acc := ASH(e.acc, n) + v; INC(e.nbits, n);
  WHILE e.nbits >= 8 DO
    DEC(e.nbits, 8); b := ASH(e.acc, -e.nbits); e.acc := e.acc - ASH(b, e.nbits);
    Files.Write(W, CHR(b));
    IF b = 255 THEN Files.Write(W, 0X) END
  END
END Put;

(* the number of bits of the magnitude of x, and the bits that code x (F.1.2.1) *)
PROCEDURE PutValue(VAR W: Files.Rider; VAR e: Encoder; x, t: LONGINT; ac: BOOLEAN; run: LONGINT);
VAR n, a: LONGINT;
BEGIN
  a := ABS(x); n := 0; WHILE a > 0 DO INC(n); a := a DIV 2 END;
  IF ac THEN Put(W, e, e.code[t, run * 16 + n], e.size[t, run * 16 + n]) ELSE Put(W, e, e.code[t, n], e.size[t, n]) END;
  IF n > 0 THEN
    IF x < 0 THEN x := x + ASH(1, n) - 1 END;
    Put(W, e, x, n)
  END
END PutValue;

(* the forward DCT of libjpeg (jfdctint.c, "islow"); the results are 8 times too large *)
PROCEDURE FDCT(VAR d: ARRAY OF LONGINT);
VAR i, p, s: LONGINT; tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp10, tmp11, tmp12, tmp13, z1, z2, z3, z4, z5: LONGINT;
BEGIN
  i := 0;
  WHILE i < 16 DO  (* the rows, then the columns *)
    IF i < 8 THEN p := 8 * i; s := 1 ELSE p := i - 8; s := 8 END;
    tmp0 := d[p] + d[p + 7 * s]; tmp7 := d[p] - d[p + 7 * s];
    tmp1 := d[p + s] + d[p + 6 * s]; tmp6 := d[p + s] - d[p + 6 * s];
    tmp2 := d[p + 2 * s] + d[p + 5 * s]; tmp5 := d[p + 2 * s] - d[p + 5 * s];
    tmp3 := d[p + 3 * s] + d[p + 4 * s]; tmp4 := d[p + 3 * s] - d[p + 4 * s];
    tmp10 := tmp0 + tmp3; tmp13 := tmp0 - tmp3; tmp11 := tmp1 + tmp2; tmp12 := tmp1 - tmp2;
    z1 := (tmp12 + tmp13) * 4433;
    z2 := tmp4 + tmp7; z3 := tmp5 + tmp6; z4 := tmp4 + tmp6; z5 := tmp5 + tmp7;  (* z1..z4 of libjpeg in z2..z5 *)
    tmp0 := (z4 + z5) * 9633;
    tmp4 := tmp4 * 2446; tmp5 := tmp5 * 16819; tmp6 := tmp6 * 25172; tmp7 := tmp7 * 12299;
    z2 := -z2 * 7373; z3 := -z3 * 20995; z4 := -z4 * 16069 + tmp0; z5 := -z5 * 3196 + tmp0;
    IF i < 8 THEN
      d[p] := (tmp10 + tmp11) * 4; d[p + 4] := (tmp10 - tmp11) * 4;
      d[p + 2] := ASH(z1 + tmp13 * 6270 + 1024, -11); d[p + 6] := ASH(z1 - tmp12 * 15137 + 1024, -11);
      d[p + 7] := ASH(tmp4 + z2 + z4 + 1024, -11); d[p + 5] := ASH(tmp5 + z3 + z5 + 1024, -11);
      d[p + 3] := ASH(tmp6 + z3 + z4 + 1024, -11); d[p + 1] := ASH(tmp7 + z2 + z5 + 1024, -11)
    ELSE
      d[p] := ASH(tmp10 + tmp11 + 2, -2); d[p + 32] := ASH(tmp10 - tmp11 + 2, -2);
      d[p + 16] := ASH(z1 + tmp13 * 6270 + 16384, -15); d[p + 48] := ASH(z1 - tmp12 * 15137 + 16384, -15);
      d[p + 56] := ASH(tmp4 + z2 + z4 + 16384, -15); d[p + 40] := ASH(tmp5 + z3 + z5 + 16384, -15);
      d[p + 24] := ASH(tmp6 + z3 + z4 + 16384, -15); d[p + 8] := ASH(tmp7 + z2 + z5 + 16384, -15)
    END;
    INC(i)
  END
END FDCT;

(* transform, quantize and code the samples blk (centred on 0) with the tables of t (0 luminance, 1 chrominance) *)
PROCEDURE PutBlock(VAR W: Files.Rider; VAR e: Encoder; VAR blk: ARRAY OF LONGINT; t: LONGINT; VAR pred: LONGINT);
VAR i, k, x, dv, run: LONGINT;
BEGIN
  FDCT(blk); i := 0;
  WHILE i < 64 DO
    dv := e.q[t, i] * 8; x := blk[i];
    IF x < 0 THEN blk[i] := -((dv DIV 2 - x) DIV dv) ELSE blk[i] := (x + dv DIV 2) DIV dv END;
    INC(i)
  END;
  PutValue(W, e, blk[0] - pred, 2 * t, FALSE, 0); pred := blk[0];
  run := 0; k := 1;
  WHILE k < 64 DO
    x := blk[zz[k]];
    IF x = 0 THEN INC(run)
    ELSE
      WHILE run > 15 DO Put(W, e, e.code[2 * t + 1, 0F0H], e.size[2 * t + 1, 0F0H]); DEC(run, 16) END;
      PutValue(W, e, x, 2 * t + 1, TRUE, run); run := 0
    END;
    INC(k)
  END;
  IF run > 0 THEN Put(W, e, e.code[2 * t + 1, 0], e.size[2 * t + 1, 0]) END
END PutBlock;

PROCEDURE WriteWord(VAR W: Files.Rider; x: LONGINT);
BEGIN Files.Write(W, CHR(x DIV 256)); Files.Write(W, CHR(x MOD 256))
END WriteWord;

PROCEDURE WriteMarker(VAR W: Files.Rider; m: LONGINT);
BEGIN Files.Write(W, 0FFX); Files.Write(W, CHR(m))
END WriteMarker;

(* the markers before the coded data *)
PROCEDURE WriteHeader(VAR W: Files.Rider; VAR e: Encoder; img: Image; grey: BOOLEAN);
VAR nc, t, i, l: LONGINT; jfif: ARRAY 14 OF CHAR;
BEGIN
  IF grey THEN nc := 1 ELSE nc := 3 END;
  WriteMarker(W, SOI);
  WriteMarker(W, APP0); WriteWord(W, 16);
  jfif := "JFIF"; jfif[4] := 0X; jfif[5] := 1X; jfif[6] := 1X; jfif[7] := 0X;  (* version 1.01, no units *)
  jfif[8] := 0X; jfif[9] := 1X; jfif[10] := 0X; jfif[11] := 1X; jfif[12] := 0X; jfif[13] := 0X;
  i := 0; WHILE i < 14 DO Files.Write(W, jfif[i]); INC(i) END;
  WriteMarker(W, DQT); WriteWord(W, 2 + 65 * ((nc + 1) DIV 2)); t := 0;
  WHILE t < (nc + 1) DIV 2 DO
    Files.Write(W, CHR(t)); i := 0; WHILE i < 64 DO Files.Write(W, CHR(e.q[t, zz[i]])); INC(i) END;
    INC(t)
  END;
  WriteMarker(W, SOF0); WriteWord(W, 8 + 3 * nc); Files.Write(W, 8X);
  WriteWord(W, img.height); WriteWord(W, img.width); Files.Write(W, CHR(nc));
  IF grey THEN Files.Write(W, 1X); Files.Write(W, 11X); Files.Write(W, 0X)
  ELSE
    Files.Write(W, 1X); Files.Write(W, 22X); Files.Write(W, 0X);
    Files.Write(W, 2X); Files.Write(W, 11X); Files.Write(W, 1X);
    Files.Write(W, 3X); Files.Write(W, 11X); Files.Write(W, 1X)
  END;
  l := 2; t := 0; WHILE t < 2 * ((nc + 1) DIV 2) DO INC(l, 17 + stdN[t]); INC(t) END;
  WriteMarker(W, DHT); WriteWord(W, l); t := 0;
  WHILE t < 2 * ((nc + 1) DIV 2) DO
    Files.Write(W, CHR(t MOD 2 * 16 + t DIV 2));  (* class (0 DC, 1 AC) and number *)
    i := 1; WHILE i <= 16 DO Files.Write(W, CHR(stdBits[t, i])); INC(i) END;
    i := 0; WHILE i < stdN[t] DO Files.Write(W, CHR(stdVals[t, i])); INC(i) END;
    INC(t)
  END;
  WriteMarker(W, SOS); WriteWord(W, 6 + 2 * nc); Files.Write(W, CHR(nc));
  IF grey THEN Files.Write(W, 1X); Files.Write(W, 0X)
  ELSE Files.Write(W, 1X); Files.Write(W, 0X); Files.Write(W, 2X); Files.Write(W, 11X); Files.Write(W, 3X); Files.Write(W, 11X)
  END;
  Files.Write(W, 0X); Files.Write(W, 3FX); Files.Write(W, 0X)
END WriteHeader;

(* the Huffman codes of the table t of annex K (annex C) *)
PROCEDURE Codes(VAR e: Encoder; t: LONGINT);
VAR c, k, l, i: LONGINT;
BEGIN
  c := 0; k := 0; l := 1;
  WHILE l <= 16 DO
    i := 0;
    WHILE i < stdBits[t, l] DO e.code[t, stdVals[t, k]] := c; e.size[t, stdVals[t, k]] := l; INC(c); INC(k); INC(i) END;
    c := c * 2; INC(l)
  END
END Codes;

(** write img at W as a baseline JFIF picture of the quality 1 (smallest) to 100 (best; 75 is usual) *)
PROCEDURE Encode*(VAR W: Files.Rider; img: Image; quality: LONGINT; VAR res: LONGINT);
VAR e: Encoder; grey: BOOLEAN; i, t, scale, w, h, n, mx, my, bx, by, x, y, px, py, p, r, g, b, k, mcu: LONGINT;
  ys, cbs, crs: ARRAY 256 OF LONGINT; blk: ARRAY 64 OF LONGINT; pred: ARRAY 3 OF LONGINT;
BEGIN
  IF (img = NIL) OR (img.pix = NIL) OR (img.width <= 0) OR (img.height <= 0) THEN res := noImage; RETURN END;
  w := img.width; h := img.height;
  IF (w > 65535) OR (h > 65535) THEN res := tooLarge; RETURN END;
  IF quality < 1 THEN quality := 1 ELSIF quality > 100 THEN quality := 100 END;
  IF quality < 50 THEN scale := 5000 DIV quality ELSE scale := 200 - 2 * quality END;  (* as libjpeg *)
  t := 0;
  WHILE t < 2 DO
    i := 0;
    WHILE i < 64 DO
      k := (stdQ[t, i] * scale + 50) DIV 100;
      IF k < 1 THEN k := 1 ELSIF k > 255 THEN k := 255 END;
      e.q[t, i] := k; INC(i)
    END;
    INC(t)
  END;
  t := 0; WHILE t < 4 DO Codes(e, t); INC(t) END;
  grey := TRUE; i := 0; n := w * h * 4;
  WHILE grey & (i < n) DO grey := (img.pix[i] = img.pix[i + 1]) & (img.pix[i] = img.pix[i + 2]); INC(i, 4) END;
  WriteHeader(W, e, img, grey);
  e.acc := 0; e.nbits := 0; pred[0] := 0; pred[1] := 0; pred[2] := 0;
  IF grey THEN mcu := 8 ELSE mcu := 16 END;
  my := 0;
  WHILE my < (h + mcu - 1) DIV mcu DO
    mx := 0;
    WHILE mx < (w + mcu - 1) DIV mcu DO
      y := 0;
      WHILE y < mcu DO  (* the pixels of the MCU, those beyond the edges repeated *)
        py := my * mcu + y; IF py >= h THEN py := h - 1 END;
        x := 0;
        WHILE x < mcu DO
          px := mx * mcu + x; IF px >= w THEN px := w - 1 END;
          p := (py * w + px) * 4; r := ORD(img.pix[p]); g := ORD(img.pix[p + 1]); b := ORD(img.pix[p + 2]);
          k := y * mcu + x;
          ys[k] := ASH(19595 * r + 38470 * g + 7471 * b + 32768, -16);
          cbs[k] := ASH(-11059 * r - 21709 * g + 32768 * b + 8421375, -16);
          crs[k] := ASH(32768 * r - 27439 * g - 5329 * b + 8421375, -16);
          INC(x)
        END;
        INC(y)
      END;
      IF grey THEN
        i := 0; WHILE i < 64 DO blk[i] := ys[i] - 128; INC(i) END;
        PutBlock(W, e, blk, 0, pred[0])
      ELSE
        by := 0;
        WHILE by < 2 DO
          bx := 0;
          WHILE bx < 2 DO
            i := 0; WHILE i < 64 DO blk[i] := ys[(by * 8 + i DIV 8) * 16 + bx * 8 + i MOD 8] - 128; INC(i) END;
            PutBlock(W, e, blk, 0, pred[0]); INC(bx)
          END;
          INC(by)
        END;
        i := 0;
        WHILE i < 64 DO  (* the colours halved: the mean of 2 by 2, rounded alternately down and up, as libjpeg *)
          k := (i DIV 8) * 32 + (i MOD 8) * 2;
          blk[i] := (cbs[k] + cbs[k + 1] + cbs[k + 16] + cbs[k + 17] + 1 + i MOD 2) DIV 4 - 128; INC(i)
        END;
        PutBlock(W, e, blk, 1, pred[1]);
        i := 0;
        WHILE i < 64 DO
          k := (i DIV 8) * 32 + (i MOD 8) * 2;
          blk[i] := (crs[k] + crs[k + 1] + crs[k + 16] + crs[k + 17] + 1 + i MOD 2) DIV 4 - 128; INC(i)
        END;
        PutBlock(W, e, blk, 1, pred[2])
      END;
      INC(mx)
    END;
    INC(my)
  END;
  IF e.nbits > 0 THEN Put(W, e, ASH(1, 8 - e.nbits) - 1, 8 - e.nbits) END;  (* the last byte filled with 1 bits *)
  WriteMarker(W, EOI);
  res := ok
END Encode;

(* tables *)

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("A") + 10 END
END Digit;

(* append the bytes written in hex in s to a from n *)
PROCEDURE Hex(s: ARRAY OF CHAR; VAR a: ARRAY OF LONGINT; VAR n: LONGINT);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO a[n] := Digit(s[i]) * 16 + Digit(s[i + 1]); INC(n); INC(i, 2) END
END Hex;

PROCEDURE InitTables;
VAR i, x, s, lo, hi, n: LONGINT;
BEGIN
  i := 0; s := 0;
  WHILE s <= 14 DO  (* the diagonals of the zigzag order *)
    lo := s - 7; IF lo < 0 THEN lo := 0 END;
    hi := s; IF hi > 7 THEN hi := 7 END;
    IF ODD(s) THEN x := hi; WHILE x >= lo DO zz[i] := (s - x) * 8 + x; INC(i); DEC(x) END
    ELSE x := lo; WHILE x <= hi DO zz[i] := (s - x) * 8 + x; INC(i); INC(x) END
    END;
    INC(s)
  END;
  WHILE i < 80 DO zz[i] := 63; INC(i) END;
  i := 0;
  WHILE i < 1024 DO
    IF i < 128 THEN idctLimit[i] := CHR(i + 128) ELSIF i < 512 THEN idctLimit[i] := 0FFX
    ELSIF i < 896 THEN idctLimit[i] := 0X ELSE idctLimit[i] := CHR(i - 896)
    END;
    IF i < 384 THEN limit[i] := 0X ELSIF i < 639 THEN limit[i] := CHR(i - 384) ELSE limit[i] := 0FFX END;
    INC(i)
  END;
  i := 0;
  WHILE i < 256 DO
    x := i - 128;
    crR[i] := ASH(91881 * x + 32768, -16); cbB[i] := ASH(116130 * x + 32768, -16);
    crG[i] := -46802 * x; cbG[i] := -22554 * x + 32768;
    INC(i)
  END;
  n := 1; Hex("00010501010101010100000000000000", stdBits[0], n);
  n := 0; Hex("000102030405060708090A0B", stdVals[0], n); stdN[0] := n;
  n := 1; Hex("0002010303020403050504040000017D", stdBits[1], n);
  n := 0;
  Hex("01020300041105122131410613516107227114328191A1082342B1C11552D1F02433627282090A161718191A25262728292A3435363738393A", stdVals[1], n);
  Hex("434445464748494A535455565758595A636465666768696A737475767778797A838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AA", stdVals[1], n);
  Hex("B2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FA", stdVals[1], n);
  stdN[1] := n;
  n := 1; Hex("00030101010101010101010000000000", stdBits[2], n);
  n := 0; Hex("000102030405060708090A0B", stdVals[2], n); stdN[2] := n;
  n := 1; Hex("00020102040403040705040400010277", stdBits[3], n);
  n := 0;
  Hex("000102031104052131061241510761711322328108144291A1B1C109233352F0156272D10A162434E125F11718191A262728292A35363738", stdVals[3], n);
  Hex("393A434445464748494A535455565758595A636465666768696A737475767778797A82838485868788898A92939495969798999AA2A3A4A5A6", stdVals[3], n);
  Hex("A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9FA", stdVals[3], n);
  stdN[3] := n;
  n := 0;
  Hex("100B0A101828333D0C0C0E131A3A3C370E0D1018283945380E11161D3357503E", stdQ[0], n);
  Hex("12162538446D674D182337405168715C31404E5767797865485C5F6270646763", stdQ[0], n);
  n := 0;
  Hex("1112182F6363636312151A4263636363181A3863636363632F42636363636363", stdQ[1], n);
  Hex("6363636363636363636363636363636363636363636363636363636363636363", stdQ[1], n)
END InitTables;

BEGIN
  InitTables
END JPEG0.
