MODULE testUnixFiles;

IMPORT Streams := ulmStreams, UnixFiles := ulmUnixFiles, Write := ulmWrite,
  SYSTEM;

VAR
  stream: Streams.Stream;
  filename: ARRAY 64 OF CHAR;
  written, received: ARRAY 5 OF CHAR;
  byte: Streams.Byte;
  position: Streams.Count;

BEGIN
  ASSERT(Streams.stdin IS UnixFiles.Stream);
  ASSERT(Streams.stdout IS UnixFiles.Stream);
  ASSERT(Streams.stderr IS UnixFiles.Stream);

  COPY("ulmUnixFiles.test", filename);
  COPY("test", written);
  ASSERT(UnixFiles.Open(stream, filename, UnixFiles.rdwr + UnixFiles.create,
                        Streams.onebuf, NIL));
  ASSERT(Streams.WritePart(stream, written, 0, 4));
  Streams.GetPos(stream, position);
  ASSERT(position = 4);
  ASSERT(Streams.Close(stream));

  COPY("ulmUnixFiles.test", filename);
  ASSERT(UnixFiles.Open(stream, filename,
                        UnixFiles.read + UnixFiles.condcreate,
                        Streams.onebuf, NIL));
  ASSERT(Streams.ReadPart(stream, received, 0, 4));
  ASSERT((received[0] = "t") & (received[1] = "e") &
         (received[2] = "s") & (received[3] = "t"));
  ASSERT(Streams.Close(stream));

  COPY("ulmUnixFiles.test", filename);
  ASSERT(UnixFiles.Open(stream, filename, UnixFiles.read,
                        Streams.nobuf, NIL));
  ASSERT(Streams.ReadByte(stream, byte));
  ASSERT(SYSTEM.VAL(CHAR, byte) = "t");
  ASSERT(Streams.Close(stream));

  Write.String("ulmUnixFiles ok");
  Write.Ln
END testUnixFiles.
