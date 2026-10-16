MODULE TestCompression;

IMPORT SYSTEM, Files, Zlib, ZlibBuffers, GZReaders, GZWriters, Out;

VAR file: Files.File; writer: GZWriters.Writer; reader: GZReaders.Reader;
  memory, src, dst: ARRAY 32 OF CHAR; buf: ZlibBuffers.Buffer;
  n, i: LONGINT; ch: CHAR;

BEGIN
  src := "123456789";
  ASSERT(SYSTEM.VAL(SYSTEM.SET32, Zlib.CRC32(0, src, 0, 9)) =
    SYSTEM.VAL(SYSTEM.SET32, 0CBF43926H));
  ZlibBuffers.Init(buf, memory, 0, LEN(memory), LEN(memory));
  src := "abcdefghij"; ZlibBuffers.WriteBytes(buf, src, 0, 10);
  ZlibBuffers.Drain(buf, dst, 0, 2); ASSERT(dst[0] = "a"); ASSERT(dst[1] = "b");
  ZlibBuffers.Drain(buf, dst, 0, 8);
  FOR i := 0 TO 7 DO ASSERT(dst[i] = src[i+2]) END;
  ZlibBuffers.Init(buf, memory, 0, LEN(memory), 0);
  ZlibBuffers.Fill(buf, src, 0, 10); ZlibBuffers.ReadBytes(buf, dst, 0, 2);
  ZlibBuffers.Fill(buf, src, 0, 10); ZlibBuffers.ReadBytes(buf, dst, 0, 18);
  FOR i := 0 TO 7 DO ASSERT(dst[i] = src[i+2]) END;
  FOR i := 0 TO 9 DO ASSERT(dst[i+8] = src[i]) END;
  file := Files.New(""); GZWriters.Open(writer, -1, 0, file);
  GZWriters.WriteBytes(writer, src, 0, 10, n); ASSERT(n = 10);
  GZWriters.Close(writer); ASSERT(writer.res = GZWriters.Ok);
  GZReaders.Open(reader, file); GZReaders.ReadBytes(reader, dst, 3, 20, n);
  ASSERT(n = 10); ASSERT(reader.res = GZReaders.StreamEnd);
  FOR i := 0 TO 9 DO ASSERT(dst[i+3] = src[i]) END;
  GZReaders.Close(reader); ASSERT(reader.res = GZReaders.Ok);
  (* Reusing a writer must reset its byte count; Write must count single bytes. *)
  file := Files.New(""); GZWriters.Open(writer, -1, 0, file);
  GZWriters.Write(writer, "x"); GZWriters.Close(writer); ASSERT(writer.res = GZWriters.Ok);
  GZReaders.Open(reader, file); GZReaders.Read(reader, ch); ASSERT(ch = "x");
  GZReaders.Read(reader, ch); ASSERT(reader.res = GZReaders.StreamEnd);
  GZReaders.Close(reader); ASSERT(reader.res = GZReaders.Ok);
  file := Files.New(""); GZWriters.Open(writer, -1, 0, file); GZWriters.Close(writer);
  ASSERT(writer.res = GZWriters.Ok);
  GZReaders.Open(reader, file); GZReaders.ReadBytes(reader, dst, 0, LEN(dst), n);
  ASSERT(n = 0); ASSERT(reader.res = GZReaders.StreamEnd);
  GZReaders.Close(reader); ASSERT(reader.res = GZReaders.Ok);
  Out.String("compression library tests passed"); Out.Ln
END TestCompression.
