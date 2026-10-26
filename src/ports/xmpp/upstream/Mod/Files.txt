MODULE XmppFiles;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)
	IMPORT Files, DS:=StringsDyn, Md5:=ypkCryptMd5, Log;
	
	TYPE
		DynString* = DS.String;
		String* = ARRAY OF CHAR;

	PROCEDURE GetFileChecksum*(f: Files.File; OUT hash: ARRAY OF CHAR; offset, length: INTEGER);
		VAR rd: Files.Reader; c: Md5.Context; digest: Md5.Digest; x: BYTE; s: ARRAY 33 OF SHORTCHAR; pos, end: INTEGER;
	BEGIN
		rd := f.NewReader(NIL); 
		c := Md5.New();
		pos:=offset; end:=length;
		rd.SetPos(pos);
		WHILE pos<end DO
			rd.ReadByte(x);
			Md5.Write(c, SHORT(CHR(x)));
			INC(pos);
		END;
		Md5.Close(c, digest);
		Md5.ToString(digest, s);
		hash := s$
	END GetFileChecksum;

BEGIN

END XmppFiles.