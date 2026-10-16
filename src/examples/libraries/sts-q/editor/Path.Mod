MODULE Path;   (* :file: Path.Mod  --  Functions on file paths. *)
(* VOC adaptation, 2026-10-16: retain upstream's 32-bit integer contract. *)
IMPORT ssqTypes, Str;
TYPE INTEGER = ssqTypes.Integer;


(* ------------------------------------------------------------------------- *)
(* :section:    path parts *)
PROCEDURE Directory* (VAR dir, path: ARRAY OF CHAR);            (** path up to last and inclusive '/' *)
VAR pos: INTEGER;
BEGIN
   IF Str.FindCharLast (path, '/', pos) THEN
      Str.Head (dir, path, pos + 1);  (* incluce '/' *)
   ELSE dir[0] := 0X
   END;
END Directory;

PROCEDURE FileBasename* (VAR name, path: ARRAY OF CHAR);        (** base of path: 'myfile' *)
VAR start,end: INTEGER;
BEGIN
   IF Str.FindCharLast (path, '/', start) THEN
      INC (start)
   ELSE start := 0
   END;
   IF Str.FindCharLast (path, '.', end) THEN END; (* no '.' --> end := Length(path) *)
   Str.Sub (name, path, start, end);
END FileBasename;

PROCEDURE FileExtension* (VAR ext, path: ARRAY OF CHAR);        (** return file extension: 'ext' *)
VAR pos: INTEGER;
BEGIN
   IF Str.FindCharLast (path, '.', pos) THEN
      Str.Tail (ext, path, pos + 1);
   ELSE ext[0] := 0X
   END;
END FileExtension;

PROCEDURE FileName* (VAR name, path: ARRAY OF CHAR);            (** return filename of path: 'myfile.ext' *)
VAR pos: INTEGER;
BEGIN
   IF Str.FindCharLast (path, '/', pos) THEN
      Str.Tail (name, path, pos + 1);
   ELSE COPY (path, name);
   END;
END FileName;

(* ------------------------------------------------------------------------- *)
(* :section:    file type *)
PROCEDURE FileType* (VAR type, path: ARRAY OF CHAR): BOOLEAN;   (** return filetype from path: obn|txt ... *)
VAR
   ext: ARRAY 32 OF CHAR;
   res: BOOLEAN;

   PROCEDURE Rtn (t: ARRAY OF CHAR); BEGIN COPY (t, type) END Rtn;

BEGIN
   FileExtension (ext, path);
   res := TRUE;
   IF FALSE THEN
   ELSIF ext = "Mod"   THEN Rtn ("obn/voc")
   ELSIF ext = "c"     THEN Rtn ("c")
   ELSIF ext = "curry" THEN Rtn ("curry")
   ELSIF ext = "dcl"   THEN Rtn ("clean")
   ELSIF ext = "fasm"  THEN Rtn ("fasm")
   ELSIF ext = "fs"    THEN Rtn ("forth")
   ELSIF ext = "f"     THEN Rtn ("forth")
   ELSIF ext = "hs"    THEN Rtn ("haskell")
   ELSIF ext = "icl"   THEN Rtn ("clean")
   ELSIF ext = "lhs"   THEN Rtn ("haskell")
   ELSIF ext = "m"     THEN Rtn ("miranda")
   ELSIF ext = "md"    THEN Rtn ("md")
   ELSIF ext = "minal" THEN Rtn ("minal")
   ELSIF ext = "tila"  THEN Rtn ("tila")
   ELSIF ext = "mod"   THEN Rtn ("obn")
   ELSIF ext = "ob"    THEN Rtn ("obn/oc7")
   ELSIF ext = "obn"   THEN Rtn ("obn/kir")
   ELSIF ext = "pl"    THEN Rtn ("prolog")
   ELSIF ext = "py"    THEN Rtn ("python")
   ELSIF ext = "rabbit"THEN Rtn ("rabbit")
   ELSIF ext = "scm"   THEN Rtn ("lisp")
   ELSIF ext = "sld"   THEN Rtn ("lisp")                (* scheme lib desc *)
   ELSIF ext = "susel" THEN Rtn ("susel")
   ELSIF ext = "susel2"THEN Rtn ("susel2")
   ELSIF ext = "txt"   THEN Rtn ("txt")
   ELSIF ext = "zig"   THEN Rtn ("zig")
   ELSIF ext = "ijs"   THEN Rtn ("j")
   ELSIF ext = "sml"   THEN Rtn ("pas")
   ELSIF ext = "m3"    THEN Rtn ("m3")
   ELSIF ext = "i3"    THEN Rtn ("m3")
   ELSIF ext = "v"     THEN Rtn ("v")
   ELSIF ext = "lena"  THEN Rtn ("lisp")
   ELSIF ext = "lisp"  THEN Rtn ("lisp")
   ELSE
      type[0] := 0X;
      res := FALSE
   END;
   RETURN res
END FileType;

PROCEDURE TabWidth* (path: ARRAY OF CHAR): INTEGER;
VAR type: ARRAY 32 OF CHAR;
   res: INTEGER;
   anyway: BOOLEAN;
BEGIN
   anyway := FileType (type, path);
   IF    type = "python"        THEN res := 4
   ELSIF type = "zig"           THEN res := 4
   ELSE res := 3
   END;
   RETURN res;
END TabWidth;


(* ------------------------------------------------------------------------- *)
END Path.
(* :file: END (c) sts-q 2024-Feb *)
