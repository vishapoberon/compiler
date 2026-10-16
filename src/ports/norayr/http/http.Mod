MODULE http;  (** an HTTP/1.1 client: GET, with Content-Length, chunked or to the end of the connection *)
(* The same file serves voc and polpo; only the imports of Strings and Out differ.
   The transport (Connect, Read, ReadBuf, Write, Disconnect) are procedure fields of the client:
   https replaces them with TLS. Read with bytesToRead >= 0 reads exactly that many bytes. *)
IMPORT IntStr, Strings, Files, Out,  (* polpo: Strings := strings, Out := out *)
       hexIntStr, Internet, strTypes, strUtils, Base64 := StringBase64;
CONST
  defName = "unknown.html";
  defReqHeaderLength = 6;
  defHeaderLength = 1024;
    defUserAgent* = "oberon-http-client/1.0";
  defHttpVersion* = "HTTP/1.1";
        defGetStr = "GET";
       defHostStr = "HOST";
         defUAStr = "User-Agent";
     defAcceptStr = "Accept";
 defEverythingStr = "*/*";
         defAuth  = "Basic";
     defConnectionStr = "Connection";
          defCloseStr = "close";

              hdrDate = "date";
            hdrServer = "server";
      hdrLastModified = "last-modified";
              hdrETag = "etag";
      hdrAcceptRanges = "accept-ranges";
     hdrContentLength = "content-length";
              hdrVary = "vary";
       hdrContentType = "content-type";
  hdrTransferEncoding = "transfer-encoding";
        hdrConnection = "keep-alive";
      hdrCacheControl = "cache-control";
           hdrExpires = "expires";
          hdrLocation = "location";
          hdrReportTo = "report-to";
               hdrNEL = "nel";
             hdrCFRAY = "cf-ray";
              hdrAuth = "Authorization";


TYPE
  transport* = POINTER TO transportDesc;
  transportDesc* = RECORD END;
   bsdSocket* = POINTER TO bsdSocketDesc;
   bsdSocketDesc = RECORD (transportDesc)
          socket : Internet.Socket
          END;
  Client* = POINTER TO ClientDesc;
  headers*    = POINTER TO ARRAY OF strTypes.pstring;

  ClientDesc* = RECORD
    host*, port*, path* : strTypes.pstring;
             rspnCode* : LONGINT;  (** the status code, 200 etc., 0 if there was no answer *)
                   trn* : transport;
        connectionFlag* : BOOLEAN;
              endClean* : BOOLEAN;  (** set by the transport: the connection ended properly (TLS:
                                        close_notify); a body up to the end is complete only then *)
          rspnComplete* : BOOLEAN;  (** the whole body arrived (length, last chunk or clean end) *)
             userAgent* : strTypes.pstring;
               version* : strTypes.pstring;
                   eol* : ARRAY 2 OF CHAR;
                  null* : ARRAY 1 OF CHAR;
             reqHeader* : headers;
          rspnPstrings* : strTypes.pstrings;
         rspnFirstLine* : strTypes.pstring;
              rspnDate* : strTypes.pstring;
            rspnServer* : strTypes.pstring;
      rspnLastModified* : strTypes.pstring;
              rspnETag* : strTypes.pstring;
      rspnAcceptRanges* : strTypes.pstring;
     rspnContentLength* : LONGINT;
              rspnVary* : strTypes.pstring;
       rspnContentType* : strTypes.pstring;
  rspnTransferEncoding* : strTypes.pstring;
        rspnConnection* : strTypes.pstring;
      rspnCacheControl* : strTypes.pstring;
           rspnExpires* : strTypes.pstring;
          rspnLocation* : strTypes.pstring;
          rspnReportTo* : strTypes.pstring;
               rspnNEL* : strTypes.pstring;
             rspnCFRAY* : strTypes.pstring;
              rspnBody* : strTypes.pstring;

                Create* : PROCEDURE(host, port, path: ARRAY OF CHAR): Client;
                   Get* : PROCEDURE(http: Client): strTypes.pstring;
          setUserAgent* : PROCEDURE(VAR http: Client; ua: ARRAY OF CHAR);
            clearState* : PROCEDURE(VAR http: Client);
                  Save* : PROCEDURE(http: Client);
               Connect* : PROCEDURE(VAR http: Client): BOOLEAN;
            Disconnect* : PROCEDURE(VAR http: Client);
                  Read* : PROCEDURE(VAR http: Client; VAR buf: ARRAY OF CHAR; bytesToRead: LONGINT): BOOLEAN;
               ReadBuf* : PROCEDURE(VAR http: Client; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN; (* returns number of read bytes in n *)
                 Write* : PROCEDURE(VAR http: Client; buf: ARRAY OF CHAR): BOOLEAN;
          appendHeader* : PROCEDURE(http: Client; hdr: strTypes.pstring);
         appendAuthHdr* : PROCEDURE(http: Client; user, password: ARRAY OF CHAR);
  END;


VAR
  verbose*: BOOLEAN;  (** progress and header messages *)

PROCEDURE ToLower(VAR stringVar: ARRAY OF CHAR);
VAR
  i: INTEGER;
BEGIN
  i := 0;
  WHILE stringVar[i] # 0X DO
    IF (stringVar[i] >= "A") & (stringVar[i] <= "Z") THEN
      stringVar[i] := CHR(ORD(stringVar[i]) + 20H);
    END;
    INC(i);
  END;
END ToLower;

PROCEDURE dumpHeaders(VAR hdrs: headers);
VAR
  i: LONGINT;
BEGIN
  i := 0;
  REPEAT
    Out.Int(i, 0); Out.String("  "); Out.String(hdrs^[i]^); Out.Ln;
    INC(i)
  UNTIL i = LEN(hdrs^);
END dumpHeaders;

PROCEDURE Empty(VAR string: strTypes.pstring);
VAR i : LONGINT;
BEGIN
  (*NEW(string, 512);
  string[0] := 0X;*)
  i := 0;
  REPEAT
    string[i] := 0X;
    INC(i)
  UNTIL i = LEN(string^) -1;
END Empty;

PROCEDURE clearstate*(VAR http: Client);
BEGIN
  http^.rspnCode              := 0;
  http^.rspnPstrings          := NIL;
  http^.rspnFirstLine         := NIL;
  http^.rspnDate              := NIL;
  http^.rspnServer            := NIL;
  http^.rspnLastModified      := NIL;
  http^.rspnETag              := NIL;
  http^.rspnAcceptRanges      := NIL;
  http^.rspnContentLength     := 0;
  http^.rspnVary              := NIL;
  http^.rspnContentType       := NIL;
  http^.rspnTransferEncoding  := NIL;
  http^.rspnConnection        := NIL;
  http^.rspnCacheControl      := NIL;
  http^.rspnExpires           := NIL;
  http^.rspnLocation          := NIL;
  http^.rspnReportTo          := NIL;
  http^.rspnNEL               := NIL;
  http^.rspnCFRAY             := NIL;
  http^.rspnBody              := NIL;
  http^.endClean              := TRUE;
  http^.rspnComplete          := FALSE
END clearstate;

PROCEDURE AppendEOLAndClean(buff: ARRAY OF CHAR; VAR buffClean: strTypes.pstring);
VAR
  i: LONGINT;
BEGIN
  i := Strings.Length(buff);
  NEW(buffClean, i + 3);

  COPY(buff, buffClean^);
  buffClean[i] := 0DX;
  buffClean[i + 1] := 0AX;
  buffClean[i + 2] := 0X;
END AppendEOLAndClean;

PROCEDURE connector(VAR http: Client): BOOLEAN;
BEGIN
  http^.connectionFlag := FALSE;
  IF http^.trn IS bsdSocket THEN
    http^.connectionFlag := Internet.Connect(http^.host^, http^.port^, http^.trn(bsdSocket).socket);
  ELSE
    Out.String("http client is not initialized with bsd socket"); Out.Ln;
    HALT(100);
  END;
  RETURN http^.connectionFlag;
END connector;

PROCEDURE disconnector(VAR http: Client);
BEGIN
  IF http^.trn IS bsdSocket THEN
    Internet.Disconnect(http^.trn(bsdSocket).socket);
  ELSE
    Out.String("http client is not initialized with bsd socket"); Out.Ln;
    HALT(100);
  END;
END disconnector;

PROCEDURE reader(VAR http: Client; VAR buf: ARRAY OF CHAR; bytesToRead: LONGINT): BOOLEAN;
BEGIN
  http^.connectionFlag := FALSE;
  IF http^.trn IS bsdSocket THEN
    IF bytesToRead = -1 THEN
      http^.connectionFlag := Internet.Read(http^.trn(bsdSocket).socket, buf)
    ELSE
      http^.connectionFlag := Internet.ReadBytes(http^.trn(bsdSocket).socket, buf, bytesToRead)
    END;
  ELSE
    Out.String("http client is not initialized with bsd socket"); Out.Ln;
    HALT(100);
  END;
  RETURN http^.connectionFlag
END reader;

PROCEDURE readBuf(VAR http: Client; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
BEGIN
  http^.connectionFlag := FALSE;
  IF http^.trn IS bsdSocket THEN
    http^.connectionFlag := Internet.ReadBuf(http^.trn(bsdSocket).socket, buf, n);
  ELSE
    Out.String("http client is not initialized with bsd socket"); Out.Ln;
    HALT(100);
  END;
  RETURN http^.connectionFlag
END readBuf;

PROCEDURE writer(VAR http: Client; buf: ARRAY OF CHAR): BOOLEAN;
BEGIN
  http^.connectionFlag := FALSE;
  IF http^.trn IS bsdSocket THEN
    http^.connectionFlag := Internet.Write(http^.trn(bsdSocket).socket, buf);
  ELSE
     Out.String("http client is not initialized with bsd socket"); Out.Ln;
    HALT(100);
  END;
  RETURN http^.connectionFlag
END writer;

PROCEDURE EnsureHeaderRoom(VAR header: strTypes.pstring; need: LONGINT);
VAR
  oldLen, newLen, i: LONGINT;
  nh: strTypes.pstring;
BEGIN
  IF need >= LEN(header^) THEN
    oldLen := LEN(header^);
    newLen := oldLen * 2;
    IF newLen < 128 THEN newLen := 128 END;
    WHILE need >= newLen DO newLen := newLen * 2 END;
    NEW(nh, newLen);
    i := 0;
    WHILE i < oldLen DO nh[i] := header[i]; INC(i) END;
    WHILE i < newLen DO nh[i] := 0X; INC(i) END;
    header := nh
  END
END EnsureHeaderRoom;

PROCEDURE readHeader(VAR http: Client):strTypes.pstring;
VAR
  header, buff: strTypes.pstring;
  headerBool : BOOLEAN;
  i: LONGINT;
BEGIN
  NEW(header, defHeaderLength);
  Empty(header);
  NEW(buff, 2);
  i := 0; headerBool := FALSE;

  REPEAT
    http^.connectionFlag := http.Read(http, buff^, -1);
    IF http^.connectionFlag THEN
      EnsureHeaderRoom(header, i + 1);
      header[i] := buff[0];
      INC(i);
      EnsureHeaderRoom(header, i);
      header[i] := 0X;

      IF i >= 4 THEN
        IF (header[i-4] = 0DX) & (header[i-3] = 0AX) &
           (header[i-2] = 0DX) & (header[i-1] = 0AX) THEN
          headerBool := TRUE
        END
      END
    ELSE
      headerBool := TRUE
    END
  UNTIL headerBool;

  IF verbose THEN Out.String("header bytes: "); Out.Int(i, 0); Out.Ln END;
  RETURN header
END readHeader;

PROCEDURE processHeader(VAR http: Client; VAR hdr: ARRAY OF CHAR): BOOLEAN;
VAR
  i, j, k, n, plen: LONGINT;
  key: ARRAY 128 OF CHAR;
  val: ARRAY 4096 OF CHAR;
  res: SHORTINT;
  isLengthFound: BOOLEAN;
  line: strTypes.pstring;
BEGIN
  isLengthFound := FALSE;

  (* getting string like 'HTTP/1.1 200 OK', hopefully *)
  http^.rspnPstrings := strUtils.string2pstrings(hdr);
  http^.rspnContentLength := 0;
  IF LEN(http^.rspnPstrings^) = 0 THEN RETURN FALSE END;
  strUtils.string2pstring(http^.rspnPstrings^[0]^, http^.rspnFirstLine);
  i := 0; http^.rspnCode := 0;
  WHILE (http^.rspnFirstLine[i] # 0X) & (http^.rspnFirstLine[i] # " ") DO INC(i) END;
  WHILE http^.rspnFirstLine[i] = " " DO INC(i) END;
  WHILE (http^.rspnFirstLine[i] >= "0") & (http^.rspnFirstLine[i] <= "9") DO
    http^.rspnCode := http^.rspnCode * 10 + ORD(http^.rspnFirstLine[i]) - ORD("0"); INC(i)
  END;

  i := 1;
  WHILE i < LEN(http^.rspnPstrings^) DO
    line := http^.rspnPstrings^[i];
    j := strUtils.Pos(':', line^, 0);

    IF j > 0 THEN
      (* Copy header key safely. Some servers send very long header lines;
         never let a fixed temporary buffer overflow. *)
      k := 0;
      WHILE k < LEN(key) DO key[k] := 0X; INC(k) END;
      k := 0;
      WHILE (k < j) & (k < LEN(key)-1) DO
        key[k] := line[k];
        INC(k)
      END;
      key[k] := 0X;
      ToLower(key);

      (* Copy value safely, bounded by val size.  This may truncate very large
         headers such as Report-To, Set-Cookie, CSP, etc.  That is OK for now;
         we only need small values such as Content-Length and Transfer-Encoding
         for the HTTP engine. *)
      k := j + 1;
      WHILE (line[k] = " ") OR (line[k] = 09X) DO INC(k) END;
      n := 0;
      WHILE (n < LEN(val)-1) &
            (line[k] # 0X) &
            (line[k] # 0DX) &
            (line[k] # 0AX) DO
        val[n] := line[k];
        INC(n); INC(k)
      END;
      val[n] := 0X;

      IF key = hdrDate THEN strUtils.string2pstring(val, http^.rspnDate) END;
      IF key = hdrServer THEN strUtils.string2pstring(val, http^.rspnServer) END;
      IF key = hdrLastModified THEN strUtils.string2pstring(val, http^.rspnLastModified) END;
      IF key = hdrETag THEN strUtils.string2pstring(val, http^.rspnETag) END;
      IF key = hdrAcceptRanges THEN strUtils.string2pstring(val, http^.rspnAcceptRanges) END;

      IF key = hdrContentLength THEN
        IntStr.StrToInt(val, http^.rspnContentLength, res);
        IF (res # IntStr.strAllRight) OR (http^.rspnContentLength < 0) THEN
          Out.String("http: content length is not a number: "); Out.String(val); Out.Ln;
          http^.rspnContentLength := 0
        ELSE
          isLengthFound := TRUE;
          IF verbose THEN Out.String("got content length: "); Out.Int(http^.rspnContentLength, 0); Out.Ln END
        END
      END;

      IF key = hdrVary THEN strUtils.string2pstring(val, http^.rspnVary) END;
      IF key = hdrContentType THEN strUtils.string2pstring(val, http^.rspnContentType) END;
      IF key = hdrTransferEncoding THEN strUtils.string2pstring(val, http^.rspnTransferEncoding) END;
      IF key = hdrConnection THEN strUtils.string2pstring(val, http^.rspnConnection) END;
      IF key = hdrCacheControl THEN strUtils.string2pstring(val, http^.rspnCacheControl) END;
      IF key = hdrExpires THEN strUtils.string2pstring(val, http^.rspnExpires) END;
      IF key = hdrLocation THEN strUtils.string2pstring(val, http^.rspnLocation) END;

      (* These can be huge on modern sites. Store bounded/debug-safe value only. *)
      IF key = hdrReportTo THEN strUtils.string2pstring(val, http^.rspnReportTo) END;
      IF key = hdrNEL THEN strUtils.string2pstring(val, http^.rspnNEL) END;
      IF key = hdrCFRAY THEN strUtils.string2pstring(val, http^.rspnCFRAY) END
    END;

    INC(i)
  END;

  IF ~isLengthFound THEN http^.rspnContentLength := 0 END;
  RETURN isLengthFound
END processHeader;

   (* this implementation reallocates,
      it is necessary when the content length is not known *)
PROCEDURE getKnownLengthRealloc(VAR http: Client): strTypes.pstring;
VAR
  buff, tmpBuff: strTypes.pstring;
  readFailure: BOOLEAN; eof: BOOLEAN;
  readThisTime, readAll: LONGINT;
BEGIN
    readThisTime := 0; readAll := 0;
    buff := NIL;
    NEW(tmpBuff, http^.rspnContentLength);
    readFailure := FALSE; eof := FALSE;
    REPEAT
      Empty(tmpBuff);
      http^.connectionFlag := http.ReadBuf(http, tmpBuff^, readThisTime);
      IF readThisTime < 0 THEN readFailure := TRUE; Out.String("read failure"); Out.Ln END;
      IF readThisTime = 0 THEN eof := TRUE END;
      readAll := readAll + readThisTime;
      IF verbose THEN Out.Char('.') END;
      IF buff = NIL THEN
        strUtils.appendNumChars(tmpBuff, readThisTime, buff, 0);
      ELSE
        strUtils.appendNumChars(tmpBuff, readThisTime, buff, LEN(buff^));
      END;
    UNTIL (readAll >= http^.rspnContentLength) OR eof OR readFailure OR ~http^.connectionFlag OR (http^.rspnContentLength = 0);
  IF verbose THEN Out.Ln END;
  http^.rspnBody := buff;
  RETURN buff;
END getKnownLengthRealloc;

(* the following is without unnecessary reallocations *)
PROCEDURE getKnownLength(VAR http: Client): strTypes.pstring;
VAR
  buff, tmpBuff: strTypes.pstring;
  eof: BOOLEAN;
  readThisTime, readAll, remaining, chunk, i: LONGINT;
BEGIN
  readAll := 0;
  eof := FALSE;

  (* rspnBody is a pstring, so allocate one extra byte for 0X.
     Save writes only rspnContentLength bytes. *)
  NEW(buff, http^.rspnContentLength + 1);
  i := 0;
  WHILE i < LEN(buff^) DO buff[i] := 0X; INC(i) END;

  WHILE (readAll < http^.rspnContentLength) & ~eof & http^.connectionFlag DO
    remaining := http^.rspnContentLength - readAll;
    chunk := remaining;
    IF chunk > 8192 THEN chunk := 8192 END;

    (* +1 so low-level readers that add 0X do not overflow. *)
    NEW(tmpBuff, chunk + 1);
    i := 0;
    WHILE i < LEN(tmpBuff^) DO tmpBuff[i] := 0X; INC(i) END;

    (* ReadBuf returns the actual number of bytes in readThisTime.
       This is important for HTTP and also for TLS, where one decrypted
       TLS record may be bigger than the caller's requested chunk. *)
    readThisTime := chunk;
    http^.connectionFlag := http.ReadBuf(http, tmpBuff^, readThisTime);

    IF (~http^.connectionFlag) OR (readThisTime <= 0) THEN
      eof := TRUE
    ELSE
      IF readThisTime > remaining THEN readThisTime := remaining END;
      i := 0;
      WHILE i < readThisTime DO
        buff[readAll + i] := tmpBuff[i];
        INC(i)
      END;
      readAll := readAll + readThisTime;
      IF verbose THEN Out.Char('.') END
    END
  END;

  IF readAll < LEN(buff^) THEN buff[readAll] := 0X END;
  IF verbose THEN Out.Ln; Out.String("body bytes read: "); Out.Int(readAll, 0); Out.Ln END;
  http^.rspnComplete := readAll = http^.rspnContentLength;
  IF ~http^.rspnComplete THEN
    Out.String("http: the body ended early, "); Out.Int(readAll, 0); Out.String(" of ");
    Out.Int(http^.rspnContentLength, 0); Out.String(" bytes"); Out.Ln;
    http^.rspnContentLength := readAll
  END;
  http^.rspnBody := buff;
  RETURN buff
END getKnownLength;

PROCEDURE fixChunkStr(VAR str: ARRAY OF CHAR);
VAR
  i: LONGINT;
BEGIN
  i := LEN(str)-1;
  REPEAT
    IF ~( ((str[i] >= 30X) & (str[i] <= 39X))
       OR ((str[i] >= 41X) & (str[i] <= 5AX))
       OR ((str[i] >= 61X) & (str[i] <= 7AX)) )THEN str[i] := 0X END;
    DEC(i)
  UNTIL i = 0;
END fixChunkStr;

PROCEDURE getNextChunkSize(VAR http: Client): LONGINT;
VAR
  tmp: ARRAY 2 OF CHAR;
  len: ARRAY 64 OF CHAR;
  i: INTEGER;
  out: LONGINT; res: SHORTINT;
BEGIN
  strUtils.zeroStr(len);
  i := 0;
  REPEAT
    http^.connectionFlag := http.Read(http, tmp, 1);
    IF ~http^.connectionFlag THEN RETURN -1 END;
    len[i] := tmp[0];
    INC(i)
  UNTIL (i = LEN(len)) OR (tmp[0] = 0AX) ;
  fixChunkStr(len);
  hexIntStr.StrToInt(len, out, res);
  IF (res # hexIntStr.strAllRight) OR (out < 0) THEN
    Out.String("http: bad chunk size: "); Out.String(len); Out.Ln; RETURN -1
  END;
  RETURN out;
END getNextChunkSize;

PROCEDURE expectCRLF(VAR http: Client);
  VAR
    tmp: ARRAY 3 OF CHAR;
BEGIN
  http^.connectionFlag := http.Read(http, tmp, 2);
  IF http^.connectionFlag & ((tmp[0] # 0DX) OR (tmp[1] # 0AX)) THEN
    Out.String("http: CR LF expected after a chunk"); Out.Ln; http^.connectionFlag := FALSE
  END
END expectCRLF;

(* the body in chunks: size in hex, CR LF, the bytes, CR LF; size 0 ends it *)
PROCEDURE getChunked(VAR http: Client): strTypes.pstring;
VAR
  buff, tmpBuff: strTypes.pstring;
  nextChunkSize, readAll: LONGINT;
BEGIN
  readAll := 0; buff := NIL;
  nextChunkSize := getNextChunkSize(http);
  WHILE (nextChunkSize > 0) & http^.connectionFlag DO
    NEW(tmpBuff, nextChunkSize + 1);
    http^.connectionFlag := http.Read(http, tmpBuff^, nextChunkSize);
    IF http^.connectionFlag THEN
      expectCRLF(http);
      strUtils.appendNumChars(tmpBuff, nextChunkSize, buff, readAll);
      readAll := readAll + nextChunkSize;
      IF verbose THEN Out.Char('.') END;
      IF http^.connectionFlag THEN nextChunkSize := getNextChunkSize(http) END
    END
  END;
  http^.rspnComplete := nextChunkSize = 0;
  IF nextChunkSize # 0 THEN Out.String("http: the chunked body ended early"); Out.Ln END;
  http^.rspnContentLength := readAll;
  RETURN buff
END getChunked;

(* the body up to the end of the connection *)
PROCEDURE getToEnd(VAR http: Client): strTypes.pstring;
VAR
  buff, tmpBuff: strTypes.pstring;
  n, readAll: LONGINT;
BEGIN
  readAll := 0; buff := NIL;
  NEW(tmpBuff, 8192);
  LOOP
    n := LEN(tmpBuff^);
    http^.connectionFlag := http.ReadBuf(http, tmpBuff^, n);
    IF ~http^.connectionFlag OR (n <= 0) THEN EXIT END;
    strUtils.appendNumChars(tmpBuff, n, buff, readAll);
    readAll := readAll + n;
    IF verbose THEN Out.Char('.') END
  END;
  http^.rspnContentLength := readAll;
  http^.rspnComplete := http^.endClean;
  IF ~http^.endClean THEN Out.String("http: the connection ended without a proper close, the body may be cut"); Out.Ln END;
  RETURN buff
END getToEnd;

(* the body as a string: one more byte, 0X *)
PROCEDURE Terminated(body: strTypes.pstring; n: LONGINT): strTypes.pstring;
VAR b: strTypes.pstring; i: LONGINT;
BEGIN
  NEW(b, n + 1);
  i := 0; WHILE i < n DO b[i] := body[i]; INC(i) END;
  b[n] := 0X;
  RETURN b
END Terminated;


PROCEDURE sendHeaders(VAR http: Client);
VAR
  i: INTEGER;
BEGIN
    i := 0;
    REPEAT
      http^.connectionFlag := http.Write(http, http^.reqHeader[i]^);
      INC(i)
    UNTIL i = LEN(http^.reqHeader^);
END sendHeaders;

PROCEDURE headersToString*(hdrs: headers; VAR ln: LONGINT): strUtils.pstring;
(* the header lines one after the other, 0X at the end; ln counts the 0X *)
VAR
  i, j, all, alli: LONGINT;
  pstr, h: strUtils.pstring;
BEGIN
  i := 0; all := 1;
  WHILE i < LEN(hdrs^) DO all := all + LEN(hdrs^[i]^); INC(i) END;
  IF verbose THEN Out.String(" all is "); Out.Int(all, 0); Out.Ln END;
  NEW(pstr, all);
  i := 0; alli := 0;
  WHILE i < LEN(hdrs^) DO
    h := hdrs^[i]; j := 0;
    WHILE j < LEN(h^) DO
      IF h[j] # 0X THEN pstr[alli] := h[j]; INC(alli) END;
      INC(j)
    END;
    INC(i)
  END;
  pstr[alli] := 0X;
  ln := alli+1;
  RETURN pstr
END headersToString;

(** GET: the body (ending with an extra 0X; its length is rspnContentLength), NIL if the
  connection failed; the status code is in rspnCode *)
PROCEDURE get*(http: Client): strTypes.pstring;
VAR
  header, body: strTypes.pstring;
  lengthFound: BOOLEAN;
BEGIN
  http^.clearState(http);
  http^.connectionFlag := http.Connect(http);
  IF ~http^.connectionFlag THEN
    Out.String("http: connection to "); Out.String(http^.host^); Out.String(" failed"); Out.Ln;
    RETURN NIL
  END;
  sendHeaders(http);
  IF http^.connectionFlag THEN
    header := readHeader(http);
    lengthFound := processHeader(http, header^);
    IF (http^.rspnTransferEncoding # NIL) & (http^.rspnTransferEncoding^ = "chunked") THEN
      body := getChunked(http);
      IF body # NIL THEN http^.rspnBody := Terminated(body, http^.rspnContentLength) END
    ELSIF lengthFound THEN
      IF http^.rspnContentLength > 0 THEN http^.rspnBody := getKnownLength(http)
      ELSE http^.rspnComplete := TRUE
      END
    ELSIF (http^.rspnCode # 204) & (http^.rspnCode # 304) & (http^.rspnCode >= 200) THEN
      body := getToEnd(http);
      IF body # NIL THEN http^.rspnBody := Terminated(body, http^.rspnContentLength) END
    ELSE http^.rspnComplete := TRUE  (* no body *)
    END;
    IF http^.rspnBody = NIL THEN
      NEW(http^.rspnBody, 1); http^.rspnBody[0] := 0X; http^.rspnContentLength := 0
    END
  END;
  http.Disconnect(http);
  RETURN http^.rspnBody
END get;

PROCEDURE nextHeaderLine(key, val: ARRAY OF CHAR): strTypes.pstring;
VAR
  header: strTypes.pstring;
  headerLength, tmp: LONGINT;
BEGIN
  headerLength := Strings.Length(key)
          + Strings.Length(val) + 2 (* 2 for ": " *)
          + 3; (* for eol: 0DX, 0AX, 0X *)
  NEW(header, headerLength);
  COPY(key, header^);
  Strings.Append(": ", header^);
  Strings.Append(val, header^);


  tmp := Strings.Length(header^);
  header^[tmp] := 0DX;
  header^[tmp+1] := 0AX;
  header^[tmp+2] := 0X;
  RETURN header
END nextHeaderLine;

PROCEDURE appendHdrLine*(h: Client; hdr: strTypes.pstring);
VAR
  i: LONGINT;
  oldLen: LONGINT;
  newHeaders: headers;
BEGIN
  oldLen := LEN(h^.reqHeader^);
  NEW(newHeaders, oldLen+1);
  i := 0;
  REPEAT
      newHeaders^[i] := h^.reqHeader^[i];
    INC(i)
  UNTIL i = oldLen-1;
  newHeaders^[i] := hdr;
  newHeaders^[i+1] := h^.reqHeader^[i];
  h^.reqHeader := newHeaders;
END appendHdrLine;

PROCEDURE formReqHeader*(http: Client);
VAR
  pstr: strTypes.pstring;
  len, tmp: INTEGER;
BEGIN
  NEW(http^.reqHeader, defReqHeaderLength);
  len := Strings.Length(http^.path^) + 1 (* space *) + Strings.Length(http^.version^) + 4 + 3 (* "GET " *);
  NEW(http^.reqHeader[0], len);
  COPY(defGetStr, http^.reqHeader[0]^);
  Strings.Append(" ",           http^.reqHeader[0]^);
  Strings.Append(http^.path^,    http^.reqHeader[0]^);
  Strings.Append(" ",           http^.reqHeader[0]^);
  Strings.Append(http^.version^, http^.reqHeader[0]^);
  tmp := Strings.Length(http^.reqHeader[0]^);
  http^.reqHeader[0]^[tmp] := 0DX;
  http^.reqHeader[0]^[tmp+1] := 0AX;
  http^.reqHeader[0]^[tmp+2] := 0X;
  (*
  Strings.Append(http^.eol,     http^.reqHeader[0]^);
  Strings.Append(http^.null,    http^.reqHeader[0]^);
*)
  IF (http^.port^ = "80") OR (http^.port^ = "443") OR (http^.port^ = "http") OR (http^.port^ = "https") THEN
    http^.reqHeader[1] := nextHeaderLine(defHostStr, http^.host^)
  ELSE
    NEW(pstr, Strings.Length(http^.host^) + Strings.Length(http^.port^) + 2);
    COPY(http^.host^, pstr^); Strings.Append(":", pstr^); Strings.Append(http^.port^, pstr^);
    http^.reqHeader[1] := nextHeaderLine(defHostStr, pstr^)
  END;

  http^.reqHeader[2] := nextHeaderLine(defUAStr, http^.userAgent^);

  http^.reqHeader[3] := nextHeaderLine(defAcceptStr, defEverythingStr);

  http^.reqHeader[4] := nextHeaderLine(defConnectionStr, defCloseStr);

  NEW(http^.reqHeader[5], 3);
  http^.reqHeader[5]^[0] := 0DX; http^.reqHeader[5]^[1] := 0AX; http^.reqHeader[5]^[2] := 0X;
END formReqHeader;

PROCEDURE setuseragent*(VAR http: Client; ua: ARRAY OF CHAR);
BEGIN
  strUtils.string2pstring(ua, http^.userAgent)
END setuseragent;

PROCEDURE save*(http: Client);
VAR
  F: Files.File; R: Files.Rider;
  out0, out1: strTypes.pstring;
  i: LONGINT;
  pos: INTEGER;
  size: LONGINT;
BEGIN
  IF http^.rspnBody = NIL THEN size := 0 ELSE size := http^.rspnContentLength END;
  NEW(out0, Strings.Length(http^.path^)+1);
  NEW(out1, Strings.Length(http^.path^)+1);
  COPY(http^.path^, out0^);
  IF (out0^ = "/") OR (out0^ = "") THEN
     NEW(out1, Strings.Length(defName)+1);
     COPY(defName, out1^);
  ELSE
    strUtils.RemoveRightChars(out0^, '/');
    pos := strUtils.Rpos(out0^, '/');
    NEW(out1, Strings.Length(out0^)-pos);
    Strings.Extract(out0^, pos+1, Strings.Length(out0^)-pos-1, out1^);
  END;
  F := Files.New(out1^);
  IF F # NIL THEN
    Files.Set(R, F, 0);
    i := 0;
    WHILE i < size DO
      Files.Write(R, http^.rspnBody[i]);
      INC(i)
    END;
    Files.Register(F);
  ELSE
    Out.String("failed to create file "); Out.String(out1^); Out.Ln;
  END
END save;

PROCEDURE appendUserPasswdHdr*(h: Client; user, password: ARRAY OF CHAR);
VAR
  credentials, b64credentials, aHdrVal, authHeader: strTypes.pstring;
BEGIN
  NEW(credentials, Strings.Length(user)+ Strings.Length(password) + 1(* +1 is enough since we don't want string to be fixed in Base64.fix *));
  Base64.fixToIncludeEOL := FALSE;
  COPY(user, credentials^);
  Strings.Append(":", credentials^);
  Strings.Append(password, credentials^);
  NEW(b64credentials, Strings.Length(credentials^)*2(* to certainly fit base64 encoded string *));
  Base64.EncodeString(credentials^, b64credentials^);
  NEW(aHdrVal,  Strings.Length(defAuth) (* Basic *) + Strings.Length(b64credentials^) + 3 (* whitespace and null *));
  COPY(defAuth, aHdrVal^); Strings.Append(" ", aHdrVal^);
  Strings.Append(b64credentials^, aHdrVal^);
  authHeader := nextHeaderLine(hdrAuth, aHdrVal^);
  appendHdrLine(h, authHeader);
END appendUserPasswdHdr;

PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  http: Client;
  socket: bsdSocket;
BEGIN
  NEW(http);
  http^.eol[0] := 0DX; http^.eol[1] := 0AX; http^.null[0] := 0X;
  strUtils.string2pstring(host, http^.host);
  strUtils.string2pstring(port, http^.port);
  strUtils.string2pstring(path, http^.path);
  strUtils.string2pstring(defUserAgent, http^.userAgent);
  strUtils.string2pstring(defHttpVersion, http^.version);

  http^.Get := get;
  http^.setUserAgent := setuseragent;
  http^.clearState := clearstate;
  http^.Save := save;
  formReqHeader(http);
  (*dumpHeaders(http^.reqHeader);*)


  clearstate(http);

  NEW(socket);
  http^.trn := socket;
  http.Connect := connector;
  http.Disconnect := disconnector;
  http.Read := reader;
  http.ReadBuf := readBuf;
  http.Write := writer;

  http.appendHeader  := appendHdrLine;
  http.appendAuthHdr := appendUserPasswdHdr;

  RETURN http
END Create;

BEGIN
  verbose := FALSE
END http.
